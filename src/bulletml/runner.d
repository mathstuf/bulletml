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
    public void createBullet(const Resolved!BulletML state, double direction, double speed);
    public uint getTurn();

    public double getBulletDirection();
    public double getAimDirection();
    public double getBulletSpeed();
    public double getDefaultSpeed();
    public double getRank();
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
  return createRunner(manager, resolve!BulletML(bml));
}

public BulletMLRunner createRunner(BulletManager manager, Resolved!BulletML bml) {
  return new GroupRunner(manager, bml);
}

public interface BulletMLRunner {
  private:
    public bool done();
    public void run();
}

private class GroupRunner: BulletMLRunner {
  private:
    BulletMLRunner runners[];

    package this(BulletManager manager, Resolved!BulletML bml) {
      BulletML.Orientation orientation = bml.get().orientation;
      foreach (elem; bml.get().elements) {
        Action* action = elem.peek!Action();
        assert(action !is null);

        runners ~= new ActionRunner(manager, orientation, *action);
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
        Action.AElement actions[];
      private:
        size_t idx;
        size_t repeat;

        public this(ActionZipper parent, Action.AElement actions[], size_t repeat = 1) {
          par = parent;
          this.actions = actions;
          idx = 0;
          this.repeat = repeat;
        }

        public this(Action.AElement actions[]) {
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

        public Action.AElement next() {
          ++idx;
          if (done() && --repeat) {
            idx = 0;
          }
          return current();
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
      Repeat** repeat = action.peek!(Repeat*)();
      if (repeat !is null) {
        return runRepeat(**repeat, turn);
      }

      Fire** fire = action.peek!(Fire*)();
      if (fire !is null) {
        return runFire(**fire, turn);
      }

      ChangeSpeed* changeSpeed = action.peek!ChangeSpeed();
      if (changeSpeed !is null) {
        return runChangeSpeed(*changeSpeed, turn);
      }

      ChangeDirection* changeDirection = action.peek!ChangeDirection();
      if (changeDirection !is null) {
        return runChangeDirection(*changeDirection, turn);
      }

      Accel* accel = action.peek!Accel();
      if (accel !is null) {
        return runAccel(*accel, turn);
      }

      Wait* wait = action.peek!Wait();
      if (wait !is null) {
        return runWait(*wait, turn);
      }

      Vanish* vanish = action.peek!Vanish();
      if (vanish !is null) {
        return runVanish(*vanish, turn);
      }

      Action** act = action.peek!(Action*)();
      if (act !is null) {
        return runAction(**act, turn);
      }

      // References should have already been resolved at this point.

      // This should never happen...
      assert(0);
      // ...but if it does, skip the element.
      return Status.CONTINUE;
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
      float curDir = manager.getBulletDirection();
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
        dir = degrees + manager.getBulletDirection();
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
      float curSpd = manager.getBulletSpeed();
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
        return change + manager.getBulletSpeed();
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
      float direction = 0;
      float speed = 0;

      // TODO: Implement.

      Bullet* bullet = fire.bullet.peek!Bullet();
      assert(bullet !is null);
      if (bullet.actions.length) {
        Resolved!BulletML bml;
        manager.createBullet(bml, direction, speed);
      } else {
        manager.createSimpleBullet(direction, speed);
      }

      return Status.CONTINUE;
    }

    private Status runRepeat(Repeat repeat, uint turn) {
      float times = repeat.times.value(manager);
      if (times < 1) {
        return Status.CONTINUE;
      }

      Action* action = repeat.action.peek!Action();
      assert(action !is null);
      zipper = new ActionZipper(zipper, action.contents, to!size_t(times));
      return Status.UPDATED;
    }

    private Status runVanish(Vanish vanish, uint turn) {
      manager.vanish();
      return Status.END;
    }

    private Status runWait(Wait wait, uint turn) {
      if (next.isNull()) {
        next = turn + cast(uint) wait.frames(manager);
      }
      if (next < turn) {
        return Status.END;
      } else {
        next.nullify();
        return Status.CONTINUE;
      }
    }
}

public interface IBullet {
  private:
}
