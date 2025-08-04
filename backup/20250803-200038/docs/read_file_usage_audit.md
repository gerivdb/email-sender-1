# Audit usages read_file

Ce rapport liste tous les appels détectés à la fonction `read_file` dans le dépôt.

## Résumé
- Nombre total d'appels détectés: 10

## Détails des Usages

| Fichier | Ligne | Extrait |
|---|---|---|
| cmd\audit_read_file\audit_read_file.go | 42 | `if strings.Contains(line, "read_file") { // Simple string match for "read_file"` |
| cmd\audit_read_file\audit_read_file.go | 72 | `fmt.Println("# Audit usages read_file\n")` |
| cmd\audit_read_file\audit_read_file.go | 73 | `fmt.Println("Ce rapport liste tous les appels détectés à la fonction `read_file` dans le dépôt.\n")` |
| cmd\audit_read_file\audit_read_file.go | 79 | `fmt.Println("Aucun usage de `read_file` n'a été trouvé.")` |
| cmd\gap_analysis.go | 9 | `fmt.Println("# Analyse d'écart de read_file")` |
| cmd\gen_read_file_spec.go | 9 | `fmt.Println("# Spécification fonctionnelle et technique read_file")` |
| cmd\gen_read_file_spec.go | 23 | `fmt.Println("// pkg/common/read_file.go")` |
| development\managers\advanced-autonomy-manager\internal\coordination\master_orchestrator.go | 668 | `consolidated/plan_ameliorations_read_file.md` |
| development\managers\advanced-autonomy-manager\internal\coordination\master_orchestrator.go | 694 | `consolidated/plan_ameliorations_read_file.md` |
| development\managers\advanced-autonomy-manager\internal\coordination\master_orchestrator.go | 713 | `consolidated/plan_ameliorations_read_file.md` |

## Contexte des Usages

### Usage 1: cmd\audit_read_file\audit_read_file.go:42
```
		lines := strings.Split(string(content), "\n")
		for i, line := range lines {
			if strings.Contains(line, "read_file") { // Simple string match for "read_file"
				// Capture context: 2 lines before, the line itself, and 2 lines after
				contextLines := []string{}
```

### Usage 2: cmd\audit_read_file\audit_read_file.go:72
```
	}

	fmt.Println("# Audit usages read_file\n")
	fmt.Println("Ce rapport liste tous les appels détectés à la fonction `read_file` dans le dépôt.\n")
	fmt.Println("## Résumé")
```

### Usage 3: cmd\audit_read_file\audit_read_file.go:73
```

	fmt.Println("# Audit usages read_file\n")
	fmt.Println("Ce rapport liste tous les appels détectés à la fonction `read_file` dans le dépôt.\n")
	fmt.Println("## Résumé")
	fmt.Printf("- Nombre total d'appels détectés: %d\n", len(usages))
```

### Usage 4: cmd\audit_read_file\audit_read_file.go:79
```

	if len(usages) == 0 {
		fmt.Println("Aucun usage de `read_file` n'a été trouvé.")
		return
	}
```

### Usage 5: cmd\gap_analysis.go:9
```

func main() {
	fmt.Println("# Analyse d'écart de read_file")
	fmt.Println("")
	fmt.Println("| Besoin utilisateur | Couvert par l'existant | Priorité | Suggestion |")
```

### Usage 6: cmd\gen_read_file_spec.go:9
```

func main() {
	fmt.Println("# Spécification fonctionnelle et technique read_file")
	fmt.Println("")
	fmt.Println("## 1. Fonctionnalités")
```

### Usage 7: cmd\gen_read_file_spec.go:23
```
	fmt.Println("")
	fmt.Println("```go")
	fmt.Println("// pkg/common/read_file.go")
	fmt.Println("package common")
	fmt.Println("")
```

### Usage 8: development\managers\advanced-autonomy-manager\internal\coordination\master_orchestrator.go:668
```
development/managers/advanced-autonomy-manager/internal/monitoring/trend_analysis.go
.golangci.yaml
consolidated/plan_ameliorations_read_file.md
development/managers/advanced-autonomy-manager/internal/coordination/master_orchestrator.go

```

### Usage 9: development\managers\advanced-autonomy-manager\internal\coordination\master_orchestrator.go:694
```
C:/response_81ee3f5e-92d3-4fd2-a424-19b9572a244c/0
C:/response_c8819f1d-16f5-497f-8c71-2da0b3074965/0
consolidated/plan_ameliorations_read_file.md
development/managers/advanced-autonomy-manager/internal/coordination/master_orchestrator.go

```

### Usage 10: development\managers\advanced-autonomy-manager\internal\coordination\master_orchestrator.go:713
```
development/managers/advanced-autonomy-manager/internal/monitoring/trend_analysis.go
.golangci.yaml
consolidated/plan_ameliorations_read_file.md
development/managers/advanced-autonomy-manager/internal/coordination/master_orchestrator.go

```

