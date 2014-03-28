module bulletml.data.changedirection;

public import bulletml.data.direction;
public import bulletml.data.term;

public class ChangeDirection {
  public:
    Direction direction;
    Term term;
  private:
    public this() {
      direction = new Direction;
      term = new Term;
    }
}
