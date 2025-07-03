# Package testgen

Package testgen provides automatic test generation for RAG components
Time-Saving Method 4: Inverted TDD
ROI: +24h immediate + 42h/month (generates 90% of test boilerplate)


## Types

### BenchmarkCase

BenchmarkCase represents benchmark test case


### FunctionInfo

FunctionInfo represents a function to test


### GeneratorConfig

GeneratorConfig controls test generation behavior


### MockDefinition

MockDefinition represents a mock object


### MockMethod

MockMethod represents a mocked method


### Parameter

Parameter represents function parameter or return value


### TestCase

TestCase represents individual test case


### TestFunction

TestFunction represents a generated test function


### TestGenerator

TestGenerator automatically generates comprehensive tests


#### Methods

##### TestGenerator.GenerateTests

GenerateTests analyzes Go code and generates comprehensive tests


```go
func (tg *TestGenerator) GenerateTests(sourceFile string) (*TestSuite, error)
```

##### TestGenerator.WriteTestFile

WriteTestFile generates and writes the test file


```go
func (tg *TestGenerator) WriteTestFile(suite *TestSuite, outputPath string) error
```

### TestSuite

TestSuite represents a generated test suite


