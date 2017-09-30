/**
 * An Expectation captures an assertion about a value made in a test block. It
 * is used by the default matchers to communicate the pass/fail state of a test
 * block and can be used by other matcher implementations if you need to extend
 * the deafault matchers.
 */
class Expectation {
  /**
   * Create a new expectation result instance.
   *
   * @param {Bool} passed Whether this expectation was successful.
   * @param {String} message Message to print if the expectation was not
   *                         successful.
   */
  construct new(passed, message) {
    _passed = passed
    _message = message
  }

  /**
   * @return {Bool} Whether or not this expectation was successful.
   */
  passed { _passed }

  /**
   * @return {String} Message that explains the failure mode of this
   * expectation.
   */
  message { _message }
}
/**
 * Defines the full interface for a test reporter.
 */
class Reporter {
  /**
   * Called when a test run is entirely finished and can be used to print a test
   * summary for instance.
   */
  epilogue () {}

  /**
   * Called when a runnable is skipped.
   *
   * @param {Skippable} skippable Skippable object that represents the runnable
   *                              that was skipped.
   */
  runnableSkipped (skippable) {}

  /**
   * Called when a suite run is started.
   *
   * @param {String} title Name of the suite that has been started.
   */
  suiteStart (title) {}

  /**
   * Called when a suite run is finished.
   *
   * @param {String} title Name of the suite that has been finished.
   */
  suiteEnd (title) {}

  /**
   * Called when a test is started.
   *
   * @param {Runnable} runnable Runnable object that is about to be run.
   */
  testStart (runnable) {}

  /**
   * Called when a test passed.
   *
   * @param {Runnable} runnable Runnable object that was successful.
   */
  testPassed (runnable) {}

  /**
   * Called when a test failed.
   *
   * @param {Runnable} runnable Runnable object that failed.
   */
  testFailed (runnable) {}

  /**
   * Called when a test encounters an error.
   *
   * @param {Runnable} runnable Runnable object that encountered an error.
   */
  testError (runnable) {}

  /**
   * Called when a test is finished.
   *
   * @param {Runnable} runnable Runnable object that just finished.
   */
  testEnd (runnable) {}
}
/**
 * Run a test block.
 */
class Runnable {
  /**
   * Create a new runnable test object. Either a Fiber or Fn can be given as the
   * runnable object.
   *
   * @param {String} title Name of the test.
   * @param {Sequence[Fn|Fiber]} beforeEaches List of functions or fibers that
   *                                          should be called before the main
   *                                          test block is run.
   * @param {Sequence[Fn|Fiber]} afterEaches List of functions or fibers that
   *                                         should be called after the main
   *                                         test block is run.
   * @param {Fiber|Fn} body Fiber or function that represents the test to run.
   */
  construct new (title, beforeEaches, afterEaches, fn) {
    _title = title

    _beforeEaches = beforeEaches
    _afterEaches = afterEaches

    _expectations = []

    // Wrap bare functions in Fibers.
    if (fn.type != Fiber) {
      fn = Fiber.new(fn)
    }

    _fn = fn
  }

  /**
   * @return {Num} Elapsed time for this test, in milliseconds, including
   * running all defined `beforeEach` and `afterEach` methods.
   */
  duration { (_duration * 1000).ceil }

  /**
   * @return {String} The error string of this Runnable if an error was
   * encountered while running this test.
   */
  error { _fn.error }

  /**
   * @return {Sequence[Expectations]} List of `Expectation`s that were emitted
   * by the test body.
   */
  expectations { _expectations }

  /**
   * @return {Bool} Whether this Runnable instance has been run.
   */
  hasRun { _fn.isDone }

