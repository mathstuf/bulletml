module bulletml.elements.bulletml;

private import bulletml.elements._element;
private import bulletml.elements.action;
private import bulletml.elements.bullet;
private import bulletml.elements.fire;
private import bulletml.elements.oref;

private import bulletml.data.bulletml;

public class EBulletML: BulletMLElement {
  public:
    mixin Storage!BulletML;
  private:
    public override void setup(ElementParser p) {
      string type = p.tag.attr["type"];
      switch (type) {
      case "none":
        value.orientation = BulletML.Orientation.NONE;
        break;
      case "vertical":
        value.orientation = BulletML.Orientation.VERTICAL;
        break;
      case "horizontal":
        value.orientation = BulletML.Orientation.HORIZONTAL;
        break;
      default:
        throw new InvalidAttribute("type", type, p);
      }

      string tags[];
      tags ~= "bullet";
      tags ~= "action";
      tags ~= "fire";

      alias Algebraic!(EBullet, EAction, EFire) Parser;

      parseManyOf!Parser(p, tags, value.elements);

      run(p);
    }
}
