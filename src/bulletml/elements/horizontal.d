module bulletml.elements.horizontal;

private import bulletml.elements._element;

private import bulletml.data.horizontal;

private import core.stdc.stdlib;

public class EHorizontal: BulletMLElement {
  public:
    mixin Storage!Horizontal;
  private:
    public override void setup(ElementParser p) {
      string typeStr = p.tag.attr["type"];
      switch (typeStr) {
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
        throw new InvalidAttribute("type", typeStr, p);
      }

      p.onText = (string s) {
        value.change = parseExpression(s);
      };

      run(p);
    }
}
