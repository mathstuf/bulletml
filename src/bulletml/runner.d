module bulletml.runner;

private import bulletml.data.bulletml;
private import bulletml.flatten;

private import std.container;
private import std.conv;
private import std.variant;

public interface BulletManager {
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

public BulletMLRunner createRunner(BulletManager manager, BulletML bml, ExpressionContext ctx) {
  return createRunner(manager, resolve!BulletML(bml), ctx);
}

public BulletMLRunner createRunner(BulletManager manager, Resolved!BulletML bml, ExpressionContext ctx) {
  return new GroupRunner(manager, bml, ctx);
}

public interface BulletMLRunner {
  private:
    public bool done();
    public void run();
}

private class GroupRunner: BulletMLRunner {
  private:
    BulletMLRunner runners[];

    package this(BulletManager manager, Resolved!BulletML bml, ExpressionContext ctx) {
      foreach (elem; bml.get().elements) {
        Action* action = elem.peek!Action();
        assert(action !is null);

        runners ~= new ActionRunner(manager, *action, ctx);
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
    ExpressionContext ctx;
    ActionZipper zipper;
    Array!uint repeatStack;
    Nullable!uint next;
    bool end;

    alias Nullable!(Function!(uint, double)) UpdateFunction;
    UpdateFunction changeDirF;
    UpdateFunction changeSpeedF;
    UpdateFunction accelXF;
    UpdateFunction accelYF;

    package this(BulletManager manager, Action act, ExpressionContext ctx) {
      this.manager = manager;
      this.ctx = ctx;
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

    private double updateTurn(ref UpdateFunction func, uint turn) {
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
      // TODO: Implement.

      return Status.CONTINUE;
    }

    private Status runAction(Action action, uint turn) {
      zipper = new ActionZipper(zipper, action.contents);
      return Status.UPDATED;
    }

    private Status runChangeDirection(ChangeDirection changeDirection, uint turn) {
      float duration = changeDirection.term.value(ctx);
      if (duration < 1) {
        return Status.CONTINUE;
      }

      // TODO: Implement.

      return Status.CONTINUE;
    }

    private Status runChangeSpeed(ChangeSpeed changeSpeed, uint turn) {
      float duration = changeSpeed.term.value(ctx);

      // TODO: Implement.

      return Status.CONTINUE;
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
      float times = repeat.times.value(ctx);
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
        next = turn + cast(uint) wait.frames(ctx);
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
