module bulletml.elements.term;

private import bulletml.elements._element;

private import bulletml.data.term;

public class ETerm: BulletMLElement {
  public:
    mixin Storage!Term;
  private:
    public override void setup(ElementParser p) {
      p.onText = (string s) {
        value.value = parseExpression(s);
      };

      run(p);
    }
}
