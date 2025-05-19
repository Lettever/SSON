- Fix error handling
- Token:
	- Do error handling differently
- Lexer:
	- In the "next" method seperate each if body into another method
	- For error handling, append to the "errors" array instead of printing to the screen
- Parser:
	- For error handling, append to the "errors" array instead of printing to the screen
	- Maybe rename peek and matches

