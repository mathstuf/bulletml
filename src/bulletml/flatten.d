module bulletml.flatten;

private import bulletml.data.bulletml;

private import std.traits;

public class Resolved(T) {
  private:
    T item;

    package this(T item) {
      this.item = item;
    }

    public T get() {
      return item;
    }
}

public Resolved!BulletML resolve(T: BulletML)(BulletML bml) {
  BulletML resolved = new BulletML;

  resolved.orientation = bml.orientation;
  foreach (elem; bml.elements) {
    Action* action = elem.peek!Action();
    if (action !is null &&
        action.label[0..3] == "top") {
      resolved.elements ~= BulletML.Element(_resolve!Action(bml, *action, []));
    }
  }

  return new Resolved!BulletML(resolved);
}

private Accel _resolve(T: Accel)(BulletML bml, Accel unresolved, Expression params[]) {
  Accel resolved = new Accel;

  resolved.horizontal = _resolve(bml, unresolved.horizontal, params);
  resolved.vertical = _resolve(bml, unresolved.vertical, params);
  resolved.term = _resolve!Term(bml, unresolved.term, params);

  return resolved;
}

private Action _resolve(T: Action)(BulletML bml, Action unresolved, Expression params[]) {
  Action resolved = new Action;

  resolved.label = unresolved.label;
  resolved.contents = _resolve(bml, unresolved.contents, params);

  return resolved;
}

private Bullet _resolve(T: Bullet)(BulletML bml, Bullet unresolved, Expression params[]) {
  Bullet resolved = new Bullet;

  resolved.label = unresolved.label;
  resolved.direction = _resolve(bml, unresolved.direction, params);
  resolved.speed = _resolve(bml, unresolved.speed, params);
  resolved.actions = _resolve(bml, unresolved.actions, params);

  return resolved;
}

private ChangeDirection _resolve(T: ChangeDirection)(BulletML bml, ChangeDirection unresolved, Expression params[]) {
  ChangeDirection resolved = new ChangeDirection;

  resolved.direction = _resolve!Direction(bml, unresolved.direction, params);
  resolved.term = _resolve!Term(bml, unresolved.term, params);

  return resolved;
}

private ChangeSpeed _resolve(T: ChangeSpeed)(BulletML bml, ChangeSpeed unresolved, Expression params[]) {
  ChangeSpeed resolved = new ChangeSpeed;

  resolved.speed = _resolve!Speed(bml, unresolved.speed, params);
  resolved.term = _resolve!Term(bml, unresolved.term, params);

  return resolved;
}

private Direction _resolve(T: Direction)(BulletML bml, Direction unresolved, Expression params[]) {
  Direction resolved = new Direction;

  resolved.type = unresolved.type;
  resolved.degrees = resolveExpr(unresolved.degrees, params);

  return resolved;
}

private Fire _resolve(T: Fire)(BulletML bml, Fire unresolved, Expression params[]) {
  Fire resolved = new Fire;

  resolved.label = unresolved.label;
  resolved.direction = _resolve(bml, unresolved.direction, params);
  resolved.speed = _resolve(bml, unresolved.speed, params);
  resolved.bullet = _resolve(bml, unresolved.bullet, params);

  return resolved;
}

private Horizontal _resolve(T: Horizontal)(BulletML bml, Horizontal unresolved, Expression params[]) {
  Horizontal resolved = new Horizontal;

  resolved.type = unresolved.type;
  resolved.change = resolveExpr(unresolved.change, params);

  return resolved;
}

private Param _resolve(T: Param)(BulletML bml, Param unresolved, Expression params[]) {
  Param resolved = new Param;

  resolved.value = resolveExpr(unresolved.value, params).get();

  return resolved;
}

private Repeat _resolve(T: Repeat)(BulletML bml, Repeat unresolved, Expression params[]) {
  Repeat resolved = new Repeat;

  resolved.times = _resolve!Times(bml, unresolved.times, params);
  resolved.action = _resolve(bml, unresolved.action, params);

  return resolved;
}

private Speed _resolve(T: Speed)(BulletML bml, Speed unresolved, Expression params[]) {
  Speed resolved = new Speed;

  resolved.type = unresolved.type;
  resolved.change = resolveExpr(unresolved.change, params);

  return resolved;
}

