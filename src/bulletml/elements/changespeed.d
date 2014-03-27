module bulletml.elements.changespeed;

private import bulletml.elements._element;
private import bulletml.elements.speed;
private import bulletml.elements.term;

public class EChangeSpeed: BulletMLElement {
  public:
    ESpeed speed;
    ETerm term;
  private:
    bool hasSpeed;
    bool hasTerm;

    public override void setup(ElementParser p) {
      p.onStartTag["speed"] = (ElementParser xml) {
        speed.setup(p);
        hasSpeed = true;
      };
      p.onStartTag["term"] = (ElementParser xml) {
        term.setup(p);
        hasTerm = true;
      };

      run(p);

      if (!hasSpeed) {
        throw new MissingTag("The changeSpeed tag requires a 'speed' "
                             "child, none were found");
      }
      if (!hasTerm) {
        throw new MissingTag("The changeSpeed tag requires a 'term' "
                             "child, none were found");
      }
    }
}
