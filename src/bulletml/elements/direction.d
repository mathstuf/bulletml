module bulletml.elements.direction;

private import bulletml.elements._element;

private import bulletml.data.direction;

public class EDirection: BulletMLElement {
  public:
    mixin Storage!Direction;
  private:
    public override void setup(ElementParser p) {
      string type = p.tag.attr["type"];
      switch (type) {
      case "aim":
        value.type = Direction.DirectionType.AIM;
        break;
      case "absolute":
        value.type = Direction.DirectionType.ABSOLUTE;
        break;
      case "relative":
        value.type = Direction.DirectionType.RELATIVE;
        break;
      case "sequence":
        value.type = Direction.DirectionType.SEQUENCE;
        break;
      default:
        throw new InvalidAttribute("type", type, p);
      }

      p.onText = (string s) {
        value.degrees = parseExpression(s);
      };

      run(p);
    }
}
