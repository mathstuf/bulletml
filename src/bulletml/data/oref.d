module bulletml.data.oref;

public import bulletml.data.param;

public class ORef(T) {
  public:
    string label;
    Param params[];
  private:
    public this() {
      label = "";
    }
}
