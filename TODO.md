- Fix error handling
- Token:
	- Do error handling differently
- Lexer:
	- Still fix the impl function to print the errors if any
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
		
