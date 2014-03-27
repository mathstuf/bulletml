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
    string name_;

    public void setup(ElementParser p);

    public string name() {
      return name_;
    }

    protected void run(ElementParser p) {
      name_ = p.tag().name;

      p.onStartTag[null] = (ElementParser xml) {
        throw new InvalidTag("The \'" ~ xml.tag().name ~ "\' " ~
                             "is not a valid child of the " ~
                             "\'" ~ name_ ~ "\' tag.");
      };

      p.parse();
    }
}
