module bulletml.resolve;

private import bulletml.data.bulletml;

private import std.conv;
private import std.traits;

public class ResolvedBulletML {
  private:
    BulletML bml;

    package this(BulletML bml) {
      this.bml = bml;
    }

    public const(BulletML) get() const {
      return bml;
    }
}

public ResolvedBulletML resolve(BulletML bml) {
  BulletML resolved = bml;

  foreach (ref elem; resolved.elements) {
    elem.tryVisit!(
      (ref Action action) {
        if (action.label.length >= 3 && action.label[0..3] == "top") {
          _resolve!Action(resolved, action, []);
        }
      },
      () {
      })();
  }

  return new ResolvedBulletML(resolved);
}

public ResolvedBulletML bulletWithActions(BulletML.Orientation orientation, Action[] actions) {
  BulletML resolved = BulletML();

  resolved.orientation = orientation;
  foreach (Action action; actions) {
    resolved.elements ~= BulletML.Element(action);
  }

  return new ResolvedBulletML(resolved);
}

private void _resolve(T: Accel)(BulletML bml, ref Accel resolved, Expression[] params) {
  _resolve(bml, resolved.horizontal, params);
  _resolve(bml, resolved.vertical, params);
  _resolve!Term(bml, resolved.term, params);
}

private void _resolve(T: Action)(BulletML bml, ref Action resolved, Expression[] params) {
  _resolve(bml, resolved.contents, params);
}

private void _resolve(T: Bullet)(BulletML bml, ref Bullet resolved, Expression[] params) {
  _resolve(bml, resolved.direction, params);
  _resolve(bml, resolved.speed, params);
  _resolve(bml, resolved.actions, params);
}

private void _resolve(T: ChangeDirection)(BulletML bml, ref ChangeDirection resolved, Expression[] params) {
  _resolve!Direction(bml, resolved.direction, params);
  _resolve!Term(bml, resolved.term, params);
}

private void _resolve(T: ChangeSpeed)(BulletML bml, ref ChangeSpeed resolved, Expression[] params) {
  _resolve!Speed(bml, resolved.speed, params);
  _resolve!Term(bml, resolved.term, params);
}

private void _resolve(T: Direction)(BulletML bml, ref Direction resolved, Expression[] params) {
  resolveExpr(resolved.degrees, params);
}

private void _resolve(T: Fire)(BulletML bml, ref Fire resolved, Expression[] params) {
  _resolve(bml, resolved.direction, params);
  _resolve(bml, resolved.speed, params);
  _resolve(bml, resolved.bullet, params);
}

private void _resolve(T: Horizontal)(BulletML bml, ref Horizontal resolved, Expression[] params) {
  resolveExpr(resolved.change, params);
}

private void _resolve(T: Param)(BulletML bml, ref Param resolved, Expression[] params) {
  resolveExpr(resolved.value, params).get();
}

private void _resolve(T: Repeat)(BulletML bml, ref Repeat resolved, Expression[] params) {
  _resolve!Times(bml, resolved.times, params);
  _resolve(bml, resolved.actions, params);
}

private void _resolve(T: Speed)(BulletML bml, ref Speed resolved, Expression[] params) {
  resolveExpr(resolved.change, params);
}

private void _resolve(T: Term)(BulletML bml, ref Term resolved, Expression[] params) {
  resolveExpr(resolved.value, params);
}

private void _resolve(T: Times)(BulletML bml, ref Times resolved, Expression[] params) {
  resolveExpr(resolved.value, params);
}

private void _resolve(T: Vanish)(BulletML bml, ref Vanish resolved, Expression[] params) {
}

private void _resolve(T: Vertical)(BulletML bml, ref Vertical resolved, Expression[] params) {
  resolveExpr(resolved.change, params);
}

private void _resolve(T: Wait)(BulletML bml, ref Wait resolved, Expression[] params) {
  resolveExpr(resolved.frames, params);
}

