module utils;

import std.json;
import std.stdio;

bool isBinaryDigit(dchar c) {
    return '0' <= c && c <= '1';
}

uint advanceWhile(string str, uint i, bool function (dchar) fp) {
	ulong len = str.length;
	while (i < len && fp(str[i])) i += 1;
	return i;
}

dchar getC(string str, uint i, dchar ch) {
    if (i >= str.length) return ch;
    return str[i];
}

JSONValue foo(JSONValue json, string[] keys, JSONValue val) {
	if (keys.length == 0) {
		return val;
	}
	try {
		if (keys[0] !in json) json[keys[0]] = JSONValue.emptyObject;
		json[keys[0]] = foo(json[keys[0]], keys[1 .. $], val);
	} catch (Exception e) {
		writeln(e.message);
	}
	return json;
}
