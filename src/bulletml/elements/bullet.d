module bulletml.elements.bullet;

private import bulletml.elements._element;
private import bulletml.elements.action;
private import bulletml.elements.direction;
private import bulletml.elements.oref;
private import bulletml.elements.speed;

private import bulletml.data.bullet;

public class EBullet: BulletMLElement {
  public:
    mixin Storage!Bullet;
  private:
    public override void setup(ElementParser p) {
      value.label = p.tag.attr.get("label", "");

      parseOptional!EDirection(p, "direction", value.direction);
      parseOptional!ESpeed(p, "speed", value.speed);

      static const string[] tags = [
        "action",
        "actionRef",
      ];

      alias Algebraic!(EAction, EORef!Action) Parser;

      parseManyOf!Parser(p, tags, value.actions);

      run(p);
    }
}

// TODO: Implement.
