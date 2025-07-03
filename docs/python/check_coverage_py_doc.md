============================= test session starts =============================
platform win32 -- Python 3.12.6, pytest-8.3.5, pluggy-1.5.0 -- C:\Python312\python.exe
cachedir: .pytest_cache
hypothesis profile 'default' -> database=DirectoryBasedExampleDatabase(WindowsPath('D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/.hypothesis/examples'))
metadata: {'Python': '3.12.6', 'Platform': 'Windows-10-10.0.19045-SP0', 'Packages': {'pytest': '8.3.5', 'pluggy': '1.5.0'}, 'Plugins': {'allure-pytest': '2.14.0', 'anyio': '4.8.0', 'hypothesis': '6.127.4', 'langsmith': '0.3.18', 'asyncio': '0.25.3', 'cov': '6.1.1', 'html': '4.1.1', 'metadata': '3.1.1', 'mock': '3.14.0', 'testmon': '2.1.3', 'xdist': '3.6.1', 'requests-mock': '1.11.0', 'typeguard': '4.4.2'}, 'JAVA_HOME': 'C:\\Program Files\\Eclipse Adoptium\\jdk-17.0.15.6-hotspot\\'}
rootdir: D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1
configfile: pytest.ini
plugins: allure-pytest-2.14.0, anyio-4.8.0, hypothesis-6.127.4, langsmith-0.3.18, asyncio-0.25.3, cov-6.1.1, html-4.1.1, metadata-3.1.1, mock-3.14.0, testmon-2.1.3, xdist-3.6.1, requests-mock-1.11.0, typeguard-4.4.2
asyncio: mode=Mode.AUTO, asyncio_default_fixture_loop_scope=function
collecting ... collected 34 items

development/scripts/python/testing/examples/test_example.py::TestExampleSuccess::test_addition PASSED [  2%]
development/scripts/python/testing/examples/test_example.py::TestExampleSuccess::test_division PASSED [  5%]
development/scripts/python/testing/examples/test_example.py::TestExampleSuccess::test_multiplication PASSED [  8%]
development/scripts/python/testing/examples/test_example.py::TestExampleSuccess::test_subtraction PASSED [ 11%]
development/scripts/python/testing/examples/test_example.py::TestExampleAssertions::test_container_assertions PASSED [ 14%]
development/scripts/python/testing/examples/test_example.py::TestExampleAssertions::test_different_assertions PASSED [ 17%]
development/scripts/python/testing/examples/test_example.py::TestExampleAssertions::test_exception_handling PASSED [ 20%]
development/scripts/python/testing/examples/test_example.py::TestExampleAssertions::test_string_assertions PASSED [ 23%]
development/scripts/python/testing/examples/test_example.py::TestExampleError::test_exception_details PASSED [ 26%]
development/scripts/python/testing/examples/test_example.py::TestExampleError::test_type_error_details PASSED [ 29%]
development/scripts/python/testing/examples/test_example.py::TestExampleError::test_value_error_details PASSED [ 32%]
development/scripts/python/testing/examples/test_example.py::TestParametrized::test_multiplication_by_two PASSED [ 35%]
development/scripts/python/testing/examples/test_example.py::TestParametrized::test_multiplication_by_two_0 PASSED [ 38%]
development/scripts/python/testing/examples/test_example.py::TestParametrized::test_multiplication_by_two_2 PASSED [ 41%]
development/scripts/python/testing/examples/test_example.py::TestParametrized::test_multiplication_by_two_3 PASSED [ 44%]
development/scripts/python/testing/examples/test_example.py::TestParametrized::test_multiplication_by_two_float PASSED [ 47%]
development/scripts/python/testing/examples/test_example.py::TestParametrized::test_multiplication_by_two_large PASSED [ 50%]
development/scripts/python/testing/examples/test_example.py::TestParametrized::test_multiplication_by_two_neg1 PASSED [ 52%]
development/scripts/python/testing/examples/test_example.py::TestParametrized::test_string_length PASSED [ 55%]
development/scripts/python/testing/examples/test_example.py::TestParametrized::test_string_length_digits PASSED [ 58%]
development/scripts/python/testing/examples/test_example.py::TestParametrized::test_string_length_empty PASSED [ 61%]
development/scripts/python/testing/examples/test_example.py::TestParametrized::test_string_length_hello PASSED [ 64%]
development/scripts/python/testing/examples/test_example.py::TestParametrized::test_string_length_python PASSED [ 67%]
development/scripts/python/testing/examples/test_example.py::TestParametrized::test_string_length_spaces PASSED [ 70%]
development/scripts/python/testing/examples/test_example.py::TestParametrized::test_with_context PASSED [ 73%]
development/scripts/python/testing/examples/test_example.py::TestAsyncExample::test_async_exception PASSED [ 76%]
development/scripts/python/testing/examples/test_example.py::TestAsyncExample::test_async_operation PASSED [ 79%]
development/scripts/python/testing/examples/test_example.py::TestCoverage::test_async_wrapper PASSED [ 82%]
development/scripts/python/testing/examples/test_example.py::TestCoverage::test_exception_handling_deep PASSED [ 85%]
development/scripts/python/testing/examples/test_example.py::TestCoverage::test_main_patching PASSED [ 88%]
development/scripts/python/testing/examples/test_example.py::TestCoverage::test_pytest_configure PASSED [ 91%]
development/scripts/python/testing/examples/test_example.py::TestMainExecution::test_main_execution PASSED [ 94%]
development/scripts/python/testing/examples/test_example.py::TestExhaustiveCoverage::test_parametrized_methods_directly PASSED [ 97%]
development/scripts/python/testing/examples/test_example.py::TestFinalCoverage::test_full_coverage PASSED [100%]

=============================== tests coverage ================================
_______________ coverage: platform win32, python 3.12.6-final-0 _______________

Name                                                          Stmts   Miss  Cover   Missing
-------------------------------------------------------------------------------------------
check_coverage.py                                                 0      0   100%
development\scripts\python\testing\examples\test_example.py       0      0   100%
run_perfect_coverage.py                                           0      0   100%
-------------------------------------------------------------------------------------------
TOTAL                                                             0      0   100%
============================= 34 passed in 2.79s ==============================
Name                                                          Stmts   Miss  Cover
---------------------------------------------------------------------------------
development\scripts\python\testing\examples\test_example.py       0      0   100%
---------------------------------------------------------------------------------
TOTAL                                                             0      0   100%
Total coverage: 100.0%
No Python documentation found for 'check_coverage.py'.
Use help() to get the interactive help utility.
Use help(str) for help on the str class.
