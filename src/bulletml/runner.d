module bulletml.runner;

private import bulletml.data._all;

public class BulletState {
  public:
    Action actions[];
    Param param[];
}

public interface BulletManager {
  private:
    public Bullet createSimpleBullet(double direction, double speed);
    public Bullet createBullet(BulletState state, double direction, double speed);
    public uint getTurn();
}

public class BulletRunner {
  private:
    BulletManager manager;

    public this(BulletManager manager) {
      this.manager = manager;
    }

    public void run(Bullet bullet) {
      if (!bullet.active()) {
        return;
      }

      // TODO: Implement.
    }
}

public interface Bullet {
  private:
    public uint birth();
    public bool active();

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
