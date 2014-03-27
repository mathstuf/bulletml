module bulletml.elements._element;

public import std.xml;

public interface Element {
  public void register(ref DocumentParser p);
  public void parse(Element e);
}
