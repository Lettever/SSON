module parser;

import token;
import lexer;
import utils;
import std.json;
import std.conv;
import std.stdio;
import std.typecons;
import std.algorithm;
import std.ascii;

struct Parser {
    TokenArray tokens;
    uint i;
    bool info;
    string[] errors;
    
    private bool peek(TokenType[] types...) {
        auto token = tokens[i];
        return types.any!(x => token.type == x);
    }
    
    private bool matches(TokenType[] types ...) {
        bool res = peek(types);
        if (res) i += 1;
        return res;
    }
    
    private Token lastToken() => tokens[i - 1];
    
    private JSONValue parseNumber() {
        if (info) writeln("parsing number at ", i);
        // number = -? numberLiteral
        int sign = 1;
        if (matches(TokenType.Minus)) sign = -1;
        auto number = tokens[i].getSpan();
        i += 1;
        if (number.length < 2) return JSONValue(sign * number.to!(int));
        switch (number[1].toLower()) {
        case 'x': return JSONValue(sign * number[2 .. $].to!(int)(16));
        case 'o': return JSONValue(sign * number[2 .. $].to!(int)(8));
        case 'b': return JSONValue(sign * number[2 .. $].to!(int)(2));
        default:
            bool isDouble = number.canFind('.') || number.canFind('e') || number.canFind('E');
            if (isDouble) return JSONValue(sign * number.to!(double));
            return JSONValue(sign * number.to!(long));
        }
    }

    private Nullable!JSONValue parseValue() {
        if (info) writeln("parsing value at ", i);
        auto token = tokens[i];
        if (matches(TokenType.String)) return nullable(JSONValue(token.getSpan()));
        if (matches(TokenType.LeftBrace)) return parseDict();
        if (matches(TokenType.LeftBracket)) return parseArray();
        if (matches(TokenType.True)) return nullable(JSONValue(true));
        if (matches(TokenType.False)) return nullable(JSONValue(false));
        if (matches(TokenType.Null)) return nullable(JSONValue(null));
        if (peek(TokenType.Minus, TokenType.Number)) return nullable(parseNumber());
        writeln("idk what (", token, ") is");
        return Nullable!JSONValue.init;
    }

    private Nullable!(string[]) parseKey() {
        // key = (string | identifier) ('.' (string | identifier))*
        if (info) writeln("parsing key at ", i);
        string[] keys = [];
        if (!matches(TokenType.String, TokenType.Identifier)) {
            writeln("not a string or ident");
            return Nullable!(string[]).init;
        }
        keys ~= lastToken().getSpan();
        while (i < tokens.length && matches(TokenType.Dot)) {
            if (!matches(TokenType.String, TokenType.Identifier)) {
                writeln("not a string or ident");
                return Nullable!(string[]).init;
            }
            keys ~= lastToken().getSpan();
        }
        if (lastToken().type == TokenType.Dot) return Nullable!(string[]).init;
        return nullable(keys);
    }

    private Nullable!JSONValue parseDict() {
        if (info) writeln("parsing dict at ", i);
        // "{" (key "=" value)* "}"
        
        auto dict = JSONValue((JSONValue[string]).init);
        
        while (i < tokens.length && !peek(TokenType.RightBrace)) {
            auto keys = parseKey();
            if (keys.isNull()) {
                writeln("key is null");
                return Nullable!JSONValue.init;
            }
            if (!matches(TokenType.Equals)) {
                writeln("missing equals");
                writeln(i);
                return Nullable!JSONValue.init;
            }
            auto val = parseValue();
            if (val.isNull()) {
                writeln("val is null");
                return Nullable!JSONValue.init;
            }
            dict = foo(dict, keys.get(), val.get());
        }

        if (!matches(TokenType.RightBrace)) return Nullable!JSONValue.init;
        return nullable(dict);
    }
    
    private Nullable!JSONValue parseArray() {
        if (info) writeln("parsing array at ", i);
        // "[" value* "]"
        JSONValue arr = JSONValue(JSONValue[].init);

        while (i < tokens.length && !peek(TokenType.RightBracket)) {
            auto val = parseValue();
            if (val.isNull()) return Nullable!JSONValue.init;
            arr.array() ~= val.get();
        }
        
        if (!matches(TokenType.RightBracket)) return Nullable!JSONValue.init;
        return nullable(arr);
    }
    
    static Nullable!JSONValue toJson(TokenArray tokens, bool info = false) {
        auto foo = Parser(tokens, 0, info);
        if (tokens.length == 0) return nullable(JSONValue());
        auto res = foo.parseValue();
        if (info) writeln("Done");
        return res;
    }
}
