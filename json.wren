
class JSON {
  static parse(string) {
    return JSONParser.new(string).parse
  }

  static stringify(object) {
    return JSONStringifier.new(object).toString
  }

  static tokenize(string) {
    return JSONScanner.new(string).tokenize
  }
}

class JSONStringifier {
  construct new(object) {
    _object = object
  }

  toString { stringify(_object) }

  stringify(obj) {
    if (obj is Num || obj is Bool || obj is Null) {
      return obj.toString
    } else if (obj is String) {
      var substrings = []
      // Escape special characters
      for (char in obj) {
        if (char == "\"") {
          substrings.add("\\\"")
        } else if (char == "\\") {
          substrings.add("\\\\")
        } else if (char == "\b") {
          substrings.add("\\b")
        } else if (char == "\f") {
          substrings.add("\\f")
        } else if (char == "\n") {
          substrings.add("\\n")
        } else if (char == "\r") {
          substrings.add("\\r")
        } else if (char == "\t") {
          substrings.add("\\t")
        } else {
          substrings.add(char)
        }
      }
      return "\"" + substrings.join("") + "\""

    } else if (obj is List) {
      var substrings = obj.map { |o| stringify(o) }
      return "[" + substrings.join(",") + "]"

    } else if (obj is Map) {
      var substrings = obj.keys.map { |key|
        return stringify(key) + ":" + stringify(obj[key])
      }
      return "{" + substrings.join(",") + "}"
    }
  }
}

class JSONParser {
  construct new(input) {
    _input = input
    _tokens = []
  }

  valueTypes { [Token.String, Token.Number, Token.Bool, Token.Null] }

  parse { nest(JSONScanner.new(_input).tokenize) }

  nest(tokens) {
    if (tokens.count == 0) { parsingError }

    var token = tokens.removeAt(0)

    if (token.type == Token.LeftBrace) {
      // Making a Map
      var map = {}

      while (tokens[0].type != Token.RightBrace) {
        var key = tokens.removeAt(0)
        if (key.type != Token.String) { parsingError }

        if ((tokens.removeAt(0)).type != Token.Colon) { parsingError }

        var value = nest(tokens)
        map[key.value] = value

        if (tokens.count >= 2 &&
            tokens[0].type == Token.Comma &&
            tokens[1].type != Token.RightBrace) {
          tokens.removeAt(0)
        }
      }

      // Remove Token.RightBrace
      tokens.removeAt(0)

      return map

    } else if (token.type == Token.LeftBracket) {
      // Making a List
      var list = []
      while (tokens[0].type != Token.RightBracket) {
        list.add(nest(tokens))

        if (tokens[0].type == Token.Comma) {
          tokens.removeAt(0)
        }
      }

      // Remove Token.RightBracket
      tokens.removeAt(0)

      return list

    } else if (valueTypes.contains(token.type)) {
      return token.value

    } else { parsingError }
  }

  parsingError {
    Fiber.abort("Invalid JSON")
  }
}

class JSONScanner {
  construct new(input) {
    _input = input
    _tokens = []
    // first unconsumed char
    _start = 0
    // char that will be considered next
    _cursor = 0
  }

  numberChars { "0123456789.-" }
  whitespaceChars { " \r\t\n"}
  escapedCharMap {
    return {
      "\"": "\"",
      "\\": "\\",
      "b": "\b",
      "f": "\f",
      "n": "\n",
      "r": "\r",
      "t": "\t"
    }
  }

  tokenize {
    while (!isAtEnd()) {
      _start = _cursor
      scanToken()
    }

    return _tokens
  }

  scanToken () {
    var char = advance()

    if (char == "{") {
      addToken(Token.LeftBrace)
    } else if (char == "}") {
      addToken(Token.RightBrace)
    } else if (char == "[") {
      addToken(Token.LeftBracket)
    } else if (char == "]") {
      addToken(Token.RightBracket)
    } else if (char == ":") {
      addToken(Token.Colon)
    } else if (char == ",") {
      addToken(Token.Comma)
    } else if (char == "/") {
      // Don't allow comments
      parsingError
    } else if (char == "\"") {
      scanString()
    } else if (numberChars.contains(char)) {
      scanNumber()
    } else if (isAlpha(char)) {
      scanIdentifier()
    } else if (whitespaceChars.contains(char)) {
      // pass
    } else {
      parsingError
    }
  }

