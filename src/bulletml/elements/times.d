module bulletml.elements.times;

private import bulletml.elements._element;

public class ETimes: BulletMLElement {
  public:
    string timesExpr;
  private:
    public override void setup(ElementParser p) {
      p.onText = (string s) {
        timesExpr = s;
      };

      run(p);
    }
}
