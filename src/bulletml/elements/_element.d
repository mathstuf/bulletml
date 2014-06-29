module bulletml.elements._element;

private import std.traits;
private import std.typecons;

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

private void _parse(P, D)(ElementParser p, string tag, ref Nullable!D store,
                          ref bool parsed) {
  p.onStartTag[tag] = (ElementParser xml) {
    if (parsed) {
      throw new DuplicateTag(xml, p);
    }

    D dat = new D;
    P elem = new P(dat);

    elem.setup(xml);

    store = Nullable!D(dat);
    parsed = true;
  };
}

private void _parse(P, D)(ElementParser p, string tag, ref D store,
                          ref bool parsed) {
  p.onStartTag[tag] = (ElementParser xml) {
    if (parsed) {
      throw new DuplicateTag(xml, p);
    }

    D dat = new D;
    P elem = new P(dat);

    elem.setup(xml);

    store = dat;
    parsed = true;
  };
}

private void _parse(P, D)(ElementParser p, string tag, ref D store,
                          ref bool parsed, ref Fuse fuse) {
  p.onStartTag[tag] = (ElementParser xml) {
    if (parsed) {
      throw new DuplicateTag(xml, p);
    }

    D dat = new D;
    P elem = new P(dat);

    elem.setup(xml);

    if (fuse !is null) {
      fuse.defuse();
    }
    store = dat;
    parsed = true;
  };
}

private void _parse(P, D, T)(ElementParser p, string tag, ref D store,
                             ref bool parsed, ref Fuse fuse) {
  p.onStartTag[tag] = (ElementParser xml) {
    if (parsed) {
      throw new DuplicateTag(xml, p);
    }

    T dat = new T;
    P elem = new P(dat);

    elem.setup(xml);

    if (fuse !is null) {
      fuse.defuse();
    }
    store = dat;
    parsed = true;
  };
}

private void _parse(P, D)(ElementParser p, string tag, ref D[] store) {
  p.onStartTag[tag] = (ElementParser xml) {
    D dat = new D;
    P elem = new P(dat);

    elem.setup(xml);

    store ~= dat;
  };
}

private void _parse(P, D, T)(ElementParser p, string tag, ref D[] store) {
  p.onStartTag[tag] = (ElementParser xml) {
    T dat = new T;
    P elem = new P(dat);

    elem.setup(xml);

    store ~= *new D(dat);
  };
}

private void _parse(P, D, U: T*, T)(ElementParser p, const string tag, ref D[] store) {
  p.onStartTag[tag] = (ElementParser xml) {
    T dat = new T;
    P elem = new P(dat);

    elem.setup(xml);

    store ~= *new D(&dat);
  };
}

public void parseOne(P, D)(ElementParser p, const string tag, ref D store) {
  bool parsed;
  Fuse fuse = new Fuse(new MissingTag(tag, p));

  _parse!(P, D)(p, tag, store, parsed, fuse);
}

public void parseOptional(P, D)(ElementParser p, const string tag, ref Nullable!D store) {
  bool parsed;

  _parse!(P, D)(p, tag, store, parsed);
}

public void parseOneOf(P, D)(ElementParser p, const string[] tags, ref D store) {
  bool parsed;
  Fuse fuse = new Fuse(new MissingTag("<many>", p));

  assert(D.AllowedTypes.length == tags.length);

  foreach (i, T; D.AllowedTypes) {
    _parse!(P.AllowedTypes[i], D, T)(p, tags[i], store, parsed, fuse);
  }
}

public void parseMany(P, D)(ElementParser p, const string tags, ref D[] store) {
  _parse!(P, D)(p, tags, store);
}

public void parseManyOf(P, D)(ElementParser p, const string[] tags, ref D[] store) {
  static assert(P.AllowedTypes.length == D.AllowedTypes.length);
  assert(D.AllowedTypes.length == tags.length);

  foreach (i, T; D.AllowedTypes) {
    static if (isPointer!T) {
      _parse!(P.AllowedTypes[i], D, T, PointerTarget!T)(p, tags[i], store);
    } else {
      _parse!(P.AllowedTypes[i], D, T)(p, tags[i], store);
    }
  }
}

private class Fuse {
  private:
    Throwable exc;

    public this(Throwable err) {
      exc = err;
    }

    public ~this() {
      if (exc !is null) {
        throw exc;
      }
    }

    public void defuse() {
      exc = null;
    }
}
