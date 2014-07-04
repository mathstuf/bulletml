module bulletml.runner;

private import bulletml.data.bulletml;
private import bulletml.flatten;

private import std.algorithm;
private import std.container;
private import std.conv;
private import std.math;
private import std.variant;

public interface BulletManager: ExpressionContext {
  private:
    public void createSimpleBullet(double direction, double speed);
    public void createBullet(const ResolvedBulletML state, double direction, double speed);
    public uint getTurn();

    public double getDirection();
    public double getAimDirection();
    public double getSpeed();
    public double getDefaultSpeed();
    public void vanish();
    public void changeDirection(double degree);
    public void changeSpeed(double ds);
    public void accelX(double dvx);
    public void accelY(double dvy);
    public double getSpeedX();
    public double getSpeedY();
}

private interface Function(X, Y) {
  private:
    public Y opCall(X x);
    public bool inDomain(X x);
    public Y last();
}

private class LinearFunction(X, Y): Function!(X, Y) {
  private:
    X min;
    X max;
    Y start;
    Y end;
    Y dy;

    public this(X min, X max, Y start, Y end) {
      this.min = min;
      this.max = max;
      this.start = start;
      this.end = end;
      dy = (end - start) / (max - min);
    }

    public Y opCall(X x) {
      return start + dy * (x - min);
    }

    public bool inDomain(X x) {
      return min <= x && x < max;
    }

    public Y last() {
      return end;
    }
}

public BulletMLRunner createRunner(BulletManager manager, BulletML bml) {
  return createRunner(manager, resolve(bml));
}

public BulletMLRunner createRunner(BulletManager manager, const ResolvedBulletML bml) {
  return new GroupRunner(manager, bml);
}

public interface BulletMLRunner {
  private:
    public bool done();
    public void run();
}

private class GroupRunner: BulletMLRunner {
  private:
    BulletMLRunner[] runners;

    package this(BulletManager manager, const ResolvedBulletML bml) {
      BulletML.Orientation orientation = bml.get().orientation;
      foreach (elem; bml.get().elements) {
        elem.tryVisit!((Action action) {
            runners ~= new ActionRunner(manager, orientation, action);
          })();
      }
    }

    public bool done() {
      foreach (runner; runners) {
        if (!runner.done()) {
          return false;
        }
      }

      return true;
    }

    public void run() {
      foreach (runner; runners) {
        runner.run();
      }
    }
}

public class ActionRunner: BulletMLRunner {
  private:
    private class ActionZipper {
      public:
        ActionZipper par;
        Action.AElement[] actions;
      private:
        size_t idx;
        size_t repeat;

        public this(ActionZipper parent, Action.AElement[] actions, size_t repeat = 1) {
          par = parent;
          this.actions = actions;
          idx = 0;
          this.repeat = repeat;
        }

        public this(Action.AElement[] actions) {
          this(null, actions);
        }

        public ActionZipper parent() {
          return par;
        }

        public bool done() {
          return actions.length == idx;
        }

        public Action.AElement current() {
          return actions[idx];
        }

        public void next() {
          ++idx;
          if (done() && --repeat) {
            idx = 0;
          }
        }
    }

    private enum Status {
      // End processing for this step.
      END,
      // Process the next node.
      CONTINUE,
      // The next action has been loaded.
      UPDATED
    }

    BulletManager manager;
    BulletML.Orientation orientation;
    ActionZipper zipper;

    Array!uint repeatStack;
    Nullable!uint next;
    Nullable!float prevSpeed;
    Nullable!float prevDirection;
    bool end;

    alias LinearFunction!(uint, double) UpdateFunction;
    alias Nullable!UpdateFunction NUpdateFunction;
    NUpdateFunction changeDirF;
    NUpdateFunction changeSpeedF;
    NUpdateFunction accelXF;
    NUpdateFunction accelYF;

