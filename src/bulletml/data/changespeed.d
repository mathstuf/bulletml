module bulletml.data.changespeed;

public import bulletml.data.speed;
public import bulletml.data.term;

public class ChangeSpeed {
  public:
    Speed speed;
    Term term;
  private:
    public this() {
      speed = new Speed;
      term = new Term;
    }
}
