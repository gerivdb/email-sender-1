package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings" // Import du package strings
)

func main() {
	fmt.Println("Scanning for observability sources...")

	var observabilitySources []string

	filepath.Walk(".", func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if info.IsDir() {
			// Ajout de logs pour ignorer les répertoires
			fmt.Printf("Ignoré (répertoire) : %s\n", path)
			return nil
		}

		if info.Name() == ".git" || info.Name() == ".github" || info.Name() == "node_modules" {
			// Ajout de logs pour ignorer les répertoires exclus
			fmt.Printf("Ignoré (répertoire exclu) : %s\n", path)
			return filepath.SkipDir
		}

		// Ajout de logs pour afficher le fichier en cours d'analyse
		fmt.Printf("Analyse du fichier : %s\n", path)

		fileContent, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		contentStr := string(fileContent)

		// Ajout de logs pour afficher le contenu du fichier (tronqué pour éviter les logs trop volumineux)
		fmt.Printf("Contenu du fichier (tronqué) : %s\n", truncateString(contentStr, 200))

		if strings.Contains(contentStr, "logger.") || strings.Contains(contentStr, "metric.") || strings.Contains(contentStr, "report.") {
			observabilitySources = append(observabilitySources, path)
			// Ajout de logs pour indiquer une correspondance
			fmt.Printf("Correspondance trouvée dans : %s\n", path)
		}

		return nil
	})

	fmt.Println("Found observability sources:")
	for _, source := range observabilitySources {
		fmt.Println(source)
	}
}

// Fonction utilitaire pour tronquer une chaîne de caractères
func truncateString(s string, maxLen int) string {
	if len(s) > maxLen {
		return s[:maxLen] + "..."
	}
	return s
}
