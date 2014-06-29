module bulletml.elements.action;

private import bulletml.elements._element;
private import bulletml.elements.accel;
private import bulletml.elements.changedirection;
private import bulletml.elements.changespeed;
private import bulletml.elements.fire;
private import bulletml.elements.oref;
private import bulletml.elements.repeat;
private import bulletml.elements.times;
private import bulletml.elements.vanish;
private import bulletml.elements.wait;

private import bulletml.data.action;

public class EAction: BulletMLElement {
  public:
    mixin Storage!Action;
  private:
    public override void setup(ElementParser p) {
      string[] tags;
      tags ~= "repeat";
      tags ~= "fire";
      tags ~= "fireRef";
      tags ~= "changeSpeed";
      tags ~= "changeDirection";
      tags ~= "accel";
      tags ~= "wait";
      tags ~= "vanish";
      tags ~= "action";
      tags ~= "actionRef";

      alias Algebraic!(
          ERepeat,
          EFire,
          EORef!Fire,
          EChangeSpeed,
          EChangeDirection,
          EAccel,
          EWait,
          EVanish,
          EAction,
          EORef!Action) Parser;

      parseManyOf!Parser(p, tags, value.contents);

      run(p);
    }
}