private Term _resolve(T: Term)(BulletML bml, Term unresolved, Expression params[]) {
  Term resolved = new Term;

  resolved.value = resolveExpr(unresolved.value, params);

  return resolved;
}

private Times _resolve(T: Times)(BulletML bml, Times unresolved, Expression params[]) {
  Times resolved = new Times;

  resolved.value = resolveExpr(unresolved.value, params);

  return resolved;
}

private Vanish _resolve(T: Vanish)(BulletML bml, Vanish unresolved, Expression params[]) {
  Vanish resolved = new Vanish;

  return resolved;
}

private Vertical _resolve(T: Vertical)(BulletML bml, Vertical unresolved, Expression params[]) {
  Vertical resolved = new Vertical;

  resolved.type = unresolved.type;
  resolved.change = resolveExpr(unresolved.change, params);

  return resolved;
}

private Wait _resolve(T: Wait)(BulletML bml, Wait unresolved, Expression params[]) {
  Wait resolved = new Wait;

  resolved.frames = resolveExpr(unresolved.frames, params);

  return resolved;
}

private Expression resolveExpr(Expression expr, Expression params[]) {
  if (expr.isConstant()) {
    return expr;
  }

  ExpressionParameter param = cast(ExpressionParameter) expr;
  if (param !is null) {
    expr = params[param.idx];
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

private Nullable!T _resolve(T)(BulletML bml, Nullable!T unresolved, Expression params[]) {
  if (unresolved.isNull()) {
    return unresolved;
  }

  return Nullable!T(_resolve!T(bml, unresolved.get(), params));
}

private T _resolve(U: ORef!T, T)(BulletML bml, U unresolved, Expression params[]) {
  Expression resolvedParams[];

  foreach (Param param; unresolved.params) {
    resolvedParams ~= resolveExpr(param.value, params);
  }

  T target = findElement!T(bml, unresolved.label);
  return _resolve!T(bml, target, resolvedParams);
}

private U _resolve(U: T[], T)(BulletML bml, U unresolveds, Expression params[]) {
  U resolved;

  foreach (unresolved; unresolveds) {
    resolved ~= _resolve!T(bml, unresolved, params);
  }

  return resolved;
}

private D _resolve(D: VariantN!A, A...)(BulletML bml, D unresolved, Expression params[]) {
  foreach (T; D.AllowedTypes) {
    T* item = unresolved.peek!T();
    if (item !is null) {
      static if (isPointer!T) {
        PointerTarget!T resolved = _resolve!(PointerTarget!T)(bml, **item, params);
        return D(&resolved);
      } else static if (isInstanceOf!(ORef, T) && D.allowed!(T.Referent*)) {
        T.Referent resolved = _resolve!T(bml, *item, params);
        return D(&resolved);
      } else {
        return D(_resolve!T(bml, *item, params));
      }
    }
  }

  assert(0);
}

private T findElement(T)(BulletML bml, string label) {
  foreach (elem; bml.elements) {
    T item = _findElement!T(elem, label);
    if (item !is null) {
      return item;
    }
  }

  return null;
}

private T _findElement(T)(Action action, string label) {
  T self = findElementSelf(action, label);
  if (self !is null) {
    return self;
  }

  return _findElement!T(action.bullet, label);
}

private T _findElement(T)(Bullet bullet, string label) {
  T self = findElementSelf(bullet, label);
  if (self !is null) {
    return self;
  }

  return _findElement!T(bullet.actions, label);
}

private T _findElement(T)(Fire fire, string label) {
  T self = findElementSelf(fire, label);
  if (self !is null) {
    return self;
  }

  return _findElement!T(fire.bullet, label);
}

private T _findElement(T)(T* item, string label) {
  return _findElement!T(*item, label);
}

private T findElementSelf(T)(T item, string label) {
  if (label == item.label) {
    return item;
  }
}

private T _findElement(T, U)(U item, string label) {
  return null;
}

private T _findElement(T)(ORef!T elem, string label) {
  return null;
}

private T _findElement(T)(T elems[], string label) {
  foreach (elem; elems) {
    T item = _findElement!T(elem, label);
    if (item !is null) {
      return item;
    }
  }

  return null;
}

private T _findElement(T: VariantN!A, D, A)(D elem, string label) {
  foreach (T; D.AllowedTypes) {
    T* item = unresolved.peek!T();
    if (item !is null) {
      return _findElement!T(*item, label);
    }
  }

  return null;
}
