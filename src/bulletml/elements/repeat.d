module bulletml.elements.repeat;

private import bulletml.elements._element;
private import bulletml.elements.action;
private import bulletml.elements.oref;
private import bulletml.elements.times;

private import bulletml.data.repeat;

public class ERepeat: BulletMLElement {
  public:
    mixin Storage!Repeat;
  private:
    public override void setup(ElementParser p) {
      parseOne!ETimes(p, "times", value.times);

      static const string[] tags = [
        "action",
        "actionRef",
      ];

      alias Algebraic!(EAction, EORef!Action) Parser;

      parseOneOf!Parser(p, tags, value.action);

      run(p);
    }
}
