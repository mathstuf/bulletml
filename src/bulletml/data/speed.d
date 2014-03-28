module bulletml.data.speed;

public import bulletml.data.change;
public import bulletml.data.expression;

public class Speed {
  public:
    ChangeType type;
    Expression change;
  private:
    public this() {
      type = ChangeType.ABSOLUTE;
      change = null;
    }
}
