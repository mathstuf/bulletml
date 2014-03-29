module bulletml.elements.changespeed;

private import bulletml.elements._element;
private import bulletml.elements.speed;
private import bulletml.elements.term;

private import bulletml.data.changespeed;

public class EChangeSpeed: BulletMLElement {
  public:
    mixin Storage!ChangeSpeed;
  private:
    public override void setup(ElementParser p) {
      parseOne!ESpeed(p, "speed", value.speed);
      parseOne!ETerm(p, "term", value.term);

      run(p);
    }
}
