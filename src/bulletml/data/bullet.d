module bulletml.data.bullet;

public import bulletml.data.action;
public import bulletml.data.direction;
public import bulletml.data.oref;
public import bulletml.data.speed;

public import std.typecons;
public import std.variant;

public class Bullet {
  public:
    string label;
    Nullable!Direction direction;
    Nullable!Speed speed;
    alias Algebraic!(
        Action,
        ORef!Action
        ) BAction;
    BAction actions[];
  private:
    public this() {
    }
}
