import "./test-framework" for Expect, Suite, ConsoleReporter
import "../json" for JSON, JSONParser, Token

var TestJSON = Suite.new("JSON") { |it|
  var mapString = "{ \"age\": 18, \"name\": \"ethan\", \"cool\": false, \"friends\": null }"
  var arrayString = "[{ \"brand\": \"taylor\" }, { \"brand\": \"martin\"}]"
  var parser = JSONParser.new("{}")

  it.suite("tokenize") { |it|
    it.should("handle basic string") {
      var tokens = JSON.tokenize("\"sup\"")
      Expect.call(tokens.count).toEqual(2)
      Expect.call(tokens[0].type).toEqual(Token.String)
    }

    it.should("handle basic number") {
      var tokens = JSON.tokenize("3")
      Expect.call(tokens.count).toEqual(2)
      Expect.call(tokens[0].type).toEqual(Token.Number)
      Expect.call(tokens[0].value).toEqual(3)
    }

    it.should("handle basic bool") {
      var tokens = JSON.tokenize("false")
      Expect.call(tokens.count).toEqual(2)
      Expect.call(tokens[0].type).toEqual(Token.Bool)
      Expect.call(tokens[0].value).toEqual(false)
    }

    it.should("handle basic map") {
      var tokens = JSON.tokenize(mapString)

      Expect.call(tokens.count).toEqual(18)
      for (token in tokens) { Expect.call(token).toBe(Token) }

      Expect.call(tokens[0].type).toEqual(Token.LeftBrace)
      Expect.call(tokens[1].type).toEqual(Token.String)
      Expect.call(tokens[2].type).toEqual(Token.Colon)
      Expect.call(tokens[3].type).toEqual(Token.Number)
      Expect.call(tokens[4].type).toEqual(Token.Comma)
    }

    it.should("handle unicode characters") {
      var tokens = JSON.tokenize("\"\\u2618\"")
      Expect.call(tokens[0].type).toEqual(Token.String)
      Expect.call(tokens[0].value).toEqual("☘")
    }
  }

  it.suite("parse String") { |it|
    var parsedString = JSON.parse("\"lonely string\"")

    it.should("return a String") {
      Expect.call(parsedString).toBe(String)
    }

    it.should("contain the correct contents") {
      Expect.call(parsedString).toEqual("lonely string")
    }
  }

  it.suite("parse Map") { |it|
    var parsedMap = JSON.parse(mapString)

    it.should("return a Map") {
      Expect.call(parsedMap).toBe(Map)
    }

    it.should("map a key to a mapString value") {
      Expect.call(parsedMap["name"]).toEqual("ethan")
      Expect.call(parsedMap["age"]).toEqual(18)
      Expect.call(parsedMap["cool"]).toBeFalse
      Expect.call(parsedMap["friends"]).toBeNull
    }
  }

  it.suite("parse List") { |it|
    var parsedList = JSON.parse(arrayString)

    it.should("return a List") {
      Expect.call(parsedList).toBe(List)
      Expect.call(parsedList.count).toEqual(2)
    }

    var nestedMaps = "
      [{
        \"some\": \"thing\",
        \"other\": [1, 2, 3, 4, 5]
      }, {
        \"more\": {
          \"don't\": \"stop\"
        }
      }]
    "

    it.should("handle nested Maps") {
      var parsedNested = JSON.parse(nestedMaps)

      Expect.call(parsedNested).toBe(List)
      Expect.call(parsedNested.count).toEqual(2)
      for (item in parsedNested) { Expect.call(item).toBe(Map) }

      Expect.call(parsedNested[0]["some"]).toEqual("thing")

      var other = parsedNested[0]["other"]
      Expect.call(other).toBe(List)
      Expect.call(other.count).toEqual(5)
      for (item in other) { Expect.call(item).toBe(Num)}

      var more = parsedNested[1]["more"]
      Expect.call(more["don't"]).toEqual("stop")
    }
  }

  it.suite("parse special characters") { |it|
    it.should("handle double quotes in strings") {
      Expect.call(JSON.parse("\"hey \\\" man\"")).toEqual("hey \" man")
    }

    it.should("handle backslashes in strings") {
      Expect.call(JSON.parse("\"hey \\\\ man\"")).toEqual("hey \\ man")
    }

    it.should("handle backspaces in strings") {
      Expect.call(JSON.parse("\"hey \\b man\"")).toEqual("hey \b man")
    }

    it.should("handle formfeeds in strings") {
      Expect.call(JSON.parse("\"hey \\f man\"")).toEqual("hey \f man")
    }

    it.should("handle newlines in strings") {
      Expect.call(JSON.parse("\"hey \\n man\"")).toEqual("hey \n man")
    }

    it.should("handle carriage returns in strings") {
      Expect.call(JSON.parse("\"hey \\r man\"")).toEqual("hey \r man")
    }

    it.should("handle horizontal tabs in strings") {
      Expect.call(JSON.parse("\"hey \\t man\"")).toEqual("hey \t man")
    }

    it.should("throw for a random slash") {
      var fiberWithError = Fiber.new { JSON.parse("\"hey \\man\"") }
      Expect.call(fiberWithError).toBeARuntimeError
    }

    it.should("handle bare numbers") {
      Expect.call(JSON.parse("3.5")).toEqual(3.5)
    }
  }

  it.suite("stringify") { |it|
    it.should("wrap strings in quotes") {
      Expect.call(JSON.stringify("hello")).toEqual("\"hello\"")
    }

    it.should("convert Bools into their string form") {
      Expect.call(JSON.stringify(true)).toEqual("true")
      Expect.call(JSON.stringify(false)).toEqual("false")
    }

    it.should("convert Nums into their string form") {
      Expect.call(JSON.stringify(2)).toEqual("2")
      Expect.call(JSON.stringify(-3.5)).toEqual("-3.5")
    }

    it.should("handle a basic Map") {
      Expect.call(JSON.stringify({})).toEqual("{}")
    }

    it.should("handle a basic List") {
      Expect.call(JSON.stringify([])).toEqual("[]")
    }

    var object = [{
      "some": "thing"
    }, {
      "other": [1, 2, 3, 4]
    }, {
      "a": null
    }, {
      "b": true
    }]

    it.should("handle a nested object") {
      var result = "[{\"some\":\"thing\"},{\"other\":[1,2,3,4]},{\"a\":null},{\"b\":true}]"
      Expect.call(JSON.stringify(object)).toEqual(result)
    }

    it.should("handle double quotes in strings") {
      Expect.call(JSON.stringify("hey \" man")).toEqual("\"hey \\\" man\"")
    }

    it.should("handle backslashes in strings") {
      Expect.call(JSON.stringify("hey \\ man")).toEqual("\"hey \\\\ man\"")
    }

    it.should("handle backspaces in strings") {
      Expect.call(JSON.stringify("hey \b man")).toEqual("\"hey \\b man\"")
    }

    it.should("handle formfeeds in strings") {
      Expect.call(JSON.stringify("hey \f man")).toEqual("\"hey \\f man\"")
    }

    it.should("handle newlines in strings") {
      Expect.call(JSON.stringify("hey \n man")).toEqual("\"hey \\n man\"")
    }

    it.should("handle carriage returns in strings") {
      Expect.call(JSON.stringify("hey \r man")).toEqual("\"hey \\r man\"")
    }

    it.should("handle horizontal tabs in strings") {
      Expect.call(JSON.stringify("hey \t man")).toEqual("\"hey \\t man\"")
    }

    it.should("escape control characters") {
      Expect.call(JSON.stringify(String.fromByte(1))).toEqual("\"\\u0001\"")
    }
  }

  it.suite("edge cases") { |it|
    it.should("throw for trailing commas") {
      var fiberWithError = Fiber.new { JSON.parse("{\"id\": 0,}") }
      Expect.call(fiberWithError).toBeARuntimeError("Invalid JSON: Unexpected \"COMMA\" at line 0, column 9")
    }

    it.should("throw for comments") {
      var fiberWithError = Fiber.new { JSON.parse("{// here comes an id\n\"id\": 0}") }
      Expect.call(fiberWithError).toBeARuntimeError("Invalid JSON: Unexpected \"/\" at line 0, column 1")
    }

    it.should("throw for unclosed structures") {
      var fiberWithError = Fiber.new { JSON.parse("{\"id\":") }
      Expect.call(fiberWithError).toBeARuntimeError("Invalid JSON: Unexpected \"EOF\" at line 0, column 6")
    }

    it.should("allow nested structures") {
      var value = JSON.parse("[[[[]]]]")
      Expect.call(value).toBe(List)
      Expect.call(value.count).toEqual(1)
      Expect.call(value[0].count).toEqual(1)
      Expect.call(value[0][0].count).toEqual(1)
      Expect.call(value[0][0][0].count).toEqual(0)
    }

    // TODO: White Spaces

    it.should("throw for NaN") {
      var fiberWithError = Fiber.new { JSON.parse("{\"id\": NaN}") }
      Expect.call(fiberWithError).toBeARuntimeError("Invalid JSON: Unexpected \"NaN\" at line 0, column 7")
    }

    it.should("throw for Infinity") {
      var fiberWithError = Fiber.new { JSON.parse("{\"id\": Infinity}") }
      Expect.call(fiberWithError).toBeARuntimeError("Invalid JSON: Unexpected \"Infinity\" at line 0, column 7")
    }

    it.should("throw for hex numbers") {
      var fiberWithError = Fiber.new { JSON.parse("{\"id\": 0xFF}") }
      Expect.call(fiberWithError).toBeARuntimeError("Invalid JSON: Unexpected \"xFF\" at line 0, column 8")
    }

    // TODO: Exponential Notation

    it.should("handle tricky arrays") {
      var value = JSON.parse("[[],[[]]]")
      Expect.call(value).toBe(List)
      Expect.call(value.count).toEqual(2)
      Expect.call(value[1].count).toEqual(1)
    }

    it.should("throw for colon instead of comma") {
      var fiberWithError = Fiber.new { JSON.parse("[\"id\": 0]") }
      Expect.call(fiberWithError).toBeARuntimeError("Invalid JSON: Unexpected \"COLON\" at line 0, column 6")
    }

    it.should("throw for comma instead of colon") {
      var fiberWithError = Fiber.new { JSON.parse("{\"id\", 0}") }
      Expect.call(fiberWithError).toBeARuntimeError("Invalid JSON: Unexpected \"COMMA\" at line 0, column 6")
    }

    it.should("handle empty keys") {
      var value = JSON.parse("{\"\": 0}")
      Expect.call(value[""]).toEqual(0)
    }

    // Well-formed JSON shouldn't have duplicate keys. Behavior isn't standardized.
    it.should("overwrite duplicate keys") {
      var value = JSON.parse("{\"id\": 0, \"id\": 1}")
      Expect.call(value["id"]).toEqual(1)
    }

    it.should("throw for double colons") {
      var fiberWithError = Fiber.new { JSON.parse("{\"id\":: 0}") }
      Expect.call(fiberWithError).toBeARuntimeError("Invalid JSON: Unexpected \"COLON\" at line 0, column 7")
    }

    it.should("throw for missing keys") {
      var fiberWithError = Fiber.new { JSON.parse("{: 0}") }
      Expect.call(fiberWithError).toBeARuntimeError("Invalid JSON: Unexpected \"COLON\" at line 0, column 2")
    }

    it.should("throw for non-string keys") {
      var fiberWithError = Fiber.new { JSON.parse("{1:1}") }
      Expect.call(fiberWithError).toBeARuntimeError("Invalid JSON: Unexpected \"NUMBER 1\" at line 0, column 2")
    }

    it.should("parse unicode keys") {
      var value = JSON.parse("{\"\\u2618\": 11}")
      Expect.call(value["☘"]).toEqual(11)
    }

    it.should("throw for extraneous text") {
      var fiberWithError = Fiber.new { JSON.parse("{\"wow\" nonsense :1}") }
      Expect.call(fiberWithError).toBeARuntimeError("Invalid JSON: Unexpected \"nonsense\" at line 0, column 7")
    }

    it.should("throw for double brackets") {
      var fiberWithError = Fiber.new { JSON.parse("{{") }
      Expect.call(fiberWithError).toBeARuntimeError("Invalid JSON: Unexpected \"LEFT_BRACE\" at line 0, column 2")
    }

    it.should("throw given an empty string") {
      var fiberWithError = Fiber.new { JSON.parse("") }
      Expect.call(fiberWithError).toBeARuntimeError("Invalid JSON: Unexpected \"EOF\" at line 0, column 0")
    }
  }
}

{
  var reporter = ConsoleReporter.new()
  TestJSON.run(reporter)
  reporter.epilogue()
}
