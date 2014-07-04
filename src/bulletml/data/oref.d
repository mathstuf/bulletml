module bulletml.data.oref;

public import bulletml.data.param;

public struct ORef(T) {
  public:
    alias T Referent;
    string label;
    Param[] params;
}
