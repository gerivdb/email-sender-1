# Package main

Ultra-Advanced 8-Level Branching Framework - Integration Test Runner


## Types

### IntegrationTestRunner

IntegrationTestRunner manages comprehensive testing


#### Methods

##### IntegrationTestRunner.GenerateReport

GenerateReport creates a comprehensive test report


```go
func (itr *IntegrationTestRunner) GenerateReport(totalDuration time.Duration)
```

##### IntegrationTestRunner.RunAllTests

RunAllTests executes the complete test suite


```go
func (itr *IntegrationTestRunner) RunAllTests()
```

##### IntegrationTestRunner.RunTest

RunTest executes a single test and records the result


```go
func (itr *IntegrationTestRunner) RunTest(name string, level int, description string, testFunc func() error)
```

##### IntegrationTestRunner.TestIntegrations

TestIntegrations tests all external integrations


```go
func (itr *IntegrationTestRunner) TestIntegrations()
```

##### IntegrationTestRunner.TestLevel1_MicroSessions

TestLevel1_MicroSessions tests atomic branching operations


```go
func (itr *IntegrationTestRunner) TestLevel1_MicroSessions()
```

##### IntegrationTestRunner.TestLevel2_EventDriven

TestLevel2_EventDriven tests automatic branch creation on events


```go
func (itr *IntegrationTestRunner) TestLevel2_EventDriven()
```

##### IntegrationTestRunner.TestLevel3_MultiDimensional

TestLevel3_MultiDimensional tests branching across multiple dimensions


```go
func (itr *IntegrationTestRunner) TestLevel3_MultiDimensional()
```

##### IntegrationTestRunner.TestLevel4_ContextualMemory

TestLevel4_ContextualMemory tests intelligent context-aware branching


```go
func (itr *IntegrationTestRunner) TestLevel4_ContextualMemory()
```

##### IntegrationTestRunner.TestLevel5_Temporal

TestLevel5_Temporal tests historical state recreation


```go
func (itr *IntegrationTestRunner) TestLevel5_Temporal()
```

##### IntegrationTestRunner.TestLevel6_PredictiveAI

TestLevel6_PredictiveAI tests neural network-based predictions


```go
func (itr *IntegrationTestRunner) TestLevel6_PredictiveAI()
```

##### IntegrationTestRunner.TestLevel7_BranchingAsCode

TestLevel7_BranchingAsCode tests programmatic branching definitions


```go
func (itr *IntegrationTestRunner) TestLevel7_BranchingAsCode()
```

##### IntegrationTestRunner.TestLevel8_Quantum

TestLevel8_Quantum tests superposition of multiple states


```go
func (itr *IntegrationTestRunner) TestLevel8_Quantum()
```

### TestResult

TestResult represents the result of a test


