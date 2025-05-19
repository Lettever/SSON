module lexer;

import std.conv;
import std.typecons;
import std.stdio;
import std.ascii;
import token;
import utils;
 
struct Lexer {
    string str;
    uint i;
    string[] errors;
    int row = 1, col = 1;
    
    static Nullable!TokenArray lex(string str) => Lexer(str, 0).impl();
    
    private Nullable!Token makeAndAdvance(TokenType type, string span) {
        i += span.length;
        return nullable(Token(type, span, row, col));
    }
    
    private Nullable!Token next() {
        if (i >= str.length) return makeAndAdvance(TokenType.EOF, "");
        char ch = str[i];
        if (ch in TokenTypeMap) {
            auto t = makeAndAdvance(TokenTypeMap[ch], ch.to!(string));
            col += 1;
            return t;
        }
        if (ch.isAlpha()) {
            string parsedIdentifier = tokenizeIdentifier();
            auto type = TokenTypeMapKeyword.get(parsedIdentifier, TokenType.Identifier);
            auto t = makeAndAdvance(type, parsedIdentifier);
            col += parsedIdentifier.length;
            return t;
        }
        if (ch.isDigit()) {
            Nullable!string parsedNumber = tokenizeNumber();
            if (parsedNumber.isNull()) {
                writeln("Invalid number at ", row, " ", col);
                return Nullable!Token.init;
            }
            auto t = makeAndAdvance(TokenType.Number, parsedNumber.get());
            col += parsedNumber.get().length;
            return t;
        }
        if (ch == '"' || ch == '\'') {
            int rowTemp = row, colTemp = col;
            Nullable!string tokenizedString = tokenizeString(ch, rowTemp, colTemp);
            if (tokenizedString.isNull()) {
                writeln("Invalid string at ", i);
                return Nullable!Token.init;
            }
            auto t = makeAndAdvance(TokenType.String, tokenizedString.get());
            row = rowTemp;
            col = colTemp;
            return t;
        }
        if (ch.isWhite()) {
            auto t = makeAndAdvance(TokenType.WhiteSpace, " ");
            col += 1;
            if (ch == '\n') {
                row += 1;
                col = 1;
            }
            return t;
        }
        writefln("i: %s, ch: %s", i, ch);
        i += 1;
        return next();
    }
    
    private Nullable!TokenArray impl() {
        TokenArray tokens = [];
        while (true) {
            auto token = next();
            if (token.isNull()) {
                writeln("Lexing failed");
                return Nullable!TokenArray.init;
            }
            if (token.get().type == TokenType.EOF) break;
            if (!canAppend(tokens, token.get().type)) continue;
            tokens ~= token.get();
        }
        return nullable(tokens);
    }
    
    private string tokenizeIdentifier() {
        uint j = advanceWhile(str, i + 1, (x) => isAlphaNum(x) || x == '_' || x == '-');
        return str[i .. j];
    }
    
    private Nullable!string tokenizeNumber() {
        if (str[i] == '0' && str.getC(i + 1, '\0') != '.') {
            return tokenizeSpecialNumber();
        }
        
        uint j = tokenizeIntegerPart(i);
        if (str.getC(j, '\0') == '.') {
            if (!str.getC(j + 1, '\0').isDigit()) return Nullable!string.init;
            j = tokenizeDecimalPart(j);
        }
        if (str.getC(j, '\0').toLower() == 'e') {
            dchar c = str.getC(j + 1, '\0');
            if (!c.isDigit() && c != '-' && c != '+') return Nullable!string.init;
            j = tokenizeExponentPart(j);
        }
        return nullable(str[i .. j]);
    }

    private uint tokenizeIntegerPart(uint i) {
        return advanceWhile(str, i + 1, &isDigit);
    }
    private uint tokenizeDecimalPart(uint i) {
        return advanceWhile(str, i + 1, &isDigit);
    }
    private uint tokenizeExponentPart(uint i) {
        if (str[i + 1] == '+' || str[i + 1] == '-') i += 1;
        return advanceWhile(str, i + 1, &isDigit);
    }
    
    private Nullable!string tokenizeSpecialNumber() {
        if (i == str.length - 1) return nullable("0");
        auto m = [
            'x': &isHexDigit,
            'o': &isOctalDigit,
            'b': &isBinaryDigit,
        ];
        auto n = str[i + 1];

        if(n in m) {
            uint j = advanceWhile(str, i + 2, m[n]);
            if (i + 2 == j) return Nullable!string.init;
            return nullable(str[i .. j]);
        }
        return nullable("0");
    }
    
    private Nullable!string tokenizeString(char delim, ref int rowTemp, ref int colTemp) {
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
        
        if (j > len) return Nullable!string.init;
        return nullable(str[i .. j]);
    }
}
