module bulletml.elements.vanish;

private import bulletml.elements._element;

private import bulletml.data.vanish;

public class EVanish: BulletMLElement {
  public:
    mixin Storage!Vanish;
  private:
    public override void setup(ElementParser p) {
      run(p);
    }
}
