package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync"
)

// ObservabilitySource représente une source d'observabilité détectée
type ObservabilitySource struct {
	Path    string `json:"path"`
	Type    string `json:"type"`            // "logger", "metric", "report"
	Content string `json:"content_snippet"` // Extrait du contenu
}

// ScannerConfig centralise les paramètres de configuration (SOLID : SRP)
type ScannerConfig struct {
	ExcludeDirs    []string
	MaxFileSize    int64
	MaxDepth       int
	OutputFileMD   string
	OutputFileJSON string
}

// DefaultScannerConfig fournit une configuration par défaut (KISS)
func DefaultScannerConfig() ScannerConfig {
	return ScannerConfig{
		ExcludeDirs:    []string{".git", ".github", "node_modules", "vendor", "logs"},
		MaxFileSize:    10 * 1024 * 1024, // 10MB
		MaxDepth:       10,
		OutputFileMD:   "manager_inventory.md",
		OutputFileJSON: "event_hooks.json",
	}
}

// scanFile analyse un fichier pour détecter les motifs d'observabilité
func scanFile(path string, content []byte) ([]ObservabilitySource, error) {
	var sources []ObservabilitySource
	contentStr := string(content)

	patterns := map[string]string{
		"logger.": "logger",
		"metric.": "metric",
		"report.": "report",
	}

	for pattern, srcType := range patterns {
		if strings.Contains(contentStr, pattern) {
			sources = append(sources, ObservabilitySource{
				Path:    path,
				Type:    srcType,
				Content: truncateString(contentStr, 200),
			})
		}
	}
	return sources, nil
}

// truncateString tronque une chaîne pour éviter les logs trop volumineux (DRY)
func truncateString(s string, maxLen int) string {
	if len(s) > maxLen {
		return s[:maxLen] + "..."
	}
	return s
}

func main() {
	config := DefaultScannerConfig()

	// Initialisation des résultats
	var mu sync.Mutex
	var observabilitySources []ObservabilitySource

	// Compteur de profondeur pour limiter la récursivité

	fmt.Println("Scanning for observability sources...")

	// Utilisation d'un WaitGroup pour gérer le parallélisme
	var wg sync.WaitGroup
	semaphore := make(chan struct{}, 10) // Limite à 10 fichiers simultanés

	err := filepath.WalkDir(".", func(path string, d os.DirEntry, err error) error {
		if err != nil {
			fmt.Fprintf(os.Stderr, "Erreur lors de l'accès à %s : %v\n", path, err)
			return nil // Continue malgré l'erreur
		}

		// Calcul de la profondeur
		currentDepth := len(strings.Split(path, string(os.PathSeparator)))
		if currentDepth > config.MaxDepth {
			return filepath.SkipDir
		}

		// Ignorer les répertoires
		if d.IsDir() {
			for _, exclude := range config.ExcludeDirs {
				if d.Name() == exclude {
					fmt.Printf("Ignoré (répertoire exclu) : %s\n", path)
					return filepath.SkipDir
				}
			}
			return nil
		}

		// Vérifier la taille du fichier
		info, err := d.Info()
		if err != nil {
			fmt.Fprintf(os.Stderr, "Erreur lors de la récupération des infos de %s : %v\n", path, err)
			return nil
		}
		if info.Size() > config.MaxFileSize {
			fmt.Printf("Ignoré (fichier trop gros) : %s\n", path)
			return nil
		}

		// Vérifier les extensions (seulement fichiers texte)
		ext := strings.ToLower(filepath.Ext(path))
		if !isTextFile(ext) {
			fmt.Printf("Ignoré (non texte) : %s\n", path)
			return nil
		}

		// Acquisition du sémaphore
		semaphore <- struct{}{}
		wg.Add(1)
		go func() {
			defer wg.Done()
			defer func() { <-semaphore }()

			// Lire le fichier
			content, err := os.ReadFile(path)
			if err != nil {
				fmt.Fprintf(os.Stderr, "Erreur lors de la lecture de %s : %v\n", path, err)
				return
			}

			// Analyser le fichier
			sources, err := scanFile(path, content)
			if err != nil {
				fmt.Fprintf(os.Stderr, "Erreur lors de l'analyse de %s : %v\n", path, err)
				return
			}

			// Ajouter les résultats de manière thread-safe
			if len(sources) > 0 {
				mu.Lock()
				observabilitySources = append(observabilitySources, sources...)
				mu.Unlock()
			}
		}()

		return nil
	})
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur lors du parcours : %v\n", err)
		os.Exit(1)
	}

	// Attendre la fin des goroutines
	wg.Wait()

	// Générer le fichier Markdown
	err = generateMarkdown(config.OutputFileMD, observabilitySources)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur lors de la génération de %s : %v\n", config.OutputFileMD, err)
		os.Exit(1)
	}

	// Générer le fichier JSON
	err = generateJSON(config.OutputFileJSON, observabilitySources)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur lors de la génération de %s : %v\n", config.OutputFileJSON, err)
		os.Exit(1)
	}

	fmt.Println("Scan terminé. Résultats enregistrés dans", config.OutputFileMD, "et", config.OutputFileJSON)
}

// isTextFile vérifie si l'extension correspond à un fichier texte
func isTextFile(ext string) bool {
	textExtensions := []string{".go", ".py", ".js", ".ts", ".yaml", ".yml", ".json", ".md", ".txt"}
	for _, validExt := range textExtensions {
		if ext == validExt {
			return true
		}
	}
	return false
}

// generateMarkdown génère le fichier Markdown (DRY)
func generateMarkdown(filename string, sources []ObservabilitySource) error {
	f, err := os.Create(filename)
	if err != nil {
		return err
	}
	defer f.Close()

	_, err = f.WriteString("# Inventaire des sources d'observabilité\n\n")
	if err != nil {
		return err
	}

	for _, source := range sources {
		_, err = f.WriteString(fmt.Sprintf("- **%s** (%s): %s\n", source.Path, source.Type, source.Content))
		if err != nil {
			return err
		}
	}
	return nil
}

// generateJSON génère le fichier JSON (DRY)
func generateJSON(filename string, sources []ObservabilitySource) error {
	data, err := json.MarshalIndent(sources, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(filename, data, 0o644)
}
