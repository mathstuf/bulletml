module bulletml.elements.vertical;

private import bulletml.elements._element;
private import bulletml.elements._types;

private import core.stdc.stdlib;

public class EVertical: BulletMLElement {
  public:
    Motion motion;
    string amountExpr;
  private:
    public override void setup(ElementParser p) {
      string type = p.tag.attr["type"];
      switch (type) {
      case "absolute":
        motion = Motion.ABSOLUTE;
        break;
      case "relative":
        motion = Motion.RELATIVE;
        break;
      case "sequence":
        motion = Motion.SEQUENCE;
        break;
      default:
        throw new InvalidAttribute("Invalid attribute for vertical: " ~ type);
      }

      p.onText = (string s) {
        amountExpr = s;
      };

      run(p);
    }
}
