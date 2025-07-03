# Package utils

Package utils provides utility functions for the plan generator


## Functions

### GenerateTOC

GenerateTOC génère la table des matières


```go
func GenerateTOC(count int) string
```

### PhaseDescription

PhaseDescription renvoie une description par défaut pour une phase en fonction de son numéro


```go
func PhaseDescription(number int) string
```

### SanitizeTitle

SanitizeTitle nettoie un titre pour l'utiliser dans un nom de fichier


```go
func SanitizeTitle(title string) string
```