    package this(BulletManager manager, BulletML.Orientation orientation, Action act) {
      this.manager = manager;
      this.orientation = orientation;
      zipper = new ActionZipper(act.contents);
      end = false;
    }

    public bool done() {
      return end;
    }

    public void run() {
      uint turn = manager.getTurn();
      bool updated = update(turn);

      // Check to see if we're at the end of the run.
      if (zipper.done()) {
        // Try to go up a level.
        if (zipper.parent() is null) {
          // We're waiting for a trailing 'wait' element.
          if (!next.isNull() && next.get() < turn) {
            // End the bullet if we have no left over update functions
            // remaining.
            if (!updated) {
              end = true;
            }
          }

          return;
        }

        nextSibling(zipper);
      }

      while (!zipper.done() && runAction(zipper.current(), turn)) {
        Status status = runAction(zipper.current(), turn);

        if (status == Status.END) {
          break;
        } else if (status == Status.CONTINUE) {
          nextAction(zipper);
        } else if (status == Status.UPDATED) {
          // zipper points to our next task already.
        }
      }
    }

    private bool update(uint turn) {
      bool updated = false;

      if (!changeDirF.isNull()) {
        double degree = updateTurn(changeDirF, turn);
        manager.changeDirection(degree);
        updated = true;
      }

      if (!changeSpeedF.isNull()) {
        double ds = updateTurn(changeSpeedF, turn);
        manager.changeSpeed(ds);
        updated = true;
      }

      if (!accelXF.isNull()) {
        double dvx = updateTurn(accelXF, turn);
        manager.accelX(dvx);
        updated = true;
      }

      if (!accelYF.isNull()) {
        double dvy = updateTurn(accelYF, turn);
        manager.accelY(dvy);
        updated = true;
      }

      return updated;
    }

    private double updateTurn(ref NUpdateFunction func, uint turn) {
      double value;

      if (func.inDomain(turn)) {
        value = func(turn);
      } else {
        value = func.last();
        func.nullify();
      }

      return value;
    }

    private void nextAction(ref ActionZipper zipper) {
      zipper.next();

      if (zipper.done()) {
        nextSibling(zipper);
      }
    }

    private void nextSibling(ref ActionZipper zipper) {
      zipper = zipper.parent();
      zipper.next();
    }

    private Status runAction(Action.AElement action, uint turn) {
      return action.tryVisit!(
        (Repeat* repeat) =>
          runRepeat(*repeat, turn),
        (Fire* fire) =>
          runFire(*fire, turn),
        (ChangeSpeed changeSpeed) =>
          runChangeSpeed(changeSpeed, turn),
        (ChangeDirection changeDirection) =>
          runChangeDirection(changeDirection, turn),
        (Accel accel) =>
          runAccel(accel, turn),
        (Wait wait) =>
          runWait(wait, turn),
        (Vanish vanish) =>
          runVanish(vanish, turn),
        (Action* action) =>
          runAction(*action, turn),
        // This should never happen...
        () =>
          // ...but if it does, skip the element.
          Status.CONTINUE
        )();
    }

    private Status runAccel(Accel accel, uint turn) {
      float durationf = accel.term.value(manager);
      int duration = max(0, to!int(durationf));

      Nullable!float xSpd;
      Nullable!float ySpd;
      if (orientation == BulletML.Orientation.HORIZONTAL) {
        setupAccelX(accel.vertical, turn, duration);
        setupAccelY(accel.horizontal, turn, duration);
      } else {
        setupAccelX(accel.horizontal, turn, duration);
        setupAccelY(accel.vertical, turn, duration);
      }

      return Status.CONTINUE;
    }

    private float getAccel(T)(T elem, float curSpeed, int duration) {
      float change = elem.change(manager);
      switch (elem.type) {
      case ChangeType.ABSOLUTE:
        // Just use the given speed.
        return change;
      case ChangeType.RELATIVE:
        // Change the current speed by the given amount over the entire
        // duration.
        return change + curSpeed;
      case ChangeType.SEQUENCE:
        // Change the current speed by the amount each frame.
        return change * duration + curSpeed;
      default:
        assert(0);
      }

      assert(0);
      return 0;
    }

