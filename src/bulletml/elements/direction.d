module bulletml.elements.direction;

private import bulletml.elements._element;
private import bulletml.elements._types;

private import core.stdc.stdlib;

public class EDirection: BulletMLElement {
  public:
    Direction direction;
    string degreesExpr;
  private:
    public override void setup(ElementParser p) {
      string type = p.tag.attr["type"];
      switch (type) {
      case "aim":
        direction = Direction.AIM;
        break;
      case "absolute":
        direction = Direction.ABSOLUTE;
        break;
      case "relative":
        direction = Direction.RELATIVE;
        break;
      case "sequence":
        direction = Direction.SEQUENCE;
        break;
      default:
        throw new InvalidAttribute("Invalid attribute for direction: " ~ type);
      }

      p.onText = (string s) {
        degreesExpr = s;
      };

      run(p);
    }
}
