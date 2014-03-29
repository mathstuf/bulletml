module bulletml.elements.speed;

private import bulletml.elements._element;

private import bulletml.data.speed;

public class ESpeed: BulletMLElement {
  public:
    mixin Storage!Speed;
  private:
    public override void setup(ElementParser p) {
      string type = p.tag.attr["type"];
      switch (type) {
      case "absolute":
        value.type = ChangeType.ABSOLUTE;
        break;
      case "relative":
        value.type = ChangeType.RELATIVE;
        break;
      case "sequence":
        value.type = ChangeType.SEQUENCE;
        break;
      default:
        throw new InvalidAttribute("type", type, p);
      }

      p.onText = (string s) {
        value.change = parseExpression(s);
      };

      run(p);
    }
}
