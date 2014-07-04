module bulletml.flatten;

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
  BulletML resolved = BulletML();

  resolved.orientation = bml.orientation;
  foreach (elem; bml.elements) {
    elem.tryVisit!((Action action) {
        if (action.label.length >= 3 && action.label[0..3] == "top") {
          resolved.elements ~= BulletML.Element(_resolve!Action(bml, action, []));
        }
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

private Accel _resolve(T: Accel)(BulletML bml, Accel unresolved, Expression[] params) {
  Accel resolved = Accel();

  resolved.horizontal = _resolve(bml, unresolved.horizontal, params);
  resolved.vertical = _resolve(bml, unresolved.vertical, params);
  resolved.term = _resolve!Term(bml, unresolved.term, params);

  return resolved;
}

private Action _resolve(T: Action)(BulletML bml, Action unresolved, Expression[] params) {
  Action resolved = Action();

  resolved.label = unresolved.label;
  resolved.contents = _resolve(bml, unresolved.contents, params);

  return resolved;
}

private Bullet _resolve(T: Bullet)(BulletML bml, Bullet unresolved, Expression[] params) {
  Bullet resolved = Bullet();

  resolved.label = unresolved.label;
  resolved.direction = _resolve(bml, unresolved.direction, params);
  resolved.speed = _resolve(bml, unresolved.speed, params);
  resolved.actions = _resolve(bml, unresolved.actions, params);

  return resolved;
}

private ChangeDirection _resolve(T: ChangeDirection)(BulletML bml, ChangeDirection unresolved, Expression[] params) {
  ChangeDirection resolved = ChangeDirection();

  resolved.direction = _resolve!Direction(bml, unresolved.direction, params);
  resolved.term = _resolve!Term(bml, unresolved.term, params);

  return resolved;
}

private ChangeSpeed _resolve(T: ChangeSpeed)(BulletML bml, ChangeSpeed unresolved, Expression[] params) {
  ChangeSpeed resolved = ChangeSpeed();

  resolved.speed = _resolve!Speed(bml, unresolved.speed, params);
  resolved.term = _resolve!Term(bml, unresolved.term, params);

  return resolved;
}

private Direction _resolve(T: Direction)(BulletML bml, Direction unresolved, Expression[] params) {
  Direction resolved = Direction();

  resolved.type = unresolved.type;
  resolved.degrees = resolveExpr(unresolved.degrees, params);

  return resolved;
}

private Fire _resolve(T: Fire)(BulletML bml, Fire unresolved, Expression[] params) {
  Fire resolved = Fire();

  resolved.label = unresolved.label;
  resolved.direction = _resolve(bml, unresolved.direction, params);
  resolved.speed = _resolve(bml, unresolved.speed, params);
  resolved.bullet = _resolve(bml, unresolved.bullet, params);

  return resolved;
}

private Horizontal _resolve(T: Horizontal)(BulletML bml, Horizontal unresolved, Expression[] params) {
  Horizontal resolved = Horizontal();

  resolved.type = unresolved.type;
  resolved.change = resolveExpr(unresolved.change, params);

  return resolved;
}

private Param _resolve(T: Param)(BulletML bml, Param unresolved, Expression[] params) {
  Param resolved = Param();

  resolved.value = resolveExpr(unresolved.value, params).get();

  return resolved;
}

private Repeat _resolve(T: Repeat)(BulletML bml, Repeat unresolved, Expression[] params) {
  Repeat resolved = Repeat();

  resolved.times = _resolve!Times(bml, unresolved.times, params);
  resolved.actions = _resolve(bml, unresolved.actions, params);

  return resolved;
}

private Speed _resolve(T: Speed)(BulletML bml, Speed unresolved, Expression[] params) {
  Speed resolved = Speed();

  resolved.type = unresolved.type;
  resolved.change = resolveExpr(unresolved.change, params);

  return resolved;
}

private Term _resolve(T: Term)(BulletML bml, Term unresolved, Expression[] params) {
  Term resolved = Term();

  resolved.value = resolveExpr(unresolved.value, params);

  return resolved;
}

private Times _resolve(T: Times)(BulletML bml, Times unresolved, Expression[] params) {
  Times resolved = Times();

  resolved.value = resolveExpr(unresolved.value, params);

  return resolved;
}

private Vanish _resolve(T: Vanish)(BulletML bml, Vanish unresolved, Expression[] params) {
  Vanish resolved = Vanish();

  return resolved;
}

private Vertical _resolve(T: Vertical)(BulletML bml, Vertical unresolved, Expression[] params) {
  Vertical resolved = Vertical();

  resolved.type = unresolved.type;
  resolved.change = resolveExpr(unresolved.change, params);

  return resolved;
}

private Wait _resolve(T: Wait)(BulletML bml, Wait unresolved, Expression[] params) {
  Wait resolved = Wait();

  resolved.frames = resolveExpr(unresolved.frames, params);

  return resolved;
}

private Expression resolveExpr(Expression expr, Expression[] params) {
  if (expr.isConstant()) {
    return expr;
  }

  ExpressionParameter param = cast(ExpressionParameter) expr;
  if (param !is null) {
    if (param.idx <= 0 || params.length < param.idx) {
      throw new Exception("Looking for parameter " ~ to!string(param.idx) ~ ", but only " ~ to!string(params.length) ~ " available");
    }
    expr = params[param.idx - 1];
  }

  ExpressionOperation op = cast(ExpressionOperation) expr;
  if (op !is null) {
    op.lhs = resolveExpr(op.lhs, params);
    op.rhs = resolveExpr(op.rhs, params);
  }

  if (expr.isConstant()) {
    expr = new ExpressionConstant(expr());
  }

  return expr;
}

private Nullable!T _resolve(T)(BulletML bml, Nullable!T unresolved, Expression[] params) {
  if (unresolved.isNull) {
    return unresolved;
  }

  return Nullable!T(_resolve!T(bml, unresolved.get(), params));
}

private T _resolve(U: ORef!T, T)(BulletML bml, U unresolved, Expression[] params) {
  Expression[] resolvedParams;

  foreach (Param param; unresolved.params) {
    resolvedParams ~= resolveExpr(param.value, params);
  }

  Nullable!T target = findElement!T(bml, unresolved.label);
  if (target.isNull) {
    throw new Exception("could not find target " ~ typeid(T).toString ~ " named " ~ unresolved.label);
  }
  return _resolve!T(bml, target, resolvedParams);
}

private U _resolve(U: T[], T)(BulletML bml, U unresolveds, Expression[] params) {
  U resolved;

  foreach (unresolved; unresolveds) {
    resolved ~= _resolve!T(bml, unresolved, params);
  }

  return resolved;
}

private D _resolve(D: VariantN!A, A...)(BulletML bml, D unresolved, Expression[] params) {
  foreach (T; D.AllowedTypes) {
    T* item = unresolved.peek!T();
    if (item !is null) {
      static if (isPointer!T) {
        alias Target = PointerTarget!T;
        Target resolved = _resolve!Target(bml, **item, params);
        Target* gcResolved = new Target();
        *gcResolved = resolved;
        return D(gcResolved);
      } else static if (isInstanceOf!(ORef, T) && D.allowed!(T.Referent*)) {
        alias Target = T.Referent;
        Target resolved = _resolve!T(bml, *item, params);
        Target* gcResolved = new Target();
        *gcResolved = resolved;
        return D(gcResolved);
      } else {
        return D(_resolve!T(bml, *item, params));
      }
    }
  }

  assert(0);
}

private Nullable!T findElement(T)(BulletML bml, string label) {
  foreach (elem; bml.elements) {
    Nullable!T item = _findElement!T(elem, label);
    if (!item.isNull) {
      return item;
    }
  }

  return Nullable!T();
}

private Nullable!T _findElement(T, U)(U[] elems, string label) {
  foreach (elem; elems) {
    Nullable!T item = _findElement!T(elem, label);
    if (!item.isNull) {
      return item;
    }
  }

  return Nullable!T();
}

private Nullable!T _findElement(T, D: VariantN!A, A...)(D elem, string label) {
  foreach (U; D.AllowedTypes) {
    U* item = elem.peek!U();
    if (item !is null) {
      return _findElement!(T, U)(*item, label);
    }
  }

  return Nullable!T();
}

private Nullable!T _findElement(T, U)(U item, string label) if (isPointer!U) {
  return _findElement!(T, PointerTarget!U)(*item, label);
}

private Nullable!T _findElement(T, U)(U item, string label)
  if (!is(T == U) &&
      !isInstanceOf!(VariantN, U) &&
      !isInstanceOf!(ORef, U) &&
      !isArray!(U) &&
      !isPointer!U) {
  return Nullable!T();
}

private Nullable!T _findElement(T, U)(U elem, string label) if (isInstanceOf!(ORef, U)) {
  return Nullable!T();
}

private Nullable!T _findElement(T, U: Action)(U action, string label) {
  Nullable!T self = findElementSelf!T(action, label);
  if (!self.isNull) {
    return self;
  }

  return _findElement!T(action.contents, label);
}

private Nullable!T _findElement(T, U: Bullet)(U bullet, string label) {
  Nullable!T self = findElementSelf!T(bullet, label);
  if (!self.isNull) {
    return self;
  }

  return _findElement!T(bullet.actions, label);
}

private Nullable!T _findElement(T, U: Fire)(Fire fire, string label) {
  Nullable!T self = findElementSelf!T(fire, label);
  if (!self.isNull) {
    return self;
  }

  return _findElement!T(fire.bullet, label);
}

private Nullable!T findElementSelf(T, U)(U item, string label) {
  static if (is(T == U)) {
    if (label == item.label) {
      return Nullable!T(item);
    }
  }

  return Nullable!T();
}
