module bulletml.elements._expression;

private import core.stdc.ctype;
private import core.stdc.stdlib;
private import std.container;
private import std.exception;
private import std.conv;
private import std.random;

version(unittest) {
  private import core.exception;
}

private alias float Value;

public interface ExpressionContext {
  private:
    public void set(string name, Value value);
    public void remove(string name);
    public Value get(string name);
    public ExpressionContext clone();
    public Value rand();
    public Value rank();
}

public class DefaultExpressionContext: ExpressionContext {
  private:
    Value[string] variables;
  public:
    public void set(string name, Value value) {
      variables[name] = value;
    }

    public void remove(string name) {
      variables.remove(name);
    }

    public Value get(string name) {
      if (name == "rand") {
        return rand();
      } else if (name == "rank") {
        return rank();
      }

      return variables[name];
    }

    public ExpressionContext clone() {
      DefaultExpressionContext ctx = new DefaultExpressionContext;
      ctx.variables = variables;
      return ctx;
    }

    public Value rand() {
      return uniform!"[]"(0.0f, 1.0f);
    }

    public Value rank() {
      return 1;
    }
}

private Expression checkPop(ref Array!Expression arr) {
  if (arr.empty()) {
    throw new ExpressionError("Missing operand");
  }
  Expression node = arr.back;
  arr.removeBack();
  return node;
}

private void appendToken(ref Token t, ref Array!Token ts) {
  if (!t.isDone()) {
    ts ~= t;
    t.done();
  }
}

private ulong opPrio(char op) {
  switch (op) {
  case '+':
  case '-':
    return 1;
  case '*':
  case '/':
  case '%':
    return 2;
  default:
    return 0;
  }
}

public Expression parseExpression(string expr) {
  Array!Token tokens;
  Token token = new Token(Token.TokenType.CONSTANT);
  Array!Token opStack;

  ulong col = 0;
  token.done();
  foreach (char c; expr) {
    ++col;

    if (c == '$') {
      assert(token.isDone());
      token = new Token(Token.TokenType.VARIABLE);
    } else if (c == '+' ||
               c == '-' ||
               c == '*' ||
               c == '/' ||
               c == '%') {
      if (c == '-' &&
          (token.isDone() &&
           (tokens.empty() ||
            !opStack.empty()))) {
        Token opToken = new Token(Token.TokenType.NEGATE, 100);
        opToken.append(c);
        appendToken(opToken, opStack);
        continue;
      }
      assert(!token.empty());
      appendToken(token, tokens);
      Token opToken = new Token(opPrio(c));
      opToken.append(c);
      while (!opStack.empty()) {
        Token top = opStack.back;
        if (opToken.priority() <= top.priority()) {
          appendToken(top, tokens);
          opStack.removeBack();
        } else {
          break;
        }
      }
      opStack ~= opToken;
    } else if (c == '(') {
      assert(tokens.empty() || !opStack.empty());
      appendToken(token, tokens);
      Token opToken = new Token(Token.TokenType.OPEN_GROUP);
      opToken.append(c);
      appendToken(opToken, opStack);
    } else if (c == ')') {
      assert(!opStack.empty && !token.empty());
      appendToken(token, tokens);
      while (opStack.back.type() != Token.TokenType.OPEN_GROUP) {
        tokens ~= opStack.back;
        opStack.removeBack();
      }
      if (opStack.empty) {
        throw new ParenMismatch("column " ~ to!string(col));
      }
      opStack.removeBack();
    } else if (isdigit(c) ||
               c == '.') {
      if (token.isDone()) {
        token = new Token(Token.TokenType.CONSTANT);
      }
      assert(token.type() == Token.TokenType.CONSTANT ||
             (token.type() == Token.TokenType.VARIABLE &&
              !token.empty()));
      token.append(c);
    } else if (isalpha(c) || c == '_') {
      assert(token.type() == Token.TokenType.VARIABLE);
      token.append(c);
    } else if (isspace(c)) {
      appendToken(token, tokens);
      if (!token.isDone()) {
        appendToken(token, tokens);
      }
    }
  }

  appendToken(token, tokens);

  while (!opStack.empty) {
    Token top = opStack.back;
    if (top.type() == Token.TokenType.OPEN_GROUP) {
      throw new ParenMismatch("column " ~ to!string(col));
    }
    tokens ~= top;
    opStack.removeBack();
  }

  Array!Expression nodeStack;
  foreach (Token top; tokens) {
    switch (top.type()) {
    case Token.TokenType.VARIABLE:
      nodeStack ~= new ExpressionVariable(top.toString());
      break;
    case Token.TokenType.CONSTANT:
      nodeStack ~= new ExpressionConstant(atof(top.toString().ptr));
      break;
    case Token.TokenType.NEGATE:
      Expression rhs = checkPop(nodeStack);

      ExpressionOperation eop = new ExpressionOperation(&subtract, new ExpressionConstant(0.0f), rhs);

      if (eop.isConstant()) {
        ExpressionContext ctx;
        nodeStack ~= new ExpressionConstant(eop.eval(ctx));
      } else {
        nodeStack ~= eop;
      }

      break;
    case Token.TokenType.OPERATOR:
      Expression rhs = checkPop(nodeStack);
      Expression lhs = checkPop(nodeStack);

      Operation op;
      switch (top.toString()) {
      case "+":
        op = &add;
        break;
      case "-":
        op = &subtract;
        break;
      case "*":
        op = &multiply;
        break;
      case "/":
        op = &divide;
        break;
      case "%":
        op = &modulo;
        break;
      default:
        assert(0);
      }
      ExpressionOperation eop = new ExpressionOperation(op, lhs, rhs);

      if (eop.isConstant()) {
        ExpressionContext ctx;
        nodeStack ~= new ExpressionConstant(eop.eval(ctx));
      } else {
        nodeStack ~= eop;
      }

      break;
    default:
      assert(0);
    }
  }

  Expression root = checkPop(nodeStack);

  if (nodeStack.length) {
    throw new ExpressionError("Leftover tokens");
  }

  return root;
}

