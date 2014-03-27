module bulletml.elements._element;

public import std.xml;

public class InvalidBulletML: Exception {
  private:
    public this(string msg) {
      super(msg);
    }
}

public class InvalidTag: InvalidBulletML {
  private:
    public this(string msg) {
      super(msg);
    }
}

public class InvalidAttribute: InvalidBulletML {
  private:
    public this(string msg) {
      super(msg);
    }
}

public class BulletMLElement {
  private:
    public void setup(ElementParser p);

    protected void run(ElementParser p) {
      p.onStartTag[null] = (ElementParser xml) {
        throw new InvalidTag("The \'" ~ xml.tag().name ~ "\' " ~
                             "is not a valid child of the " ~
                             "\'" ~ p.tag().name ~ "\' tag.");
      };

      p.parse();
    }
}
