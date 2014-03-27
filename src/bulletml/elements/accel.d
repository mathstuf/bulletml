module bulletml.elements.accel;

private import bulletml.elements._element;
private import bulletml.elements.horizontal;
private import bulletml.elements.term;
private import bulletml.elements.vertical;

public class EAccel: BulletMLElement {
  public:
    EHorizontal horizontal;
    EVertical vertical;
    ETerm term;
  private:
    bool hasHorizontal;
    bool hasVertical;
    bool hasTerm;

    public override void setup(ElementParser p) {
      p.onStartTag["horizontal"] = (ElementParser xml) {
        horizontal.setup(p);
        hasHorizontal = true;
      };
      p.onStartTag["vertical"] = (ElementParser xml) {
        vertical.setup(p);
        hasVertical = true;
      };
      p.onStartTag["term"] = (ElementParser xml) {
        term.setup(p);
        hasTerm = true;
      };

      run(p);

      if (!hasTerm) {
        throw new MissingTag("The accel tag requires a 'term' "
                             "child, none were found");
      }
    }
}
