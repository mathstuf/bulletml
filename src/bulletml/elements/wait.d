module bulletml.elements.wait;

private import bulletml.elements._element;

private import bulletml.data.wait;

public class EWait: BulletMLElement {
  public:
    mixin Storage!Wait;
  private:
    public override void setup(ElementParser p) {
      p.onText = (string s) {
        value.frames = parseExpression(s);
      };

      run(p);
    }
}