  /**
   * Runs the test function and collects the `Expectation`s that were generated.
   *
   * @return {Sequence[Expectation]} List of `Expectation`s that were emitted by
   * the test body.
   */
  run() {
    var startTime = System.clock

    for (fn in _beforeEaches) { fn.call() }

    while (!_fn.isDone) {
      var result = _fn.try()

      // Ignore any values that were yielded that weren't an Expectation.
      // Note: When a fiber is finished the last `yield` invocation returns
      // `null` so it will not be added to the array.
      if (result is Expectation) {
        _expectations.add(result)
      }
    }

    for (fn in _afterEaches) { fn.call() }

    _duration = System.clock - startTime

    return _expectations
  }

  /**
   * @return {String} Title string of this Runnable.
   */
  title { _title }
}
/**
 * Represents a skipped test or suite and implements the same basic interface as
 * `Runnable`.
 */
class Skippable {
  /**
   * Create a new skipped test or suite.
   *
   * @param {String} title Name of the skipped test or suite.
   */
  construct new (title) {
    _title = title
  }

  run { /* Do nothing. */ }

  /**
   * @return {String} Title string of this Skippable.
   */
  title { _title }
}
/**
 * This class provides a way to create a stub function that can used in place of
 * a real method with additional tracking and introspection capabilities.
 *
 * This class takes advantage of the `call` semantics of Wren to create a class
 * that can be passed around like a function by virtue of defining the
 * appropriate `call` methods for any number of allowed arguments.
 *
 * This class does not contain any matcher methods instead look at StubMatchers
 * for matchers that work with Stub instances.
 *
 * A number of static constructor helper methods are provided to make stub
 * creation more readable in context.
 */
class Stub {
  /**
   * Create a new Stub instance that returns nothing when invoked.
   *
   * @param {String} name Name of the stub instance.
   */
  construct new (name) {
    _name = name
    _calls = []
  }

  /**
   * Create a new Stub instance that calls the given function when invoked.
   *
   * @param {String} name Name of the stub instance.
   * @param {Fn} fakeFn Function to call when this stub is invoked.
   */
  construct new (name, fakeFn) {
    _name = name
    _fakeFn = fakeFn
    _calls = []
  }

  /**
   * Creates a Stub that calls the given fake function when called.
   *
   * @param {String} name Name of the stub instance.
   * @param {Fn} fakeFn Function that should be called every time this stub is
   *                    called.
   * @return {Stub} Instance that calls the fake function when called with any
   * number of arguments.
   */
  static andCallFake (name, fakeFn) {
    return Stub.new(name, fakeFn)
  }

  /**
   * Creates a Stub that always returns the same value when called.
   *
   * @param {String} name Name of the stub instance.
   * @param {*} returnValue Value that should be returned when this stub is
   *                        called.
   * @return {Stub} Instance that returns a value when called with any number of
   * arguments.
   */
  static andReturnValue (name, returnValue) {
    // Wrap the bare return value in a function to unify interfaces.
    var valueReturningFn = Fn.new { |args| returnValue }

    return Stub.new(name, valueReturningFn)
  }

  /**
   * @return {Bool} Whether or not the stub has been called.
   */
  called { _calls.count != 0 }

  /**
   * @return {Sequence[Sequence[*]]} List of lists containing the arguments that
   * each call to this stub provided.
   */
  calls { _calls }

  /**
   * @return {Sequence[*]} List of arguments for the first call on this stub.
   */
  firstCall {
    if (_calls.count > 0) {
      return _calls[0]
    }
  }

  /**
   * @return {Sequence[*]} List of arguments for the most recent call on this
   * stub.
   */
  mostRecentCall {
    if (_calls.count > 0) {
      return _calls[_calls.count - 1]
    }
  }

  /**
   * @return {String} Name of the stub instance.
   */
  name { _name }

  /**
   * Clears all tracking for this stub.
   */
  reset {
    _calls = []
  }

  call {
    _calls.add([])

    if (_fakeFn) {
      return _fakeFn.call([])
    }
  }

  call () {
    _calls.add([])

    if (_fakeFn) {
      return _fakeFn.call([])
    }
  }

