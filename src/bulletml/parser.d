module bulletml.parser;

public import bulletml.data.bulletml;
private import bulletml.elements.bulletml;

private import std.stream;
private import std.xml;

public BulletML parse(string fname) {
  return parse(new File(fname, FileMode.In));
}

public BulletML parse(InputStream istr) {
  char[] contents;
  while (!istr.eof) {
    char[] chunk;
    istr.read(chunk);
    contents ~= chunk;
  }
  DocumentParser p = new DocumentParser(contents.idup);
  BulletML bml = new BulletML;
  EBulletML elem = new EBulletML(bml);

  elem.setup(p);

  return bml;
}