alias Value function(Value, Value) Operation;

private Value add(Value lhs, Value rhs) {
  return lhs + rhs;
}

private Value subtract(Value lhs, Value rhs) {
  return lhs - rhs;
}

private Value multiply(Value lhs, Value rhs) {
  return lhs * rhs;
}

private Value divide(Value lhs, Value rhs) {
  return lhs / rhs;
}

private Value modulo(Value lhs, Value rhs) {
  return lhs % rhs;
}

public interface Expression {
  public Value eval(ExpressionContext ctx);
  public bool isConstant();
}

public class ExpressionConstant: Expression {
  public:
    Value value;
  private:
    public this(Value value) {
      this.value = value;
    }

    public Value eval(ExpressionContext) {
      return value;
    }

    public bool isConstant() {
      return true;
    }
}

public class ExpressionVariable: Expression {
  public:
    string name;
  private:
    public this(string name) {
      this.name = name;
    }

    public Value eval(ExpressionContext ctx) {
      return ctx.get(name);
    }

    public bool isConstant() {
      return false;
    }
}

public class ExpressionOperation: Expression {
  public:
    Operation op;
    Expression lhs;
    Expression rhs;
  private:
    public this(Operation op, Expression lhs, Expression rhs) {
      this.op = op;
      this.lhs = lhs;
      this.rhs = rhs;
    }

    public Value eval(ExpressionContext ctx) {
      return op(lhs.eval(ctx), rhs.eval(ctx));
    }

    public bool isConstant() {
      return lhs.isConstant() && rhs.isConstant();
    }
}

private class Token {
  public:
    public enum TokenType {
      OPERATOR,
      NEGATE,
      VARIABLE,
      CONSTANT,
      OPEN_GROUP,
      CLOSE_GROUP,
    }
  private:
    char[] value;
    TokenType type_;
    ulong priority_;
    bool done_;

    public this(ulong priority) {
      type_ = TokenType.OPERATOR;
      priority_ = priority;
      done_ = false;
    }

    public this(TokenType type, ulong priority = 0) {
      type_ = type;
      priority_ = priority;
      done_ = false;
    }

    public void done() {
      done_ = true;
    }

    public bool isDone() {
      return done_;
    }

    public ulong priority() {
      return priority_;
    }

    public void append(char c) {
      assert(!done_);
      value ~= c;
    }

    public bool empty() {
      return !value.length;
    }

    public size_t size() {
      return value.length;
    }

    public override string toString() {
      return to!string(value);
    }

    public TokenType type() {
      return type_;
    }
}

public class ParenMismatch: object.Exception {
  private:
    public this(string msg) {
      super(msg);
    }
}

