module bulletml.elements.param;

private import bulletml.elements._element;

private import bulletml.data.param;

public class EParam: BulletMLElement {
  public:
    mixin Storage!Param;
  private:
    public override void setup(ElementParser p) {
      p.onText = (string s) {
        value.value = new Expression(s);
      };

      run(p);
    }
}
