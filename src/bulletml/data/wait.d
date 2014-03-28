module bulletml.data.wait;

public import bulletml.data.expression;

public class Wait {
  public:
    Expression frames;
  private:
    public this() {
      frames = null;
    }
}
