module bulletml.data.bulletml;

public import bulletml.data.action;
public import bulletml.data.bullet;
public import bulletml.data.fire;

public import std.variant;

public struct BulletML {
  public:
    public enum Orientation {
      NONE,
      VERTICAL,
      HORIZONTAL
    }

    Orientation orientation;
    alias Algebraic!(
        Bullet,
        Action,
        Fire
        ) Element;
    Element[] elements;
  private:
    public static BulletML opCall() {
      BulletML b;
      b.orientation = Orientation.NONE;
      return b;
    }
}
