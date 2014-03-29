module bulletml.elements._element;

public import std.xml;

public class InvalidBulletML: Exception {
  private:
    public this(string msg) {
      super(msg);
    }
}

public class MissingTag: InvalidBulletML {
  private:
    public this(string tag, ElementParser p) {
      super("The \'" ~ p.tag().name ~ "\' tag requires " ~
            "a '" ~ tag ~ "' child; none were found");
    }
}

public class InvalidTag: InvalidBulletML {
  private:
    public this(string tag, ElementParser p) {
      super("The \'" ~ p.tag().name ~ "\' tag is not " ~
            "allowed to have a '" ~ tag ~ "' child");
    }
}

public class InvalidAttribute: InvalidBulletML {
  private:
    public this(string attr, string value, ElementParser p) {
      super("The \'" ~ p.tag().name ~ "\' tag\'s " ~ attr ~
            "value of " ~ value ~ " is not valid");
    }
}

public class DuplicateTag: InvalidBulletML {
  private:
    public this(ElementParser child, ElementParser par) {
      super("The \'" ~ child.tag().name ~ "\' tag may " ~
            "not be duplicated in " ~ par.tag().name);
    }
}

public mixin template Storage(T) {
  public:
    T* value;
  private:
    public this(T value) {
      this.value = &value;
    }
}

public class BulletMLElement {
  private:
    string name_;

    public void setup(ElementParser) {
      assert(0);
    }

    public string name() {
      return name_;
    }

    protected void run(ElementParser p) {
      name_ = p.tag().name;

      p.onStartTag[null] = (ElementParser xml) {
        throw new InvalidTag(xml.tag().name, p);
      };

      p.parse();
    }
}
