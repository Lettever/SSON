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
    
    private bool matches(TokenType[] types) {
        auto token = tokens[i];
        foreach(type; types) {
            if (token.type == type) {
                i += 1;
                return true;
            }
        }
        return false;
    }
    private JSONValue parseNumber() {
        if (info) { writeln("parsing number at ", i); }
        // number = -? numberLiteral
        int sign = 1;
        if (matches([TokenType.Minus])) {
            sign = -1;
        }
        auto number = tokens[i].getSpan();
        i += 1;
        if (number.length < 2) {
            writeln(1);
            return JSONValue(sign * number.to!(int));
        }
        switch (number[1].toLower()) {
        case 'x': return JSONValue(sign * number[2 .. $].to!(int)(16));
        case 'o': return JSONValue(sign * number[2 .. $].to!(int)(8));
        case 'b': return JSONValue(sign * number[2 .. $].to!(int)(2));
        default:
            if (number.canFind('.') || number.canFind('e') || number.canFind('E')) {
                return JSONValue(sign * number.to!(double));
            }
            return JSONValue(sign * number.to!(int));
        }
    }
    private Nullable!JSONValue parseValue() {
        if(info) { writeln("parsing value at ", i); }
        // value = number | string | dict | array
        auto token = tokens[i];
        if (matches([TokenType.True])) {
            return nullable(JSONValue(true));
        }
        if (matches([TokenType.False])) {
            return nullable(JSONValue(false));
        }
        if (matches([TokenType.Null])) {
            return nullable(JSONValue(null));
        }
        if (matches([TokenType.Minus, TokenType.Number])) {
            i -= 1;
            return nullable(parseNumber());
        }
        if (matches([TokenType.String])) {
            return nullable(JSONValue(token.getSpan()));
        }
        if (matches([TokenType.LeftBrace])) {
            auto dict = parseDict();
            if (dict.isNull()) {
                return Nullable!JSONValue.init;
            }
            return dict;
        }
        if (matches([TokenType.LeftBracket])) {
            auto arr = parseArray();
            if (arr.isNull()) {
                return Nullable!JSONValue.init;
            }
            return arr;
        }
        writeln("idk what (", token, ") is");
        return Nullable!JSONValue.init;
    }
    private Nullable!(string[]) parseKey() {
        // key = (string | identifier) ('.'? (string | identifier))*
        if (info) { writeln("parsing key at ", i); }
        string key = "";
        string[] res = [];
        if (!matches([TokenType.String, TokenType.Identifier])) {
            writeln("not a string or ident");
            return Nullable!(string[]).init;
        }
        key ~= tokens[i - 1].getSpan();
        while (matches([TokenType.Dot, TokenType.String, TokenType.Identifier])) {
            if (tokens[i - 1].type == TokenType.Dot) {
                res ~= key;
                key = "";
            } else {
                key ~= tokens[i - 1].getSpan();
            }
        }
        if (key.length != 0) {
            res ~= key;
        }
        // if the last token is a dot, it means the last key does not exist
        if (tokens[i - 1].type == TokenType.Dot) {
            return Nullable!(string[]).init;
        } 
        return nullable(res);
    }
    private Nullable!JSONValue parseDict() {
        if (info) { writeln("parsing dict at ", i); }
        // "{" (key "=" value)* "}"
        
        auto dict = JSONValue((JSONValue[string]).init);
        
        while (i < tokens.length && !matches([TokenType.RightBrace])) {
            auto key = parseKey();
            if (key.isNull()) {
                writeln("key is null");
                return Nullable!JSONValue.init;
            }
            if (!matches([TokenType.Equals])) {
                writeln("missing equals");
                writeln(i);
                return Nullable!JSONValue.init;
            }
            auto val = parseValue();
            if (val.isNull()) {
                writeln("val is null");
                return Nullable!JSONValue.init;
            }
            auto keys = key.get();
            dict = foo(dict, keys, val.get());
        }

        i -= 1;
        if (!matches([TokenType.RightBrace])) {
            return Nullable!JSONValue.init;
        }

        return nullable(dict);
    }
    private Nullable!JSONValue parseArray() {
        if (info) { writeln("parsing array at ", i); }
        // "[" value* "]"
        JSONValue arr = JSONValue(JSONValue[].init);
        //arr.array = [];

        while (i < tokens.length && !matches([TokenType.RightBracket])) {
            auto val = parseValue();
            if (val.isNull()) {
                return Nullable!JSONValue.init;
            }
            arr.array() ~= val.get();
        }
        i -= 1;
        if (!matches([TokenType.RightBracket])) {
            return Nullable!JSONValue.init;
        }
        return nullable(arr);
    }
    
    static Nullable!JSONValue toJson(TokenArray tokens, bool info = false) {
        auto foo = Parser(tokens, 0, info);
        if (tokens.length == 0) {
            return nullable(JSONValue());
        }
        if (info) writeln("Done");
        return foo.parseValue();
    }
}