  call (a) {
    _calls.add([a])

    if (_fakeFn) {
      return _fakeFn.call([a])
    }
  }

  call (a, b) {
    _calls.add([a, b])

    if (_fakeFn) {
      return _fakeFn.call([a, b])
    }
  }

  call (a, b, c) {
    _calls.add([a, b, c])

    if (_fakeFn) {
      return _fakeFn.call([a, b, c])
    }
  }

  call (a, b, c, d) {
    _calls.add([a, b, c, d])

    if (_fakeFn) {
      return _fakeFn.call([a, b, c, d])
    }
  }

  call (a, b, c, d, e) {
    _calls.add([a, b, c, d, e])

    if (_fakeFn) {
      return _fakeFn.call([a, b, c, d, e])
    }
  }

  call (a, b, c, d, e, f) {
    _calls.add([a, b, c, d, e, f])

    if (_fakeFn) {
      return _fakeFn.call([a, b, c, d, e, f])
    }
  }

  call (a, b, c, d, e, f, g) {
    _calls.add([a, b, c, d, e, f, g])

    if (_fakeFn) {
      return _fakeFn.call([a, b, c, d, e, f, g])
    }
  }

  call (a, b, c, d, e, f, g, h) {
    _calls.add([a, b, c, d, e, f, g, h])

    if (_fakeFn) {
      return _fakeFn.call([a, b, c, d, e, f, g, h])
    }
  }

  call (a, b, c, d, e, f, g, h, i) {
    _calls.add([a, b, c, d, e, f, g, h, i])

    if (_fakeFn) {
      return _fakeFn.call([a, b, c, d, e, f, g, h, i])
    }
  }

  call (a, b, c, d, e, f, g, h, i, j) {
    _calls.add([a, b, c, d, e, f, g, h, i, j])

    if (_fakeFn) {
      return _fakeFn.call([a, b, c, d, e, f, g, h, i, j])
    }
  }

  call (a, b, c, d, e, f, g, h, i, j, k) {
    _calls.add([a, b, c, d, e, f, g, h, i, j, k])

    if (_fakeFn) {
      return _fakeFn.call([a, b, c, d, e, f, g, h, i, j, k])
    }
  }

  call (a, b, c, d, e, f, g, h, i, j, k, l) {
    _calls.add([a, b, c, d, e, f, g, h, i, j, k, l])

    if (_fakeFn) {
      return _fakeFn.call([a, b, c, d, e, f, g, h, i, j, k, l])
    }
  }

  call (a, b, c, d, e, f, g, h, i, j, k, l, m) {
    _calls.add([a, b, c, d, e, f, g, h, i, j, k, l, m])

    if (_fakeFn) {
      return _fakeFn.call([a, b, c, d, e, f, g, h, i, j, k, l, m])
    }
  }

  call (a, b, c, d, e, f, g, h, i, j, k, l, m, n) {
    _calls.add([a, b, c, d, e, f, g, h, i, j, k, l, m, n])

    if (_fakeFn) {
      return _fakeFn.call([a, b, c, d, e, f, g, h, i, j, k, l, m, n])
    }
  }

  call (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o) {
    _calls.add([a, b, c, d, e, f, g, h, i, j, k, l, m, n, o])

    if (_fakeFn) {
      return _fakeFn.call([a, b, c, d, e, f, g, h, i, j, k, l, m, n, o])
    }
  }

  call (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p) {
    _calls.add([a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p])

    if (_fakeFn) {
      return _fakeFn.call([a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p])
    }
  }
}

class Suite {
  /**
   * Create a new suite of tests.
   *
   * @param {String} name Name of the suite.
   * @param {Fn} block Function that defines the set of tests that belong to
   *                   this suite. It receives this instance as its first
   *                   argument.
   */
  construct new (name, block) {
    constructor_(name, [], [], block)
  }

