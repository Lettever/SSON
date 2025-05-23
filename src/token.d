module token;

import std.stdio;
import std.array;
import std.functional;
import std.algorithm;

enum TokenType {
    Minus,
    Dot,
    Equals,
    
    True,
    False,
    Null,
    
    String,
    Number,
    Identifier,
    
    LeftBrace,
    RightBrace,
    LeftBracket,
    RightBracket,
    
    WhiteSpace,
    EOF,
    
    Illegal,
}

static immutable TokenTypeMap = [
    '-': TokenType.Minus,
    '.': TokenType.Dot,
    '=': TokenType.Equals,
    '[': TokenType.LeftBracket,
    ']': TokenType.RightBracket,
    '{': TokenType.LeftBrace,
    '}': TokenType.RightBrace,
];

static immutable TokenTypeMapKeyword = [
    "true": TokenType.True,
    "false": TokenType.False,
    "null": TokenType.Null
];

struct Token {
    TokenType type;
    string span;
    int row, col;
    
    string getSpan() {
        if (type == TokenType.String) {
            return span[1 .. $ - 1];
        }
        return span;
    }
    
    bool isValue() {
        return (
            type == TokenType.Number ||
            type == TokenType.True ||
            type == TokenType.False ||
            type == TokenType.Null ||
            type == TokenType.String ||
            type == TokenType.Number
        );
    }
    
    void print() {
        writeln("Type = ", type);
        writeln("Span = ", span);
        writeln("Row = ", row);
        writeln("Col = ", col);
        writeln();
    }
}
alias TokenArray = Token[];

TokenArray removeWhiteSpace(TokenArray tokens) => tokens.filter!((x) => x.type != TokenType.WhiteSpace).array();

int[] getInvalidIndexes(TokenArray tokens) {
    int[] invalidIndexes = [];
    for (int i = 0; i < tokens.length - 1; i++) {
        auto token = tokens[i], nextToken = tokens[i + 1];
        if (token.isValue() && nextToken.isValue()) {
            invalidIndexes ~= i;
        }
    }
    return invalidIndexes;
}

bool canAppend(TokenArray tokens, TokenType type) {
    if (tokens.length == 0) return true;
    if (type != TokenType.WhiteSpace) return true;
    return tokens[$ - 1].type != TokenType.WhiteSpace;
}
