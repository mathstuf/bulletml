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
      super("The \'" ~ p.tag().name ~ "\' tag requires "
            "a '" ~ tag ~ "' child; none were found");
    }
}

public class InvalidTag: InvalidBulletML {
  private:
    public this(string tag, ElementParser p) {
      super("The \'" ~ p.tag().name ~ "\' tag is not "
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
    public this(ElementParser child, string par) {
      super("The \'" ~ child.tag().name ~ "\' tag may "
            "not be duplicated in " ~ par);
    }
}

public mixin template Storage(T) {
  public:
    T* value;
  private:
    public this(T* value) {
      this.value = value;
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
                          OnlyOnce parsed) {
  string name = p.tag().name;
  p.onStartTag[tag] = (ElementParser xml) {
    if (parsed.triggered()) {
      throw new DuplicateTag(xml, name);
    }

    D dat = D();
    P elem = new P(&dat);

    elem.setup(xml);

    store = Nullable!D(dat);
    parsed.trigger();
  };
}

private void _parse(P, D)(ElementParser p, string tag, ref D store,
                          OnlyOnce parsed) {
  string name = p.tag().name;
  p.onStartTag[tag] = (ElementParser xml) {
    if (parsed.triggered()) {
      throw new DuplicateTag(xml, name);
    }

    D dat = D();
    P elem = new P(dat);

    elem.setup(xml);

    store = dat;
    parsed.trigger();
  };
}

private void _parse(P, D)(ElementParser p, string tag, ref D store,
                          OnlyOnce parsed, Fuse fuse) {
  string name = p.tag().name;
  p.onStartTag[tag] = (ElementParser xml) {
    if (parsed.triggered()) {
      throw new DuplicateTag(xml, name);
    }

    D dat = D();
    P elem = new P(&dat);

    elem.setup(xml);

    fuse.defuse();
    store = dat;
    parsed.trigger();
  };
}

private void _parse(P, D, T)(ElementParser p, string tag, ref D store,
                             OnlyOnce parsed, Fuse fuse) {
  string name = p.tag().name;
  p.onStartTag[tag] = (ElementParser xml) {
    if (parsed.triggered()) {
      throw new DuplicateTag(xml, name);
    }

    T dat = T();
    P elem = new P(&dat);

    elem.setup(xml);

    fuse.defuse();
    store = dat;
    parsed.trigger();
  };
}

private void _parse(P, D)(ElementParser p, string tag, ref D[] store) {
  p.onStartTag[tag] = (ElementParser xml) {
    D dat = D();
    P elem = new P(&dat);

    elem.setup(xml);

    store ~= dat;
  };
}

private void _parse(P, D, T)(ElementParser p, string tag, ref D[] store) {
  p.onStartTag[tag] = (ElementParser xml) {
    T dat = T();
    P elem = new P(&dat);

    elem.setup(xml);

    store ~= D(dat);
  };
}

private void _parse(P, D, U: T*, T)(ElementParser p, const string tag, ref D[] store) {
  p.onStartTag[tag] = (ElementParser xml) {
    T* dat = new T();
    P elem = new P(dat);

    elem.setup(xml);

    store ~= D(dat);
  };
}

private void _parse(P, D, T)(ElementParser p, string tag, ref D[] store,
                             Fuse fuse) {
  p.onStartTag[tag] = (ElementParser xml) {
    T dat = T();
    P elem = new P(&dat);

    elem.setup(xml);

    fuse.defuse();
    store ~= D(dat);
  };
}

private void _parse(P, D, U: T*, T)(ElementParser p, const string tag, ref D[] store,
                                    Fuse fuse) {
  p.onStartTag[tag] = (ElementParser xml) {
    T* dat = new T();
    P elem = new P(dat);

    elem.setup(xml);

    fuse.defuse();
    store ~= D(dat);
  };
}

public void parseOne(P, D)(ElementParser p, const string tag, ref D store) {
  OnlyOnce parsed = new OnlyOnce;
  Fuse fuse = new Fuse(new MissingTag(tag, p));

  _parse!(P, D)(p, tag, store, parsed, fuse);

  p.onEndTag[p.tag().name] = (const Element elem) {
    fuse.check();
  };
}

public void parseOptional(P, D)(ElementParser p, const string tag, ref Nullable!D store) {
  OnlyOnce parsed = new OnlyOnce;

  _parse!(P, D)(p, tag, store, parsed);
}

public void parseOneOf(P, D)(ElementParser p, const string[] tags, ref D store) {
  OnlyOnce[D.AllowedTypes.length] parsed;
  Fuse fuse = new Fuse(new MissingTag("<many>", p));

  assert(D.AllowedTypes.length == tags.length);

  foreach (i, T; D.AllowedTypes) {
    parsed[i] = new OnlyOnce;
    _parse!(P.AllowedTypes[i], D, T)(p, tags[i], store, parsed[i], fuse);
  }

  p.onEndTag[p.tag().name] = (const Element elem) {
    fuse.check();
  };
}

public void parseAtLeastOneOf(P, D)(ElementParser p, const string tag, ref D[] store) {
  Fuse fuse = new Fuse(new MissingTag("<many>", p));

  _parse!(P, D)(p, tag, store, fuse);

  p.onEndTag[p.tag().name] = (const Element elem) {
    fuse.check();
  };
}

public void parseAtLeastOneOf(P, D)(ElementParser p, const string[] tags, ref D[] store) {
  Fuse fuse = new Fuse(new MissingTag("<many>", p));

  static assert(P.AllowedTypes.length == D.AllowedTypes.length);
  assert(D.AllowedTypes.length == tags.length);

  foreach (i, T; D.AllowedTypes) {
    static if (isPointer!T) {
      _parse!(P.AllowedTypes[i], D, T, PointerTarget!T)(p, tags[i], store, fuse);
    } else {
      _parse!(P.AllowedTypes[i], D, T)(p, tags[i], store, fuse);
    }
  }

  p.onEndTag[p.tag().name] = (const Element elem) {
    fuse.check();
  };
}

public void parseMany(P, D)(ElementParser p, const string tag, ref D[] store) {
  _parse!(P, D)(p, tag, store);
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

private class OnlyOnce {
  private:
    bool _triggered;

    public this() {
      _triggered = false;
    }

    public bool triggered() {
      return _triggered;
    }

    public void trigger() {
      _triggered = true;
    }
}

private class Fuse {
  private:
    Throwable exc;

    public this(Throwable err) {
      exc = err;
    }

    public void check() {
      if (exc !is null) {
        throw exc;
      }
    }

    public void defuse() {
      exc = null;
    }
}
