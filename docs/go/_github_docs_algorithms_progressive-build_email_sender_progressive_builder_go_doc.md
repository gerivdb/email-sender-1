# Package main

## Types

### BuildComponent

BuildComponent represents a component within a build layer


### BuildConfig

BuildConfig holds configuration for the build strategy


### BuildLayer

BuildLayer represents a layer in the EMAIL_SENDER_1 architecture


### BuildStrategy

BuildStrategy represents the overall build strategy


#### Methods

##### BuildStrategy.DisplaySummary

DisplaySummary displays a summary of the build results


```go
func (bs *BuildStrategy) DisplaySummary()
```

##### BuildStrategy.ExecuteProgressiveBuild

ExecuteProgressiveBuild executes the progressive build strategy


```go
func (bs *BuildStrategy) ExecuteProgressiveBuild() error
```

##### BuildStrategy.GenerateReport

GenerateReport generates a comprehensive build report


```go
func (bs *BuildStrategy) GenerateReport(outputFile string) error
```

##### BuildStrategy.InitializeBuildStrategy

InitializeBuildStrategy initializes the build strategy with EMAIL_SENDER_1 layers


```go
func (bs *BuildStrategy) InitializeBuildStrategy()
```

##### BuildStrategy.LoadConfig

LoadConfig loads build configuration from file


```go
func (bs *BuildStrategy) LoadConfig(configFile string) error
```

##### BuildStrategy.ValidateProjectStructure

ValidateProjectStructure validates the EMAIL_SENDER_1 project structure


```go
func (bs *BuildStrategy) ValidateProjectStructure() error
```

### TestResult

TestResult represents test execution results


