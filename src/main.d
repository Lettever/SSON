import std.stdio;

import parser;
import std.file;

void main() {
    string filePath = "./test.lml";
    string test = readText(filePath);
    auto tokens = Lexer.lex(test);
	
    if (tokens.isNull()) {
        writeln("lexing failed");
        return;
	}
	
    writeln(isValid(tokens.get()));
    auto parsed = Parser.toJson(tokens.get().removeWhiteSpace(), false);
    if (parsed.isNull()) {
        writeln("Parsing failed");
        return;
    }
    writeln(test);
    writeln(parsed.get().toPrettyString());
    writeln(__FILE__);
}