private void _resolve(T: ORef!U, U)(BulletML bml, ref T resolved, Expression[] params) {
  resolved.target = findElement!U(bml, resolved.label);

  if (resolved.target is null) {
    throw new Exception("could not find target " ~ typeid(U).toString ~ " named " ~ resolved.label);
  }
}

private void resolveExpr(ref Expression expr, Expression[] params) {
  if (expr.isConstant()) {
    return;
  }

  ExpressionParameter param = cast(ExpressionParameter) expr;
  if (param !is null) {
    if (param.idx <= 0 || params.length < param.idx) {
      expr = new ExpressionConstant(1);
    } else {
      expr = params[param.idx - 1];
    }
  }

  ExpressionOperation op = cast(ExpressionOperation) expr;
  if (op !is null) {
    resolveExpr(op.lhs, params);
    resolveExpr(op.rhs, params);
  }

  if (expr.isConstant()) {
    expr = new ExpressionConstant(expr());
  }
}

private void _resolve(T)(BulletML bml, ref Nullable!T resolved, Expression[] params) {
  if (resolved.isNull) {
    return;
  }

  _resolve!T(bml, resolved.get(), params);
}

private void _resolve(U: T[], T)(BulletML bml, ref U unresolveds, Expression[] params) {
  foreach (ref resolved; unresolveds) {
    _resolve!T(bml, resolved, params);
  }
}

private void _resolve(D: VariantN!A, A...)(BulletML bml, ref D resolved, Expression[] params) {
  foreach (T; D.AllowedTypes) {
    T* item = resolved.peek!T();
    if (item !is null) {
      static if (isPointer!T) {
        alias Target = PointerTarget!T;
        _resolve!Target(bml, **item, params);
        return;
      } else {
        _resolve!T(bml, *item, params);
        return;
      }
    }
  }

  assert(0);
}

private T* findElement(T)(ref BulletML bml, string label) {
  foreach (elem; bml.elements) {
    T* item = _findElement!T(elem, label);
    if (item !is null) {
      return item;
    }
  }

  return null;
}

private T* _findElement(T, U)(ref U[] elems, string label) {
  foreach (elem; elems) {
    T* item = _findElement!T(elem, label);
    if (item !is null) {
      return item;
    }
  }

  return null;
}

private T* _findElement(T, D: VariantN!A, A...)(ref D elem, string label) {
  foreach (U; D.AllowedTypes) {
    U* item = elem.peek!U();
    if (item !is null) {
      return _findElement!(T, U)(*item, label);
    }
  }

  return null;
}

private T* _findElement(T, U)(ref U item, string label) if (isPointer!U) {
  return _findElement!(T, PointerTarget!U)(*item, label);
}

private T* _findElement(T, U)(ref U item, string label)
  if (!is(T == U) &&
      !isInstanceOf!(VariantN, U) &&
      !isInstanceOf!(ORef, U) &&
      !isArray!(U) &&
      !isPointer!U) {
  return null;
}

private T* _findElement(T, U)(ref U elem, string label) if (isInstanceOf!(ORef, U)) {
  return null;
}

private T* _findElement(T, U: Action)(ref U action, string label) {
  T* self = findElementSelf!T(action, label);
  if (self !is null) {
    return self;
  }

  return _findElement!T(action.contents, label);
}

private T* _findElement(T, U: Bullet)(ref U bullet, string label) {
  T* self = findElementSelf!T(bullet, label);
  if (self !is null) {
    return self;
  }

  return _findElement!T(bullet.actions, label);
}

private T* _findElement(T, U: Fire)(ref Fire fire, string label) {
  T* self = findElementSelf!T(fire, label);
  if (self !is null) {
    return self;
  }

  return _findElement!T(fire.bullet, label);
}

private T* findElementSelf(T, U)(ref U item, string label) {
  static if (is(T == U)) {
    if (label == item.label) {
      return &item;
    }
  }

  return null;
}