  /**
   * Create a new suite of tests with the given `beforeEach` and `afterEach`
   * functions.
   *
   * @param {String} name Name of the suite.
   * @param {Sequence[Fn]} beforeEaches A list of functions to invoke before
   *                                    each test is invoked.
   * @param {Sequence[Fn]} afterEaches A list of functions to invoke after each
   *                                   test is invoked.
   * @param {Fn} block Function that defines the set of tests that belong to
   *                   this suite. It receives this instance as its first
   *                   argument.
   */
  construct new (name, beforeEaches, afterEaches, block) {
    constructor_(name, beforeEaches, afterEaches, block)
  }

  /**
   * Stub method used when skipping an `afterEach` block.
   */
  afterEach { this }

  /**
   * Define a block to run after every test in this suite and any nested suites.
   *
   * @param {Fn} block Function that should be run after every test.
   */
  afterEach (block) {
    _afterEaches.add(block)
  }

  /**
   * Stub method used when skipping a `beforeEach` block.
   */
  beforeEach { this }

  /**
   * Define a block to run before every test in this suite and any nested
   * suites.
   *
   * @param {Fn} block Function that should be run before every test.
   */
  beforeEach (block) {
    _beforeEaches.add(block)
  }

  run (reporter) {

    reporter.suiteStart(title)

    for (runnable in _runnables) {
      if (runnable is Suite) {
        runnable.run(reporter)
      } else if (runnable is Skippable) {
        reporter.runnableSkipped(runnable)
      } else {
        reporter.testStart(runnable)

        var result = runnable.run()
        var passed = result.all { |r| r.passed }

        if (runnable.error) {
          reporter.testError(runnable)
        } else if (passed) {
          reporter.testPassed(runnable)
        } else {
          reporter.testFailed(runnable)
        }

        reporter.testEnd(runnable)
      }
    }

    reporter.suiteEnd(title)
  }

  /**
   * Stub method used when skipping a `should` block inside the suite.
   *
   * @param {String} name Descriptive name for the test.
   */
  should (name) {
    var skippable = Skippable.new(name)
    _runnables.add(skippable)

    return this
  }

  /**
   * Create a new test block.
   *
   * @param {String} name Descriptive name for the test.
   * @param {Fn|Fiber} block Function or fiber block that should be executed for
   *                         this test.
   */
  should (name, block) {
    var runnable = Runnable.new(name, _beforeEaches, _afterEaches, block)
    _runnables.add(runnable)
  }

  /**
   * Does nothing except receive the block that would normally be associated
   * with the construct that was skipped.
   */
  skip (block) { /* Do nothing */ }

  /**
   * Stub method used when skipping a `suite` block inside the suite.
   *
   * @param {String} name Name of the suite.
   */
  suite (name) {
    var skippable = Skippable.new(name)
    _runnables.add(skippable)

    return this
  }

  /**
   * Create a new suite of tests that are nested under this suite.
   *
   * @param {String} name Name of the suite.
   * @param {Fn} block Function that defines the set of tests that belong to
   *                   this suite.
   */
  suite (name, block) {
    var suite = Suite.new(name, _beforeEaches, _afterEaches, block)
    _runnables.add(suite)
  }

  /**
   * @return {String} Title string of this suite.
   */
  title { _name }

  constructor_ (name, beforeEaches, afterEaches, block) {
    _name = name

    _beforeEaches = beforeEaches
    _afterEaches = afterEaches

    _runnables = []

    // Invoke the block that defines the tests in this suite.
    block.call(this)
  }
}

/**
 * A class of matchers to use for making assertions.
 */
class BaseMatchers {
  /**
   * Create a new `Matcher` object for a value.
   *
   * @param {*} value The value to be matched on.
   */
  construct new (value) {
    _value = value
  }

  /**
   * @return The value for which this matcher was constructed.
   */
  value { _value }

