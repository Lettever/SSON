- Fix error handling
- Token:
	- use SyntaxSymbol for the single space things
	- Do error handling differently
	- Fix is valid, ensure there is never another value after another
- Lexer:
	- In the "next" method seperate each if body into another method
	- For error handling, append to the "errors" array instead of printing to the screen
- Parser:
	- For error handling, append to the "errors" array instead of printing to the screen
	- Maybe rename peek and matches
	- Try out this by deepseek """private static bool isType(TokenType x)(Token t) {
			return t.type =\= x;  // Direct comparison
		}

		bool peek(TokenType[] types...) {
			foreach (T; types) {
				if (isType!T(tokens[i])) return true;  // Static dispatch
			}
			return false;
		}"""
		
