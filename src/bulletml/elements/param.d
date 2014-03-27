module bulletml.elements.param;

private import bulletml.elements._element;

public class EParam: BulletMLElement {
  public:
    string valueExpr;
  private:
    public override void setup(ElementParser p) {
      p.onText = (string s) {
        valueExpr = s;
      };

      run(p);
    }
}
