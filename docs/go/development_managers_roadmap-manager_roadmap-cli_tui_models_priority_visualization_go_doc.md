# Package models

## Types

### AnimationTickMsg

Message types


### InteractivePriorityWidget

InteractivePriorityWidget provides real-time priority adjustment


#### Methods

##### InteractivePriorityWidget.Init

Init implements tea.Model


```go
func (ipw *InteractivePriorityWidget) Init() tea.Cmd
```

##### InteractivePriorityWidget.IsActive

IsActive returns whether the widget is active


```go
func (ipw *InteractivePriorityWidget) IsActive() bool
```

##### InteractivePriorityWidget.SetActive

SetActive sets the active state


```go
func (ipw *InteractivePriorityWidget) SetActive(active bool)
```

##### InteractivePriorityWidget.SetItem

SetItem sets the current item for priority adjustment


```go
func (ipw *InteractivePriorityWidget) SetItem(item types.RoadmapItem)
```

##### InteractivePriorityWidget.Update

Update implements tea.Model


```go
func (ipw *InteractivePriorityWidget) Update(msg tea.Msg) (tea.Model, tea.Cmd)
```

##### InteractivePriorityWidget.View

View implements tea.Model


```go
func (ipw *InteractivePriorityWidget) View() string
```

### PriorityConfigUpdatedMsg

### PriorityDetailMsg

### PriorityItemSelectedMsg

Message types


### PriorityRefreshMsg

Message types for priority view communication


### PriorityView

PriorityView implements tea.Model for priority visualization


#### Methods

##### PriorityView.Init

Init implements tea.Model


```go
func (pv *PriorityView) Init() tea.Cmd
```

##### PriorityView.IsActive

IsActive returns whether the priority view is active


```go
func (pv *PriorityView) IsActive() bool
```

##### PriorityView.SetActive

SetActive sets the active state of the priority view


```go
func (pv *PriorityView) SetActive(active bool)
```

##### PriorityView.Update

Update implements tea.Model


```go
func (pv *PriorityView) Update(msg tea.Msg) (tea.Model, tea.Cmd)
```

##### PriorityView.View

View implements tea.Model


```go
func (pv *PriorityView) View() string
```

### PriorityViewMode

PriorityViewMode represents different priority view modes


### PriorityVisualization

PriorityVisualization provides ASCII graphics for priority data


#### Methods

##### PriorityVisualization.Init

Init implements tea.Model


```go
func (pv *PriorityVisualization) Init() tea.Cmd
```

##### PriorityVisualization.IsActive

IsActive returns whether the visualization is active


```go
func (pv *PriorityVisualization) IsActive() bool
```

##### PriorityVisualization.SetActive

SetActive sets the active state


```go
func (pv *PriorityVisualization) SetActive(active bool)
```

##### PriorityVisualization.Update

Update implements tea.Model


```go
func (pv *PriorityVisualization) Update(msg tea.Msg) (tea.Model, tea.Cmd)
```

##### PriorityVisualization.View

View implements tea.Model


```go
func (pv *PriorityVisualization) View() string
```

### VisualizationType

VisualizationType represents different visualization types


### WeightField

WeightField represents a configurable weight field


## Functions

### TestIntegration_PriorityViewAndVisualization

```go
func TestIntegration_PriorityViewAndVisualization(t *testing.T)
```

### TestPriorityEngine_Calculate

```go
func TestPriorityEngine_Calculate(t *testing.T)
```

### TestPriorityEngine_Rank

```go
func TestPriorityEngine_Rank(t *testing.T)
```

### TestPriorityEngine_WeightingConfig

```go
func TestPriorityEngine_WeightingConfig(t *testing.T)
```

### TestPriorityView_NewPriorityView

```go
func TestPriorityView_NewPriorityView(t *testing.T)
```

### TestPriorityVisualization_EdgeCases

```go
func TestPriorityVisualization_EdgeCases(t *testing.T)
```

### TestPriorityVisualization_NewPriorityVisualization

```go
func TestPriorityVisualization_NewPriorityVisualization(t *testing.T)
```

### TestPriorityVisualization_SetActive

```go
func TestPriorityVisualization_SetActive(t *testing.T)
```

### TestPriorityVisualization_View

```go
func TestPriorityVisualization_View(t *testing.T)
```

### TestPriorityVisualization_VisualizationTypes

```go
func TestPriorityVisualization_VisualizationTypes(t *testing.T)
```

