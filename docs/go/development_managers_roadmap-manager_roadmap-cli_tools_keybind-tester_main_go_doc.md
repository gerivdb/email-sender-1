# Package main

keybind-tester - Tool for testing and validating TaskMaster CLI key bindings


## Types

### CoverageReport

CoverageReport provides coverage analysis of key bindings


### PerformanceMetrics

PerformanceMetrics tracks performance of key binding operations


### TestResult

TestResult represents the result of a key binding test


### TesterModel

TesterModel represents the TUI model for interactive testing


#### Methods

##### TesterModel.Init

TUI Implementation


```go
func (m *TesterModel) Init() tea.Cmd
```

##### TesterModel.Update

```go
func (m *TesterModel) Update(msg tea.Msg) (tea.Model, tea.Cmd)
```

##### TesterModel.View

```go
func (m *TesterModel) View() string
```