    private void setupAccelX(T)(Nullable!T mElem, uint turn, int duration) {
      if (mElem.isNull()) {
        return;
      }

      float curSpeed = manager.getSpeedX();
      float finalSpeed = getAccel!T(mElem.get(), curSpeed, duration);

      accelXF = new UpdateFunction(turn, turn + duration,
                                   curSpeed, finalSpeed);
    }

    private void setupAccelY(T)(Nullable!T mElem, uint turn, int duration) {
      if (mElem.isNull()) {
        return;
      }

      float curSpeed = manager.getSpeedY();
      float finalSpeed = getAccel!T(mElem.get(), curSpeed, duration);

      accelYF = new UpdateFunction(turn, turn + duration,
                                   curSpeed, finalSpeed);
    }

    private Status runAction(Action action, uint turn) {
      zipper = new ActionZipper(zipper, action.contents);
      return Status.UPDATED;
    }

    private Status runChangeDirection(ChangeDirection changeDirection, uint turn) {
      float durationf = changeDirection.term.value(manager);
      int duration = max(0, to!int(durationf));

      Direction direction = changeDirection.direction;

      float dir;
      float curDir = manager.getDirection();
      if (direction.type == Direction.DirectionType.SEQUENCE) {
        // Calculate the final direction.
        float degrees = direction.degrees(manager);
        dir = duration * degrees + curDir;
      } else {
        // Get the final direction.
        float targetDir = getDirection(direction);

        // Go around the circle in the shorter direction.
        float dirDiff = targetDir - curDir;
        if (180 < fabs(dirDiff)) {
          if (dirDiff < 0) {
            dirDiff += 360;
          } else {
            dirDiff -= 360;
          }
        }
        dir = curDir + dirDiff;
      }

      changeDirF = new UpdateFunction(turn, turn + duration,
                                      curDir, dir);

      return Status.CONTINUE;
    }

    private float getDirection(Direction direction) {
      float dir = 0;

      float degrees = direction.degrees(manager);

      switch (direction.type) {
      case Direction.DirectionType.AIM:
        // Be relative to the target direction.
        dir = degrees + manager.getAimDirection();
        break;
      case Direction.DirectionType.ABSOLUTE:
        if (orientation == BulletML.Orientation.HORIZONTAL) {
          // Point to the right instead of up.
          degrees -= 90;
        }
        dir = degrees;
        break;
      case Direction.DirectionType.RELATIVE:
        // Change the current direction.
        dir = degrees + manager.getDirection();
        break;
      case Direction.DirectionType.SEQUENCE:
        if (prevDirection.isNull()) {
          // Default to aiming at the player.
          dir = manager.getAimDirection();
        } else {
          // Change relative to the last (relevant) direction.
          dir = degrees + prevDirection.get();
        }
        break;
      default:
        assert(0);
      }

      // Make the direction in the range [0, 360).
      while (dir > 360) {
        dir -= 360;
      }
      while (dir < 0) {
        dir += 360;
      }

      return dir;
    }

    private Status runChangeSpeed(ChangeSpeed changeSpeed, uint turn) {
      float durationf = changeSpeed.term.value(manager);
      int duration = max(0, to!int(durationf));

      Speed speed = changeSpeed.speed;

      float spd;
      float curSpd = manager.getSpeed();
      if (speed.type == ChangeType.SEQUENCE) {
        // Calculate the final speed.
        float change = speed.change(manager);
        spd = duration * change + curSpd;
      } else {
        // Get the final speed.
        spd = getSpeed(speed);

        // Update the last speed.
        // XXX: Why is this done? The direction isn't updated and the sequence
        // mode doesn't update this either. This seems hacky, but it's what
        // other implementations do :( .
        prevSpeed = spd;
      }

      changeDirF = new UpdateFunction(turn, turn + duration,
                                      curSpd, spd);

      return Status.CONTINUE;
    }

