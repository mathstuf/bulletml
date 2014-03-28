module bulletml.data.repeat;

public import bulletml.data.action;
public import bulletml.data.oref;
public import bulletml.data.times;

public import std.variant;

public class Repeat {
  public:
    Times times;
    alias Algebraic!(
        Action,
        ORef!Action
        ) RAction;
    RAction actions[];
  private:
    public this() {
      times = new Times;
    }
}
