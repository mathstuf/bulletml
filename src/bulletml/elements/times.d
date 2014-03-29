module bulletml.elements.times;

private import bulletml.elements._element;

private import bulletml.data.times;

public class ETimes: BulletMLElement {
  public:
    mixin Storage!Times;
  private:
    public override void setup(ElementParser p) {
      p.onText = (string s) {
        value.value = new Expression(s);
      };

      run(p);
    }
}
