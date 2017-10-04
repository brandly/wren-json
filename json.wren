
class JSON {
  static parse(string) {
    return JSONParser.new(string).parse
  }

  static stringify(object) {
    return JSONStringifier.new(object).toString
  }

  static tokenize(string) {
    return JSONParser.new(string).tokenize
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

  tokenLeftBracket { "LEFT_BRACKET" }
  tokenRightBracket { "RIGHT_BRACKET" }
  tokenLeftBrace { "LEFT_BRACE" }
  tokenRightBrace { "RIGHT_BRACE" }
  tokenColon { "COLON" }
  tokenComma { "COMMA" }
  tokenString { "STRING" }
  tokenNumber { "NUMBER" }
  tokenBool { "BOOL" }
  tokenNull { "NULL"}
  numberChars { "0123456789.-" }
  valueTypes { [tokenString, tokenNumber, tokenBool, tokenNull] }
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

  parse { nest(tokenize) }

  nest(tokens) {
    if (tokens.count == 0) { parsingError }

    var token = tokens.removeAt(0)

    if (token.type == tokenLeftBrace) {
      // Making a Map
      var map = {}

      while (tokens[0].type != tokenRightBrace) {
        var key = tokens.removeAt(0)
        if (key.type != tokenString) { parsingError }

        if ((tokens.removeAt(0)).type != tokenColon) { parsingError }

        var value = nest(tokens)
        map[key.value] = value

        if (tokens.count >= 2 &&
            tokens[0].type == tokenComma &&
            tokens[1].type != tokenRightBrace) {
          tokens.removeAt(0)
        }
      }

      // Remove tokenRightBrace
      tokens.removeAt(0)

      return map

    } else if (token.type == tokenLeftBracket) {
      // Making a List
      var list = []
      while (tokens[0].type != tokenRightBracket) {
        list.add(nest(tokens))

        if (tokens[0].type == tokenComma) {
          tokens.removeAt(0)
        }
      }

      // Remove tokenRightBracket
      tokens.removeAt(0)

      return list

    } else if (valueTypes.contains(token.type)) {
      return token.value

    } else { parsingError }
  }

  tokenize {
    var inString = false
    var isEscaping = false
    var inNumber = false
    var valueInProgress = []
    var lastIndex = _input.count - 1

    var i = 0
    while (i < _input.count) {
      var char = _input[i]

      if (inString) {

        if (isEscaping) {
          if (escapedCharMap.containsKey(char)) {
            valueInProgress.add(escapedCharMap[char])
          } else if (char == "u") { // unicode char!
            var charsToPull = 4
            var start = i + 1
            var hexString = Helper.slice(_input, start, start + charsToPull).join("")

            var decimal = Helper.hexToDecimal(hexString)
            if (decimal == null) tokenizeError(i)
            valueInProgress.add(String.fromCodePoint(decimal))

            i = i + charsToPull
          } else {
            tokenizeError(i)
          }

          isEscaping = false
        } else if (char == "\\") {
          isEscaping = true

        } else if (char == "\"") {
          addToken(i, tokenString, valueInProgress.join(""))
          valueInProgress = []
          inString = false

        } else {
          valueInProgress.add(char)
        }

      } else if (char == "\"") {
        inString = true

      } else if (inNumber) {
        if (numberChars.contains(char)) {
          valueInProgress.add(char)
        }

        // Check last index to support bare numbers
        if (!numberChars.contains(char) || i == lastIndex) {
          var number = Num.fromString(valueInProgress.join(""))

          if (number == null) {
            tokenizeError(i)
          } else {
            addToken(i, tokenNumber, number)
          }

          valueInProgress = []
          inNumber = false

          // Since there's no terminal char for a Num, we have to wait
          // until we run into a non-Num char. Then, we back up, so that
          // char gets processed
          i = i - 1
        }
      } else if (numberChars.contains(char)) {
        valueInProgress.add(char)
        inNumber = true

        var peek = i < (_input.count - 1) ? _input[i + 1] : null
        if (char == "0" && peek == "x") {
          // Don't allow hex numbers
          tokenizeError(i)
        }

      } else if (char == "{") {
        addToken(i, tokenLeftBrace)

      } else if (char == "}") {
        addToken(i, tokenRightBrace)

      } else if (char == "[") {
        addToken(i, tokenLeftBracket)

      } else if (char == "]") {
        addToken(i, tokenRightBracket)

      } else if (char == ":") {
        addToken(i, tokenColon)

      } else if (char == ",") {
        addToken(i, tokenComma)
      } else if (char == "/") {
        // Don't allow comments
        tokenizeError(i)
      } else {
        var slicedInput = Helper.slice(_input, i).join("")
        if (slicedInput.startsWith("true")) {
          addToken(i, tokenBool, true)
        } else if (slicedInput.startsWith("false")) {
          addToken(i, tokenBool, false)
        } else if (slicedInput.startsWith("null")) {
          addToken(i, tokenNull, null)
        }
      }

      i = i + 1
    }

    return _tokens
  }

  addToken(index, type) { addToken(index, type, null) }
  addToken(index, type, value) { _tokens.add(Token.new(type, value, index)) }

  tokenizeError {
    invalidJSON("")
  }
  tokenizeError (index) {
    var position = getPositionForIndex(index)
    invalidJSON("Unexpected \"%(_input[index])\" at line %(position["line"]), column %(position["column"])")
  }
  parsingError {
    if (_tokens.count > 0) {
      var position = getPositionForIndex(_tokens[0].index)
      var value = _tokens[0].value == null ? _tokens[0] : _tokens[0].value
      invalidJSON("Unexpected \"%(value)\" at line %(position["line"]), column %(position["column"])")
    } else {
      invalidJSON("")
    }
  }
  invalidJSON(message) {
    var base = "Invalid JSON"
    Fiber.abort(message.count > 0 ? "%(base): %(message)" : base)
  }
  getPositionForIndex (index) {
    var precedingInput = Helper.slice(_input, 0, index)
    var linebreaks = precedingInput.where {|char| char == "\n"}

    var reversedPreceding = Helper.reverse(precedingInput)
    var hasSeenLinebreak = false
    var i = 0
    while (i < reversedPreceding.count && !hasSeenLinebreak) {
      if (reversedPreceding[i] == "\n") {
        hasSeenLinebreak = true
      }
      i = i + 1
    }

    return {
      "line": linebreaks.count,
      "column": i
    }
  }
}

class Token {
  construct new(type, value, index) {
    _type = type
    _value = value
    _index = index
  }

  toString {
    return (_value != null) ? (_type + " " + _value.toString) : _type
  }

  type { _type }
  value { _value }
  index { _index }
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
