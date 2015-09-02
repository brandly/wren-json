import "test-framework" for Expect, Suite, ConsoleReporter
import "../json" for JSON, JSONParser, Token

var TestJSON = Suite.new("JSON") { |it|
  var mapString = "{ \"age\": 18, \"name\": \"ethan\", \"cool\": false, \"friends\": null }"
  var arrayString = "[{ \"brand\": \"taylor\" }, { \"brand\": \"martin\"}]"
  var parser = JSONParser.new("{}")

  it.suite("tokenize") { |it|
    it.should("handle basic string") {
      var tokens = JSON.tokenize(mapString)

      Expect.call(tokens.count).toEqual(17)
      for (token in tokens) { Expect.call(token).toBe(Token) }

      Expect.call(tokens[0].type).toEqual(parser.tokenLeftBrace)
      Expect.call(tokens[1].type).toEqual(parser.tokenString)
      Expect.call(tokens[2].type).toEqual(parser.tokenColon)
      Expect.call(tokens[3].type).toEqual(parser.tokenNumber)
      Expect.call(tokens[4].type).toEqual(parser.tokenComma)
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
      Expect.call(fiberWithError).toBeARuntimeError("Invalid JSON")
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
  }
}

{
  var reporter = ConsoleReporter.new()
  TestJSON.run(reporter)
  reporter.epilogue()
}
