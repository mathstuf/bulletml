module bulletml.elements._expression;

private import core.stdc.ctype;
private import std.container;
private import std.exception;
private import std.conv;
private import std.random;

version(unittest) {
  private import core.exception;
  private import std.math;
  private import std.stdio;
}

private alias float Value;

public interface ExpressionContext {
  private:
    public void set(string name, Value value);
    public void remove(string name);
    public Value get(string name);
    public Expression param(size_t idx);
    public ExpressionContext clone();
    public Value rand();
    public Value rank();
}

public class DefaultExpressionContext: ExpressionContext {
  private:
    Value[string] variables;
    Expression params[];
  public:
    public this() {
    }

    public this(Expression params[]) {
      this.params = params;
    }

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

    public Expression param(size_t idx) {
      return params[idx];
    }

    public ExpressionContext clone() {
      DefaultExpressionContext ctx = new DefaultExpressionContext;
      ctx.variables = variables;
      ctx.params = params;
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
  // Parse the input.
  foreach (char c; expr) {
    ++col;

    // Check for a variable reference.
    if (c == '$') {
      // We must have a fully processed token before this (operator or
      // parentheses).
      assert(token.isDone());
      // Start a variable token.
      token = new Token(Token.TokenType.VARIABLE);
    } else if (c == '+' ||
               c == '-' ||
               c == '*' ||
               c == '/' ||
               c == '%') {
      // Check for unary negation.
      if (c == '-' &&
          (token.isDone() &&
           (tokens.empty() ||
            !opStack.empty()))) {
        Token opToken = new Token(Token.TokenType.NEGATE, 100);
        opToken.append(c);
        appendToken(opToken, opStack);
        continue;
      }
      // The previous token must not have been empty.
      assert(!token.empty());

      // Push the current token to the output.
      appendToken(token, tokens);

      // Create the operator token.
      Token opToken = new Token(opPrio(c));
      opToken.append(c);

      // Pop operators to the output while the priority is higher than the new
      // operator. Also stop once a non-operator is hit.
      while (!opStack.empty() &&
             opStack.back.type() == Token.TokenType.OPERATOR) {
        Token top = opStack.back;
        if (opToken.priority() <= top.priority()) {
          appendToken(top, tokens);
          opStack.removeBack();
        } else {
          break;
        }
      }

      // Push the operator onto the operator stack.
      opStack ~= opToken;
    } else if (c == '(') {
      // An open parenthesis must either be the first token or there has to be
      // an operator available.
      assert(tokens.empty() || !opStack.empty());

      // Push the current token to the output.
      appendToken(token, tokens);

      // Create the open parenthesis token and put it on the operator stack.
      Token opToken = new Token(Token.TokenType.OPEN_GROUP);
      opToken.append(c);
      appendToken(opToken, opStack);
    } else if (c == ')') {
      // There must be something on the stack (at least an open parenthesis)
      // and a non-empty token (no trailing operator).
      assert(!opStack.empty && !token.empty());

      // Push the current token to the output.
      appendToken(token, tokens);

      // Pop tokens until an open parenthesis is encountered.
      while (opStack.back.type() != Token.TokenType.OPEN_GROUP) {
        tokens ~= opStack.back;
        opStack.removeBack();
      }

      // Remove the opening parenthesis.
      if (opStack.empty) {
        throw new ParenMismatch("column " ~ to!string(col));
      }
      opStack.removeBack();
    } else if (isdigit(c)) {
      // Found a number.

      // If this is a new number, create the token.
      if (token.isDone()) {
        token = new Token(Token.TokenType.CONSTANT);
      }

      // Enforce that the token is a constant or that it is a variable and the
      // digit is not the first character (also disallow '.' in variable
      // names).
      assert(token.type() == Token.TokenType.CONSTANT ||
             (token.type() == Token.TokenType.VARIABLE &&
              !token.empty()));

      // Append to the token.
      token.append(c);
    } else if (c == '.') {
      // If this is a new token, create a number.
      if (token.isDone()) {
        token = new Token(Token.TokenType.CONSTANT);
      }

      assert(token.type() == Token.TokenType.CONSTANT);

      // Append to the token.
      token.append(c);
    } else if (isalpha(c) || c == '_') {
      // The token must be a variable.
      assert(token.type() == Token.TokenType.VARIABLE);

      // Append to the token.
      token.append(c);
    } else if (isspace(c)) {
      // Whitespace.

      // Push the current token to the output.
      appendToken(token, tokens);
    } else {
      // Unknown character.
      throw new ExpressionError("unrecognized character: " ~ to!string(c));
    }
  }

  // Push the last token into the output.
  appendToken(token, tokens);

  // Pop the remaining operators.
  while (!opStack.empty) {
    Token top = opStack.back;
    // Check for any rogue open parentheses.
    if (top.type() == Token.TokenType.OPEN_GROUP) {
      throw new ParenMismatch("column " ~ to!string(col));
    }

    // Manually push since the opTokens are 'done'.
    tokens ~= top;
    opStack.removeBack();
  }

  // Build the expression tree.
  Array!Expression nodeStack;
  foreach (Token top; tokens) {
    switch (top.type()) {
    case Token.TokenType.VARIABLE:
      nodeStack ~= new ExpressionVariable(top.toString());
      break;
    case Token.TokenType.CONSTANT:
      nodeStack ~= new ExpressionConstant(to!float(top.toString()));
      break;
    case Token.TokenType.NEGATE:
      Expression rhs = checkPop(nodeStack);

      // Simulate negation with subtraction.
      ExpressionOperation eop = new ExpressionOperation(&subtract, new ExpressionConstant(0.0f), rhs);

      // Perform constant folding.
      if (eop.isConstant()) {
        ExpressionContext ctx;
        nodeStack ~= new ExpressionConstant(eop(ctx));
      } else {
        nodeStack ~= eop;
      }

      break;
    case Token.TokenType.OPERATOR:
      Expression rhs = checkPop(nodeStack);
      Expression lhs = checkPop(nodeStack);

      // Find the operator's implementation.
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

      // Perform constant folding.
      if (eop.isConstant()) {
        ExpressionContext ctx;
        nodeStack ~= new ExpressionConstant(eop(ctx));
      } else {
        nodeStack ~= eop;
      }

      break;
    default:
      assert(0);
    }
  }

  // Get the remaining expression.
  Expression root = checkPop(nodeStack);

  // Extra operators are necessary (should have been caught when adding the
  // operator in the first place.
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
  public Value opCall(ExpressionContext ctx);
  public bool isConstant();
}

public class ExpressionConstant: Expression {
  public:
    Value value;
  private:
    public this(Value value) {
      this.value = value;
    }

