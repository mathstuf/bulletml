module bulletml.data.direction;

public import bulletml.data.expression;
public import bulletml.data.term;

public struct Direction {
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
    public static Direction opCall() {
      Direction d;
      d.type = DirectionType.AIM;
      return d;
    }
}
