module bulletml.data.horizontal;

public import bulletml.data.change;
public import bulletml.data.expression;

public class Horizontal {
  public:
    ChangeType type;
    Expression change;
  private:
    public this() {
      type = ChangeType.ABSOLUTE;
      change = null;
    }
}
