# Package tui

## Types

### HierarchyKeyMap

HierarchyKeyMap defines keyboard shortcuts for hierarchy navigation


#### Methods

##### HierarchyKeyMap.FullHelp

FullHelp implements help.KeyMap


```go
func (k HierarchyKeyMap) FullHelp() [][]key.Binding
```

##### HierarchyKeyMap.ShortHelp

ShortHelp implements help.KeyMap


```go
func (k HierarchyKeyMap) ShortHelp() []key.Binding
```

### HierarchyModel

HierarchyModel represents the TUI model for hierarchical navigation


#### Methods

##### HierarchyModel.Init

Init implements tea.Model


```go
func (m HierarchyModel) Init() tea.Cmd
```

##### HierarchyModel.Update

Update implements tea.Model


```go
func (m HierarchyModel) Update(msg tea.Msg) (tea.Model, tea.Cmd)
```

##### HierarchyModel.View

View implements tea.Model


```go
func (m HierarchyModel) View() string
```

### PriorityMode

PriorityMode represents different priority view modes


### RoadmapModel

RoadmapModel is the main bubbletea model


#### Methods

##### RoadmapModel.Init

Init initializes the model


```go
func (m *RoadmapModel) Init() tea.Cmd
```

##### RoadmapModel.Update

Update handles messages and updates the model


```go
func (m *RoadmapModel) Update(msg tea.Msg) (tea.Model, tea.Cmd)
```

##### RoadmapModel.View

View renders the TUI based on current view mode


```go
func (m *RoadmapModel) View() string
```

### ViewMode

ViewMode represents different TUI view modes


## Variables

### SelectedStyle, NormalStyle, MetaStyle, HeaderStyle, HelpStyle

Shared styles for TUI components


```go
var (
	SelectedStyle	= lipgloss.NewStyle().
			Foreground(lipgloss.Color("12")).
			Bold(true)

	NormalStyle	= lipgloss.NewStyle().
			Foreground(lipgloss.Color("15"))

	MetaStyle	= lipgloss.NewStyle().
			Foreground(lipgloss.Color("8"))

	HeaderStyle	= lipgloss.NewStyle().
			Bold(true).
			Foreground(lipgloss.Color("14")).
			Border(lipgloss.DoubleBorder()).
			Padding(0, 1)

	HelpStyle	= lipgloss.NewStyle().
			Foreground(lipgloss.Color("8")).
			Italic(true)
)
```

