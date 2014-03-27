module bulletml.elements.changedirection;

private import bulletml.elements._element;
private import bulletml.elements.direction;
private import bulletml.elements.term;

public class EChangeDirection: BulletMLElement {
  public:
    EDirection direction;
    ETerm term;
  private:
    bool hasDirection;
    bool hasTerm;

    public override void setup(ElementParser p) {
      p.onStartTag["direction"] = (ElementParser xml) {
        direction.setup(p);
        hasDirection = true;
      };
      p.onStartTag["term"] = (ElementParser xml) {
        term.setup(p);
        hasTerm = true;
      };

      run(p);

      if (!hasDirection) {
        throw new MissingTag("The changeDirection tag requires a 'direction' "
                             "child, none were found");
      }
      if (!hasTerm) {
        throw new MissingTag("The changeDirection tag requires a 'term' "
                             "child, none were found");
      }
    }
}
