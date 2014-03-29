module bulletml.elements.changedirection;

private import bulletml.elements._element;
private import bulletml.elements.direction;
private import bulletml.elements.term;

private import bulletml.data.changedirection;

public class EChangeDirection: BulletMLElement {
  public:
    mixin Storage!ChangeDirection;
  private:
    public override void setup(ElementParser p) {
      parseOne!EDirection(p, "direction", value.direction);
      parseOne!ETerm(p, "term", value.term);

      run(p);
    }
}
