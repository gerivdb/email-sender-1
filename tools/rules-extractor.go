// tools/rules-extractor.go
// Extraction automatisée des règles Roo-Code (v107)
// Génère un rapport Markdown d’inventaire des règles à partir des fichiers .roo/rules/*.md

package main

import (
	"bufio"
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"strings"
	"time"
)

func main() {
	start := time.Now()
	logFile, err := os.Create("rapport-inventaire-rules.log")
	if err != nil {
		fmt.Println("Erreur création log:", err)
		return
	}
	defer logFile.Close()
	logger := log.New(logFile, "", log.LstdFlags)
	logger.Println("Début extraction des règles Roo-Code")

	rulesDir := ".roo/rules"
	reportFile := "rapport-inventaire-rules.md"
	files, err := filepath.Glob(filepath.Join(rulesDir, "*.md"))
	if err != nil || len(files) == 0 {
		logger.Println("Aucun fichier de règles trouvé dans", rulesDir)
		fmt.Println("Aucun fichier de règles trouvé.")
		return
	}

	report, err := os.Create(reportFile)
	if err != nil {
		logger.Println("Erreur création rapport:", err)
		fmt.Println("Erreur création rapport:", err)
		return
	}
	defer report.Close()

	fmt.Fprintf(report, "# Rapport d’inventaire des règles Roo-Code\n\n")
	fmt.Fprintf(report, "_Généré le %s_\n\n", time.Now().Format(time.RFC3339))
	fmt.Fprintf(report, "| Fichier | Titre | Niveau |\n|---|---|---|\n")

	for _, file := range files {
		f, err := os.Open(file)
		if err != nil {
			logger.Println("Erreur ouverture fichier:", file, err)
			continue
		}
		defer f.Close()
		reader := bufio.NewReader(f)
		for {
			line, err := reader.ReadString('\n')
			if err != nil && err != io.EOF {
				logger.Println("Erreur lecture ligne:", err)
				break
			}
			trimmed := strings.TrimSpace(line)
			if strings.HasPrefix(trimmed, "# ") {
				fmt.Fprintf(report, "| %s | %s | 1 |\n", filepath.Base(file), strings.TrimPrefix(trimmed, "# "))
			} else if strings.HasPrefix(trimmed, "## ") {
				fmt.Fprintf(report, "| %s | %s | 2 |\n", filepath.Base(file), strings.TrimPrefix(trimmed, "## "))
			}
			if err == io.EOF {
				break
			}
		}
		logger.Println("Fichier traité:", file)
	}
	logger.Printf("Extraction terminée en %s\n", time.Since(start))
	fmt.Println("Extraction des règles terminée. Rapport généré:", reportFile)
}
