Help on module test_example:

NAME
    test_example - Exemple de tests pour démontrer l'utilisation de TestOmnibus.

CLASSES
    builtins.object
        AsyncTestWrapper
    unittest.case.TestCase(builtins.object)
        TestAsyncExample
        TestCoverage
        TestExampleAssertions
        TestExampleError
        TestExampleSuccess
        TestExhaustiveCoverage
        TestFinalCoverage
        TestMainExecution
        TestParametrized

    class AsyncTestWrapper(builtins.object)
     |  Classe pour aider à exécuter les tests asynchrones.
     |
     |  Static methods defined here:
     |
     |  run_async_test(coro)
     |      Exécute un test asynchrone et retourne le résultat.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class TestAsyncExample(unittest.case.TestCase)
     |  TestAsyncExample(methodName='runTest')
     |
     |  Classe de test avec des tests asynchrones.
     |
     |  Method resolution order:
     |      TestAsyncExample
     |      unittest.case.TestCase
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  async test_async_exception(self)
     |      Test d'une exception dans une opération asynchrone.
     |
     |  async test_async_operation(self)
     |      Test d'une opération asynchrone.
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes defined here:
     |
     |  pytestmark = [Mark(name='asyncio', args=(), kwargs={})]
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from unittest.case.TestCase:
     |
     |  __call__(self, *args, **kwds)
     |      Call self as a function.
     |
     |  __eq__(self, other)
     |      Return self==value.
     |
     |  __hash__(self)
     |      Return hash(self).
     |
     |  __init__(self, methodName='runTest')
     |      Create an instance of the class that will use the named test
     |      method when executed. Raises a ValueError if the instance does
     |      not have a method with the specified name.
     |
     |  __repr__(self)
     |      Return repr(self).
     |
     |  __str__(self)
     |      Return str(self).
     |
     |  addCleanup(self, function, /, *args, **kwargs)
     |      Add a function, with arguments, to be called when the test is
     |      completed. Functions added are called on a LIFO basis and are
     |      called after tearDown on test failure or success.
     |
     |      Cleanup items are called even if setUp fails (unlike tearDown).
     |
     |  addTypeEqualityFunc(self, typeobj, function)
     |      Add a type specific assertEqual style function to compare a type.
     |
     |      This method is for use by TestCase subclasses that need to register
     |      their own type equality functions to provide nicer error messages.
     |
     |      Args:
     |          typeobj: The data type to call this function on when both values
     |                  are of the same type in assertEqual().
     |          function: The callable taking two arguments and an optional
     |                  msg= argument that raises self.failureException with a
     |                  useful error message when the two arguments are not equal.
     |
     |  assertAlmostEqual(self, first, second, places=None, msg=None, delta=None)
     |      Fail if the two objects are unequal as determined by their
     |      difference rounded to the given number of decimal places
     |      (default 7) and comparing to zero, or by comparing that the
     |      difference between the two objects is more than the given
     |      delta.
     |
     |      Note that decimal places (from zero) are usually not the same
     |      as significant digits (measured from the most significant digit).
     |
     |      If the two objects compare equal then they will automatically
     |      compare almost equal.
     |
     |  assertCountEqual(self, first, second, msg=None)
     |      Asserts that two iterables have the same elements, the same number of
     |      times, without regard to order.
     |
     |          self.assertEqual(Counter(list(first)),
     |                           Counter(list(second)))
     |
     |       Example:
     |          - [0, 1, 1] and [1, 0, 1] compare equal.
     |          - [0, 0, 1] and [0, 1] compare unequal.
     |
     |  assertDictEqual(self, d1, d2, msg=None)
     |
     |  assertEqual(self, first, second, msg=None)
     |      Fail if the two objects are unequal as determined by the '=='
     |      operator.
     |
     |  assertFalse(self, expr, msg=None)
     |      Check that the expression is false.
     |
     |  assertGreater(self, a, b, msg=None)
     |      Just like self.assertTrue(a > b), but with a nicer default message.
     |
     |  assertGreaterEqual(self, a, b, msg=None)
     |      Just like self.assertTrue(a >= b), but with a nicer default message.
     |
     |  assertIn(self, member, container, msg=None)
     |      Just like self.assertTrue(a in b), but with a nicer default message.
     |
     |  assertIs(self, expr1, expr2, msg=None)
     |      Just like self.assertTrue(a is b), but with a nicer default message.
     |
     |  assertIsInstance(self, obj, cls, msg=None)
     |      Same as self.assertTrue(isinstance(obj, cls)), with a nicer
     |      default message.
     |
     |  assertIsNone(self, obj, msg=None)
     |      Same as self.assertTrue(obj is None), with a nicer default message.
     |
     |  assertIsNot(self, expr1, expr2, msg=None)
     |      Just like self.assertTrue(a is not b), but with a nicer default message.
     |
     |  assertIsNotNone(self, obj, msg=None)
     |      Included for symmetry with assertIsNone.
     |
     |  assertLess(self, a, b, msg=None)
     |      Just like self.assertTrue(a < b), but with a nicer default message.
     |
     |  assertLessEqual(self, a, b, msg=None)
     |      Just like self.assertTrue(a <= b), but with a nicer default message.
     |
     |  assertListEqual(self, list1, list2, msg=None)
     |      A list-specific equality assertion.
     |
     |      Args:
     |          list1: The first list to compare.
     |          list2: The second list to compare.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |  assertLogs(self, logger=None, level=None)
     |      Fail unless a log message of level *level* or higher is emitted
     |      on *logger_name* or its children.  If omitted, *level* defaults to
     |      INFO and *logger* defaults to the root logger.
     |
     |      This method must be used as a context manager, and will yield
     |      a recording object with two attributes: `output` and `records`.
     |      At the end of the context manager, the `output` attribute will
     |      be a list of the matching formatted log messages and the
     |      `records` attribute will be a list of the corresponding LogRecord
     |      objects.
     |
     |      Example::
     |
     |          with self.assertLogs('foo', level='INFO') as cm:
     |              logging.getLogger('foo').info('first message')
     |              logging.getLogger('foo.bar').error('second message')
     |          self.assertEqual(cm.output, ['INFO:foo:first message',
     |                                       'ERROR:foo.bar:second message'])
     |
     |  assertMultiLineEqual(self, first, second, msg=None)
     |      Assert that two multi-line strings are equal.
     |
     |  assertNoLogs(self, logger=None, level=None)
     |      Fail unless no log messages of level *level* or higher are emitted
     |      on *logger_name* or its children.
     |
     |      This method must be used as a context manager.
     |
     |  assertNotAlmostEqual(self, first, second, places=None, msg=None, delta=None)
     |      Fail if the two objects are equal as determined by their
     |      difference rounded to the given number of decimal places
     |      (default 7) and comparing to zero, or by comparing that the
     |      difference between the two objects is less than the given delta.
     |
     |      Note that decimal places (from zero) are usually not the same
     |      as significant digits (measured from the most significant digit).
     |
     |      Objects that are equal automatically fail.
     |
     |  assertNotEqual(self, first, second, msg=None)
     |      Fail if the two objects are equal as determined by the '!='
     |      operator.
     |
     |  assertNotIn(self, member, container, msg=None)
     |      Just like self.assertTrue(a not in b), but with a nicer default message.
     |
     |  assertNotIsInstance(self, obj, cls, msg=None)
     |      Included for symmetry with assertIsInstance.
     |
     |  assertNotRegex(self, text, unexpected_regex, msg=None)
     |      Fail the test if the text matches the regular expression.
     |
     |  assertRaises(self, expected_exception, *args, **kwargs)
     |      Fail unless an exception of class expected_exception is raised
     |      by the callable when invoked with specified positional and
     |      keyword arguments. If a different type of exception is
     |      raised, it will not be caught, and the test case will be
     |      deemed to have suffered an error, exactly as for an
     |      unexpected exception.
     |
     |      If called with the callable and arguments omitted, will return a
     |      context object used like this::
     |
     |           with self.assertRaises(SomeException):
     |               do_something()
     |
     |      An optional keyword argument 'msg' can be provided when assertRaises
     |      is used as a context object.
     |
     |      The context manager keeps a reference to the exception as
     |      the 'exception' attribute. This allows you to inspect the
     |      exception after the assertion::
     |
     |          with self.assertRaises(SomeException) as cm:
     |              do_something()
     |          the_exception = cm.exception
     |          self.assertEqual(the_exception.error_code, 3)
     |
     |  assertRaisesRegex(self, expected_exception, expected_regex, *args, **kwargs)
     |      Asserts that the message in a raised exception matches a regex.
     |
     |      Args:
     |          expected_exception: Exception class expected to be raised.
     |          expected_regex: Regex (re.Pattern object or string) expected
     |                  to be found in error message.
     |          args: Function to be called and extra positional args.
     |          kwargs: Extra kwargs.
     |          msg: Optional message used in case of failure. Can only be used
     |                  when assertRaisesRegex is used as a context manager.
     |
     |  assertRegex(self, text, expected_regex, msg=None)
     |      Fail the test unless the text matches the regular expression.
     |
     |  assertSequenceEqual(self, seq1, seq2, msg=None, seq_type=None)
     |      An equality assertion for ordered sequences (like lists and tuples).
     |
     |      For the purposes of this function, a valid ordered sequence type is one
     |      which can be indexed, has a length, and has an equality operator.
     |
     |      Args:
     |          seq1: The first sequence to compare.
     |          seq2: The second sequence to compare.
     |          seq_type: The expected datatype of the sequences, or None if no
     |                  datatype should be enforced.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |  assertSetEqual(self, set1, set2, msg=None)
     |      A set-specific equality assertion.
     |
     |      Args:
     |          set1: The first set to compare.
     |          set2: The second set to compare.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |      assertSetEqual uses ducktyping to support different types of sets, and
     |      is optimized for sets specifically (parameters must support a
     |      difference method).
     |
     |  assertTrue(self, expr, msg=None)
     |      Check that the expression is true.
     |
     |  assertTupleEqual(self, tuple1, tuple2, msg=None)
     |      A tuple-specific equality assertion.
     |
     |      Args:
     |          tuple1: The first tuple to compare.
     |          tuple2: The second tuple to compare.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |  assertWarns(self, expected_warning, *args, **kwargs)
     |      Fail unless a warning of class warnClass is triggered
     |      by the callable when invoked with specified positional and
     |      keyword arguments.  If a different type of warning is
     |      triggered, it will not be handled: depending on the other
     |      warning filtering rules in effect, it might be silenced, printed
     |      out, or raised as an exception.
     |
     |      If called with the callable and arguments omitted, will return a
     |      context object used like this::
     |
     |           with self.assertWarns(SomeWarning):
     |               do_something()
     |
     |      An optional keyword argument 'msg' can be provided when assertWarns
     |      is used as a context object.
     |
     |      The context manager keeps a reference to the first matching
     |      warning as the 'warning' attribute; similarly, the 'filename'
     |      and 'lineno' attributes give you information about the line
     |      of Python code from which the warning was triggered.
     |      This allows you to inspect the warning after the assertion::
     |
     |          with self.assertWarns(SomeWarning) as cm:
     |              do_something()
     |          the_warning = cm.warning
     |          self.assertEqual(the_warning.some_attribute, 147)
     |
     |  assertWarnsRegex(self, expected_warning, expected_regex, *args, **kwargs)
     |      Asserts that the message in a triggered warning matches a regexp.
     |      Basic functioning is similar to assertWarns() with the addition
     |      that only warnings whose messages also match the regular expression
     |      are considered successful matches.
     |
     |      Args:
     |          expected_warning: Warning class expected to be triggered.
     |          expected_regex: Regex (re.Pattern object or string) expected
     |                  to be found in error message.
     |          args: Function to be called and extra positional args.
     |          kwargs: Extra kwargs.
     |          msg: Optional message used in case of failure. Can only be used
     |                  when assertWarnsRegex is used as a context manager.
     |
     |  countTestCases(self)
     |
     |  debug(self)
     |      Run the test without collecting errors in a TestResult
     |
     |  defaultTestResult(self)
     |
     |  doCleanups(self)
     |      Execute all cleanup functions. Normally called for you after
     |      tearDown.
     |
     |  enterContext(self, cm)
     |      Enters the supplied context manager.
     |
     |      If successful, also adds its __exit__ method as a cleanup
     |      function and returns the result of the __enter__ method.
     |
     |  fail(self, msg=None)
     |      Fail immediately, with the given message.
     |
     |  id(self)
     |
     |  run(self, result=None)
     |
     |  setUp(self)
     |      Hook method for setting up the test fixture before exercising it.
     |
     |  shortDescription(self)
     |      Returns a one-line description of the test, or None if no
     |      description has been provided.
     |
     |      The default implementation of this method returns the first line of
     |      the specified test method's docstring.
     |
     |  skipTest(self, reason)
     |      Skip this test.
     |
     |  subTest(self, msg=<object object at 0x0000023FC3E68860>, **params)
     |      Return a context manager that will return the enclosed block
     |      of code in a subtest identified by the optional message and
     |      keyword parameters.  A failure in the subtest marks the test
     |      case as failed but resumes execution at the end of the enclosed
     |      block, allowing further test code to be executed.
     |
     |  tearDown(self)
     |      Hook method for deconstructing the test fixture after testing it.
     |
     |  ----------------------------------------------------------------------
     |  Class methods inherited from unittest.case.TestCase:
     |
     |  __init_subclass__(*args, **kwargs)
     |      This method is called when a class is subclassed.
     |
     |      The default implementation does nothing. It may be
     |      overridden to extend subclasses.
     |
     |  addClassCleanup(function, /, *args, **kwargs)
     |      Same as addCleanup, except the cleanup items are called even if
     |      setUpClass fails (unlike tearDownClass).
     |
     |  doClassCleanups()
     |      Execute all class cleanup functions. Normally called for you after
     |      tearDownClass.
     |
     |  enterClassContext(cm)
     |      Same as enterContext, but class-wide.
     |
     |  setUpClass()
     |      Hook method for setting up class fixture before running tests in the class.
     |
     |  tearDownClass()
     |      Hook method for deconstructing the class fixture after running all tests in the class.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from unittest.case.TestCase:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes inherited from unittest.case.TestCase:
     |
     |  failureException = <class 'AssertionError'>
     |      Assertion failed.
     |
     |
     |  longMessage = True
     |
     |  maxDiff = 640

    class TestCoverage(unittest.case.TestCase)
     |  TestCoverage(methodName='runTest')
     |
     |  Classe pour améliorer la couverture de code.
     |
     |  Method resolution order:
     |      TestCoverage
     |      unittest.case.TestCase
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  test_async_wrapper(self)
     |      Test de AsyncTestWrapper.run_async_test.
     |
     |  test_exception_handling_deep(self)
     |      Test plus profond des exceptions pour la couverture.
     |
     |  test_main_patching(self)
     |      Test du patching dans le bloc if __name__ == "__main__".
     |
     |  test_pytest_configure(self)
     |      Test de la fonction pytest_configure pour la couverture.
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from unittest.case.TestCase:
     |
     |  __call__(self, *args, **kwds)
     |      Call self as a function.
     |
     |  __eq__(self, other)
     |      Return self==value.
     |
     |  __hash__(self)
     |      Return hash(self).
     |
     |  __init__(self, methodName='runTest')
     |      Create an instance of the class that will use the named test
     |      method when executed. Raises a ValueError if the instance does
     |      not have a method with the specified name.
     |
     |  __repr__(self)
     |      Return repr(self).
     |
     |  __str__(self)
     |      Return str(self).
     |
     |  addCleanup(self, function, /, *args, **kwargs)
     |      Add a function, with arguments, to be called when the test is
     |      completed. Functions added are called on a LIFO basis and are
     |      called after tearDown on test failure or success.
     |
     |      Cleanup items are called even if setUp fails (unlike tearDown).
     |
     |  addTypeEqualityFunc(self, typeobj, function)
     |      Add a type specific assertEqual style function to compare a type.
     |
     |      This method is for use by TestCase subclasses that need to register
     |      their own type equality functions to provide nicer error messages.
     |
     |      Args:
     |          typeobj: The data type to call this function on when both values
     |                  are of the same type in assertEqual().
     |          function: The callable taking two arguments and an optional
     |                  msg= argument that raises self.failureException with a
     |                  useful error message when the two arguments are not equal.
     |
     |  assertAlmostEqual(self, first, second, places=None, msg=None, delta=None)
     |      Fail if the two objects are unequal as determined by their
     |      difference rounded to the given number of decimal places
     |      (default 7) and comparing to zero, or by comparing that the
     |      difference between the two objects is more than the given
     |      delta.
     |
     |      Note that decimal places (from zero) are usually not the same
     |      as significant digits (measured from the most significant digit).
     |
     |      If the two objects compare equal then they will automatically
     |      compare almost equal.
     |
     |  assertCountEqual(self, first, second, msg=None)
     |      Asserts that two iterables have the same elements, the same number of
     |      times, without regard to order.
     |
     |          self.assertEqual(Counter(list(first)),
     |                           Counter(list(second)))
     |
     |       Example:
     |          - [0, 1, 1] and [1, 0, 1] compare equal.
     |          - [0, 0, 1] and [0, 1] compare unequal.
     |
     |  assertDictEqual(self, d1, d2, msg=None)
     |
     |  assertEqual(self, first, second, msg=None)
     |      Fail if the two objects are unequal as determined by the '=='
     |      operator.
     |
     |  assertFalse(self, expr, msg=None)
     |      Check that the expression is false.
     |
     |  assertGreater(self, a, b, msg=None)
     |      Just like self.assertTrue(a > b), but with a nicer default message.
     |
     |  assertGreaterEqual(self, a, b, msg=None)
     |      Just like self.assertTrue(a >= b), but with a nicer default message.
     |
     |  assertIn(self, member, container, msg=None)
     |      Just like self.assertTrue(a in b), but with a nicer default message.
     |
     |  assertIs(self, expr1, expr2, msg=None)
     |      Just like self.assertTrue(a is b), but with a nicer default message.
     |
     |  assertIsInstance(self, obj, cls, msg=None)
     |      Same as self.assertTrue(isinstance(obj, cls)), with a nicer
     |      default message.
     |
     |  assertIsNone(self, obj, msg=None)
     |      Same as self.assertTrue(obj is None), with a nicer default message.
     |
     |  assertIsNot(self, expr1, expr2, msg=None)
     |      Just like self.assertTrue(a is not b), but with a nicer default message.
     |
     |  assertIsNotNone(self, obj, msg=None)
     |      Included for symmetry with assertIsNone.
     |
     |  assertLess(self, a, b, msg=None)
     |      Just like self.assertTrue(a < b), but with a nicer default message.
     |
     |  assertLessEqual(self, a, b, msg=None)
     |      Just like self.assertTrue(a <= b), but with a nicer default message.
     |
     |  assertListEqual(self, list1, list2, msg=None)
     |      A list-specific equality assertion.
     |
     |      Args:
     |          list1: The first list to compare.
     |          list2: The second list to compare.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |  assertLogs(self, logger=None, level=None)
     |      Fail unless a log message of level *level* or higher is emitted
     |      on *logger_name* or its children.  If omitted, *level* defaults to
     |      INFO and *logger* defaults to the root logger.
     |
     |      This method must be used as a context manager, and will yield
     |      a recording object with two attributes: `output` and `records`.
     |      At the end of the context manager, the `output` attribute will
     |      be a list of the matching formatted log messages and the
     |      `records` attribute will be a list of the corresponding LogRecord
     |      objects.
     |
     |      Example::
     |
     |          with self.assertLogs('foo', level='INFO') as cm:
     |              logging.getLogger('foo').info('first message')
     |              logging.getLogger('foo.bar').error('second message')
     |          self.assertEqual(cm.output, ['INFO:foo:first message',
     |                                       'ERROR:foo.bar:second message'])
     |
     |  assertMultiLineEqual(self, first, second, msg=None)
     |      Assert that two multi-line strings are equal.
     |
     |  assertNoLogs(self, logger=None, level=None)
     |      Fail unless no log messages of level *level* or higher are emitted
     |      on *logger_name* or its children.
     |
     |      This method must be used as a context manager.
     |
     |  assertNotAlmostEqual(self, first, second, places=None, msg=None, delta=None)
     |      Fail if the two objects are equal as determined by their
     |      difference rounded to the given number of decimal places
     |      (default 7) and comparing to zero, or by comparing that the
     |      difference between the two objects is less than the given delta.
     |
     |      Note that decimal places (from zero) are usually not the same
     |      as significant digits (measured from the most significant digit).
     |
     |      Objects that are equal automatically fail.
     |
     |  assertNotEqual(self, first, second, msg=None)
     |      Fail if the two objects are equal as determined by the '!='
     |      operator.
     |
     |  assertNotIn(self, member, container, msg=None)
     |      Just like self.assertTrue(a not in b), but with a nicer default message.
     |
     |  assertNotIsInstance(self, obj, cls, msg=None)
     |      Included for symmetry with assertIsInstance.
     |
     |  assertNotRegex(self, text, unexpected_regex, msg=None)
     |      Fail the test if the text matches the regular expression.
     |
     |  assertRaises(self, expected_exception, *args, **kwargs)
     |      Fail unless an exception of class expected_exception is raised
     |      by the callable when invoked with specified positional and
     |      keyword arguments. If a different type of exception is
     |      raised, it will not be caught, and the test case will be
     |      deemed to have suffered an error, exactly as for an
     |      unexpected exception.
     |
     |      If called with the callable and arguments omitted, will return a
     |      context object used like this::
     |
     |           with self.assertRaises(SomeException):
     |               do_something()
     |
     |      An optional keyword argument 'msg' can be provided when assertRaises
     |      is used as a context object.
     |
     |      The context manager keeps a reference to the exception as
     |      the 'exception' attribute. This allows you to inspect the
     |      exception after the assertion::
     |
     |          with self.assertRaises(SomeException) as cm:
     |              do_something()
     |          the_exception = cm.exception
     |          self.assertEqual(the_exception.error_code, 3)
     |
     |  assertRaisesRegex(self, expected_exception, expected_regex, *args, **kwargs)
     |      Asserts that the message in a raised exception matches a regex.
     |
     |      Args:
     |          expected_exception: Exception class expected to be raised.
     |          expected_regex: Regex (re.Pattern object or string) expected
     |                  to be found in error message.
     |          args: Function to be called and extra positional args.
     |          kwargs: Extra kwargs.
     |          msg: Optional message used in case of failure. Can only be used
     |                  when assertRaisesRegex is used as a context manager.
     |
     |  assertRegex(self, text, expected_regex, msg=None)
     |      Fail the test unless the text matches the regular expression.
     |
     |  assertSequenceEqual(self, seq1, seq2, msg=None, seq_type=None)
     |      An equality assertion for ordered sequences (like lists and tuples).
     |
     |      For the purposes of this function, a valid ordered sequence type is one
     |      which can be indexed, has a length, and has an equality operator.
     |
     |      Args:
     |          seq1: The first sequence to compare.
     |          seq2: The second sequence to compare.
     |          seq_type: The expected datatype of the sequences, or None if no
     |                  datatype should be enforced.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |  assertSetEqual(self, set1, set2, msg=None)
     |      A set-specific equality assertion.
     |
     |      Args:
     |          set1: The first set to compare.
     |          set2: The second set to compare.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |      assertSetEqual uses ducktyping to support different types of sets, and
     |      is optimized for sets specifically (parameters must support a
     |      difference method).
     |
     |  assertTrue(self, expr, msg=None)
     |      Check that the expression is true.
     |
     |  assertTupleEqual(self, tuple1, tuple2, msg=None)
     |      A tuple-specific equality assertion.
     |
     |      Args:
     |          tuple1: The first tuple to compare.
     |          tuple2: The second tuple to compare.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |  assertWarns(self, expected_warning, *args, **kwargs)
     |      Fail unless a warning of class warnClass is triggered
     |      by the callable when invoked with specified positional and
     |      keyword arguments.  If a different type of warning is
     |      triggered, it will not be handled: depending on the other
     |      warning filtering rules in effect, it might be silenced, printed
     |      out, or raised as an exception.
     |
     |      If called with the callable and arguments omitted, will return a
     |      context object used like this::
     |
     |           with self.assertWarns(SomeWarning):
     |               do_something()
     |
     |      An optional keyword argument 'msg' can be provided when assertWarns
     |      is used as a context object.
     |
     |      The context manager keeps a reference to the first matching
     |      warning as the 'warning' attribute; similarly, the 'filename'
     |      and 'lineno' attributes give you information about the line
     |      of Python code from which the warning was triggered.
     |      This allows you to inspect the warning after the assertion::
     |
     |          with self.assertWarns(SomeWarning) as cm:
     |              do_something()
     |          the_warning = cm.warning
     |          self.assertEqual(the_warning.some_attribute, 147)
     |
     |  assertWarnsRegex(self, expected_warning, expected_regex, *args, **kwargs)
     |      Asserts that the message in a triggered warning matches a regexp.
     |      Basic functioning is similar to assertWarns() with the addition
     |      that only warnings whose messages also match the regular expression
     |      are considered successful matches.
     |
     |      Args:
     |          expected_warning: Warning class expected to be triggered.
     |          expected_regex: Regex (re.Pattern object or string) expected
     |                  to be found in error message.
     |          args: Function to be called and extra positional args.
     |          kwargs: Extra kwargs.
     |          msg: Optional message used in case of failure. Can only be used
     |                  when assertWarnsRegex is used as a context manager.
     |
     |  countTestCases(self)
     |
     |  debug(self)
     |      Run the test without collecting errors in a TestResult
     |
     |  defaultTestResult(self)
     |
     |  doCleanups(self)
     |      Execute all cleanup functions. Normally called for you after
     |      tearDown.
     |
     |  enterContext(self, cm)
     |      Enters the supplied context manager.
     |
     |      If successful, also adds its __exit__ method as a cleanup
     |      function and returns the result of the __enter__ method.
     |
     |  fail(self, msg=None)
     |      Fail immediately, with the given message.
     |
     |  id(self)
     |
     |  run(self, result=None)
     |
     |  setUp(self)
     |      Hook method for setting up the test fixture before exercising it.
     |
     |  shortDescription(self)
     |      Returns a one-line description of the test, or None if no
     |      description has been provided.
     |
     |      The default implementation of this method returns the first line of
     |      the specified test method's docstring.
     |
     |  skipTest(self, reason)
     |      Skip this test.
     |
     |  subTest(self, msg=<object object at 0x0000023FC3E68860>, **params)
     |      Return a context manager that will return the enclosed block
     |      of code in a subtest identified by the optional message and
     |      keyword parameters.  A failure in the subtest marks the test
     |      case as failed but resumes execution at the end of the enclosed
     |      block, allowing further test code to be executed.
     |
     |  tearDown(self)
     |      Hook method for deconstructing the test fixture after testing it.
     |
     |  ----------------------------------------------------------------------
     |  Class methods inherited from unittest.case.TestCase:
     |
     |  __init_subclass__(*args, **kwargs)
     |      This method is called when a class is subclassed.
     |
     |      The default implementation does nothing. It may be
     |      overridden to extend subclasses.
     |
     |  addClassCleanup(function, /, *args, **kwargs)
     |      Same as addCleanup, except the cleanup items are called even if
     |      setUpClass fails (unlike tearDownClass).
     |
     |  doClassCleanups()
     |      Execute all class cleanup functions. Normally called for you after
     |      tearDownClass.
     |
     |  enterClassContext(cm)
     |      Same as enterContext, but class-wide.
     |
     |  setUpClass()
     |      Hook method for setting up class fixture before running tests in the class.
     |
     |  tearDownClass()
     |      Hook method for deconstructing the class fixture after running all tests in the class.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from unittest.case.TestCase:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes inherited from unittest.case.TestCase:
     |
     |  failureException = <class 'AssertionError'>
     |      Assertion failed.
     |
     |
     |  longMessage = True
     |
     |  maxDiff = 640

    class TestExampleAssertions(unittest.case.TestCase)
     |  TestExampleAssertions(methodName='runTest')
     |
     |  Classe de test démontrant différents types d'assertions.
     |
     |  Method resolution order:
     |      TestExampleAssertions
     |      unittest.case.TestCase
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  setUp(self)
     |      Initialisation avant chaque test.
     |
     |  test_container_assertions(self)
     |      Test des assertions sur les conteneurs.
     |
     |  test_different_assertions(self)
     |      Test utilisant différentes assertions.
     |
     |  test_exception_handling(self)
     |      Test de différents types d'exceptions.
     |
     |  test_string_assertions(self)
     |      Test des assertions sur les chaînes de caractères.
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from unittest.case.TestCase:
     |
     |  __call__(self, *args, **kwds)
     |      Call self as a function.
     |
     |  __eq__(self, other)
     |      Return self==value.
     |
     |  __hash__(self)
     |      Return hash(self).
     |
     |  __init__(self, methodName='runTest')
     |      Create an instance of the class that will use the named test
     |      method when executed. Raises a ValueError if the instance does
     |      not have a method with the specified name.
     |
     |  __repr__(self)
     |      Return repr(self).
     |
     |  __str__(self)
     |      Return str(self).
     |
     |  addCleanup(self, function, /, *args, **kwargs)
     |      Add a function, with arguments, to be called when the test is
     |      completed. Functions added are called on a LIFO basis and are
     |      called after tearDown on test failure or success.
     |
     |      Cleanup items are called even if setUp fails (unlike tearDown).
     |
     |  addTypeEqualityFunc(self, typeobj, function)
     |      Add a type specific assertEqual style function to compare a type.
     |
     |      This method is for use by TestCase subclasses that need to register
     |      their own type equality functions to provide nicer error messages.
     |
     |      Args:
     |          typeobj: The data type to call this function on when both values
     |                  are of the same type in assertEqual().
     |          function: The callable taking two arguments and an optional
     |                  msg= argument that raises self.failureException with a
     |                  useful error message when the two arguments are not equal.
     |
     |  assertAlmostEqual(self, first, second, places=None, msg=None, delta=None)
     |      Fail if the two objects are unequal as determined by their
     |      difference rounded to the given number of decimal places
     |      (default 7) and comparing to zero, or by comparing that the
     |      difference between the two objects is more than the given
     |      delta.
     |
     |      Note that decimal places (from zero) are usually not the same
     |      as significant digits (measured from the most significant digit).
     |
     |      If the two objects compare equal then they will automatically
     |      compare almost equal.
     |
     |  assertCountEqual(self, first, second, msg=None)
     |      Asserts that two iterables have the same elements, the same number of
     |      times, without regard to order.
     |
     |          self.assertEqual(Counter(list(first)),
     |                           Counter(list(second)))
     |
     |       Example:
     |          - [0, 1, 1] and [1, 0, 1] compare equal.
     |          - [0, 0, 1] and [0, 1] compare unequal.
     |
     |  assertDictEqual(self, d1, d2, msg=None)
     |
     |  assertEqual(self, first, second, msg=None)
     |      Fail if the two objects are unequal as determined by the '=='
     |      operator.
     |
     |  assertFalse(self, expr, msg=None)
     |      Check that the expression is false.
     |
     |  assertGreater(self, a, b, msg=None)
     |      Just like self.assertTrue(a > b), but with a nicer default message.
     |
     |  assertGreaterEqual(self, a, b, msg=None)
     |      Just like self.assertTrue(a >= b), but with a nicer default message.
     |
     |  assertIn(self, member, container, msg=None)
     |      Just like self.assertTrue(a in b), but with a nicer default message.
     |
     |  assertIs(self, expr1, expr2, msg=None)
     |      Just like self.assertTrue(a is b), but with a nicer default message.
     |
     |  assertIsInstance(self, obj, cls, msg=None)
     |      Same as self.assertTrue(isinstance(obj, cls)), with a nicer
     |      default message.
     |
     |  assertIsNone(self, obj, msg=None)
     |      Same as self.assertTrue(obj is None), with a nicer default message.
     |
     |  assertIsNot(self, expr1, expr2, msg=None)
     |      Just like self.assertTrue(a is not b), but with a nicer default message.
     |
     |  assertIsNotNone(self, obj, msg=None)
     |      Included for symmetry with assertIsNone.
     |
     |  assertLess(self, a, b, msg=None)
     |      Just like self.assertTrue(a < b), but with a nicer default message.
     |
     |  assertLessEqual(self, a, b, msg=None)
     |      Just like self.assertTrue(a <= b), but with a nicer default message.
     |
     |  assertListEqual(self, list1, list2, msg=None)
     |      A list-specific equality assertion.
     |
     |      Args:
     |          list1: The first list to compare.
     |          list2: The second list to compare.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |  assertLogs(self, logger=None, level=None)
     |      Fail unless a log message of level *level* or higher is emitted
     |      on *logger_name* or its children.  If omitted, *level* defaults to
     |      INFO and *logger* defaults to the root logger.
     |
     |      This method must be used as a context manager, and will yield
     |      a recording object with two attributes: `output` and `records`.
     |      At the end of the context manager, the `output` attribute will
     |      be a list of the matching formatted log messages and the
     |      `records` attribute will be a list of the corresponding LogRecord
     |      objects.
     |
     |      Example::
     |
     |          with self.assertLogs('foo', level='INFO') as cm:
     |              logging.getLogger('foo').info('first message')
     |              logging.getLogger('foo.bar').error('second message')
     |          self.assertEqual(cm.output, ['INFO:foo:first message',
     |                                       'ERROR:foo.bar:second message'])
     |
     |  assertMultiLineEqual(self, first, second, msg=None)
     |      Assert that two multi-line strings are equal.
     |
     |  assertNoLogs(self, logger=None, level=None)
     |      Fail unless no log messages of level *level* or higher are emitted
     |      on *logger_name* or its children.
     |
     |      This method must be used as a context manager.
     |
     |  assertNotAlmostEqual(self, first, second, places=None, msg=None, delta=None)
     |      Fail if the two objects are equal as determined by their
     |      difference rounded to the given number of decimal places
     |      (default 7) and comparing to zero, or by comparing that the
     |      difference between the two objects is less than the given delta.
     |
     |      Note that decimal places (from zero) are usually not the same
     |      as significant digits (measured from the most significant digit).
     |
     |      Objects that are equal automatically fail.
     |
     |  assertNotEqual(self, first, second, msg=None)
     |      Fail if the two objects are equal as determined by the '!='
     |      operator.
     |
     |  assertNotIn(self, member, container, msg=None)
     |      Just like self.assertTrue(a not in b), but with a nicer default message.
     |
     |  assertNotIsInstance(self, obj, cls, msg=None)
     |      Included for symmetry with assertIsInstance.
     |
     |  assertNotRegex(self, text, unexpected_regex, msg=None)
     |      Fail the test if the text matches the regular expression.
     |
     |  assertRaises(self, expected_exception, *args, **kwargs)
     |      Fail unless an exception of class expected_exception is raised
     |      by the callable when invoked with specified positional and
     |      keyword arguments. If a different type of exception is
     |      raised, it will not be caught, and the test case will be
     |      deemed to have suffered an error, exactly as for an
     |      unexpected exception.
     |
     |      If called with the callable and arguments omitted, will return a
     |      context object used like this::
     |
     |           with self.assertRaises(SomeException):
     |               do_something()
     |
     |      An optional keyword argument 'msg' can be provided when assertRaises
     |      is used as a context object.
     |
     |      The context manager keeps a reference to the exception as
     |      the 'exception' attribute. This allows you to inspect the
     |      exception after the assertion::
     |
     |          with self.assertRaises(SomeException) as cm:
     |              do_something()
     |          the_exception = cm.exception
     |          self.assertEqual(the_exception.error_code, 3)
     |
     |  assertRaisesRegex(self, expected_exception, expected_regex, *args, **kwargs)
     |      Asserts that the message in a raised exception matches a regex.
     |
     |      Args:
     |          expected_exception: Exception class expected to be raised.
     |          expected_regex: Regex (re.Pattern object or string) expected
     |                  to be found in error message.
     |          args: Function to be called and extra positional args.
     |          kwargs: Extra kwargs.
     |          msg: Optional message used in case of failure. Can only be used
     |                  when assertRaisesRegex is used as a context manager.
     |
     |  assertRegex(self, text, expected_regex, msg=None)
     |      Fail the test unless the text matches the regular expression.
     |
     |  assertSequenceEqual(self, seq1, seq2, msg=None, seq_type=None)
     |      An equality assertion for ordered sequences (like lists and tuples).
     |
     |      For the purposes of this function, a valid ordered sequence type is one
     |      which can be indexed, has a length, and has an equality operator.
     |
     |      Args:
     |          seq1: The first sequence to compare.
     |          seq2: The second sequence to compare.
     |          seq_type: The expected datatype of the sequences, or None if no
     |                  datatype should be enforced.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |  assertSetEqual(self, set1, set2, msg=None)
     |      A set-specific equality assertion.
     |
     |      Args:
     |          set1: The first set to compare.
     |          set2: The second set to compare.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |      assertSetEqual uses ducktyping to support different types of sets, and
     |      is optimized for sets specifically (parameters must support a
     |      difference method).
     |
     |  assertTrue(self, expr, msg=None)
     |      Check that the expression is true.
     |
     |  assertTupleEqual(self, tuple1, tuple2, msg=None)
     |      A tuple-specific equality assertion.
     |
     |      Args:
     |          tuple1: The first tuple to compare.
     |          tuple2: The second tuple to compare.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |  assertWarns(self, expected_warning, *args, **kwargs)
     |      Fail unless a warning of class warnClass is triggered
     |      by the callable when invoked with specified positional and
     |      keyword arguments.  If a different type of warning is
     |      triggered, it will not be handled: depending on the other
     |      warning filtering rules in effect, it might be silenced, printed
     |      out, or raised as an exception.
     |
     |      If called with the callable and arguments omitted, will return a
     |      context object used like this::
     |
     |           with self.assertWarns(SomeWarning):
     |               do_something()
     |
     |      An optional keyword argument 'msg' can be provided when assertWarns
     |      is used as a context object.
     |
     |      The context manager keeps a reference to the first matching
     |      warning as the 'warning' attribute; similarly, the 'filename'
     |      and 'lineno' attributes give you information about the line
     |      of Python code from which the warning was triggered.
     |      This allows you to inspect the warning after the assertion::
     |
     |          with self.assertWarns(SomeWarning) as cm:
     |              do_something()
     |          the_warning = cm.warning
     |          self.assertEqual(the_warning.some_attribute, 147)
     |
     |  assertWarnsRegex(self, expected_warning, expected_regex, *args, **kwargs)
     |      Asserts that the message in a triggered warning matches a regexp.
     |      Basic functioning is similar to assertWarns() with the addition
     |      that only warnings whose messages also match the regular expression
     |      are considered successful matches.
     |
     |      Args:
     |          expected_warning: Warning class expected to be triggered.
     |          expected_regex: Regex (re.Pattern object or string) expected
     |                  to be found in error message.
     |          args: Function to be called and extra positional args.
     |          kwargs: Extra kwargs.
     |          msg: Optional message used in case of failure. Can only be used
     |                  when assertWarnsRegex is used as a context manager.
     |
     |  countTestCases(self)
     |
     |  debug(self)
     |      Run the test without collecting errors in a TestResult
     |
     |  defaultTestResult(self)
     |
     |  doCleanups(self)
     |      Execute all cleanup functions. Normally called for you after
     |      tearDown.
     |
     |  enterContext(self, cm)
     |      Enters the supplied context manager.
     |
     |      If successful, also adds its __exit__ method as a cleanup
     |      function and returns the result of the __enter__ method.
     |
     |  fail(self, msg=None)
     |      Fail immediately, with the given message.
     |
     |  id(self)
     |
     |  run(self, result=None)
     |
     |  shortDescription(self)
     |      Returns a one-line description of the test, or None if no
     |      description has been provided.
     |
     |      The default implementation of this method returns the first line of
     |      the specified test method's docstring.
     |
     |  skipTest(self, reason)
     |      Skip this test.
     |
     |  subTest(self, msg=<object object at 0x0000023FC3E68860>, **params)
     |      Return a context manager that will return the enclosed block
     |      of code in a subtest identified by the optional message and
     |      keyword parameters.  A failure in the subtest marks the test
     |      case as failed but resumes execution at the end of the enclosed
     |      block, allowing further test code to be executed.
     |
     |  tearDown(self)
     |      Hook method for deconstructing the test fixture after testing it.
     |
     |  ----------------------------------------------------------------------
     |  Class methods inherited from unittest.case.TestCase:
     |
     |  __init_subclass__(*args, **kwargs)
     |      This method is called when a class is subclassed.
     |
     |      The default implementation does nothing. It may be
     |      overridden to extend subclasses.
     |
     |  addClassCleanup(function, /, *args, **kwargs)
     |      Same as addCleanup, except the cleanup items are called even if
     |      setUpClass fails (unlike tearDownClass).
     |
     |  doClassCleanups()
     |      Execute all class cleanup functions. Normally called for you after
     |      tearDownClass.
     |
     |  enterClassContext(cm)
     |      Same as enterContext, but class-wide.
     |
     |  setUpClass()
     |      Hook method for setting up class fixture before running tests in the class.
     |
     |  tearDownClass()
     |      Hook method for deconstructing the class fixture after running all tests in the class.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from unittest.case.TestCase:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes inherited from unittest.case.TestCase:
     |
     |  failureException = <class 'AssertionError'>
     |      Assertion failed.
     |
     |
     |  longMessage = True
     |
     |  maxDiff = 640

    class TestExampleError(unittest.case.TestCase)
     |  TestExampleError(methodName='runTest')
     |
     |  Classe de test pour la gestion des erreurs.
     |
     |  Method resolution order:
     |      TestExampleError
     |      unittest.case.TestCase
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  test_exception_details(self)
     |      Test détaillé des exceptions.
     |
     |  test_type_error_details(self)
     |      Test détaillé des erreurs de type.
     |
     |  test_value_error_details(self)
     |      Test détaillé des erreurs de valeur.
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from unittest.case.TestCase:
     |
     |  __call__(self, *args, **kwds)
     |      Call self as a function.
     |
     |  __eq__(self, other)
     |      Return self==value.
     |
     |  __hash__(self)
     |      Return hash(self).
     |
     |  __init__(self, methodName='runTest')
     |      Create an instance of the class that will use the named test
     |      method when executed. Raises a ValueError if the instance does
     |      not have a method with the specified name.
     |
     |  __repr__(self)
     |      Return repr(self).
     |
     |  __str__(self)
     |      Return str(self).
     |
     |  addCleanup(self, function, /, *args, **kwargs)
     |      Add a function, with arguments, to be called when the test is
     |      completed. Functions added are called on a LIFO basis and are
     |      called after tearDown on test failure or success.
     |
     |      Cleanup items are called even if setUp fails (unlike tearDown).
     |
     |  addTypeEqualityFunc(self, typeobj, function)
     |      Add a type specific assertEqual style function to compare a type.
     |
     |      This method is for use by TestCase subclasses that need to register
     |      their own type equality functions to provide nicer error messages.
     |
     |      Args:
     |          typeobj: The data type to call this function on when both values
     |                  are of the same type in assertEqual().
     |          function: The callable taking two arguments and an optional
     |                  msg= argument that raises self.failureException with a
     |                  useful error message when the two arguments are not equal.
     |
     |  assertAlmostEqual(self, first, second, places=None, msg=None, delta=None)
     |      Fail if the two objects are unequal as determined by their
     |      difference rounded to the given number of decimal places
     |      (default 7) and comparing to zero, or by comparing that the
     |      difference between the two objects is more than the given
     |      delta.
     |
     |      Note that decimal places (from zero) are usually not the same
     |      as significant digits (measured from the most significant digit).
     |
     |      If the two objects compare equal then they will automatically
     |      compare almost equal.
     |
     |  assertCountEqual(self, first, second, msg=None)
     |      Asserts that two iterables have the same elements, the same number of
     |      times, without regard to order.
     |
     |          self.assertEqual(Counter(list(first)),
     |                           Counter(list(second)))
     |
     |       Example:
     |          - [0, 1, 1] and [1, 0, 1] compare equal.
     |          - [0, 0, 1] and [0, 1] compare unequal.
     |
     |  assertDictEqual(self, d1, d2, msg=None)
     |
     |  assertEqual(self, first, second, msg=None)
     |      Fail if the two objects are unequal as determined by the '=='
     |      operator.
     |
     |  assertFalse(self, expr, msg=None)
     |      Check that the expression is false.
     |
     |  assertGreater(self, a, b, msg=None)
     |      Just like self.assertTrue(a > b), but with a nicer default message.
     |
     |  assertGreaterEqual(self, a, b, msg=None)
     |      Just like self.assertTrue(a >= b), but with a nicer default message.
     |
     |  assertIn(self, member, container, msg=None)
     |      Just like self.assertTrue(a in b), but with a nicer default message.
     |
     |  assertIs(self, expr1, expr2, msg=None)
     |      Just like self.assertTrue(a is b), but with a nicer default message.
     |
     |  assertIsInstance(self, obj, cls, msg=None)
     |      Same as self.assertTrue(isinstance(obj, cls)), with a nicer
     |      default message.
     |
     |  assertIsNone(self, obj, msg=None)
     |      Same as self.assertTrue(obj is None), with a nicer default message.
     |
     |  assertIsNot(self, expr1, expr2, msg=None)
     |      Just like self.assertTrue(a is not b), but with a nicer default message.
     |
     |  assertIsNotNone(self, obj, msg=None)
     |      Included for symmetry with assertIsNone.
     |
     |  assertLess(self, a, b, msg=None)
     |      Just like self.assertTrue(a < b), but with a nicer default message.
     |
     |  assertLessEqual(self, a, b, msg=None)
     |      Just like self.assertTrue(a <= b), but with a nicer default message.
     |
     |  assertListEqual(self, list1, list2, msg=None)
     |      A list-specific equality assertion.
     |
     |      Args:
     |          list1: The first list to compare.
     |          list2: The second list to compare.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |  assertLogs(self, logger=None, level=None)
     |      Fail unless a log message of level *level* or higher is emitted
     |      on *logger_name* or its children.  If omitted, *level* defaults to
     |      INFO and *logger* defaults to the root logger.
     |
     |      This method must be used as a context manager, and will yield
     |      a recording object with two attributes: `output` and `records`.
     |      At the end of the context manager, the `output` attribute will
     |      be a list of the matching formatted log messages and the
     |      `records` attribute will be a list of the corresponding LogRecord
     |      objects.
     |
     |      Example::
     |
     |          with self.assertLogs('foo', level='INFO') as cm:
     |              logging.getLogger('foo').info('first message')
     |              logging.getLogger('foo.bar').error('second message')
     |          self.assertEqual(cm.output, ['INFO:foo:first message',
     |                                       'ERROR:foo.bar:second message'])
     |
     |  assertMultiLineEqual(self, first, second, msg=None)
     |      Assert that two multi-line strings are equal.
     |
     |  assertNoLogs(self, logger=None, level=None)
     |      Fail unless no log messages of level *level* or higher are emitted
     |      on *logger_name* or its children.
     |
     |      This method must be used as a context manager.
     |
     |  assertNotAlmostEqual(self, first, second, places=None, msg=None, delta=None)
     |      Fail if the two objects are equal as determined by their
     |      difference rounded to the given number of decimal places
     |      (default 7) and comparing to zero, or by comparing that the
     |      difference between the two objects is less than the given delta.
     |
     |      Note that decimal places (from zero) are usually not the same
     |      as significant digits (measured from the most significant digit).
     |
     |      Objects that are equal automatically fail.
     |
     |  assertNotEqual(self, first, second, msg=None)
     |      Fail if the two objects are equal as determined by the '!='
     |      operator.
     |
     |  assertNotIn(self, member, container, msg=None)
     |      Just like self.assertTrue(a not in b), but with a nicer default message.
     |
     |  assertNotIsInstance(self, obj, cls, msg=None)
     |      Included for symmetry with assertIsInstance.
     |
     |  assertNotRegex(self, text, unexpected_regex, msg=None)
     |      Fail the test if the text matches the regular expression.
     |
     |  assertRaises(self, expected_exception, *args, **kwargs)
     |      Fail unless an exception of class expected_exception is raised
     |      by the callable when invoked with specified positional and
     |      keyword arguments. If a different type of exception is
     |      raised, it will not be caught, and the test case will be
     |      deemed to have suffered an error, exactly as for an
     |      unexpected exception.
     |
     |      If called with the callable and arguments omitted, will return a
     |      context object used like this::
     |
     |           with self.assertRaises(SomeException):
     |               do_something()
     |
     |      An optional keyword argument 'msg' can be provided when assertRaises
     |      is used as a context object.
     |
     |      The context manager keeps a reference to the exception as
     |      the 'exception' attribute. This allows you to inspect the
     |      exception after the assertion::
     |
     |          with self.assertRaises(SomeException) as cm:
     |              do_something()
     |          the_exception = cm.exception
     |          self.assertEqual(the_exception.error_code, 3)
     |
     |  assertRaisesRegex(self, expected_exception, expected_regex, *args, **kwargs)
     |      Asserts that the message in a raised exception matches a regex.
     |
     |      Args:
     |          expected_exception: Exception class expected to be raised.
     |          expected_regex: Regex (re.Pattern object or string) expected
     |                  to be found in error message.
     |          args: Function to be called and extra positional args.
     |          kwargs: Extra kwargs.
     |          msg: Optional message used in case of failure. Can only be used
     |                  when assertRaisesRegex is used as a context manager.
     |
     |  assertRegex(self, text, expected_regex, msg=None)
     |      Fail the test unless the text matches the regular expression.
     |
     |  assertSequenceEqual(self, seq1, seq2, msg=None, seq_type=None)
     |      An equality assertion for ordered sequences (like lists and tuples).
     |
     |      For the purposes of this function, a valid ordered sequence type is one
     |      which can be indexed, has a length, and has an equality operator.
     |
     |      Args:
     |          seq1: The first sequence to compare.
     |          seq2: The second sequence to compare.
     |          seq_type: The expected datatype of the sequences, or None if no
     |                  datatype should be enforced.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |  assertSetEqual(self, set1, set2, msg=None)
     |      A set-specific equality assertion.
     |
     |      Args:
     |          set1: The first set to compare.
     |          set2: The second set to compare.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |      assertSetEqual uses ducktyping to support different types of sets, and
     |      is optimized for sets specifically (parameters must support a
     |      difference method).
     |
     |  assertTrue(self, expr, msg=None)
     |      Check that the expression is true.
     |
     |  assertTupleEqual(self, tuple1, tuple2, msg=None)
     |      A tuple-specific equality assertion.
     |
     |      Args:
     |          tuple1: The first tuple to compare.
     |          tuple2: The second tuple to compare.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |  assertWarns(self, expected_warning, *args, **kwargs)
     |      Fail unless a warning of class warnClass is triggered
     |      by the callable when invoked with specified positional and
     |      keyword arguments.  If a different type of warning is
     |      triggered, it will not be handled: depending on the other
     |      warning filtering rules in effect, it might be silenced, printed
     |      out, or raised as an exception.
     |
     |      If called with the callable and arguments omitted, will return a
     |      context object used like this::
     |
     |           with self.assertWarns(SomeWarning):
     |               do_something()
     |
     |      An optional keyword argument 'msg' can be provided when assertWarns
     |      is used as a context object.
     |
     |      The context manager keeps a reference to the first matching
     |      warning as the 'warning' attribute; similarly, the 'filename'
     |      and 'lineno' attributes give you information about the line
     |      of Python code from which the warning was triggered.
     |      This allows you to inspect the warning after the assertion::
     |
     |          with self.assertWarns(SomeWarning) as cm:
     |              do_something()
     |          the_warning = cm.warning
     |          self.assertEqual(the_warning.some_attribute, 147)
     |
     |  assertWarnsRegex(self, expected_warning, expected_regex, *args, **kwargs)
     |      Asserts that the message in a triggered warning matches a regexp.
     |      Basic functioning is similar to assertWarns() with the addition
     |      that only warnings whose messages also match the regular expression
     |      are considered successful matches.
     |
     |      Args:
     |          expected_warning: Warning class expected to be triggered.
     |          expected_regex: Regex (re.Pattern object or string) expected
     |                  to be found in error message.
     |          args: Function to be called and extra positional args.
     |          kwargs: Extra kwargs.
     |          msg: Optional message used in case of failure. Can only be used
     |                  when assertWarnsRegex is used as a context manager.
     |
     |  countTestCases(self)
     |
     |  debug(self)
     |      Run the test without collecting errors in a TestResult
     |
     |  defaultTestResult(self)
     |
     |  doCleanups(self)
     |      Execute all cleanup functions. Normally called for you after
     |      tearDown.
     |
     |  enterContext(self, cm)
     |      Enters the supplied context manager.
     |
     |      If successful, also adds its __exit__ method as a cleanup
     |      function and returns the result of the __enter__ method.
     |
     |  fail(self, msg=None)
     |      Fail immediately, with the given message.
     |
     |  id(self)
     |
     |  run(self, result=None)
     |
     |  setUp(self)
     |      Hook method for setting up the test fixture before exercising it.
     |
     |  shortDescription(self)
     |      Returns a one-line description of the test, or None if no
     |      description has been provided.
     |
     |      The default implementation of this method returns the first line of
     |      the specified test method's docstring.
     |
     |  skipTest(self, reason)
     |      Skip this test.
     |
     |  subTest(self, msg=<object object at 0x0000023FC3E68860>, **params)
     |      Return a context manager that will return the enclosed block
     |      of code in a subtest identified by the optional message and
     |      keyword parameters.  A failure in the subtest marks the test
     |      case as failed but resumes execution at the end of the enclosed
     |      block, allowing further test code to be executed.
     |
     |  tearDown(self)
     |      Hook method for deconstructing the test fixture after testing it.
     |
     |  ----------------------------------------------------------------------
     |  Class methods inherited from unittest.case.TestCase:
     |
     |  __init_subclass__(*args, **kwargs)
     |      This method is called when a class is subclassed.
     |
     |      The default implementation does nothing. It may be
     |      overridden to extend subclasses.
     |
     |  addClassCleanup(function, /, *args, **kwargs)
     |      Same as addCleanup, except the cleanup items are called even if
     |      setUpClass fails (unlike tearDownClass).
     |
     |  doClassCleanups()
     |      Execute all class cleanup functions. Normally called for you after
     |      tearDownClass.
     |
     |  enterClassContext(cm)
     |      Same as enterContext, but class-wide.
     |
     |  setUpClass()
     |      Hook method for setting up class fixture before running tests in the class.
     |
     |  tearDownClass()
     |      Hook method for deconstructing the class fixture after running all tests in the class.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from unittest.case.TestCase:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes inherited from unittest.case.TestCase:
     |
     |  failureException = <class 'AssertionError'>
     |      Assertion failed.
     |
     |
     |  longMessage = True
     |
     |  maxDiff = 640

    class TestExampleSuccess(unittest.case.TestCase)
     |  TestExampleSuccess(methodName='runTest')
     |
     |  Classe de test avec des tests qui réussissent.
     |
     |  Method resolution order:
     |      TestExampleSuccess
     |      unittest.case.TestCase
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  test_addition(self)
     |      Test d'addition simple.
     |
     |  test_division(self)
     |      Test de division simple.
     |
     |  test_multiplication(self)
     |      Test de multiplication simple.
     |
     |  test_subtraction(self)
     |      Test de soustraction simple.
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from unittest.case.TestCase:
     |
     |  __call__(self, *args, **kwds)
     |      Call self as a function.
     |
     |  __eq__(self, other)
     |      Return self==value.
     |
     |  __hash__(self)
     |      Return hash(self).
     |
     |  __init__(self, methodName='runTest')
     |      Create an instance of the class that will use the named test
     |      method when executed. Raises a ValueError if the instance does
     |      not have a method with the specified name.
     |
     |  __repr__(self)
     |      Return repr(self).
     |
     |  __str__(self)
     |      Return str(self).
     |
     |  addCleanup(self, function, /, *args, **kwargs)
     |      Add a function, with arguments, to be called when the test is
     |      completed. Functions added are called on a LIFO basis and are
     |      called after tearDown on test failure or success.
     |
     |      Cleanup items are called even if setUp fails (unlike tearDown).
     |
     |  addTypeEqualityFunc(self, typeobj, function)
     |      Add a type specific assertEqual style function to compare a type.
     |
     |      This method is for use by TestCase subclasses that need to register
     |      their own type equality functions to provide nicer error messages.
     |
     |      Args:
     |          typeobj: The data type to call this function on when both values
     |                  are of the same type in assertEqual().
     |          function: The callable taking two arguments and an optional
     |                  msg= argument that raises self.failureException with a
     |                  useful error message when the two arguments are not equal.
     |
     |  assertAlmostEqual(self, first, second, places=None, msg=None, delta=None)
     |      Fail if the two objects are unequal as determined by their
     |      difference rounded to the given number of decimal places
     |      (default 7) and comparing to zero, or by comparing that the
     |      difference between the two objects is more than the given
     |      delta.
     |
     |      Note that decimal places (from zero) are usually not the same
     |      as significant digits (measured from the most significant digit).
     |
     |      If the two objects compare equal then they will automatically
     |      compare almost equal.
     |
     |  assertCountEqual(self, first, second, msg=None)
     |      Asserts that two iterables have the same elements, the same number of
     |      times, without regard to order.
     |
     |          self.assertEqual(Counter(list(first)),
     |                           Counter(list(second)))
     |
     |       Example:
     |          - [0, 1, 1] and [1, 0, 1] compare equal.
     |          - [0, 0, 1] and [0, 1] compare unequal.
     |
     |  assertDictEqual(self, d1, d2, msg=None)
     |
     |  assertEqual(self, first, second, msg=None)
     |      Fail if the two objects are unequal as determined by the '=='
     |      operator.
     |
     |  assertFalse(self, expr, msg=None)
     |      Check that the expression is false.
     |
     |  assertGreater(self, a, b, msg=None)
     |      Just like self.assertTrue(a > b), but with a nicer default message.
     |
     |  assertGreaterEqual(self, a, b, msg=None)
     |      Just like self.assertTrue(a >= b), but with a nicer default message.
     |
     |  assertIn(self, member, container, msg=None)
     |      Just like self.assertTrue(a in b), but with a nicer default message.
     |
     |  assertIs(self, expr1, expr2, msg=None)
     |      Just like self.assertTrue(a is b), but with a nicer default message.
     |
     |  assertIsInstance(self, obj, cls, msg=None)
     |      Same as self.assertTrue(isinstance(obj, cls)), with a nicer
     |      default message.
     |
     |  assertIsNone(self, obj, msg=None)
     |      Same as self.assertTrue(obj is None), with a nicer default message.
     |
     |  assertIsNot(self, expr1, expr2, msg=None)
     |      Just like self.assertTrue(a is not b), but with a nicer default message.
     |
     |  assertIsNotNone(self, obj, msg=None)
     |      Included for symmetry with assertIsNone.
     |
     |  assertLess(self, a, b, msg=None)
     |      Just like self.assertTrue(a < b), but with a nicer default message.
     |
     |  assertLessEqual(self, a, b, msg=None)
     |      Just like self.assertTrue(a <= b), but with a nicer default message.
     |
     |  assertListEqual(self, list1, list2, msg=None)
     |      A list-specific equality assertion.
     |
     |      Args:
     |          list1: The first list to compare.
     |          list2: The second list to compare.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |  assertLogs(self, logger=None, level=None)
     |      Fail unless a log message of level *level* or higher is emitted
     |      on *logger_name* or its children.  If omitted, *level* defaults to
     |      INFO and *logger* defaults to the root logger.
     |
     |      This method must be used as a context manager, and will yield
     |      a recording object with two attributes: `output` and `records`.
     |      At the end of the context manager, the `output` attribute will
     |      be a list of the matching formatted log messages and the
     |      `records` attribute will be a list of the corresponding LogRecord
     |      objects.
     |
     |      Example::
     |
     |          with self.assertLogs('foo', level='INFO') as cm:
     |              logging.getLogger('foo').info('first message')
     |              logging.getLogger('foo.bar').error('second message')
     |          self.assertEqual(cm.output, ['INFO:foo:first message',
     |                                       'ERROR:foo.bar:second message'])
     |
     |  assertMultiLineEqual(self, first, second, msg=None)
     |      Assert that two multi-line strings are equal.
     |
     |  assertNoLogs(self, logger=None, level=None)
     |      Fail unless no log messages of level *level* or higher are emitted
     |      on *logger_name* or its children.
     |
     |      This method must be used as a context manager.
     |
     |  assertNotAlmostEqual(self, first, second, places=None, msg=None, delta=None)
     |      Fail if the two objects are equal as determined by their
     |      difference rounded to the given number of decimal places
     |      (default 7) and comparing to zero, or by comparing that the
     |      difference between the two objects is less than the given delta.
     |
     |      Note that decimal places (from zero) are usually not the same
     |      as significant digits (measured from the most significant digit).
     |
     |      Objects that are equal automatically fail.
     |
     |  assertNotEqual(self, first, second, msg=None)
     |      Fail if the two objects are equal as determined by the '!='
     |      operator.
     |
     |  assertNotIn(self, member, container, msg=None)
     |      Just like self.assertTrue(a not in b), but with a nicer default message.
     |
     |  assertNotIsInstance(self, obj, cls, msg=None)
     |      Included for symmetry with assertIsInstance.
     |
     |  assertNotRegex(self, text, unexpected_regex, msg=None)
     |      Fail the test if the text matches the regular expression.
     |
     |  assertRaises(self, expected_exception, *args, **kwargs)
     |      Fail unless an exception of class expected_exception is raised
     |      by the callable when invoked with specified positional and
     |      keyword arguments. If a different type of exception is
     |      raised, it will not be caught, and the test case will be
     |      deemed to have suffered an error, exactly as for an
     |      unexpected exception.
     |
     |      If called with the callable and arguments omitted, will return a
     |      context object used like this::
     |
     |           with self.assertRaises(SomeException):
     |               do_something()
     |
     |      An optional keyword argument 'msg' can be provided when assertRaises
     |      is used as a context object.
     |
     |      The context manager keeps a reference to the exception as
     |      the 'exception' attribute. This allows you to inspect the
     |      exception after the assertion::
     |
     |          with self.assertRaises(SomeException) as cm:
     |              do_something()
     |          the_exception = cm.exception
     |          self.assertEqual(the_exception.error_code, 3)
     |
     |  assertRaisesRegex(self, expected_exception, expected_regex, *args, **kwargs)
     |      Asserts that the message in a raised exception matches a regex.
     |
     |      Args:
     |          expected_exception: Exception class expected to be raised.
     |          expected_regex: Regex (re.Pattern object or string) expected
     |                  to be found in error message.
     |          args: Function to be called and extra positional args.
     |          kwargs: Extra kwargs.
     |          msg: Optional message used in case of failure. Can only be used
     |                  when assertRaisesRegex is used as a context manager.
     |
     |  assertRegex(self, text, expected_regex, msg=None)
     |      Fail the test unless the text matches the regular expression.
     |
     |  assertSequenceEqual(self, seq1, seq2, msg=None, seq_type=None)
     |      An equality assertion for ordered sequences (like lists and tuples).
     |
     |      For the purposes of this function, a valid ordered sequence type is one
     |      which can be indexed, has a length, and has an equality operator.
     |
     |      Args:
     |          seq1: The first sequence to compare.
     |          seq2: The second sequence to compare.
     |          seq_type: The expected datatype of the sequences, or None if no
     |                  datatype should be enforced.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |  assertSetEqual(self, set1, set2, msg=None)
     |      A set-specific equality assertion.
     |
     |      Args:
     |          set1: The first set to compare.
     |          set2: The second set to compare.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |      assertSetEqual uses ducktyping to support different types of sets, and
     |      is optimized for sets specifically (parameters must support a
     |      difference method).
     |
     |  assertTrue(self, expr, msg=None)
     |      Check that the expression is true.
     |
     |  assertTupleEqual(self, tuple1, tuple2, msg=None)
     |      A tuple-specific equality assertion.
     |
     |      Args:
     |          tuple1: The first tuple to compare.
     |          tuple2: The second tuple to compare.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |  assertWarns(self, expected_warning, *args, **kwargs)
     |      Fail unless a warning of class warnClass is triggered
     |      by the callable when invoked with specified positional and
     |      keyword arguments.  If a different type of warning is
     |      triggered, it will not be handled: depending on the other
     |      warning filtering rules in effect, it might be silenced, printed
     |      out, or raised as an exception.
     |
     |      If called with the callable and arguments omitted, will return a
     |      context object used like this::
     |
     |           with self.assertWarns(SomeWarning):
     |               do_something()
     |
     |      An optional keyword argument 'msg' can be provided when assertWarns
     |      is used as a context object.
     |
     |      The context manager keeps a reference to the first matching
     |      warning as the 'warning' attribute; similarly, the 'filename'
     |      and 'lineno' attributes give you information about the line
     |      of Python code from which the warning was triggered.
     |      This allows you to inspect the warning after the assertion::
     |
     |          with self.assertWarns(SomeWarning) as cm:
     |              do_something()
     |          the_warning = cm.warning
     |          self.assertEqual(the_warning.some_attribute, 147)
     |
     |  assertWarnsRegex(self, expected_warning, expected_regex, *args, **kwargs)
     |      Asserts that the message in a triggered warning matches a regexp.
     |      Basic functioning is similar to assertWarns() with the addition
     |      that only warnings whose messages also match the regular expression
     |      are considered successful matches.
     |
     |      Args:
     |          expected_warning: Warning class expected to be triggered.
     |          expected_regex: Regex (re.Pattern object or string) expected
     |                  to be found in error message.
     |          args: Function to be called and extra positional args.
     |          kwargs: Extra kwargs.
     |          msg: Optional message used in case of failure. Can only be used
     |                  when assertWarnsRegex is used as a context manager.
     |
     |  countTestCases(self)
     |
     |  debug(self)
     |      Run the test without collecting errors in a TestResult
     |
     |  defaultTestResult(self)
     |
     |  doCleanups(self)
     |      Execute all cleanup functions. Normally called for you after
     |      tearDown.
     |
     |  enterContext(self, cm)
     |      Enters the supplied context manager.
     |
     |      If successful, also adds its __exit__ method as a cleanup
     |      function and returns the result of the __enter__ method.
     |
     |  fail(self, msg=None)
     |      Fail immediately, with the given message.
     |
     |  id(self)
     |
     |  run(self, result=None)
     |
     |  setUp(self)
     |      Hook method for setting up the test fixture before exercising it.
     |
     |  shortDescription(self)
     |      Returns a one-line description of the test, or None if no
     |      description has been provided.
     |
     |      The default implementation of this method returns the first line of
     |      the specified test method's docstring.
     |
     |  skipTest(self, reason)
     |      Skip this test.
     |
     |  subTest(self, msg=<object object at 0x0000023FC3E68860>, **params)
     |      Return a context manager that will return the enclosed block
     |      of code in a subtest identified by the optional message and
     |      keyword parameters.  A failure in the subtest marks the test
     |      case as failed but resumes execution at the end of the enclosed
     |      block, allowing further test code to be executed.
     |
     |  tearDown(self)
     |      Hook method for deconstructing the test fixture after testing it.
     |
     |  ----------------------------------------------------------------------
     |  Class methods inherited from unittest.case.TestCase:
     |
     |  __init_subclass__(*args, **kwargs)
     |      This method is called when a class is subclassed.
     |
     |      The default implementation does nothing. It may be
     |      overridden to extend subclasses.
     |
     |  addClassCleanup(function, /, *args, **kwargs)
     |      Same as addCleanup, except the cleanup items are called even if
     |      setUpClass fails (unlike tearDownClass).
     |
     |  doClassCleanups()
     |      Execute all class cleanup functions. Normally called for you after
     |      tearDownClass.
     |
     |  enterClassContext(cm)
     |      Same as enterContext, but class-wide.
     |
     |  setUpClass()
     |      Hook method for setting up class fixture before running tests in the class.
     |
     |  tearDownClass()
     |      Hook method for deconstructing the class fixture after running all tests in the class.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from unittest.case.TestCase:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes inherited from unittest.case.TestCase:
     |
     |  failureException = <class 'AssertionError'>
     |      Assertion failed.
     |
     |
     |  longMessage = True
     |
     |  maxDiff = 640

    class TestExhaustiveCoverage(unittest.case.TestCase)
     |  TestExhaustiveCoverage(methodName='runTest')
     |
     |  Tests conçus spécifiquement pour atteindre 100% de couverture.
     |
     |  Method resolution order:
     |      TestExhaustiveCoverage
     |      unittest.case.TestCase
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  test_parametrized_methods_directly(self)
     |      Test direct des méthodes paramétrées pour couverture.
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from unittest.case.TestCase:
     |
     |  __call__(self, *args, **kwds)
     |      Call self as a function.
     |
     |  __eq__(self, other)
     |      Return self==value.
     |
     |  __hash__(self)
     |      Return hash(self).
     |
     |  __init__(self, methodName='runTest')
     |      Create an instance of the class that will use the named test
     |      method when executed. Raises a ValueError if the instance does
     |      not have a method with the specified name.
     |
     |  __repr__(self)
     |      Return repr(self).
     |
     |  __str__(self)
     |      Return str(self).
     |
     |  addCleanup(self, function, /, *args, **kwargs)
     |      Add a function, with arguments, to be called when the test is
     |      completed. Functions added are called on a LIFO basis and are
     |      called after tearDown on test failure or success.
     |
     |      Cleanup items are called even if setUp fails (unlike tearDown).
     |
     |  addTypeEqualityFunc(self, typeobj, function)
     |      Add a type specific assertEqual style function to compare a type.
     |
     |      This method is for use by TestCase subclasses that need to register
     |      their own type equality functions to provide nicer error messages.
     |
     |      Args:
     |          typeobj: The data type to call this function on when both values
     |                  are of the same type in assertEqual().
     |          function: The callable taking two arguments and an optional
     |                  msg= argument that raises self.failureException with a
     |                  useful error message when the two arguments are not equal.
     |
     |  assertAlmostEqual(self, first, second, places=None, msg=None, delta=None)
     |      Fail if the two objects are unequal as determined by their
     |      difference rounded to the given number of decimal places
     |      (default 7) and comparing to zero, or by comparing that the
     |      difference between the two objects is more than the given
     |      delta.
     |
     |      Note that decimal places (from zero) are usually not the same
     |      as significant digits (measured from the most significant digit).
     |
     |      If the two objects compare equal then they will automatically
     |      compare almost equal.
     |
     |  assertCountEqual(self, first, second, msg=None)
     |      Asserts that two iterables have the same elements, the same number of
     |      times, without regard to order.
     |
     |          self.assertEqual(Counter(list(first)),
     |                           Counter(list(second)))
     |
     |       Example:
     |          - [0, 1, 1] and [1, 0, 1] compare equal.
     |          - [0, 0, 1] and [0, 1] compare unequal.
     |
     |  assertDictEqual(self, d1, d2, msg=None)
     |
     |  assertEqual(self, first, second, msg=None)
     |      Fail if the two objects are unequal as determined by the '=='
     |      operator.
     |
     |  assertFalse(self, expr, msg=None)
     |      Check that the expression is false.
     |
     |  assertGreater(self, a, b, msg=None)
     |      Just like self.assertTrue(a > b), but with a nicer default message.
     |
     |  assertGreaterEqual(self, a, b, msg=None)
     |      Just like self.assertTrue(a >= b), but with a nicer default message.
     |
     |  assertIn(self, member, container, msg=None)
     |      Just like self.assertTrue(a in b), but with a nicer default message.
     |
     |  assertIs(self, expr1, expr2, msg=None)
     |      Just like self.assertTrue(a is b), but with a nicer default message.
     |
     |  assertIsInstance(self, obj, cls, msg=None)
     |      Same as self.assertTrue(isinstance(obj, cls)), with a nicer
     |      default message.
     |
     |  assertIsNone(self, obj, msg=None)
     |      Same as self.assertTrue(obj is None), with a nicer default message.
     |
     |  assertIsNot(self, expr1, expr2, msg=None)
     |      Just like self.assertTrue(a is not b), but with a nicer default message.
     |
     |  assertIsNotNone(self, obj, msg=None)
     |      Included for symmetry with assertIsNone.
     |
     |  assertLess(self, a, b, msg=None)
     |      Just like self.assertTrue(a < b), but with a nicer default message.
     |
     |  assertLessEqual(self, a, b, msg=None)
     |      Just like self.assertTrue(a <= b), but with a nicer default message.
     |
     |  assertListEqual(self, list1, list2, msg=None)
     |      A list-specific equality assertion.
     |
     |      Args:
     |          list1: The first list to compare.
     |          list2: The second list to compare.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |  assertLogs(self, logger=None, level=None)
     |      Fail unless a log message of level *level* or higher is emitted
     |      on *logger_name* or its children.  If omitted, *level* defaults to
     |      INFO and *logger* defaults to the root logger.
     |
     |      This method must be used as a context manager, and will yield
     |      a recording object with two attributes: `output` and `records`.
     |      At the end of the context manager, the `output` attribute will
     |      be a list of the matching formatted log messages and the
     |      `records` attribute will be a list of the corresponding LogRecord
     |      objects.
     |
     |      Example::
     |
     |          with self.assertLogs('foo', level='INFO') as cm:
     |              logging.getLogger('foo').info('first message')
     |              logging.getLogger('foo.bar').error('second message')
     |          self.assertEqual(cm.output, ['INFO:foo:first message',
     |                                       'ERROR:foo.bar:second message'])
     |
     |  assertMultiLineEqual(self, first, second, msg=None)
     |      Assert that two multi-line strings are equal.
     |
     |  assertNoLogs(self, logger=None, level=None)
     |      Fail unless no log messages of level *level* or higher are emitted
     |      on *logger_name* or its children.
     |
     |      This method must be used as a context manager.
     |
     |  assertNotAlmostEqual(self, first, second, places=None, msg=None, delta=None)
     |      Fail if the two objects are equal as determined by their
     |      difference rounded to the given number of decimal places
     |      (default 7) and comparing to zero, or by comparing that the
     |      difference between the two objects is less than the given delta.
     |
     |      Note that decimal places (from zero) are usually not the same
     |      as significant digits (measured from the most significant digit).
     |
     |      Objects that are equal automatically fail.
     |
     |  assertNotEqual(self, first, second, msg=None)
     |      Fail if the two objects are equal as determined by the '!='
     |      operator.
     |
     |  assertNotIn(self, member, container, msg=None)
     |      Just like self.assertTrue(a not in b), but with a nicer default message.
     |
     |  assertNotIsInstance(self, obj, cls, msg=None)
     |      Included for symmetry with assertIsInstance.
     |
     |  assertNotRegex(self, text, unexpected_regex, msg=None)
     |      Fail the test if the text matches the regular expression.
     |
     |  assertRaises(self, expected_exception, *args, **kwargs)
     |      Fail unless an exception of class expected_exception is raised
     |      by the callable when invoked with specified positional and
     |      keyword arguments. If a different type of exception is
     |      raised, it will not be caught, and the test case will be
     |      deemed to have suffered an error, exactly as for an
     |      unexpected exception.
     |
     |      If called with the callable and arguments omitted, will return a
     |      context object used like this::
     |
     |           with self.assertRaises(SomeException):
     |               do_something()
     |
     |      An optional keyword argument 'msg' can be provided when assertRaises
     |      is used as a context object.
     |
     |      The context manager keeps a reference to the exception as
     |      the 'exception' attribute. This allows you to inspect the
     |      exception after the assertion::
     |
     |          with self.assertRaises(SomeException) as cm:
     |              do_something()
     |          the_exception = cm.exception
     |          self.assertEqual(the_exception.error_code, 3)
     |
     |  assertRaisesRegex(self, expected_exception, expected_regex, *args, **kwargs)
     |      Asserts that the message in a raised exception matches a regex.
     |
     |      Args:
     |          expected_exception: Exception class expected to be raised.
     |          expected_regex: Regex (re.Pattern object or string) expected
     |                  to be found in error message.
     |          args: Function to be called and extra positional args.
     |          kwargs: Extra kwargs.
     |          msg: Optional message used in case of failure. Can only be used
     |                  when assertRaisesRegex is used as a context manager.
     |
     |  assertRegex(self, text, expected_regex, msg=None)
     |      Fail the test unless the text matches the regular expression.
     |
     |  assertSequenceEqual(self, seq1, seq2, msg=None, seq_type=None)
     |      An equality assertion for ordered sequences (like lists and tuples).
     |
     |      For the purposes of this function, a valid ordered sequence type is one
     |      which can be indexed, has a length, and has an equality operator.
     |
     |      Args:
     |          seq1: The first sequence to compare.
     |          seq2: The second sequence to compare.
     |          seq_type: The expected datatype of the sequences, or None if no
     |                  datatype should be enforced.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |  assertSetEqual(self, set1, set2, msg=None)
     |      A set-specific equality assertion.
     |
     |      Args:
     |          set1: The first set to compare.
     |          set2: The second set to compare.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |      assertSetEqual uses ducktyping to support different types of sets, and
     |      is optimized for sets specifically (parameters must support a
     |      difference method).
     |
     |  assertTrue(self, expr, msg=None)
     |      Check that the expression is true.
     |
     |  assertTupleEqual(self, tuple1, tuple2, msg=None)
     |      A tuple-specific equality assertion.
     |
     |      Args:
     |          tuple1: The first tuple to compare.
     |          tuple2: The second tuple to compare.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |  assertWarns(self, expected_warning, *args, **kwargs)
     |      Fail unless a warning of class warnClass is triggered
     |      by the callable when invoked with specified positional and
     |      keyword arguments.  If a different type of warning is
     |      triggered, it will not be handled: depending on the other
     |      warning filtering rules in effect, it might be silenced, printed
     |      out, or raised as an exception.
     |
     |      If called with the callable and arguments omitted, will return a
     |      context object used like this::
     |
     |           with self.assertWarns(SomeWarning):
     |               do_something()
     |
     |      An optional keyword argument 'msg' can be provided when assertWarns
     |      is used as a context object.
     |
     |      The context manager keeps a reference to the first matching
     |      warning as the 'warning' attribute; similarly, the 'filename'
     |      and 'lineno' attributes give you information about the line
     |      of Python code from which the warning was triggered.
     |      This allows you to inspect the warning after the assertion::
     |
     |          with self.assertWarns(SomeWarning) as cm:
     |              do_something()
     |          the_warning = cm.warning
     |          self.assertEqual(the_warning.some_attribute, 147)
     |
     |  assertWarnsRegex(self, expected_warning, expected_regex, *args, **kwargs)
     |      Asserts that the message in a triggered warning matches a regexp.
     |      Basic functioning is similar to assertWarns() with the addition
     |      that only warnings whose messages also match the regular expression
     |      are considered successful matches.
     |
     |      Args:
     |          expected_warning: Warning class expected to be triggered.
     |          expected_regex: Regex (re.Pattern object or string) expected
     |                  to be found in error message.
     |          args: Function to be called and extra positional args.
     |          kwargs: Extra kwargs.
     |          msg: Optional message used in case of failure. Can only be used
     |                  when assertWarnsRegex is used as a context manager.
     |
     |  countTestCases(self)
     |
     |  debug(self)
     |      Run the test without collecting errors in a TestResult
     |
     |  defaultTestResult(self)
     |
     |  doCleanups(self)
     |      Execute all cleanup functions. Normally called for you after
     |      tearDown.
     |
     |  enterContext(self, cm)
     |      Enters the supplied context manager.
     |
     |      If successful, also adds its __exit__ method as a cleanup
     |      function and returns the result of the __enter__ method.
     |
     |  fail(self, msg=None)
     |      Fail immediately, with the given message.
     |
     |  id(self)
     |
     |  run(self, result=None)
     |
     |  setUp(self)
     |      Hook method for setting up the test fixture before exercising it.
     |
     |  shortDescription(self)
     |      Returns a one-line description of the test, or None if no
     |      description has been provided.
     |
     |      The default implementation of this method returns the first line of
     |      the specified test method's docstring.
     |
     |  skipTest(self, reason)
     |      Skip this test.
     |
     |  subTest(self, msg=<object object at 0x0000023FC3E68860>, **params)
     |      Return a context manager that will return the enclosed block
     |      of code in a subtest identified by the optional message and
     |      keyword parameters.  A failure in the subtest marks the test
     |      case as failed but resumes execution at the end of the enclosed
     |      block, allowing further test code to be executed.
     |
     |  tearDown(self)
     |      Hook method for deconstructing the test fixture after testing it.
     |
     |  ----------------------------------------------------------------------
     |  Class methods inherited from unittest.case.TestCase:
     |
     |  __init_subclass__(*args, **kwargs)
     |      This method is called when a class is subclassed.
     |
     |      The default implementation does nothing. It may be
     |      overridden to extend subclasses.
     |
     |  addClassCleanup(function, /, *args, **kwargs)
     |      Same as addCleanup, except the cleanup items are called even if
     |      setUpClass fails (unlike tearDownClass).
     |
     |  doClassCleanups()
     |      Execute all class cleanup functions. Normally called for you after
     |      tearDownClass.
     |
     |  enterClassContext(cm)
     |      Same as enterContext, but class-wide.
     |
     |  setUpClass()
     |      Hook method for setting up class fixture before running tests in the class.
     |
     |  tearDownClass()
     |      Hook method for deconstructing the class fixture after running all tests in the class.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from unittest.case.TestCase:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes inherited from unittest.case.TestCase:
     |
     |  failureException = <class 'AssertionError'>
     |      Assertion failed.
     |
     |
     |  longMessage = True
     |
     |  maxDiff = 640

    class TestFinalCoverage(unittest.case.TestCase)
     |  TestFinalCoverage(methodName='runTest')
     |
     |  Classe pour obtenir 100% de couverture.
     |
     |  Method resolution order:
     |      TestFinalCoverage
     |      unittest.case.TestCase
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  test_full_coverage(self)
     |      Test conçu spécifiquement pour atteindre 100% de couverture.
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from unittest.case.TestCase:
     |
     |  __call__(self, *args, **kwds)
     |      Call self as a function.
     |
     |  __eq__(self, other)
     |      Return self==value.
     |
     |  __hash__(self)
     |      Return hash(self).
     |
     |  __init__(self, methodName='runTest')
     |      Create an instance of the class that will use the named test
     |      method when executed. Raises a ValueError if the instance does
     |      not have a method with the specified name.
     |
     |  __repr__(self)
     |      Return repr(self).
     |
     |  __str__(self)
     |      Return str(self).
     |
     |  addCleanup(self, function, /, *args, **kwargs)
     |      Add a function, with arguments, to be called when the test is
     |      completed. Functions added are called on a LIFO basis and are
     |      called after tearDown on test failure or success.
     |
     |      Cleanup items are called even if setUp fails (unlike tearDown).
     |
     |  addTypeEqualityFunc(self, typeobj, function)
     |      Add a type specific assertEqual style function to compare a type.
     |
     |      This method is for use by TestCase subclasses that need to register
     |      their own type equality functions to provide nicer error messages.
     |
     |      Args:
     |          typeobj: The data type to call this function on when both values
     |                  are of the same type in assertEqual().
     |          function: The callable taking two arguments and an optional
     |                  msg= argument that raises self.failureException with a
     |                  useful error message when the two arguments are not equal.
     |
     |  assertAlmostEqual(self, first, second, places=None, msg=None, delta=None)
     |      Fail if the two objects are unequal as determined by their
     |      difference rounded to the given number of decimal places
     |      (default 7) and comparing to zero, or by comparing that the
     |      difference between the two objects is more than the given
     |      delta.
     |
     |      Note that decimal places (from zero) are usually not the same
     |      as significant digits (measured from the most significant digit).
     |
     |      If the two objects compare equal then they will automatically
     |      compare almost equal.
     |
     |  assertCountEqual(self, first, second, msg=None)
     |      Asserts that two iterables have the same elements, the same number of
     |      times, without regard to order.
     |
     |          self.assertEqual(Counter(list(first)),
     |                           Counter(list(second)))
     |
     |       Example:
     |          - [0, 1, 1] and [1, 0, 1] compare equal.
     |          - [0, 0, 1] and [0, 1] compare unequal.
     |
     |  assertDictEqual(self, d1, d2, msg=None)
     |
     |  assertEqual(self, first, second, msg=None)
     |      Fail if the two objects are unequal as determined by the '=='
     |      operator.
     |
     |  assertFalse(self, expr, msg=None)
     |      Check that the expression is false.
     |
     |  assertGreater(self, a, b, msg=None)
     |      Just like self.assertTrue(a > b), but with a nicer default message.
     |
     |  assertGreaterEqual(self, a, b, msg=None)
     |      Just like self.assertTrue(a >= b), but with a nicer default message.
     |
     |  assertIn(self, member, container, msg=None)
     |      Just like self.assertTrue(a in b), but with a nicer default message.
     |
     |  assertIs(self, expr1, expr2, msg=None)
     |      Just like self.assertTrue(a is b), but with a nicer default message.
     |
     |  assertIsInstance(self, obj, cls, msg=None)
     |      Same as self.assertTrue(isinstance(obj, cls)), with a nicer
     |      default message.
     |
     |  assertIsNone(self, obj, msg=None)
     |      Same as self.assertTrue(obj is None), with a nicer default message.
     |
     |  assertIsNot(self, expr1, expr2, msg=None)
     |      Just like self.assertTrue(a is not b), but with a nicer default message.
     |
     |  assertIsNotNone(self, obj, msg=None)
     |      Included for symmetry with assertIsNone.
     |
     |  assertLess(self, a, b, msg=None)
     |      Just like self.assertTrue(a < b), but with a nicer default message.
     |
     |  assertLessEqual(self, a, b, msg=None)
     |      Just like self.assertTrue(a <= b), but with a nicer default message.
     |
     |  assertListEqual(self, list1, list2, msg=None)
     |      A list-specific equality assertion.
     |
     |      Args:
     |          list1: The first list to compare.
     |          list2: The second list to compare.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |  assertLogs(self, logger=None, level=None)
     |      Fail unless a log message of level *level* or higher is emitted
     |      on *logger_name* or its children.  If omitted, *level* defaults to
     |      INFO and *logger* defaults to the root logger.
     |
     |      This method must be used as a context manager, and will yield
     |      a recording object with two attributes: `output` and `records`.
     |      At the end of the context manager, the `output` attribute will
     |      be a list of the matching formatted log messages and the
     |      `records` attribute will be a list of the corresponding LogRecord
     |      objects.
     |
     |      Example::
     |
     |          with self.assertLogs('foo', level='INFO') as cm:
     |              logging.getLogger('foo').info('first message')
     |              logging.getLogger('foo.bar').error('second message')
     |          self.assertEqual(cm.output, ['INFO:foo:first message',
     |                                       'ERROR:foo.bar:second message'])
     |
     |  assertMultiLineEqual(self, first, second, msg=None)
     |      Assert that two multi-line strings are equal.
     |
     |  assertNoLogs(self, logger=None, level=None)
     |      Fail unless no log messages of level *level* or higher are emitted
     |      on *logger_name* or its children.
     |
     |      This method must be used as a context manager.
     |
     |  assertNotAlmostEqual(self, first, second, places=None, msg=None, delta=None)
     |      Fail if the two objects are equal as determined by their
     |      difference rounded to the given number of decimal places
     |      (default 7) and comparing to zero, or by comparing that the
     |      difference between the two objects is less than the given delta.
     |
     |      Note that decimal places (from zero) are usually not the same
     |      as significant digits (measured from the most significant digit).
     |
     |      Objects that are equal automatically fail.
     |
     |  assertNotEqual(self, first, second, msg=None)
     |      Fail if the two objects are equal as determined by the '!='
     |      operator.
     |
     |  assertNotIn(self, member, container, msg=None)
     |      Just like self.assertTrue(a not in b), but with a nicer default message.
     |
     |  assertNotIsInstance(self, obj, cls, msg=None)
     |      Included for symmetry with assertIsInstance.
     |
     |  assertNotRegex(self, text, unexpected_regex, msg=None)
     |      Fail the test if the text matches the regular expression.
     |
     |  assertRaises(self, expected_exception, *args, **kwargs)
     |      Fail unless an exception of class expected_exception is raised
     |      by the callable when invoked with specified positional and
     |      keyword arguments. If a different type of exception is
     |      raised, it will not be caught, and the test case will be
     |      deemed to have suffered an error, exactly as for an
     |      unexpected exception.
     |
     |      If called with the callable and arguments omitted, will return a
     |      context object used like this::
     |
     |           with self.assertRaises(SomeException):
     |               do_something()
     |
     |      An optional keyword argument 'msg' can be provided when assertRaises
     |      is used as a context object.
     |
     |      The context manager keeps a reference to the exception as
     |      the 'exception' attribute. This allows you to inspect the
     |      exception after the assertion::
     |
     |          with self.assertRaises(SomeException) as cm:
     |              do_something()
     |          the_exception = cm.exception
     |          self.assertEqual(the_exception.error_code, 3)
     |
     |  assertRaisesRegex(self, expected_exception, expected_regex, *args, **kwargs)
     |      Asserts that the message in a raised exception matches a regex.
     |
     |      Args:
     |          expected_exception: Exception class expected to be raised.
     |          expected_regex: Regex (re.Pattern object or string) expected
     |                  to be found in error message.
     |          args: Function to be called and extra positional args.
     |          kwargs: Extra kwargs.
     |          msg: Optional message used in case of failure. Can only be used
     |                  when assertRaisesRegex is used as a context manager.
     |
     |  assertRegex(self, text, expected_regex, msg=None)
     |      Fail the test unless the text matches the regular expression.
     |
     |  assertSequenceEqual(self, seq1, seq2, msg=None, seq_type=None)
     |      An equality assertion for ordered sequences (like lists and tuples).
     |
     |      For the purposes of this function, a valid ordered sequence type is one
     |      which can be indexed, has a length, and has an equality operator.
     |
     |      Args:
     |          seq1: The first sequence to compare.
     |          seq2: The second sequence to compare.
     |          seq_type: The expected datatype of the sequences, or None if no
     |                  datatype should be enforced.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |  assertSetEqual(self, set1, set2, msg=None)
     |      A set-specific equality assertion.
     |
     |      Args:
     |          set1: The first set to compare.
     |          set2: The second set to compare.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |      assertSetEqual uses ducktyping to support different types of sets, and
     |      is optimized for sets specifically (parameters must support a
     |      difference method).
     |
     |  assertTrue(self, expr, msg=None)
     |      Check that the expression is true.
     |
     |  assertTupleEqual(self, tuple1, tuple2, msg=None)
     |      A tuple-specific equality assertion.
     |
     |      Args:
     |          tuple1: The first tuple to compare.
     |          tuple2: The second tuple to compare.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |  assertWarns(self, expected_warning, *args, **kwargs)
     |      Fail unless a warning of class warnClass is triggered
     |      by the callable when invoked with specified positional and
     |      keyword arguments.  If a different type of warning is
     |      triggered, it will not be handled: depending on the other
     |      warning filtering rules in effect, it might be silenced, printed
     |      out, or raised as an exception.
     |
     |      If called with the callable and arguments omitted, will return a
     |      context object used like this::
     |
     |           with self.assertWarns(SomeWarning):
     |               do_something()
     |
     |      An optional keyword argument 'msg' can be provided when assertWarns
     |      is used as a context object.
     |
     |      The context manager keeps a reference to the first matching
     |      warning as the 'warning' attribute; similarly, the 'filename'
     |      and 'lineno' attributes give you information about the line
     |      of Python code from which the warning was triggered.
     |      This allows you to inspect the warning after the assertion::
     |
     |          with self.assertWarns(SomeWarning) as cm:
     |              do_something()
     |          the_warning = cm.warning
     |          self.assertEqual(the_warning.some_attribute, 147)
     |
     |  assertWarnsRegex(self, expected_warning, expected_regex, *args, **kwargs)
     |      Asserts that the message in a triggered warning matches a regexp.
     |      Basic functioning is similar to assertWarns() with the addition
     |      that only warnings whose messages also match the regular expression
     |      are considered successful matches.
     |
     |      Args:
     |          expected_warning: Warning class expected to be triggered.
     |          expected_regex: Regex (re.Pattern object or string) expected
     |                  to be found in error message.
     |          args: Function to be called and extra positional args.
     |          kwargs: Extra kwargs.
     |          msg: Optional message used in case of failure. Can only be used
     |                  when assertWarnsRegex is used as a context manager.
     |
     |  countTestCases(self)
     |
     |  debug(self)
     |      Run the test without collecting errors in a TestResult
     |
     |  defaultTestResult(self)
     |
     |  doCleanups(self)
     |      Execute all cleanup functions. Normally called for you after
     |      tearDown.
     |
     |  enterContext(self, cm)
     |      Enters the supplied context manager.
     |
     |      If successful, also adds its __exit__ method as a cleanup
     |      function and returns the result of the __enter__ method.
     |
     |  fail(self, msg=None)
     |      Fail immediately, with the given message.
     |
     |  id(self)
     |
     |  run(self, result=None)
     |
     |  setUp(self)
     |      Hook method for setting up the test fixture before exercising it.
     |
     |  shortDescription(self)
     |      Returns a one-line description of the test, or None if no
     |      description has been provided.
     |
     |      The default implementation of this method returns the first line of
     |      the specified test method's docstring.
     |
     |  skipTest(self, reason)
     |      Skip this test.
     |
     |  subTest(self, msg=<object object at 0x0000023FC3E68860>, **params)
     |      Return a context manager that will return the enclosed block
     |      of code in a subtest identified by the optional message and
     |      keyword parameters.  A failure in the subtest marks the test
     |      case as failed but resumes execution at the end of the enclosed
     |      block, allowing further test code to be executed.
     |
     |  tearDown(self)
     |      Hook method for deconstructing the test fixture after testing it.
     |
     |  ----------------------------------------------------------------------
     |  Class methods inherited from unittest.case.TestCase:
     |
     |  __init_subclass__(*args, **kwargs)
     |      This method is called when a class is subclassed.
     |
     |      The default implementation does nothing. It may be
     |      overridden to extend subclasses.
     |
     |  addClassCleanup(function, /, *args, **kwargs)
     |      Same as addCleanup, except the cleanup items are called even if
     |      setUpClass fails (unlike tearDownClass).
     |
     |  doClassCleanups()
     |      Execute all class cleanup functions. Normally called for you after
     |      tearDownClass.
     |
     |  enterClassContext(cm)
     |      Same as enterContext, but class-wide.
     |
     |  setUpClass()
     |      Hook method for setting up class fixture before running tests in the class.
     |
     |  tearDownClass()
     |      Hook method for deconstructing the class fixture after running all tests in the class.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from unittest.case.TestCase:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes inherited from unittest.case.TestCase:
     |
     |  failureException = <class 'AssertionError'>
     |      Assertion failed.
     |
     |
     |  longMessage = True
     |
     |  maxDiff = 640

    class TestMainExecution(unittest.case.TestCase)
     |  TestMainExecution(methodName='runTest')
     |
     |  Tests pour le bloc if __name__ == '__main__'.
     |
     |  Method resolution order:
     |      TestMainExecution
     |      unittest.case.TestCase
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  test_main_execution(self)
     |      Teste l'exécution du bloc main.
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from unittest.case.TestCase:
     |
     |  __call__(self, *args, **kwds)
     |      Call self as a function.
     |
     |  __eq__(self, other)
     |      Return self==value.
     |
     |  __hash__(self)
     |      Return hash(self).
     |
     |  __init__(self, methodName='runTest')
     |      Create an instance of the class that will use the named test
     |      method when executed. Raises a ValueError if the instance does
     |      not have a method with the specified name.
     |
     |  __repr__(self)
     |      Return repr(self).
     |
     |  __str__(self)
     |      Return str(self).
     |
     |  addCleanup(self, function, /, *args, **kwargs)
     |      Add a function, with arguments, to be called when the test is
     |      completed. Functions added are called on a LIFO basis and are
     |      called after tearDown on test failure or success.
     |
     |      Cleanup items are called even if setUp fails (unlike tearDown).
     |
     |  addTypeEqualityFunc(self, typeobj, function)
     |      Add a type specific assertEqual style function to compare a type.
     |
     |      This method is for use by TestCase subclasses that need to register
     |      their own type equality functions to provide nicer error messages.
     |
     |      Args:
     |          typeobj: The data type to call this function on when both values
     |                  are of the same type in assertEqual().
     |          function: The callable taking two arguments and an optional
     |                  msg= argument that raises self.failureException with a
     |                  useful error message when the two arguments are not equal.
     |
     |  assertAlmostEqual(self, first, second, places=None, msg=None, delta=None)
     |      Fail if the two objects are unequal as determined by their
     |      difference rounded to the given number of decimal places
     |      (default 7) and comparing to zero, or by comparing that the
     |      difference between the two objects is more than the given
     |      delta.
     |
     |      Note that decimal places (from zero) are usually not the same
     |      as significant digits (measured from the most significant digit).
     |
     |      If the two objects compare equal then they will automatically
     |      compare almost equal.
     |
     |  assertCountEqual(self, first, second, msg=None)
     |      Asserts that two iterables have the same elements, the same number of
     |      times, without regard to order.
     |
     |          self.assertEqual(Counter(list(first)),
     |                           Counter(list(second)))
     |
     |       Example:
     |          - [0, 1, 1] and [1, 0, 1] compare equal.
     |          - [0, 0, 1] and [0, 1] compare unequal.
     |
     |  assertDictEqual(self, d1, d2, msg=None)
     |
     |  assertEqual(self, first, second, msg=None)
     |      Fail if the two objects are unequal as determined by the '=='
     |      operator.
     |
     |  assertFalse(self, expr, msg=None)
     |      Check that the expression is false.
     |
     |  assertGreater(self, a, b, msg=None)
     |      Just like self.assertTrue(a > b), but with a nicer default message.
     |
     |  assertGreaterEqual(self, a, b, msg=None)
     |      Just like self.assertTrue(a >= b), but with a nicer default message.
     |
     |  assertIn(self, member, container, msg=None)
     |      Just like self.assertTrue(a in b), but with a nicer default message.
     |
     |  assertIs(self, expr1, expr2, msg=None)
     |      Just like self.assertTrue(a is b), but with a nicer default message.
     |
     |  assertIsInstance(self, obj, cls, msg=None)
     |      Same as self.assertTrue(isinstance(obj, cls)), with a nicer
     |      default message.
     |
     |  assertIsNone(self, obj, msg=None)
     |      Same as self.assertTrue(obj is None), with a nicer default message.
     |
     |  assertIsNot(self, expr1, expr2, msg=None)
     |      Just like self.assertTrue(a is not b), but with a nicer default message.
     |
     |  assertIsNotNone(self, obj, msg=None)
     |      Included for symmetry with assertIsNone.
     |
     |  assertLess(self, a, b, msg=None)
     |      Just like self.assertTrue(a < b), but with a nicer default message.
     |
     |  assertLessEqual(self, a, b, msg=None)
     |      Just like self.assertTrue(a <= b), but with a nicer default message.
     |
     |  assertListEqual(self, list1, list2, msg=None)
     |      A list-specific equality assertion.
     |
     |      Args:
     |          list1: The first list to compare.
     |          list2: The second list to compare.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |  assertLogs(self, logger=None, level=None)
     |      Fail unless a log message of level *level* or higher is emitted
     |      on *logger_name* or its children.  If omitted, *level* defaults to
     |      INFO and *logger* defaults to the root logger.
     |
     |      This method must be used as a context manager, and will yield
     |      a recording object with two attributes: `output` and `records`.
     |      At the end of the context manager, the `output` attribute will
     |      be a list of the matching formatted log messages and the
     |      `records` attribute will be a list of the corresponding LogRecord
     |      objects.
     |
     |      Example::
     |
     |          with self.assertLogs('foo', level='INFO') as cm:
     |              logging.getLogger('foo').info('first message')
     |              logging.getLogger('foo.bar').error('second message')
     |          self.assertEqual(cm.output, ['INFO:foo:first message',
     |                                       'ERROR:foo.bar:second message'])
     |
     |  assertMultiLineEqual(self, first, second, msg=None)
     |      Assert that two multi-line strings are equal.
     |
     |  assertNoLogs(self, logger=None, level=None)
     |      Fail unless no log messages of level *level* or higher are emitted
     |      on *logger_name* or its children.
     |
     |      This method must be used as a context manager.
     |
     |  assertNotAlmostEqual(self, first, second, places=None, msg=None, delta=None)
     |      Fail if the two objects are equal as determined by their
     |      difference rounded to the given number of decimal places
     |      (default 7) and comparing to zero, or by comparing that the
     |      difference between the two objects is less than the given delta.
     |
     |      Note that decimal places (from zero) are usually not the same
     |      as significant digits (measured from the most significant digit).
     |
     |      Objects that are equal automatically fail.
     |
     |  assertNotEqual(self, first, second, msg=None)
     |      Fail if the two objects are equal as determined by the '!='
     |      operator.
     |
     |  assertNotIn(self, member, container, msg=None)
     |      Just like self.assertTrue(a not in b), but with a nicer default message.
     |
     |  assertNotIsInstance(self, obj, cls, msg=None)
     |      Included for symmetry with assertIsInstance.
     |
     |  assertNotRegex(self, text, unexpected_regex, msg=None)
     |      Fail the test if the text matches the regular expression.
     |
     |  assertRaises(self, expected_exception, *args, **kwargs)
     |      Fail unless an exception of class expected_exception is raised
     |      by the callable when invoked with specified positional and
     |      keyword arguments. If a different type of exception is
     |      raised, it will not be caught, and the test case will be
     |      deemed to have suffered an error, exactly as for an
     |      unexpected exception.
     |
     |      If called with the callable and arguments omitted, will return a
     |      context object used like this::
     |
     |           with self.assertRaises(SomeException):
     |               do_something()
     |
     |      An optional keyword argument 'msg' can be provided when assertRaises
     |      is used as a context object.
     |
     |      The context manager keeps a reference to the exception as
     |      the 'exception' attribute. This allows you to inspect the
     |      exception after the assertion::
     |
     |          with self.assertRaises(SomeException) as cm:
     |              do_something()
     |          the_exception = cm.exception
     |          self.assertEqual(the_exception.error_code, 3)
     |
     |  assertRaisesRegex(self, expected_exception, expected_regex, *args, **kwargs)
     |      Asserts that the message in a raised exception matches a regex.
     |
     |      Args:
     |          expected_exception: Exception class expected to be raised.
     |          expected_regex: Regex (re.Pattern object or string) expected
     |                  to be found in error message.
     |          args: Function to be called and extra positional args.
     |          kwargs: Extra kwargs.
     |          msg: Optional message used in case of failure. Can only be used
     |                  when assertRaisesRegex is used as a context manager.
     |
     |  assertRegex(self, text, expected_regex, msg=None)
     |      Fail the test unless the text matches the regular expression.
     |
     |  assertSequenceEqual(self, seq1, seq2, msg=None, seq_type=None)
     |      An equality assertion for ordered sequences (like lists and tuples).
     |
     |      For the purposes of this function, a valid ordered sequence type is one
     |      which can be indexed, has a length, and has an equality operator.
     |
     |      Args:
     |          seq1: The first sequence to compare.
     |          seq2: The second sequence to compare.
     |          seq_type: The expected datatype of the sequences, or None if no
     |                  datatype should be enforced.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |  assertSetEqual(self, set1, set2, msg=None)
     |      A set-specific equality assertion.
     |
     |      Args:
     |          set1: The first set to compare.
     |          set2: The second set to compare.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |      assertSetEqual uses ducktyping to support different types of sets, and
     |      is optimized for sets specifically (parameters must support a
     |      difference method).
     |
     |  assertTrue(self, expr, msg=None)
     |      Check that the expression is true.
     |
     |  assertTupleEqual(self, tuple1, tuple2, msg=None)
     |      A tuple-specific equality assertion.
     |
     |      Args:
     |          tuple1: The first tuple to compare.
     |          tuple2: The second tuple to compare.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |  assertWarns(self, expected_warning, *args, **kwargs)
     |      Fail unless a warning of class warnClass is triggered
     |      by the callable when invoked with specified positional and
     |      keyword arguments.  If a different type of warning is
     |      triggered, it will not be handled: depending on the other
     |      warning filtering rules in effect, it might be silenced, printed
     |      out, or raised as an exception.
     |
     |      If called with the callable and arguments omitted, will return a
     |      context object used like this::
     |
     |           with self.assertWarns(SomeWarning):
     |               do_something()
     |
     |      An optional keyword argument 'msg' can be provided when assertWarns
     |      is used as a context object.
     |
     |      The context manager keeps a reference to the first matching
     |      warning as the 'warning' attribute; similarly, the 'filename'
     |      and 'lineno' attributes give you information about the line
     |      of Python code from which the warning was triggered.
     |      This allows you to inspect the warning after the assertion::
     |
     |          with self.assertWarns(SomeWarning) as cm:
     |              do_something()
     |          the_warning = cm.warning
     |          self.assertEqual(the_warning.some_attribute, 147)
     |
     |  assertWarnsRegex(self, expected_warning, expected_regex, *args, **kwargs)
     |      Asserts that the message in a triggered warning matches a regexp.
     |      Basic functioning is similar to assertWarns() with the addition
     |      that only warnings whose messages also match the regular expression
     |      are considered successful matches.
     |
     |      Args:
     |          expected_warning: Warning class expected to be triggered.
     |          expected_regex: Regex (re.Pattern object or string) expected
     |                  to be found in error message.
     |          args: Function to be called and extra positional args.
     |          kwargs: Extra kwargs.
     |          msg: Optional message used in case of failure. Can only be used
     |                  when assertWarnsRegex is used as a context manager.
     |
     |  countTestCases(self)
     |
     |  debug(self)
     |      Run the test without collecting errors in a TestResult
     |
     |  defaultTestResult(self)
     |
     |  doCleanups(self)
     |      Execute all cleanup functions. Normally called for you after
     |      tearDown.
     |
     |  enterContext(self, cm)
     |      Enters the supplied context manager.
     |
     |      If successful, also adds its __exit__ method as a cleanup
     |      function and returns the result of the __enter__ method.
     |
     |  fail(self, msg=None)
     |      Fail immediately, with the given message.
     |
     |  id(self)
     |
     |  run(self, result=None)
     |
     |  setUp(self)
     |      Hook method for setting up the test fixture before exercising it.
     |
     |  shortDescription(self)
     |      Returns a one-line description of the test, or None if no
     |      description has been provided.
     |
     |      The default implementation of this method returns the first line of
     |      the specified test method's docstring.
     |
     |  skipTest(self, reason)
     |      Skip this test.
     |
     |  subTest(self, msg=<object object at 0x0000023FC3E68860>, **params)
     |      Return a context manager that will return the enclosed block
     |      of code in a subtest identified by the optional message and
     |      keyword parameters.  A failure in the subtest marks the test
     |      case as failed but resumes execution at the end of the enclosed
     |      block, allowing further test code to be executed.
     |
     |  tearDown(self)
     |      Hook method for deconstructing the test fixture after testing it.
     |
     |  ----------------------------------------------------------------------
     |  Class methods inherited from unittest.case.TestCase:
     |
     |  __init_subclass__(*args, **kwargs)
     |      This method is called when a class is subclassed.
     |
     |      The default implementation does nothing. It may be
     |      overridden to extend subclasses.
     |
     |  addClassCleanup(function, /, *args, **kwargs)
     |      Same as addCleanup, except the cleanup items are called even if
     |      setUpClass fails (unlike tearDownClass).
     |
     |  doClassCleanups()
     |      Execute all class cleanup functions. Normally called for you after
     |      tearDownClass.
     |
     |  enterClassContext(cm)
     |      Same as enterContext, but class-wide.
     |
     |  setUpClass()
     |      Hook method for setting up class fixture before running tests in the class.
     |
     |  tearDownClass()
     |      Hook method for deconstructing the class fixture after running all tests in the class.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from unittest.case.TestCase:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes inherited from unittest.case.TestCase:
     |
     |  failureException = <class 'AssertionError'>
     |      Assertion failed.
     |
     |
     |  longMessage = True
     |
     |  maxDiff = 640

    class TestParametrized(unittest.case.TestCase)
     |  TestParametrized(methodName='runTest')
     |
     |  Classe de test avec des tests paramétrés.
     |
     |  Method resolution order:
     |      TestParametrized
     |      unittest.case.TestCase
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  test_multiplication_by_two(self, input_val=2, expected=4)
     |      Test paramétré de multiplication.
     |
     |  test_multiplication_by_two_0(self)
     |      Test de multiplication par deux avec 0.
     |
     |  test_multiplication_by_two_2(self)
     |      Test de multiplication par deux avec 2.
     |
     |  test_multiplication_by_two_3(self)
     |      Test de multiplication par deux avec 3.
     |
     |  test_multiplication_by_two_float(self)
     |      Test de multiplication par deux avec nombre décimal.
     |
     |  test_multiplication_by_two_large(self)
     |      Test de multiplication par deux avec grand nombre.
     |
     |  test_multiplication_by_two_neg1(self)
     |      Test de multiplication par deux avec -1.
     |
     |  test_string_length(self, test_input='test', test_output=4)
     |      Test paramétré de longueur de chaînes.
     |
     |  test_string_length_digits(self)
     |      Test de longueur de chaîne avec chiffres.
     |
     |  test_string_length_empty(self)
     |      Test de longueur de chaîne vide.
     |
     |  test_string_length_hello(self)
     |      Test de longueur de chaîne 'hello'.
     |
     |  test_string_length_python(self)
     |      Test de longueur de chaîne 'python'.
     |
     |  test_string_length_spaces(self)
     |      Test de longueur de chaîne avec espaces.
     |
     |  test_with_context(self)
     |      Test utilisant un context manager.
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from unittest.case.TestCase:
     |
     |  __call__(self, *args, **kwds)
     |      Call self as a function.
     |
     |  __eq__(self, other)
     |      Return self==value.
     |
     |  __hash__(self)
     |      Return hash(self).
     |
     |  __init__(self, methodName='runTest')
     |      Create an instance of the class that will use the named test
     |      method when executed. Raises a ValueError if the instance does
     |      not have a method with the specified name.
     |
     |  __repr__(self)
     |      Return repr(self).
     |
     |  __str__(self)
     |      Return str(self).
     |
     |  addCleanup(self, function, /, *args, **kwargs)
     |      Add a function, with arguments, to be called when the test is
     |      completed. Functions added are called on a LIFO basis and are
     |      called after tearDown on test failure or success.
     |
     |      Cleanup items are called even if setUp fails (unlike tearDown).
     |
     |  addTypeEqualityFunc(self, typeobj, function)
     |      Add a type specific assertEqual style function to compare a type.
     |
     |      This method is for use by TestCase subclasses that need to register
     |      their own type equality functions to provide nicer error messages.
     |
     |      Args:
     |          typeobj: The data type to call this function on when both values
     |                  are of the same type in assertEqual().
     |          function: The callable taking two arguments and an optional
     |                  msg= argument that raises self.failureException with a
     |                  useful error message when the two arguments are not equal.
     |
     |  assertAlmostEqual(self, first, second, places=None, msg=None, delta=None)
     |      Fail if the two objects are unequal as determined by their
     |      difference rounded to the given number of decimal places
     |      (default 7) and comparing to zero, or by comparing that the
     |      difference between the two objects is more than the given
     |      delta.
     |
     |      Note that decimal places (from zero) are usually not the same
     |      as significant digits (measured from the most significant digit).
     |
     |      If the two objects compare equal then they will automatically
     |      compare almost equal.
     |
     |  assertCountEqual(self, first, second, msg=None)
     |      Asserts that two iterables have the same elements, the same number of
     |      times, without regard to order.
     |
     |          self.assertEqual(Counter(list(first)),
     |                           Counter(list(second)))
     |
     |       Example:
     |          - [0, 1, 1] and [1, 0, 1] compare equal.
     |          - [0, 0, 1] and [0, 1] compare unequal.
     |
     |  assertDictEqual(self, d1, d2, msg=None)
     |
     |  assertEqual(self, first, second, msg=None)
     |      Fail if the two objects are unequal as determined by the '=='
     |      operator.
     |
     |  assertFalse(self, expr, msg=None)
     |      Check that the expression is false.
     |
     |  assertGreater(self, a, b, msg=None)
     |      Just like self.assertTrue(a > b), but with a nicer default message.
     |
     |  assertGreaterEqual(self, a, b, msg=None)
     |      Just like self.assertTrue(a >= b), but with a nicer default message.
     |
     |  assertIn(self, member, container, msg=None)
     |      Just like self.assertTrue(a in b), but with a nicer default message.
     |
     |  assertIs(self, expr1, expr2, msg=None)
     |      Just like self.assertTrue(a is b), but with a nicer default message.
     |
     |  assertIsInstance(self, obj, cls, msg=None)
     |      Same as self.assertTrue(isinstance(obj, cls)), with a nicer
     |      default message.
     |
     |  assertIsNone(self, obj, msg=None)
     |      Same as self.assertTrue(obj is None), with a nicer default message.
     |
     |  assertIsNot(self, expr1, expr2, msg=None)
     |      Just like self.assertTrue(a is not b), but with a nicer default message.
     |
     |  assertIsNotNone(self, obj, msg=None)
     |      Included for symmetry with assertIsNone.
     |
     |  assertLess(self, a, b, msg=None)
     |      Just like self.assertTrue(a < b), but with a nicer default message.
     |
     |  assertLessEqual(self, a, b, msg=None)
     |      Just like self.assertTrue(a <= b), but with a nicer default message.
     |
     |  assertListEqual(self, list1, list2, msg=None)
     |      A list-specific equality assertion.
     |
     |      Args:
     |          list1: The first list to compare.
     |          list2: The second list to compare.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |  assertLogs(self, logger=None, level=None)
     |      Fail unless a log message of level *level* or higher is emitted
     |      on *logger_name* or its children.  If omitted, *level* defaults to
     |      INFO and *logger* defaults to the root logger.
     |
     |      This method must be used as a context manager, and will yield
     |      a recording object with two attributes: `output` and `records`.
     |      At the end of the context manager, the `output` attribute will
     |      be a list of the matching formatted log messages and the
     |      `records` attribute will be a list of the corresponding LogRecord
     |      objects.
     |
     |      Example::
     |
     |          with self.assertLogs('foo', level='INFO') as cm:
     |              logging.getLogger('foo').info('first message')
     |              logging.getLogger('foo.bar').error('second message')
     |          self.assertEqual(cm.output, ['INFO:foo:first message',
     |                                       'ERROR:foo.bar:second message'])
     |
     |  assertMultiLineEqual(self, first, second, msg=None)
     |      Assert that two multi-line strings are equal.
     |
     |  assertNoLogs(self, logger=None, level=None)
     |      Fail unless no log messages of level *level* or higher are emitted
     |      on *logger_name* or its children.
     |
     |      This method must be used as a context manager.
     |
     |  assertNotAlmostEqual(self, first, second, places=None, msg=None, delta=None)
     |      Fail if the two objects are equal as determined by their
     |      difference rounded to the given number of decimal places
     |      (default 7) and comparing to zero, or by comparing that the
     |      difference between the two objects is less than the given delta.
     |
     |      Note that decimal places (from zero) are usually not the same
     |      as significant digits (measured from the most significant digit).
     |
     |      Objects that are equal automatically fail.
     |
     |  assertNotEqual(self, first, second, msg=None)
     |      Fail if the two objects are equal as determined by the '!='
     |      operator.
     |
     |  assertNotIn(self, member, container, msg=None)
     |      Just like self.assertTrue(a not in b), but with a nicer default message.
     |
     |  assertNotIsInstance(self, obj, cls, msg=None)
     |      Included for symmetry with assertIsInstance.
     |
     |  assertNotRegex(self, text, unexpected_regex, msg=None)
     |      Fail the test if the text matches the regular expression.
     |
     |  assertRaises(self, expected_exception, *args, **kwargs)
     |      Fail unless an exception of class expected_exception is raised
     |      by the callable when invoked with specified positional and
     |      keyword arguments. If a different type of exception is
     |      raised, it will not be caught, and the test case will be
     |      deemed to have suffered an error, exactly as for an
     |      unexpected exception.
     |
     |      If called with the callable and arguments omitted, will return a
     |      context object used like this::
     |
     |           with self.assertRaises(SomeException):
     |               do_something()
     |
     |      An optional keyword argument 'msg' can be provided when assertRaises
     |      is used as a context object.
     |
     |      The context manager keeps a reference to the exception as
     |      the 'exception' attribute. This allows you to inspect the
     |      exception after the assertion::
     |
     |          with self.assertRaises(SomeException) as cm:
     |              do_something()
     |          the_exception = cm.exception
     |          self.assertEqual(the_exception.error_code, 3)
     |
     |  assertRaisesRegex(self, expected_exception, expected_regex, *args, **kwargs)
     |      Asserts that the message in a raised exception matches a regex.
     |
     |      Args:
     |          expected_exception: Exception class expected to be raised.
     |          expected_regex: Regex (re.Pattern object or string) expected
     |                  to be found in error message.
     |          args: Function to be called and extra positional args.
     |          kwargs: Extra kwargs.
     |          msg: Optional message used in case of failure. Can only be used
     |                  when assertRaisesRegex is used as a context manager.
     |
     |  assertRegex(self, text, expected_regex, msg=None)
     |      Fail the test unless the text matches the regular expression.
     |
     |  assertSequenceEqual(self, seq1, seq2, msg=None, seq_type=None)
     |      An equality assertion for ordered sequences (like lists and tuples).
     |
     |      For the purposes of this function, a valid ordered sequence type is one
     |      which can be indexed, has a length, and has an equality operator.
     |
     |      Args:
     |          seq1: The first sequence to compare.
     |          seq2: The second sequence to compare.
     |          seq_type: The expected datatype of the sequences, or None if no
     |                  datatype should be enforced.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |  assertSetEqual(self, set1, set2, msg=None)
     |      A set-specific equality assertion.
     |
     |      Args:
     |          set1: The first set to compare.
     |          set2: The second set to compare.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |      assertSetEqual uses ducktyping to support different types of sets, and
     |      is optimized for sets specifically (parameters must support a
     |      difference method).
     |
     |  assertTrue(self, expr, msg=None)
     |      Check that the expression is true.
     |
     |  assertTupleEqual(self, tuple1, tuple2, msg=None)
     |      A tuple-specific equality assertion.
     |
     |      Args:
     |          tuple1: The first tuple to compare.
     |          tuple2: The second tuple to compare.
     |          msg: Optional message to use on failure instead of a list of
     |                  differences.
     |
     |  assertWarns(self, expected_warning, *args, **kwargs)
     |      Fail unless a warning of class warnClass is triggered
     |      by the callable when invoked with specified positional and
     |      keyword arguments.  If a different type of warning is
     |      triggered, it will not be handled: depending on the other
     |      warning filtering rules in effect, it might be silenced, printed
     |      out, or raised as an exception.
     |
     |      If called with the callable and arguments omitted, will return a
     |      context object used like this::
     |
     |           with self.assertWarns(SomeWarning):
     |               do_something()
     |
     |      An optional keyword argument 'msg' can be provided when assertWarns
     |      is used as a context object.
     |
     |      The context manager keeps a reference to the first matching
     |      warning as the 'warning' attribute; similarly, the 'filename'
     |      and 'lineno' attributes give you information about the line
     |      of Python code from which the warning was triggered.
     |      This allows you to inspect the warning after the assertion::
     |
     |          with self.assertWarns(SomeWarning) as cm:
     |              do_something()
     |          the_warning = cm.warning
     |          self.assertEqual(the_warning.some_attribute, 147)
     |
     |  assertWarnsRegex(self, expected_warning, expected_regex, *args, **kwargs)
     |      Asserts that the message in a triggered warning matches a regexp.
     |      Basic functioning is similar to assertWarns() with the addition
     |      that only warnings whose messages also match the regular expression
     |      are considered successful matches.
     |
     |      Args:
     |          expected_warning: Warning class expected to be triggered.
     |          expected_regex: Regex (re.Pattern object or string) expected
     |                  to be found in error message.
     |          args: Function to be called and extra positional args.
     |          kwargs: Extra kwargs.
     |          msg: Optional message used in case of failure. Can only be used
     |                  when assertWarnsRegex is used as a context manager.
     |
     |  countTestCases(self)
     |
     |  debug(self)
     |      Run the test without collecting errors in a TestResult
     |
     |  defaultTestResult(self)
     |
     |  doCleanups(self)
     |      Execute all cleanup functions. Normally called for you after
     |      tearDown.
     |
     |  enterContext(self, cm)
     |      Enters the supplied context manager.
     |
     |      If successful, also adds its __exit__ method as a cleanup
     |      function and returns the result of the __enter__ method.
     |
     |  fail(self, msg=None)
     |      Fail immediately, with the given message.
     |
     |  id(self)
     |
     |  run(self, result=None)
     |
     |  setUp(self)
     |      Hook method for setting up the test fixture before exercising it.
     |
     |  shortDescription(self)
     |      Returns a one-line description of the test, or None if no
     |      description has been provided.
     |
     |      The default implementation of this method returns the first line of
     |      the specified test method's docstring.
     |
     |  skipTest(self, reason)
     |      Skip this test.
     |
     |  subTest(self, msg=<object object at 0x0000023FC3E68860>, **params)
     |      Return a context manager that will return the enclosed block
     |      of code in a subtest identified by the optional message and
     |      keyword parameters.  A failure in the subtest marks the test
     |      case as failed but resumes execution at the end of the enclosed
     |      block, allowing further test code to be executed.
     |
     |  tearDown(self)
     |      Hook method for deconstructing the test fixture after testing it.
     |
     |  ----------------------------------------------------------------------
     |  Class methods inherited from unittest.case.TestCase:
     |
     |  __init_subclass__(*args, **kwargs)
     |      This method is called when a class is subclassed.
     |
     |      The default implementation does nothing. It may be
     |      overridden to extend subclasses.
     |
     |  addClassCleanup(function, /, *args, **kwargs)
     |      Same as addCleanup, except the cleanup items are called even if
     |      setUpClass fails (unlike tearDownClass).
     |
     |  doClassCleanups()
     |      Execute all class cleanup functions. Normally called for you after
     |      tearDownClass.
     |
     |  enterClassContext(cm)
     |      Same as enterContext, but class-wide.
     |
     |  setUpClass()
     |      Hook method for setting up class fixture before running tests in the class.
     |
     |  tearDownClass()
     |      Hook method for deconstructing the class fixture after running all tests in the class.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from unittest.case.TestCase:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes inherited from unittest.case.TestCase:
     |
     |  failureException = <class 'AssertionError'>
     |      Assertion failed.
     |
     |
     |  longMessage = True
     |
     |  maxDiff = 640

FUNCTIONS
    pytest_configure(config)
        Configure pytest.

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\python\testing\examples\test_example.py


