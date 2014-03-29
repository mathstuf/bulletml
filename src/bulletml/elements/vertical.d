module bulletml.elements.vertical;

private import bulletml.elements._element;

private import bulletml.data.vertical;

public class EVertical: BulletMLElement {
  public:
    mixin Storage!Vertical;
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
        value.change = new Expression(s);
      };

      run(p);
    }
}
