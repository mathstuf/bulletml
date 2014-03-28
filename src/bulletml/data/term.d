module bulletml.data.term;

public import bulletml.data.expression;

public class Term {
  public:
    Expression value;
  private:
    public this() {
      value = null;
    }
}
