module bulletml.data.vertical;

public import bulletml.data.change;
public import bulletml.data.expression;

public class Vertical {
  public:
    ChangeType type;
    Expression change;
  private:
    public this() {
      type = ChangeType.ABSOLUTE;
      change = null;
    }
}
