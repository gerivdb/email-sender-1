package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

func main() {
	inputPath := "plans_impactes_jan.md"
	outputPath := "plans_impactes_jan_cleaned.md"
	baseDir := "projet/roadmaps/plans/consolidated/"

	file, err := os.Open(inputPath)
	if err != nil {
		fmt.Printf("Erreur lors de l'ouverture du fichier %s: %v\n", inputPath, err)
		os.Exit(1)
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	uniquePaths := make(map[string]bool)
	var cleanedPaths []string

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			continue
		}

		// Nettoyer le chemin pour le rendre relatif et uniforme
		// Supprimer les préfixes de chemin absolu et normaliser
		relativePath := strings.ReplaceAll(line, `\`, `/`)
		if strings.HasPrefix(relativePath, "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/") {
			relativePath = strings.TrimPrefix(relativePath, "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/")
		}

		// Vérifier si le chemin contient le baseDir
		if !strings.HasPrefix(relativePath, baseDir) {
			// Si ce n'est pas le cas, c'est un chemin qui n'est pas dans le répertoire ciblé.
			// On peut choisir de l'ignorer ou de le reporter. Pour l'instant, on l'ignore.
			continue
		}

		if _, exists := uniquePaths[relativePath]; !exists {
			uniquePaths[relativePath] = true
			cleanedPaths = append(cleanedPaths, relativePath)
		}
	}

	if err := scanner.Err(); err != nil {
		fmt.Printf("Erreur lors de la lecture du fichier %s: %v\n", inputPath, err)
		os.Exit(1)
	}

	outputFile, err := os.Create(outputPath)
	if err != nil {
		fmt.Printf("Erreur lors de la création du fichier %s: %v\n", outputPath, err)
		os.Exit(1)
	}
	defer outputFile.Close()

	for _, p := range cleanedPaths {
		_, err := outputFile.WriteString(p + "\n")
		if err != nil {
			fmt.Printf("Erreur lors de l'écriture dans le fichier %s: %v\n", outputPath, err)
			os.Exit(1)
		}
	}

	fmt.Printf("Liste des plans nettoyée et enregistrée dans %s\n", outputPath)
}