public class ExpressionError: object.Exception {
  private:
    public this(string msg) {
      super(msg);
    }
}

unittest {
  Value epsilon = 1e-8;
  void fuzzyCmp(Value a, Value b) {
    assert((a - b) < epsilon);
  }

  DefaultExpressionContext ctx = new DefaultExpressionContext;

  // Values
  {
    Expression tint = parseExpression("1");
    fuzzyCmp(tint.eval(ctx), 1f);

    Expression tdecimal = parseExpression("1.5");
    fuzzyCmp(tdecimal.eval(ctx), 1.5f);

    Expression tleadzero = parseExpression("0.5");
    fuzzyCmp(tleadzero.eval(ctx), 0.5f);

    Expression tnoleadzero = parseExpression(".5");
    fuzzyCmp(tnoleadzero.eval(ctx), 0.5f);
  }

  // Basic expressions
  {
    Expression tadd = parseExpression("1+2");
    fuzzyCmp(tadd.eval(ctx), 3.0f);

    Expression tsub = parseExpression("10-1");
    fuzzyCmp(tsub.eval(ctx), 9.0f);

    Expression tmult = parseExpression("2*3");
    fuzzyCmp(tmult.eval(ctx), 6.0f);

    Expression tdiv = parseExpression("1/2");
    fuzzyCmp(tdiv.eval(ctx), 0.5f);

    Expression tmod = parseExpression("1%2");
    fuzzyCmp(tmod.eval(ctx), 1.0f);

    Expression tneg = parseExpression("-1");
    fuzzyCmp(tneg.eval(ctx), -1.0f);
  }

  // Whitespace
  {
    Expression tleadwhite = parseExpression(" 1+1");
    fuzzyCmp(tleadwhite.eval(ctx), 2.0f);

    Expression ttrailwhite = parseExpression("1+1 ");
    fuzzyCmp(ttrailwhite.eval(ctx), 2.0f);

    Expression tpreop = parseExpression("1 +1");
    fuzzyCmp(tpreop.eval(ctx), 2.0f);

    Expression tpostop = parseExpression("1+ 1");
    fuzzyCmp(tpostop.eval(ctx), 2.0f);
  }

  // Order of operations
  {
    Expression taddmult = parseExpression("1+2*2");
    fuzzyCmp(taddmult.eval(ctx), 5.0f);

    Expression tmultadd = parseExpression("2*2+1");
    fuzzyCmp(tmultadd.eval(ctx), 5.0f);
  }

  // Parentheses
  {
    Expression tparen = parseExpression("(1+1)");
    fuzzyCmp(tparen.eval(ctx), 2.0f);

    Expression taddmult2 = parseExpression("2*(2+1)");
    fuzzyCmp(taddmult2.eval(ctx), 6.0f);
  }

  // Compound
  {
    Expression tnegmult = parseExpression("1*-1");
    fuzzyCmp(tnegmult.eval(ctx), -1.0f);

    Expression tnegparen = parseExpression("(-1)");
    fuzzyCmp(tnegparen.eval(ctx), -1.0f);
  }

  ctx.set("four", 4.0f);
  ctx.set("five", 5.0f);
  ctx.set("under_score", 1.0f);

  // Variables
  {
    Expression texpn = parseExpression("$four");
    fuzzyCmp(texpn.eval(ctx), 4.0f);

    Expression tvarmath = parseExpression("$five+$four");
    fuzzyCmp(tvarmath.eval(ctx), 9.0f);

    Expression tunderscore = parseExpression("$under_score");
    fuzzyCmp(tunderscore.eval(ctx), 1.0f);
  }

  ctx.set("four", 5.0f);

  // Variables
  {
    Expression trebind = parseExpression("$four");
    fuzzyCmp(trebind.eval(ctx), 5.0f);
  }

  // Exceptions
  {
    bool caught = false;
    try {
      Expression e = parseExpression("$novar");
      e.eval(ctx);
    } catch (RangeError) {
      caught = true;
    }
    assert(caught);

    caught = false;
    try {
      parseExpression("(");
    } catch (ParenMismatch) {
      caught = true;
    }
    assert(caught);

    caught = false;
    try {
      parseExpression("+");
    } catch (AssertError) {
      caught = true;
    }
    assert(caught);

    caught = false;
    try {
      parseExpression("4+");
    } catch (ExpressionError) {
      caught = true;
    }
    assert(caught);
  }
}
