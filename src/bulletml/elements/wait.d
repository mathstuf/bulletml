module bulletml.elements.wait;

private import bulletml.elements._element;

public class EWait: BulletMLElement {
  public:
    string framesExpr;
  private:
    public override void setup(ElementParser p) {
      p.onText = (string s) {
        framesExpr = s;
      };

      run(p);
    }
}
