module bulletml.data.param;

public import bulletml.data.expression;

public class Param {
  public:
    Expression value;
  private:
    public this() {
      value = null;
    }
}