  /**
   * Negates this matcher and returns itself so that it can be chained with
   * other matchers:
   *
   *     var matcher = Matchers.new("value")
   *     matcher.not.toEqual("string") // Passing expectation.
   *
   * @return This instance of the classes that received this method.
   */
  not {
    _negated = true

    // Return this matcher to support chaining.
    return this
  }

  /**
   * Asserts that the value is of a given class.
   *
   * @param {Class} klass Class which the value should be an instacne of.
   */
  toBe (klass) {
    var message = "Expected " + _value.toString + " of class " +
        _value.type.toString + " to be of class " + klass.toString
    report_(_value is klass, message)
  }

  /**
   * Asserts that the value is false.
   */
  toBeFalse {
    var message = "Expected " + _value.toString + " to be false"
    report_(_value == false, message)
  }

  /**
   * Asserts that the value is true.
   */
  toBeTrue {
    var message = "Expected " + _value.toString + " to be true"
    report_(_value == true, message)
  }

  /**
   * Asserts that the value is null.
   */
  toBeNull {
    var message = "Expected " + _value.toString + " to be null"
    report_(_value == null, message)
  }

  /**
   * Asserts that the value is equal to the given value.
   *
   * @param {*} other Object that this value should be equal to.
   */
  toEqual (other) {
    var message = "Expected " + _value.toString + " to equal " +  other.toString
    report_(_value == other, message)
  }

  report_ (result, message) {
    result = _negated ? !result : result

    var expectation = Expectation.new(result, message)
    Fiber.yield(expectation)
  }

  /**
   * Enforces that the value for this matcher instance is of a certain class. If
   * the value is not of the specified type the current Fiber will be aborted
   * with an error message.
   *
   * @param {Class} klass Type of which the value should be an instance.
   */
  enforceClass_ (klass) {
    if (!(value is klass)) {
      Fiber.abort(value.toString + " was not a " + klass.toString)
    }
  }
}

/**
 * A class of matchers for making assertions about Fibers.
 */
class FiberMatchers is BaseMatchers {
  /**
   * Create a new `Matcher` object for a value.
   *
   * @param {*} value The value to be matched on.
   */
  construct new (value) {
    super(value)
  }

  /**
   * Assert that invoking this value as a fiber generated a runtime error.
   */
  toBeARuntimeError {
    enforceClass_(Fiber)

    // Run the fiber to generate the possible error.
    value.try()

    var message = "Expected a runtime error but it did not occur"
    report_(value.error != null, message)
  }

  /**
   * Assert that invoking this value as a fiber generated a runtime error with
   * the given message.
   *
   * @param {String} errorMessage Error message that should have been generated
   *                              by the fiber.
   */
  toBeARuntimeError (errorMessage) {
    enforceClass_(Fiber)

    // Run the fiber to generate the possible error.
    while (!value.isDone) {
      value.try()
    }

    if (value.error == null) {
      var message = "Expected a runtime error but it did not occur"
      report_(false, message)
    } else {
      var message = "Expected a runtime error with error: " + errorMessage +
          " but got: " + value.error
      report_(value.error == errorMessage, message)
    }
  }

  /**
   * Assert that the fiber is done.
   */
  toBeDone {
    enforceClass_(Fiber)

    var message = "Expected the fiber to be done"
    report_(value.isDone, message)
  }

  /**
   * Assert that invoking this fiber yields the expected value(s).
   *
   * @param shouldYield
   */
  /*toYield (shouldYield) {
    enforceClass_(Fiber)

    // If a bare value was passed coerce it into a list.
    if (!(shouldYield is List)) { shouldYield = [shouldYield] }

    var results = []

    // Get all values that this fiber could yield.
    while (!value.isDone) {
      results.add(value.try())
    }

    // The last value yielded from any fiber before it finishes is null.
    results.removeAt(results.size - 1)

    if (value.error != null) {
      var message = "Expected the fiber to yield `" + shouldYield.toString +
          "` but instead got a runtime error with message: `" + value.error +
          " and yielded `" + results.toString + "`"
      report_(false, message)
    } else {
      var message = "Expected the fiber to yield `" + shouldYield.toString +
          "` but instead it yielded `" + results.toString + "`"
      report_(results.size == shouldYield.size, message)
    }
  }*/
}

