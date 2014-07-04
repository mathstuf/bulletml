module bulletml.data.speed;

public import bulletml.data.change;
public import bulletml.data.expression;

public struct Speed {
  public:
    ChangeType type;
    Expression change;
  private:
    public static Speed opCall() {
      Speed s;
      s.type = ChangeType.ABSOLUTE;
      return s;
    }
}
