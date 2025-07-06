Help on module test_cognitive_architecture:

NAME
    test_cognitive_architecture - Tests unitaires pour l'architecture cognitive des roadmaps.

DESCRIPTION
    Ce module contient les tests unitaires pour l'architecture cognitive des roadmaps.

CLASSES
    unittest.case.TestCase(builtins.object)
        TestBuilding
        TestCity
        TestCognitiveNode
        TestContinent
        TestCosmos
        TestDistrict
        TestGalaxy
        TestPlanet
        TestRegion
        TestStellarSystem
        TestStreet

    class TestBuilding(unittest.case.TestCase)
     |  TestBuilding(methodName='runTest')
     |
     |  Tests pour la classe Building.
     |
     |  Method resolution order:
     |      TestBuilding
     |      unittest.case.TestCase
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  test_init(self)
     |      Teste l'initialisation d'un n�ud BATIMENT.
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
     |  subTest(self, msg=<object object at 0x0000022D43538860>, **params)
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

    class TestCity(unittest.case.TestCase)
     |  TestCity(methodName='runTest')
     |
     |  Tests pour la classe City.
     |
     |  Method resolution order:
     |      TestCity
     |      unittest.case.TestCase
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  test_init(self)
     |      Teste l'initialisation d'un n�ud VILLE.
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
     |  subTest(self, msg=<object object at 0x0000022D43538860>, **params)
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

    class TestCognitiveNode(unittest.case.TestCase)
     |  TestCognitiveNode(methodName='runTest')
     |
     |  Tests pour la classe CognitiveNode.
     |
     |  Method resolution order:
     |      TestCognitiveNode
     |      unittest.case.TestCase
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  test_add_child(self)
     |      Teste l'ajout d'un enfant � un n�ud cognitif.
     |
     |  test_from_dict(self)
     |      Teste la cr�ation d'un n�ud cognitif � partir d'un dictionnaire.
     |
     |  test_init(self)
     |      Teste l'initialisation d'un n�ud cognitif.
     |
     |  test_init_with_values(self)
     |      Teste l'initialisation d'un n�ud cognitif avec des valeurs sp�cifiques.
     |
     |  test_remove_child(self)
     |      Teste la suppression d'un enfant d'un n�ud cognitif.
     |
     |  test_to_dict(self)
     |      Teste la conversion d'un n�ud cognitif en dictionnaire.
     |
     |  test_update_metadata(self)
     |      Teste la mise � jour des m�tadonn�es d'un n�ud cognitif.
     |
     |  test_update_status(self)
     |      Teste la mise � jour du statut d'un n�ud cognitif.
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
     |  subTest(self, msg=<object object at 0x0000022D43538860>, **params)
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

    class TestContinent(unittest.case.TestCase)
     |  TestContinent(methodName='runTest')
     |
     |  Tests pour la classe Continent.
     |
     |  Method resolution order:
     |      TestContinent
     |      unittest.case.TestCase
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  test_init(self)
     |      Teste l'initialisation d'un n�ud CONTINENT.
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
     |  subTest(self, msg=<object object at 0x0000022D43538860>, **params)
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

    class TestCosmos(unittest.case.TestCase)
     |  TestCosmos(methodName='runTest')
     |
     |  Tests pour la classe Cosmos.
     |
     |  Method resolution order:
     |      TestCosmos
     |      unittest.case.TestCase
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  test_init(self)
     |      Teste l'initialisation d'un n�ud COSMOS.
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
     |  subTest(self, msg=<object object at 0x0000022D43538860>, **params)
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

    class TestDistrict(unittest.case.TestCase)
     |  TestDistrict(methodName='runTest')
     |
     |  Tests pour la classe District.
     |
     |  Method resolution order:
     |      TestDistrict
     |      unittest.case.TestCase
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  test_init(self)
     |      Teste l'initialisation d'un n�ud QUARTIER.
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
     |  subTest(self, msg=<object object at 0x0000022D43538860>, **params)
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

    class TestGalaxy(unittest.case.TestCase)
     |  TestGalaxy(methodName='runTest')
     |
     |  Tests pour la classe Galaxy.
     |
     |  Method resolution order:
     |      TestGalaxy
     |      unittest.case.TestCase
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  test_init(self)
     |      Teste l'initialisation d'un n�ud GALAXIE.
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
     |  subTest(self, msg=<object object at 0x0000022D43538860>, **params)
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

    class TestPlanet(unittest.case.TestCase)
     |  TestPlanet(methodName='runTest')
     |
     |  Tests pour la classe Planet.
     |
     |  Method resolution order:
     |      TestPlanet
     |      unittest.case.TestCase
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  test_init(self)
     |      Teste l'initialisation d'un n�ud PLANETE.
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
     |  subTest(self, msg=<object object at 0x0000022D43538860>, **params)
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

    class TestRegion(unittest.case.TestCase)
     |  TestRegion(methodName='runTest')
     |
     |  Tests pour la classe Region.
     |
     |  Method resolution order:
     |      TestRegion
     |      unittest.case.TestCase
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  test_init(self)
     |      Teste l'initialisation d'un n�ud REGION.
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
     |  subTest(self, msg=<object object at 0x0000022D43538860>, **params)
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

    class TestStellarSystem(unittest.case.TestCase)
     |  TestStellarSystem(methodName='runTest')
     |
     |  Tests pour la classe StellarSystem.
     |
     |  Method resolution order:
     |      TestStellarSystem
     |      unittest.case.TestCase
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  test_init(self)
     |      Teste l'initialisation d'un n�ud SYSTEME STELLAIRE.
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
     |  subTest(self, msg=<object object at 0x0000022D43538860>, **params)
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

    class TestStreet(unittest.case.TestCase)
     |  TestStreet(methodName='runTest')
     |
     |  Tests pour la classe Street.
     |
     |  Method resolution order:
     |      TestStreet
     |      unittest.case.TestCase
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  test_init(self)
     |      Teste l'initialisation d'un n�ud RUE.
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
     |  subTest(self, msg=<object object at 0x0000022D43538860>, **params)
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

DATA
    parent_dir = r'D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1'

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\mcp\tests\roadmap\test_cognitive_architecture.py


