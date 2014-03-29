module bulletml.elements.oref;

private import bulletml.elements._element;
private import bulletml.elements.param;

private import bulletml.data.oref;

public class EORef(T): BulletMLElement {
  public:
    mixin Storage!(ORef!T);
  private:
    public override void setup(ElementParser p) {
      value.label = p.tag.attr["label"];

      parseMany!EParam(p, "param", value.params);

      run(p);
    }
}
