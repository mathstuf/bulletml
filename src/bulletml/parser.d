module bulletml.parser;

public import bulletml.data.bulletml;
private import bulletml.elements.bulletml;

private import std.file;
private import std.stream;
private import std.xml;

public BulletML parse(string fname) {
  string contents = readText(fname);
  DocumentParser p = new DocumentParser(contents);
  BulletML bml = BulletML();
  EBulletML elem = new EBulletML(&bml);

  elem.setup(p);

  return bml;
}

public BulletML parse(InputStream istr) {
  char[] contents;
  while (!istr.eof) {
    char[] chunk;
    istr.read(chunk);
    contents ~= chunk;
  }
  DocumentParser p = new DocumentParser(contents.idup);
  BulletML bml = BulletML();
  EBulletML elem = new EBulletML(&bml);

  elem.setup(p);

  return bml;
}
