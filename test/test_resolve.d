private import std.stdio;

private import bml = bulletml.bulletml;

int main(string[] args) {
  string fname = args[1];
  int ret = 0;

  try {
    bml.BulletML b = bml.parse(fname);
    bml.resolve(b);
    writeln("Successfully resolved " ~ fname);
  } catch (Throwable t) {
    writeln("Caught exception while resolving " ~ fname ~ ": " ~ t.toString());
    ret = 1;
  }

  return ret;
}
