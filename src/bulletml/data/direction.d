module bulletml.data.direction;

public import bulletml.data.expression;
public import bulletml.data.term;

public class Direction {
  public:
    public enum DirectionType {
      AIM,
      ABSOLUTE,
      RELATIVE,
      SEQUENCE
    }

    DirectionType type;
    Expression degrees;
  private:
    public this() {
      type = DirectionType.AIM;
      degrees = null;
    }
}
