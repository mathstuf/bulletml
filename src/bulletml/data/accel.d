module bulletml.data.accel;

public import bulletml.data.horizontal;
public import bulletml.data.term;
public import bulletml.data.vertical;

public import std.typecons;

public class Accel {
  public:
    Nullable!Horizontal horizontal;
    Nullable!Vertical vertical;
    Term term;
  private:
    public this() {
      term = new Term;
    }
}
