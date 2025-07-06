# Package adapters

## Types

### DuplicatedFileInfo

DuplicatedFileInfo informations sur un fichier dupliqué


### DuplicationContext

DuplicationContext contexte enrichi pour les erreurs de duplication
Micro-étape 8.3.1 : Ajouter un champ DuplicationContext à la structure ErrorEntry


### DuplicationCorrelation

DuplicationCorrelation corrélation entre erreurs et duplications


### DuplicationError

DuplicationError représente une erreur de duplication détectée


### DuplicationErrorHandler

DuplicationErrorHandler gère les erreurs liées à la détection de duplications
Micro-étape 8.2.1 : Adapter Find-CodeDuplication.ps1 pour signaler les erreurs via ErrorManager


#### Methods

##### DuplicationErrorHandler.GenerateDuplicationError

GenerateDuplicationError crée une erreur de duplication standardisée


```go
func (d *DuplicationErrorHandler) GenerateDuplicationError(sourceFile, duplicateFile string, similarityScore float64) DuplicationError
```

##### DuplicationErrorHandler.IntegrateWithFindCodeDuplication

IntegrateWithFindCodeDuplication interface avec le script PowerShell Find-CodeDuplication.ps1


```go
func (d *DuplicationErrorHandler) IntegrateWithFindCodeDuplication(scriptPath, targetDirectory string) error
```

##### DuplicationErrorHandler.ProcessDuplicationReport

ProcessDuplicationReport traite un rapport de duplication
Micro-étape 8.2.3 : Implémenter la surveillance des rapports de duplication (duplication_report.json)


```go
func (d *DuplicationErrorHandler) ProcessDuplicationReport(reportPath string) error
```

##### DuplicationErrorHandler.SetErrorCallback

SetErrorCallback définit le callback pour traiter les erreurs détectées
Micro-étape 8.2.2 : Créer DuplicationErrorHandler() pour traiter les erreurs de détection


```go
func (d *DuplicationErrorHandler) SetErrorCallback(callback func(DuplicationError))
```

##### DuplicationErrorHandler.WatchDuplicationReports

WatchDuplicationReports surveille les nouveaux rapports de duplication


```go
func (d *DuplicationErrorHandler) WatchDuplicationReports() error
```

### DuplicationMetrics

DuplicationMetrics métriques de duplication pour analyse
Micro-étape 8.3.3 : Créer des corrélations entre erreurs et duplications détectées


### DuplicationReport

DuplicationReport rapport de détection de duplications


### DuplicationSummary

DuplicationSummary résumé d'une duplication


### EnhancedErrorEntry

EnhancedErrorEntry structure ErrorEntry enrichie avec contexte de duplication
Micro-étape 8.3.2 : Inclure les scores de similarité et références de fichiers dupliqués


### ScriptInfo

ScriptInfo informations sur un script détecté


### ScriptInventoryAdapter

ScriptInventoryAdapter gère l'intégration avec l'infrastructure PowerShell existante


#### Methods

##### ScriptInventoryAdapter.ConnectToScriptInventory

ConnectToScriptInventory établit la connexion avec le module PowerShell
Micro-étape 8.1.2 : Implémenter ConnectToScriptInventory() pour interfacer avec le module PowerShell


```go
func (s *ScriptInventoryAdapter) ConnectToScriptInventory() error
```

##### ScriptInventoryAdapter.ExecuteScriptInventory

ExecuteScriptInventory exécute le module ScriptInventoryManager
Micro-étape 8.1.3 : Créer des bindings Go-PowerShell via os/exec pour appeler les fonctions du module


```go
func (s *ScriptInventoryAdapter) ExecuteScriptInventory(targetPath string) (*ScriptInventoryResult, error)
```

##### ScriptInventoryAdapter.GetScriptDependencies

GetScriptDependencies récupère les dépendances d'un script spécifique


```go
func (s *ScriptInventoryAdapter) GetScriptDependencies(scriptPath string) ([]string, error)
```

### ScriptInventoryConfig

ScriptInventoryConfig configuration pour l'adaptateur


### ScriptInventoryResult

ScriptInventoryResult résultat de l'exécution du script d'inventaire


## Functions

### CalculateCorrelationScore

CalculateCorrelationScore calcule le score de corrélation entre une erreur et une duplication


```go
func CalculateCorrelationScore(errorEntry *EnhancedErrorEntry, duplication DuplicationError) float64
```

### ExampleUsageDemo

Exemple d'utilisation des adaptateurs Infrastructure PowerShell/Python


```go
func ExampleUsageDemo()
```

