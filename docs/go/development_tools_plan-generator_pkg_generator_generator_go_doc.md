# Package generator

Package generator implements task and phase generation functions


## Functions

### CalculateMaxDepth

CalculateMaxDepth calcule la profondeur maximale d'une tâche en incluant ses sous-tâches


```go
func CalculateMaxDepth(task models.Task) int
```

### GenerateNestedTasks

GenerateNestedTasks génère une structure de tâches imbriquée avec une profondeur spécifiée


```go
func GenerateNestedTasks(baseID string, label string, description string, currentLevel int, maxDepth int) []models.Task
```

### GeneratePhases

GeneratePhases génère toutes les phases du plan


```go
func GeneratePhases(count int, maxTaskDepth int) []models.Phase
```

### GenerateTasksForPhase

GenerateTasksForPhase génère des tâches pour une phase spécifique avec une profondeur donnée


```go
func GenerateTasksForPhase(phaseNum int, maxTaskDepth int) []models.Task
```

### RenderTasksHierarchy

RenderTasksHierarchy génère le contenu Markdown pour une tâche et ses sous-tâches


```go
func RenderTasksHierarchy(task models.Task, level int) string
```

