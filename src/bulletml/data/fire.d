module bulletml.data.fire;

public import bulletml.data.bullet;
public import bulletml.data.direction;
public import bulletml.data.oref;
public import bulletml.data.speed;

public import std.typecons;
public import std.variant;

public struct Fire {
  public:
    string label;
    Nullable!Direction direction;
    Nullable!Speed speed;
    alias Algebraic!(
        Bullet,
        ORef!Bullet,
        ) FBullet;
    FBullet bullet;

    bool opEquals() @disable;
}
