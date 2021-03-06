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

public alias float Value;

public interface ExpressionContext {
  private:
    public void set(string name, Value value);
    public void remove(string name);
    public Value get(string name);
    public Value rand();
    public Value rank();
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
  if (!t.isDone() && !t.empty() && t.type() != Token.TokenType.EMPTY) {
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
  Token token = new Token(Token.TokenType.EMPTY);
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
      assert(token.isDone() || token.type() == Token.TokenType.EMPTY);
      // Start a variable token.
      token = new Token(Token.TokenType.VARIABLE);
    } else if (c == '+' ||
               c == '-' ||
               c == '*' ||
               c == '/' ||
               c == '%') {
      // Check for unary negation.
      bool empOp = opStack.empty();
      bool empTok = tokens.empty();
      Token lOp = empOp ? null : opStack.back();
      Token lTok = empTok ? null : tokens.back();

      if (c == '-' &&
          (token.isDone() &&
            // Beginning of input '-' -> negation
           (empTok ||
            // '-' after open paren -> negation
            token.type() == Token.TokenType.OPEN_GROUP ||
            // '-' after operator -> negation
            token.type() == Token.TokenType.OPERATOR))) {
        Token opToken = new Token(Token.TokenType.NEGATE, 3);
        opToken.append(c);
        opStack ~= opToken;
        continue;
      }
      // The previous token must not have been empty.
      assert(!token.empty() || token.type() == Token.TokenType.EMPTY);

      // Push the current token to the output.
      appendToken(token, tokens);

      // Create the operator token.
      Token opToken = new Token(opPrio(c));
      opToken.append(c);

      // Pop operators to the output while the priority is higher than the new
      // operator. Also stop once a non-operator is hit.
      while (!opStack.empty() &&
             (opStack.back.type() == Token.TokenType.OPERATOR ||
              opStack.back.type() == Token.TokenType.NEGATE)) {
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
      token = new Token(Token.TokenType.OPERATOR);
      token.done();
    } else if (c == '(') {
      // An open parenthesis must either be the first token or there has to be
      // an operator available.
      assert(tokens.empty() || !opStack.empty());

      // Push the current token to the output.
      appendToken(token, tokens);

      // Create the open parenthesis token and put it on the operator stack.
      token = new Token(Token.TokenType.OPEN_GROUP);
      token.append(c);
      appendToken(token, opStack);
    } else if (c == ')') {
      // There must be something on the stack (at least an open parenthesis)
      // and a non-empty token (no trailing operator).
      assert(!opStack.empty() && (!token.empty() || token.type() == Token.TokenType.EMPTY));

      // Push the current token to the output.
      appendToken(token, tokens);

      // Pop tokens until an open parenthesis is encountered.
      while (opStack.back.type() != Token.TokenType.OPEN_GROUP) {
        tokens ~= opStack.back;
        opStack.removeBack();
      }

      // Remove the opening parenthesis.
      if (opStack.empty()) {
        throw new ParenMismatch("column " ~ to!string(col));
      }
      opStack.removeBack();

      if (!opStack.empty() && opStack.back.type() == Token.TokenType.NEGATE) {
        tokens ~= opStack.back;
        opStack.removeBack();
      }
      token = new Token(Token.TokenType.EMPTY);
      token.done();
    } else if (isdigit(c)) {
      // Found a number.

      // If this is an empty variable, this is actually a parameter.
      if (!token.isDone() &&
          token.type() == Token.TokenType.VARIABLE &&
          token.empty()) {
        token = new Token(Token.TokenType.PARAMETER);
      }

      // If this is a new number, create the token.
      if (token.isDone() || token.type() == Token.TokenType.EMPTY) {
        token = new Token(Token.TokenType.CONSTANT);
      }

      // Enforce that the token is a constant or that it is a variable and the
      // digit is not the first character (also disallow '.' in variable
      // names).
      assert(token.type() == Token.TokenType.CONSTANT ||
             token.type() == Token.TokenType.PARAMETER ||
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
      //appendToken(token, tokens);
      //token = new Token(Token.TokenType.EMPTY);
    } else {
      // Unknown character.
      throw new ExpressionError("unrecognized character: " ~ to!string(c));
    }
  }

  // Push the last token into the output.
  appendToken(token, tokens);

  // Pop the remaining operators.
  while (!opStack.empty()) {
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
    case Token.TokenType.PARAMETER:
      nodeStack ~= new ExpressionParameter(to!size_t(top.toString()));
      break;
    case Token.TokenType.NEGATE:
      Expression rhs = checkPop(nodeStack);

      // Simulate negation with subtraction.
      ExpressionOperation eop = new ExpressionOperation(&subtract, new ExpressionConstant(0.0f), rhs);

      // Perform constant folding.
      if (eop.isConstant()) {
        nodeStack ~= new ExpressionConstant(eop());
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
        nodeStack ~= new ExpressionConstant(eop());
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
    throw new ExpressionError("Leftover tokens: " ~ to!string(nodeStack.length) ~ ": " ~ to!string(nodeStack[0]));
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
  public Value opCall();
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

    public Value opCall() {
      return value;
    }

    public Value opCall(ExpressionContext ctx) {
      return value;
    }

    public bool isConstant() {
      return true;
    }
}

public class ExpressionParameter: Expression {
  public:
    size_t idx;
  private:
    public this(size_t idx) {
      this.idx = idx;
    }

    public Value opCall() {
      assert(0);
      return 0;
    }

    public Value opCall(ExpressionContext ctx) {
      // Parameters are meant to have been resolved by now.
      assert(0);
      return 0;
    }

    public bool isConstant() {
      return false;
    }
}

public class ExpressionVariable: Expression {
  public:
    string name;
  private:
    public this(string name) {
      this.name = name;
    }

    public Value opCall() {
      assert(0);
      return 0;
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

    public Value opCall() {
      return op(lhs(), rhs());
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
      PARAMETER,
      OPEN_GROUP,
      CLOSE_GROUP,

      EMPTY,
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
      return !value.length || type == TokenType.EMPTY;
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
  class SimpleExpressionContext: ExpressionContext {
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

      public Value rand() {
        return uniform!"[]"(0.0f, 1.0f);
      }

      public Value rank() {
        return 1;
      }
  }

  Value epsilon = 1e-6;
  bool success = true;

  void testExpr(string expr, Value expected, ExpressionContext ctx) {
    try {
      Expression e = parseExpression(expr);
      Value actual = e(ctx);
      Value diff = fabs(actual - expected);
      if (epsilon < diff) {
        writeln("--------");
        writeln("Expression: " ~ expr);
        writeln("Expected  : " ~ to!string(expected));
        writeln("Actual    : " ~ to!string(actual));
        success = false;
      }
    } catch (Throwable t) {
      writeln("Failed to parse: " ~ expr ~ ": " ~ to!string(t));
      success = false;
    }
  }

  SimpleExpressionContext ctx = new SimpleExpressionContext;

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
    testExpr("2*(2+1*2)", 8.0f, ctx);
    testExpr("2*(2-1*2)", 0.0f, ctx);
    testExpr("-(2)", -2.0f, ctx);
    testExpr("-(-1)", 1.0f, ctx);
    testExpr("(2*2)*(1+2)-4", 8.0f, ctx);
    testExpr("(2*2)-(1+2)*4", -8.0f, ctx);
    testExpr("2*(1-2*4)", -14.0f, ctx);
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

  // Failures from example BulletML files
  {
    testExpr("$four*(1-4*$under_score)", -12.0f, ctx);
    testExpr("$four*(1 -4*$under_score)", -12.0f, ctx);
    testExpr("$four * (1 - 4 * $under_score)", -12.0f, ctx);
    testExpr("$four * (1.7 - 0.4 * $under_score)", 5.2f, ctx);
    testExpr("-10+$four*20", 70.0f, ctx);
    testExpr("((1-2)-3)", -4.0f, ctx);
    testExpr("(360 / $four) + (3 + 12 * (1 - $under_score) * (1 - $under_score)) * (-1 + 2 * $five)", 117.0f, ctx);
    testExpr(" -10+$four*20", 70.0f, ctx);
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
    } catch (ExpressionError) {
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