  scanString () {
    var isEscaping = false
    var valueInProgress = []

    while (peek() != "\"" && !isAtEnd()) {
      var char = advance()

      if (isEscaping) {
        if (escapedCharMap.containsKey(char)) {
          valueInProgress.add(escapedCharMap[char])
        } else if (char == "u") { // unicode char!
          var charsToPull = 4
          var start = _cursor + 1
          var hexString = Helper.slice(_input, start, start + charsToPull).join("")

          var decimal = Helper.hexToDecimal(hexString)
          if (decimal == null) parsingError
          valueInProgress.add(String.fromCodePoint(decimal))

          _cursor = _cursor + charsToPull
        } else {
          parsingError
        }

        isEscaping = false
      } else if (char == "\\") {
        isEscaping = true

      } else {
        valueInProgress.add(char)
      }
    }

    if (isAtEnd()) {
      // unterminated string
      parsingError
      return
    }

    // consume closing "
    advance()

    addToken(Token.String, valueInProgress.join(""))
  }

  scanNumber () {
    while (numberChars.contains(peek())) {
      advance()
    }

    var number = Num.fromString(Helper.slice(_input, _start, _cursor).join(""))

    if (number == null) {
      parsingError
    } else {
      addToken(Token.Number, number)
    }
  }

  scanIdentifier () {
    while (isAlpha(peek())) {
      advance()
    }

    var value = Helper.slice(_input, _start, _cursor).join("")
    if (value == "true") {
      addToken(Token.Bool, true)
    } else if (value == "false") {
      addToken(Token.Bool, false)
    } else if (value == "null") {
      addToken(Token.Null, null)
    } else {
      parsingError
    }
  }

  current () {
    return _input[cursor]
  }

  advance () {
    _cursor = _cursor + 1
    return _input[_cursor - 1]
  }

  isAlpha (char) {
    var pt = char.codePoints[0]
    return (pt >= "a".codePoints[0] && pt <= "z".codePoints[0]) ||
           (pt >= "A".codePoints[0] && pt <= "Z".codePoints[0])
  }

  isAtEnd () {
    return _cursor >= _input.count
  }

  peek () {
    if (isAtEnd()) return "\0"
    return _input[_cursor]
  }

  nextCharIs (char) {
    if (isAtEnd()) return false
    if (_input[_cursor] != char) return false
    return true
  }

  addToken(type) { addToken(type, null) }
  addToken(type, value) { _tokens.add(Token.new(type, value)) }

  parsingError {
    Fiber.abort("Invalid JSON")
  }
}

class Token {
  static LeftBracket { "LEFT_BRACKET" }
  static RightBracket { "RIGHT_BRACKET" }
  static LeftBrace { "LEFT_BRACE" }
  static RightBrace { "RIGHT_BRACE" }
  static Colon { "COLON" }
  static Comma { "COMMA" }
  static String { "STRING" }
  static Number { "NUMBER" }
  static Bool { "BOOL" }
  static Null { "NULL"}

  construct new(type, value) {
    _type = type
    _value = value
  }

  toString {
    return (_value != null) ? (_type + " " + _value.toString) : _type
  }

  type { _type }
  value { _value }
}

// TODO: use Pure when we have a nice module system
class Helper {
  static slice(list, start) {
    return slice(list, start, list.count)
  }
  static slice(list, start, end) {
    var result = []
    for (index in start...end) {
      result.add(list[index])
    }
    return result
  }
  // shout out to http://www.permadi.com/tutorial/numHexToDec/
  static hexToDecimal (str) {
    var lastIndex = str.count - 1
    var power = 0
    var result = 0
    for (char in reverse(str)) {
      var num = Num.fromString(char)
      if (num == null) return null
      result = result + (num * exponent(16, power))
      power = power + 1
    }
    return result
  }
  static reverse (str) {
    var result = ""
    for (char in str) {
      result = char + result
    }
    return result
  }
  static exponent (value, power) {
    if (power == 0) return 1

    var result = value
    for (i in 1...power) {
      result = result * value
    }
    return result
  }
}
