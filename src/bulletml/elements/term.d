module bulletml.elements.term;

private import bulletml.elements._element;

public class ETerm: BulletMLElement {
  public:
    string termExpr;
  private:
    public override void setup(ElementParser p) {
      p.onText = (string s) {
        termExpr = s;
      };

      run(p);
    }
}
