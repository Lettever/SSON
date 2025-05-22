module lexer;

import std.conv;
import std.typecons;
import std.stdio;
import std.ascii;
import token;
import utils;

struct TokenizeResult {
    string span;
    bool isValid;

    static auto success(string span) => TokenizeResult(span, true);
    static auto failure(string span) => TokenizeResult(span, false);
}

struct Lexer {
    string str;
    uint i;
    string[] errors;
    int row = 1, col = 1;
    
    static Nullable!TokenArray lex(string str) => Lexer(str, 0).impl();
    
    private Token makeAndAdvance(TokenType type, string span) {
        i += span.length;
        return Token(type, span, row, col);
    }
    
    private Token next() {
        if (i >= str.length) return makeAndAdvance(TokenType.EOF, "");
        char ch = str[i];
        if (ch in TokenTypeMap) return lexSyntaxSymbol();
        if (ch.isAlpha()) return lexIdentifier();
        if (ch.isDigit()) return lexNumber();
        if (ch == '"' || ch == '\'') return lexString(ch);
        if (ch.isWhite()) return lexWhite();
        errors ~= __LINE__ ~ " " ~ __FUNCTION__;
        i += 1;
        return next();
    }
    
    private Nullable!TokenArray impl() {
        TokenArray tokens = [];
        while (true) {
            auto token = next();
            if (token.type == TokenType.Illegal) {
                errors ~= __LINE__ ~ " " ~ __FUNCTION__;
                return Nullable!TokenArray.init;
            }
            if (token.type == TokenType.EOF) break;
            if (!canAppend(tokens, token.type)) continue;
            tokens ~= token;
        }
        return nullable(tokens);
    }
    
    private Token lexSyntaxSymbol() {
        char ch = str[i];
        col += 1;
        return makeAndAdvance(TokenTypeMap[ch], ch.to!(string));
    }
    
    private Token lexWhite() {
        col += 1;
        if (str[i] == '\n') {
            row += 1;
            col = 1;
        }
        return makeAndAdvance(TokenType.WhiteSpace, " ");
    }

    private string tokenizeIdentifier() {
        uint j = advanceWhile(str, i + 1, (x) => isAlphaNum(x) || x == '_' || x == '-');
        return str[i .. j];
    }
    
    private Token lexIdentifier() {
        string parsedIdentifier = tokenizeIdentifier();
        TokenType type = TokenTypeMapKeyword.get(parsedIdentifier, TokenType.Identifier);
        Token t = makeAndAdvance(type, parsedIdentifier);
        col += parsedIdentifier.length;
        return t;
    }
    
    bool shouldTokenizeSpecialNumber() => str[i] == '0' && str.getC(i + 1, '\0') != '.';
    
    private TokenizeResult tokenizeNumber() {
        if (shouldTokenizeSpecialNumber()) return tokenizeSpecialNumber();
        
        uint j = tokenizeIntegerPart(i);
        if (str.getC(j, '\0') == '.') {
            if (!str.getC(j + 1, '\0').isDigit()) {
                errors ~= __LINE__ ~ " " ~ __FUNCTION__;
                return TokenizeResult.failure(str[i .. j]);
            }
            j = tokenizeDecimalPart(j);
        }
        if (str.getC(j, '\0').toLower() == 'e') {
            dchar c = str.getC(j + 1, '\0');
            if (!c.isDigit() && c != '-' && c != '+') {
                errors ~= __LINE__ ~ " " ~ __FUNCTION__;
                return TokenizeResult.failure(str[i .. j]);
            }
            j = tokenizeExponentPart(j);
        }
        return TokenizeResult.success(str[i .. j]);
    }

    private uint tokenizeIntegerPart(uint i) => advanceWhile(str, i + 1, &isDigit);
    private uint tokenizeDecimalPart(uint i) => advanceWhile(str, i + 1, &isDigit);
    private uint tokenizeExponentPart(uint i) {
        if (str[i + 1] == '+' || str[i + 1] == '-') i += 1;
        return advanceWhile(str, i + 1, &isDigit);
    }
    
    private TokenizeResult tokenizeSpecialNumber() {
        if (i == str.length - 1) return TokenizeResult.success("0");
        auto m = [
            'x': &isHexDigit,
            'o': &isOctalDigit,
            'b': &isBinaryDigit,
        ];
        auto n = str[i + 1];

        if(n in m) {
            uint j = advanceWhile(str, i + 2, m[n]);
            if (i + 2 != j) return TokenizeResult.success(str[i .. j]);
            errors ~= __LINE__ ~ " " ~ __FUNCTION__;
            return TokenizeResult.failure(str[i .. j]);
        }
        return TokenizeResult.success("0");
    }
    
    private Token lexNumber() {
        TokenizeResult tokenizedNumber = tokenizeNumber();
        TokenType type = tokenizedNumber.isValid ? TokenType.Number : TokenType.Illegal;
        col += tokenizedNumber.span.length;
        if (type == TokenType.Illegal) {
            errors ~= __LINE__ ~ " " ~ __FUNCTION__;
        }
        return makeAndAdvance(type, tokenizedNumber.span);
    }

    private TokenizeResult tokenizeString(char delim, ref int rowTemp, ref int colTemp) {
        ulong len = str.length;
        uint j = i + 1;
        
        while (j < len) {
            char ch = str[j];
            colTemp += 1;
            if (ch == '\n') {
                rowTemp += 1;
                colTemp = 1;
            }
            else if (ch == '\\' && j + 1 < len && str[j + 1] == delim) {
                j += 2;
                continue;
            }
            else if (ch == delim) break;
            j += 1;
        }
        j += 1;
        
        if (j > len) {
            errors ~= __LINE__ ~ " " ~ __FUNCTION__;
            return TokenizeResult.failure(str[i .. $]);
        }
        return TokenizeResult.success(str[i .. j]);
    }

    private Token lexString(char delim) {
        int rowTemp = row, colTemp = col;
        TokenizeResult tokenizedString = tokenizeString(delim, rowTemp, colTemp);
        row = rowTemp;
        col = colTemp;
        TokenType type = tokenizedString.isValid ? TokenType.String : TokenType.Illegal;
        if (type == TokenType.Illegal) {
            errors ~= __LINE__ ~ " " ~ __FUNCTION__;
        }
        return makeAndAdvance(type, tokenizedString.span);
    }
}