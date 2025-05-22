import std.stdio;
import std.file;

import parser;
import lexer;
import token;

void main() {
    string filePath = "./examples/keys.sson";
    string test = readText(filePath);
    auto tokens = Lexer.lex(test);
	
    if (tokens.isNull()) {
        writeln("Pexing failed");
        return;
	}
	
    // writeln(getInvalidIndexes(tokens.get()));
    auto parsed = Parser.toJson(tokens.get().removeWhiteSpace(), false);
    if (parsed.isNull()) {
        writeln("Parsing failed");
        return;
    }
    writeln(test);
    writeln(parsed.get().toPrettyString());
}
