module bulletml.elements._expression;

private import core.stdc.ctype;
private import core.stdc.stdlib;
private import std.container;
private import std.exception;
private import std.conv;
private import std.random;

private alias ExpressionContext.Value EValue;

public class ExpressionContext {
  private:
    Value[string] variables;
  public:
    alias float Value;

    public void set(string name, Value value) {
      variables[name] = value;
    }

    public void remove(string name) {
      variables.remove(name);
    }

    public Value get(string name) {
      if (name == "rand") {
        return uniform!"[]"(0.0f, 1.0f);
      }

      return variables[name];
    }

    public ExpressionContext clone() {
      ExpressionContext ctx = new ExpressionContext;
      ctx.variables = variables;
      return ctx;
    }
}

public class Expression {
  private:
    ExpressionNode root;

    public this(string expr) {
      Array!Token tokens;
      Token token;
      Array!char opStack;

      ulong col = 0;
      token.done();
      foreach (char c; expr) {
        ++col;

        if (c == '$') {
          assert(token.isDone());
          token = new Token(Token.TokenType.VARIABLE);
        // TODO: Handle unary negation?
        } else if (c == '+' ||
                   c == '-' ||
                   c == '*' ||
                   c == '/' ||
                   c == '%') {
          if (c == '-' &&
              (token.isDone() &&
               (tokens.empty() ||
                !opStack.empty()))) {
            token = new Token(Token.TokenType.NEGATE);
            token.done();
            continue;
          }
          assert(!token.empty());
          tokens.insertBack(token);
          token.done();
          while (!opStack.empty()) {
            char top = opStack.back;
            if (((c == '+' ||
                  c == '-') &&
                 (top == '+' ||
                  top == '-')) ||
                top == '*' ||
                top == '/' ||
                top == '%') {
              Token opToken = new Token(Token.TokenType.OPERATOR);
              opToken.append(top);
              tokens.insertBack(opToken);
              opStack.removeBack();
            }
          }
          opStack.insertBack(c);
        } else if (c == '(') {
          assert(tokens.empty() ||
                 (token.type() == Token.TokenType.OPERATOR));
          if (!token.isDone()) {
            tokens.insertBack(token);
            token.done();
          }
          opStack ~= c;
        } else if (c == ')') {
          assert(!opStack.empty && !token.empty());
          tokens.insertBack(token);
          token.done();
          while (opStack.back != '(') {
            Token opToken = new Token(Token.TokenType.OPERATOR);
            opToken.append(opStack.back);
            tokens.insertBack(opToken);
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
          if (!token.isDone()) {
            tokens ~= token;
            token.done();
          }
        }
      }

      if (!token.isDone()) {
        tokens.insertBack(token);
      }

      while (!opStack.empty) {
        char top = opStack.back;
        if (top == '(') {
          throw new ParenMismatch("column " ~ to!string(col));
        }
        Token opToken = new Token(Token.TokenType.OPERATOR);
        opToken.append(top);
        tokens.insertBack(opToken);
        opStack.removeBack();
      }

      Array!ExpressionNode nodeStack;
      while (!tokens.empty()) {
        Token top = tokens.back;
        tokens.removeBack();
        switch (top.type()) {
        case Token.TokenType.VARIABLE:
          nodeStack.insertBack(new ExpressionVariable(top.toString()));
          break;
        case Token.TokenType.CONSTANT:
          nodeStack.insertBack(new ExpressionConstant(atof(top.toString().ptr)));
          break;
        case Token.TokenType.NEGATE:
          ExpressionNode rhs = checkPop(nodeStack);

          ExpressionOperation eop = new ExpressionOperation(&subtract, new ExpressionConstant(0.0f), rhs);

          if (eop.isConstant()) {
            ExpressionContext ctx;
            nodeStack.insertBack(new ExpressionConstant(eop.eval(ctx)));
          } else {
            nodeStack.insertBack(eop);
          }

          break;
        case Token.TokenType.OPERATOR:
          ExpressionNode rhs = checkPop(nodeStack);
          ExpressionNode lhs = checkPop(nodeStack);

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
            nodeStack.insertBack(new ExpressionConstant(eop.eval(ctx)));
          } else {
            nodeStack.insertBack(eop);
          }

          break;
        default:
          assert(0);
        }
      }

      root = checkPop(nodeStack);

      if (nodeStack.length) {
        throw new ExpressionError("Leftover tokens");
      }
    }

    public EValue eval(ExpressionContext ctx) {
      return root.eval(ctx);
    }

    private ExpressionNode checkPop(ref Array!ExpressionNode arr) {
      if (arr.empty()) {
        throw new ExpressionError("Missing operand");
      }
      ExpressionNode node = arr.back;
      arr.removeBack();
      return node;
    }
}

alias EValue function(EValue, EValue) Operation;

private EValue add(EValue lhs, EValue rhs) {
  return lhs + rhs;
}

private EValue subtract(EValue lhs, EValue rhs) {
  return lhs - rhs;
}

private EValue multiply(EValue lhs, EValue rhs) {
  return lhs * rhs;
}

private EValue divide(EValue lhs, EValue rhs) {
  return lhs / rhs;
}

private EValue modulo(EValue lhs, EValue rhs) {
  return lhs % rhs;
}

private interface ExpressionNode {
  public EValue eval(ExpressionContext ctx);
  public bool isConstant();
}

private class ExpressionConstant: ExpressionNode {
  private:
    EValue value;

    public this(EValue value) {
      this.value = value;
    }

    public EValue eval(ExpressionContext) {
      return value;
    }

    public bool isConstant() {
      return true;
    }
}

private class ExpressionVariable: ExpressionNode {
  private:
    string name;

    public this(string name) {
      this.name = name;
    }

    public EValue eval(ExpressionContext ctx) {
      return ctx.get(name);
    }

    public bool isConstant() {
      return false;
    }
}

private class ExpressionOperation: ExpressionNode {
  private:
    Operation op;
    ExpressionNode lhs;
    ExpressionNode rhs;

    public this(Operation op, ExpressionNode lhs, ExpressionNode rhs) {
      this.op = op;
      this.lhs = lhs;
      this.rhs = rhs;
    }

    public EValue eval(ExpressionContext ctx) {
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
      VARIABLE,
      NEGATE,
      CONSTANT
    }
  private:
    char[] value;
    TokenType type_;
    bool done_;

    public this(TokenType type) {
      type_ = type;
      done_ = false;
    }

    public void done() {
      done_ = true;
    }

    public bool isDone() {
      return done_;
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
