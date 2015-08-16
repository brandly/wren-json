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

  it.suite("stringify") { |it|
    var object = [{
      "some": "thing"
    }, {
      "other": [1, 2, 3, 4]
    }]

    it.should("handle object") {
      var result = "[{\"some\":\"thing\"},{\"other\":[1,2,3,4]}]"
      Expect.call(JSON.stringify(object)).toEqual(result)
    }
  }
}

{
  var reporter = ConsoleReporter.new()
  TestJSON.run(reporter)
  reporter.epilogue()
}
