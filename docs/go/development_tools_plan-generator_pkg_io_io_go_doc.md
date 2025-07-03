# Package io

Package io implements file I/O operations for the plan generator


## Functions

### ExportPlanToJSON

ExportPlanToJSON exporte un plan au format JSON


```go
func ExportPlanToJSON(plan *models.Plan, outputDir, version, title string) (string, error)
```

### GenerateMarkdown

GenerateMarkdown génère le contenu Markdown du plan de développement


```go
func GenerateMarkdown(plan *models.Plan) string
```

### ImportPlanFromJSON

ImportPlanFromJSON importe un plan depuis un fichier JSON


```go
func ImportPlanFromJSON(filePath string) (*models.Plan, error)
```

### ReadExistingPlanMD

ReadExistingPlanMD lit un plan existant au format Markdown pour en extraire les métadonnées
Cette fonction est utilisée pour mettre à jour un plan existant


```go
func ReadExistingPlanMD(filePath string) (*models.Plan, error)
```

### SavePlanToFile

SavePlanToFile sauvegarde le plan généré dans un fichier Markdown


```go
func SavePlanToFile(content, outputDir, version, title string) (string, error)
```

