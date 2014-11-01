module bulletml.elements.fire;

private import bulletml.elements._element;
private import bulletml.elements.bullet;
private import bulletml.elements.direction;
private import bulletml.elements.oref;
private import bulletml.elements.speed;

private import bulletml.data.fire;

public class EFire: BulletMLElement {
  public:
    mixin Storage!Fire;
  private:
    public override void setup(ElementParser p) {
      value.label = p.tag.attr.get("label", "");

      parseOptional!EDirection(p, "direction", value.direction);
      parseOptional!ESpeed(p, "speed", value.speed);

      static const string[] tags = [
        "bullet",
        "bulletRef",
      ];

      alias Algebraic!(EBullet, EORef!Bullet) Parser;

      parseOneOf!Parser(p, tags, value.bullet);

      run(p);
    }
}