class NumMatchers is FiberMatchers {
  /**
   * Create a new `Matcher` object for a value.
   *
   * @param {*} value The value to be matched on.
   */
  construct new (value) {
    super(value)
  }

  /**
   * Assert that the value is greater than some value. This matcher works on any
   * class that defines the `>` operator.
   */
  toBeGreaterThan (other) {
    report_(value > other, "Expected " + value.toString + " to be greater " +
        "than " + other.toString)
  }

  /**
   * Assert that the value is less than some value. This matcher works on any
   * class that defines the `<` operator.
   */
  toBeLessThan (other) {
    report_(value < other, "Expected " + value.toString + " to be less than " +
        other.toString)
  }

  /**
   * Assert that the value is between two values. This matches works on any
   * class that defines the `<` and `>` operator.
   */
  toBeBetween (min, max) {
    var message = "Expected " + value.toString + " to be between " +
        min.toString + " and " + max.toString
    report_(value > min && value < max, message)
  }
}

/**
 * A class of matchers for making assertions about ranges.
 */
class RangeMatchers is NumMatchers {
  /**
   * Create a new `Matcher` object for a value.
   *
   * @param {*} value The value to be matched on.
   */
  construct new (value) {
    super(value)
  }

  /**
   * Assert that the value contains the given range.
   *
   * @param {Range} other The range that should be contained within the range
   *                      represented by the value.
   */
  toContain (other) {
    enforceClass_(Range)

    var result = rangeIsContainedBy_(value, other)
    var message = "Expected " + value.toString + " to contain " + other.toString
    report_(result, message)
  }

  /**
   * Assert that the value is contained within the given range.
   *
   * @param {Range} other The range that should contain this range represented
   *                      by the value.
   */
  toBeContainedBy (other) {
    enforceClass_(Range)

    var result = rangeIsContainedBy_(other, value)
    var message = "Expected " + value.toString + " to be contained by " +
        other.toString
    report_(result, message)
  }

  rangeIsContainedBy_ (parent, child) {
    var parentTo = parent.isInclusive ? parent.to : (parent.to - 1)
    var childTo = child.isInclusive ? child.to : (child.to - 1)

    return (child.from >= parent.from) && (childTo <= parentTo)
  }
}

class StubMatchers is RangeMatchers {
  /**
   * Create a new `Matcher` object for a value.
   *
   * @param {*} value The value to be matched on.
   */
  construct new (value) {
    super(value)
  }

  /**
   * Assert that this stub was called at least once.
   */
  toHaveBeenCalled {
    enforceClass_(Stub)

    var message = "Expected " + value.name + " to have been called"
    report_(value.called, message)
  }

  /**
   * Assert that this stub was called a certain number of times.
   *
   * @param {Num} times Number of times this stub should have been called.
   */
  toHaveBeenCalled (times) {
    enforceClass_(Stub)

    var message = "Expected " + value.name + " to have been called " +
        times.toString + " times but was called " + value.calls.count.toString +
        " times"
    report_(value.calls.count == times, message)
  }

  /**
   * Assert that this stub was called with the given arguments.
   *
   * @param {Sequence[*]} args Arguments that the stub should have been called
   *                           with.
   */
  toHaveBeenCalledWith (args) {
    enforceClass_(Stub)

    for (call in value.calls) {
      // Ignore any call lists that aren't the same size.
      if (call.count == args.count) {
        var i = 0

        var argsEqual = call.all { |callArg|
          i = i + 1
          return callArg == args[i - 1]
        }

        if (argsEqual) {
          report_(true, "")
          return
        }
      }
    }

    var message = "Expected " + value.name + " to have been called with " +
        args.toString + " but was never called. Calls were:\n    " +
        value.calls.join("\n    ")
    report_(false, message)
  }
}

