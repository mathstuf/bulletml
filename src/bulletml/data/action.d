module bulletml.data.action;

public import bulletml.data.accel;
public import bulletml.data.action;
public import bulletml.data.changedirection;
public import bulletml.data.changespeed;
public import bulletml.data.fire;
public import bulletml.data.oref;
public import bulletml.data.repeat;
public import bulletml.data.vanish;
public import bulletml.data.wait;

public import std.variant;

public class Action {
  public:
    string label;
    alias Algebraic!(
        Repeat*, // TODO: Fix this.
        Fire*, // TODO: Fix this.
        ORef!Fire,
        ChangeSpeed,
        ChangeDirection,
        Accel,
        Wait,
        Vanish,
        Action*, // TODO: Fix this.
        ORef!Action
        ) AElement;
    AElement[] contents;
  private:
    public this() {
    }
}
