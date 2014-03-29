module bulletml.elements.accel;

private import bulletml.elements._element;
private import bulletml.elements.horizontal;
private import bulletml.elements.term;
private import bulletml.elements.vertical;

private import bulletml.data.accel;

public class EAccel: BulletMLElement {
  public:
    mixin Storage!Accel;
  private:
    public override void setup(ElementParser p) {
      parseOptional!EHorizontal(p, "horizontal", value.horizontal);
      parseOptional!EVertical(p, "vertical", value.vertical);
      parseOne!ETerm(p, "term", value.term);

      run(p);
    }
}