/**
 * A test reporter that outputs the results to the console.
 */
class ConsoleReporter is Reporter {
  construct new() {
    _indent = 0

    // Count the different kinds of tests reported.
    _counters = {
      "tests": 0,
      "passed": 0,
      "failed": 0,
      "errors": 0,
      "skipped": 0
    }

    _startTime = System.clock
  }

  getCount_ (kind) { _counters[kind].toString }

  count_ (kind) {
    _counters[kind] = _counters[kind] + 1
  }

  /**
   * Prints out a summary of the test run reported on by this instance.
   */
  epilogue () {
    var duration = ((System.clock - _startTime) * 1000).ceil.toString

    System.print("")
    System.print("==== Tests Summary ====")

    var result = getCount_("tests") + " tests, " + getCount_("passed") +
      " passed, " + getCount_("failed") + " failed, " + getCount_("errors") +
      " errors, " + getCount_("skipped") + " skipped (" + duration + " ms)"
    print_(result, 2)
  }

  runnableSkipped (skippable) {
    count_("skipped")

    print_("- " + skippable.title, _indent + 1,
      "\u001b[36m")
  }

  suiteStart (title) {
    _indent = _indent + 1

    print_(title)
  }

  suiteEnd (title) {
    _indent = _indent - 1

    if (_indent == 0) { System.print("") }
  }

  testStart (runnable) {
    _indent = _indent + 1
    count_("tests")
  }

  testEnd (runnable) {
    _indent = _indent - 1
  }

  testPassed (runnable) {
    count_("passed")

    print_(Symbols["ok"] + " \u001b[90mshould " + runnable.title, _indent,
      "\u001b[32m")
  }

  testFailed (runnable) {
    count_("failed")

    print_(Symbols["err"] + " \u001b[90mshould " + runnable.title, _indent,
      "\u001b[31m")

    var failedExpectations = runnable.expectations.where { |e| !e.passed }

    for (expectation in failedExpectations) {
      print_(expectation.message, _indent + 1, "\u001b[31m")
    }
  }

  testError (runnable) {
    count_("errors")

    print_(Symbols["err"] + " \u001b[90mshould " + runnable.title)
    print_("Error: " + runnable.error, _indent + 1, "\u001b[31m")
  }

  print_ (string) {
    print_(string, _indent)
  }

  print_ (string, indent) {
    print_(string, indent, "")
  }

  print_ (string, indent, color) {
    var result = ""

    for (i in 2...(indent * 2)) {
      result = result + " "
    }

    System.print(color + result + string + "\u001b[0m")
  }
}

var Symbols = {
  "ok": "✓",
  "err": "✖"
}

// Create top-level class so that trying to access an undefined matcher doesn't
// result in leaking the implementation details of how our matcher classes are
// combined and create a potentially misleading error message:
//   Error: StubMatchers does not implement 'toBeUndefined'
// This error message is misleading because this isn't a problem with the
// StubMatchers class instead the real problem is that none of the base matcher
// classes define the 'toBeUndefined' matcher. Utilizing this empty class will
// result in a more correct (and useful) error message if the user is accessing
// an undefined matcher:
//   Error: Matchers does not implement 'toBeUndefinedMatcher'
class Matchers is StubMatchers {
  /**
   * Create a new `Matcher` object for a value.
   *
   * @param {*} value The value to be matched on.
   */
  construct new (value) {
    super(value)
  }
}

/**
 * Convenience method for creating new Matchers in a more readable style.
 *
 * @param {*} value Value to create a new matcher for.
 * @return A new `Matchers` instance for the given value.
 */
var Expect = Fn.new { |value|
  return Matchers.new(value)
}