    public Value opCall(ExpressionContext) {
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

    public Value opCall(ExpressionContext ctx) {
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

    public Value opCall(ExpressionContext ctx) {
      return op(lhs(ctx), rhs(ctx));
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
  bool success = true;

  void testExpr(string expr, Value expected, ExpressionContext ctx) {
    Expression e = parseExpression(expr);
    Value actual = e(ctx);
    if (epsilon < fabs(actual - expected)) {
      writeln("--------");
      writeln("Expression: " ~ expr);
      writeln("Expected  : " ~ to!string(expected));
      writeln("Actual    : " ~ to!string(actual));
      success = false;
    }
  }

  DefaultExpressionContext ctx = new DefaultExpressionContext;

  // Values
  {
    testExpr("1", 1f, ctx);
    testExpr("1.5", 1.5f, ctx);
    testExpr("0.5", 0.5f, ctx);
    testExpr(".5", 0.5f, ctx);
  }

  // Basic expressions
  {
    testExpr("1+2", 3.0f, ctx);
    testExpr("10-1", 9.0f, ctx);
    testExpr("2*3", 6.0f, ctx);
    testExpr("1/2", 0.5f, ctx);
    testExpr("1%2", 1.0f, ctx);
    testExpr("-1", -1.0f, ctx);
  }

  // Whitespace
  {
    testExpr(" 1+1", 2.0f, ctx);
    testExpr("1+1 ", 2.0f, ctx);
    testExpr("1 +1", 2.0f, ctx);
    testExpr("1+ 1", 2.0f, ctx);
  }

  // Order of operations
  {
    testExpr("1+2*2", 5.0f, ctx);
    testExpr("2*2+1", 5.0f, ctx);
  }

  // Parentheses
  {
    testExpr("(1+1)", 2.0f, ctx);
    testExpr("2*(2+1)", 6.0f, ctx);
    testExpr("(2+1)*2", 6.0f, ctx);
    testExpr("(2+1)*(2+3)", 15.0f, ctx);
    testExpr("(2*1)+(2*3)", 8.0f, ctx);
    testExpr("(4*(1+2))*2", 24.0f, ctx);
    testExpr("(4+(1+2))+2", 9.0f, ctx);
  }

  // Compound
  {
    testExpr("1*-1", -1.0f, ctx);
    testExpr("(-1)", -1.0f, ctx);
  }

  ctx.set("four", 4.0f);
  ctx.set("five", 5.0f);
  ctx.set("under_score", 1.0f);

  // Variables
  {
    testExpr("$four", 4.0f, ctx);
    testExpr("$five+$four", 9.0f, ctx);
    testExpr("$under_score", 1.0f, ctx);
  }

  ctx.set("four", 5.0f);

  // Variables
  {
    testExpr("$four", 5.0f, ctx);
  }

  // Exceptions
  {
    bool caught = false;
    try {
      Expression e = parseExpression("$novar");
      e(ctx);
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

  if (!success) {
    assert(0);
  }
}
