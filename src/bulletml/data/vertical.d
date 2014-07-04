module bulletml.data.vertical;

public import bulletml.data.change;
public import bulletml.data.expression;

public struct Vertical {
  public:
    ChangeType type;
    Expression change;
  private:
    public static Vertical opCall() {
      Vertical v;
      v.type = ChangeType.ABSOLUTE;
      return v;
    }
}
