module bulletml.data.horizontal;

public import bulletml.data.change;
public import bulletml.data.expression;

public struct Horizontal {
  public:
    ChangeType type;
    Expression change;
  private:
    public static Horizontal opCall() {
      Horizontal h;
      h.type = ChangeType.ABSOLUTE;
      return h;
    }
}