    private float getSpeed(Speed speed) {
      float change = speed.change(manager);

      switch (speed.type) {
      case ChangeType.ABSOLUTE:
        // Just use the given speed.
        return change;
      case ChangeType.RELATIVE:
        // Change the current speed.
        return change + manager.getSpeed();
      case ChangeType.SEQUENCE:
        if (prevSpeed.isNull()) {
          // Use a default speed of 1.
          return 1;
        } else {
          // Change relative to the last (relevant) speed.
          return change + prevSpeed.get();
        }
      default:
        assert(0);
      }

      assert(0);
      return 0;
    }

    private Status runFire(Fire fire, uint turn) {
      // Get the fire-level direction and speed.
      Nullable!float fDirection = getDirection(fire.direction, Nullable!float());
      Nullable!float fSpeed = getSpeed(fire.speed, Nullable!float());

      // Clear the previous values and set them to whatever the fire element
      // used.
      prevDirection = fDirection;
      prevSpeed = fSpeed;

      Bullet bullet = fire.bullet.get!Bullet();

      // Update with any bullet-specific direction and speeds.
      Nullable!float bDirection = getDirection(bullet.direction, fDirection);
      Nullable!float bSpeed = getSpeed(bullet.speed, fSpeed);

      // Set defaults for sanity.
      if (bDirection.isNull()) {
        bDirection = manager.getAimDirection();
      }
      if (bSpeed.isNull()) {
        bSpeed = manager.getDefaultSpeed();
      }

      // Update the previous values.
      prevDirection = bDirection;
      prevSpeed = bSpeed;

      if (bullet.actions.length) {
        Action[] actions;
        foreach (act; bullet.actions) {
          actions ~= act.get!Action();
        }

        ResolvedBulletML bml = bulletWithActions(orientation, actions);
        manager.createBullet(bml, bDirection.get(), bSpeed.get());
      } else {
        // A boring bullet.
        manager.createSimpleBullet(bDirection.get(), bSpeed.get());
      }

      return Status.CONTINUE;
    }

    private Nullable!float getDirection(Nullable!Direction mDirection, Nullable!float mDefault) {
      if (mDirection.isNull()) {
        return mDefault;
      } else {
        return Nullable!float(getDirection(mDirection.get()));
      }
    }

    private Nullable!float getSpeed(Nullable!Speed mSpeed, Nullable!float mDefault) {
      if (mSpeed.isNull()) {
        return mDefault;
      } else {
        return Nullable!float(getSpeed(mSpeed.get()));
      }
    }

    private Status runRepeat(Repeat repeat, uint turn) {
      float times = repeat.times.value(manager);
      // Other implementations use C++'s static_cast which truncates, so
      // compare with 1 (rather then letting rounding occur).
      if (times < 1) {
        return Status.CONTINUE;
      }

      Action action;
      foreach (ref Repeat.RAction raction; repeat.actions) {
        action.contents ~= Action.AElement(raction.peek!Action());
      }
      zipper = new ActionZipper(zipper, action.contents, to!size_t(times));
      return Status.UPDATED;
    }

    private Status runVanish(Vanish vanish, uint turn) {
      // Poof.
      manager.vanish();
      // Nothing further to do.
      return Status.END;
    }

    private Status runWait(Wait wait, uint turn) {
      if (next.isNull()) {
        float frames = wait.frames(manager);
        next = turn + to!int(frames);
      }
      if (next.get() < turn) {
        // Stop any further processing.
        return Status.END;
      } else {
        // Clear the wait flag and execute the next action.
        next.nullify();
        return Status.CONTINUE;
      }
    }
}
