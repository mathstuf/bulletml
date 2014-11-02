module bulletml.data.oref;

public import bulletml.data.param;

public struct ORef(T) {
  public:
    alias T Referent;
    T* target = null;
    string label;
    Param[] params;
}
