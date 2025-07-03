# Package main

## Types

### ConsolidationConfig

ConsolidationConfig configuration pour la consolidation


### ConsolidationResult

ConsolidationResult résultat de la consolidation


### QdrantConsolidator

QdrantConsolidator gestionnaire de consolidation


#### Methods

##### QdrantConsolidator.FindDuplicateClients

FindDuplicateClients trouve tous les clients Qdrant dupliqués


```go
func (qc *QdrantConsolidator) FindDuplicateClients() ([]string, error)
```

##### QdrantConsolidator.RemoveDuplicateClientFiles

RemoveDuplicateClientFiles supprime les fichiers de clients dupliqués


```go
func (qc *QdrantConsolidator) RemoveDuplicateClientFiles() error
```

##### QdrantConsolidator.RunConsolidation

RunConsolidation exécute la consolidation complète


```go
func (qc *QdrantConsolidator) RunConsolidation() error
```

##### QdrantConsolidator.UpdateClientUsage

UpdateClientUsage met à jour l'utilisation des clients dans le code


```go
func (qc *QdrantConsolidator) UpdateClientUsage(filePath string) error
```

##### QdrantConsolidator.UpdateImports

UpdateImports met à jour les imports dans les fichiers Go


```go
func (qc *QdrantConsolidator) UpdateImports(filePath string) error
```

##### QdrantConsolidator.UpdateTestFiles

UpdateTestFiles met à jour les fichiers de tests


```go
func (qc *QdrantConsolidator) UpdateTestFiles() error
```

##### QdrantConsolidator.ValidateConsolidation

ValidateConsolidation valide que la consolidation s'est bien passée


```go
func (qc *QdrantConsolidator) ValidateConsolidation() error
```

