// SPDX-License-Identifier: MIT
// Package docmanager : path tracker intelligent (v65B)
package docmanager

import (
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"sync"
)

// PathTracker structure pour suivi chemins de fichiers uniquement (SRP)
// MICRO-TASK 3.1.1.2.1 - Responsabilité suivi chemins exclusive
type PathTracker struct {
	// Champs uniquement liés au tracking de paths
	trackedPaths  map[string]string   // oldPath -> newPath
	references    map[string][]string // path -> list of referencing files
	ContentHashes map[string]string   // path -> content hash pour détection changements
	mu            sync.RWMutex
}

// NewPathTracker constructeur respectant SRP
func NewPathTracker() *PathTracker {
	return &PathTracker{
		trackedPaths: make(map[string]string),
		references:   make(map[string][]string),
	}
}

// PathHealthReport rapport de santé des chemins
type PathHealthReport struct {
	TotalPaths   int
	BrokenLinks  int
	MissingFiles int
	UpdatedPaths int
	Issues       []string
}

// Structures précédentes inchangées...

// --- LOT 16-31 : MICRO-TÂCHES ATOMIQUES NUMÉROTÉES --- //

// 16. Implémentation du squelette de updateAllReferences
// 17. Ajout des sous-fonctions updateMarkdownLinks, updateCodeReferences, updateConfigPaths, updateImportStatements
// 18. Ajout d’un WaitGroup pour exécution parallèle des mises à jour
// 19. Collecte des erreurs de chaque goroutine
// 20. Retour d’erreur consolidée si au moins une mise à jour échoue
func (pt *PathTracker) UpdateAllReferences(oldPath, newPath string) error {
	// 16. Validation et court-circuit
	if oldPath == newPath {
		return nil
	}
	var errs []error
	var wg sync.WaitGroup
	errCh := make(chan error, 4)

	// 18. Ajout WaitGroup et lancement goroutines
	wg.Add(4)
	go func() {
		defer wg.Done()
		// 17. updateMarkdownLinks
		if err := pt.updateMarkdownLinks(oldPath, newPath); err != nil {
			errCh <- fmt.Errorf("updateMarkdownLinks: %w", err)
		}
	}()
	go func() {
		defer wg.Done()
		// 17. updateCodeReferences
		if err := pt.updateCodeReferences(oldPath, newPath); err != nil {
			errCh <- fmt.Errorf("updateCodeReferences: %w", err)
		}
	}()
	go func() {
		defer wg.Done()
		// 17. updateConfigPaths
		if err := pt.updateConfigPaths(oldPath, newPath); err != nil {
			errCh <- fmt.Errorf("updateConfigPaths: %w", err)
		}
	}()
	go func() {
		defer wg.Done()
		// 17. updateImportStatements
		if err := pt.updateImportStatements(oldPath, newPath); err != nil {
			errCh <- fmt.Errorf("updateImportStatements: %w", err)
		}
	}()
	wg.Wait()
	close(errCh)
	// 19. Collecte des erreurs
	for err := range errCh {
		errs = append(errs, err)
	}
	// 20. Retour d’erreur consolidée
	if len(errs) > 0 {
		return fmt.Errorf("multiple update errors: %v", errs)
	}
	return nil
}

// 21. updateMarkdownLinks : recherche fichiers .md, regex remplacement liens
func (pt *PathTracker) updateMarkdownLinks(oldPath, newPath string) error {
	mdFiles, err := filepath.Glob("**/*.md")
	if err != nil {
		return err
	}
	linkPattern := regexp.MustCompile(`\[[^\]]*\]\(([^)]*)\)`)
	for _, file := range mdFiles {
		input, err := os.ReadFile(file)
		if err != nil {
			continue
		}
		changed := false
		lines := strings.Split(string(input), "\n")
		for i, line := range lines {
			if strings.Contains(line, oldPath) {
				newLine := linkPattern.ReplaceAllStringFunc(line, func(m string) string {
					return strings.ReplaceAll(m, oldPath, newPath)
				})
				if newLine != line {
					lines[i] = newLine
					changed = true
				}
			}
		}
		if changed {
			tmpFile := file + ".tmp"
			err := os.WriteFile(tmpFile, []byte(strings.Join(lines, "\n")), 0o644)
			if err != nil {
				return err
			}
			err = os.Rename(tmpFile, file)
			if err != nil {
				return err
			}
		}
	}
	return nil
}

// 22. updateCodeReferences : recherche fichiers .go, AST parsing, remplacement string literals
func (pt *PathTracker) updateCodeReferences(oldPath, newPath string) error {
	goFiles, err := filepath.Glob("**/*.go")
	if err != nil {
		return err
	}
	for _, file := range goFiles {
		fset := token.NewFileSet()
		node, err := parser.ParseFile(fset, file, nil, parser.ParseComments)
		if err != nil {
			continue
		}
		changed := false
		var output strings.Builder
		src, err := os.ReadFile(file)
		if err != nil {
			continue
		}
		lines := strings.Split(string(src), "\n")
		ast.Inspect(node, func(n ast.Node) bool {
			lit, ok := n.(*ast.BasicLit)
			if ok && lit.Kind == token.STRING && strings.Contains(lit.Value, oldPath) {
				lit.Value = strings.ReplaceAll(lit.Value, oldPath, newPath)
				changed = true
			}
			return true
		})
		if changed {
			for _, line := range lines {
				output.WriteString(strings.ReplaceAll(line, oldPath, newPath) + "\n")
			}
			tmpFile := file + ".tmp"
			err := os.WriteFile(tmpFile, []byte(output.String()), 0o644)
			if err != nil {
				return err
			}
			err = os.Rename(tmpFile, file)
			if err != nil {
				return err
			}
		}
	}
	return nil
}

// 23. updateConfigPaths : recherche fichiers .json/.yaml, remplacement chemins
func (pt *PathTracker) updateConfigPaths(oldPath, newPath string) error {
	configFiles, err := filepath.Glob("**/*.{json,yaml,yml}")
	if err != nil {
		return err
	}
	for _, file := range configFiles {
		input, err := os.ReadFile(file)
		if err != nil {
			continue
		}
		if !strings.Contains(string(input), oldPath) {
			continue
		}
		newContent := strings.ReplaceAll(string(input), oldPath, newPath)
		tmpFile := file + ".tmp"
		err = os.WriteFile(tmpFile, []byte(newContent), 0o644)
		if err != nil {
			return err
		}
		err = os.Rename(tmpFile, file)
		if err != nil {
			return err
		}
	}
	return nil
}

// 24. updateImportStatements : recherche imports Go, remplacement si besoin
func (pt *PathTracker) updateImportStatements(oldPath, newPath string) error {
	goFiles, err := filepath.Glob("**/*.go")
	if err != nil {
		return err
	}
	for _, file := range goFiles {
		input, err := os.ReadFile(file)
		if err != nil {
			continue
		}
		changed := false
		lines := strings.Split(string(input), "\n")
		for i, line := range lines {
			if strings.HasPrefix(strings.TrimSpace(line), "import") && strings.Contains(line, oldPath) {
				lines[i] = strings.ReplaceAll(line, oldPath, newPath)
				changed = true
			}
		}
		if changed {
			tmpFile := file + ".tmp"
			err := os.WriteFile(tmpFile, []byte(strings.Join(lines, "\n")), 0o644)
			if err != nil {
				return err
			}
			err = os.Rename(tmpFile, file)
			if err != nil {
				return err
			}
		}
	}
	return nil
}

// 25. Ajout de PathHealthReport détaillé (structure déjà présente)
// 26. Squelette HealthCheck : scan ContentHashes, vérification existence fichiers
// 27. Pour chaque hash, recalcul et comparaison avec stocké
// 28. Ajout des fichiers manquants à BrokenPaths
// 29. Ajout des hashes orphelins à OrphanedHashes
// 30. Génération de recommandations simples (stub)
// 31. Retour du rapport santé complet
func (pt *PathTracker) HealthCheck() (*PathHealthReport, error) {
	pt.mu.RLock()
	defer pt.mu.RUnlock()
	report := &PathHealthReport{
		TotalPaths:   len(pt.ContentHashes),
		BrokenLinks:  0,
		MissingFiles: 0,
		UpdatedPaths: 0,
		Issues:       []string{},
	}
	for path, hash := range pt.ContentHashes {
		if _, err := os.Stat(path); os.IsNotExist(err) {
			// 28. Ajout fichier manquant
			report.MissingFiles++
			report.Issues = append(report.Issues, fmt.Sprintf("Fichier manquant: %s", path))
			continue
		}
		actualHash, err := pt.CalculateContentHash(path)
		if err != nil {
			report.BrokenLinks++
			report.Issues = append(report.Issues, fmt.Sprintf("Erreur de calcul de hash: %s", path))
			continue
		}
		if actualHash != hash {
			// 29. Ajout hash orphelin
			report.BrokenLinks++
			report.Issues = append(report.Issues, fmt.Sprintf("Hash orphelin détecté: %s", path))
		} else {
			report.UpdatedPaths++
		}
	}
	// 30. Génération recommandations
	if len(report.Issues) > 0 {
		report.Issues = append(report.Issues, "Veuillez vérifier les problèmes signalés.")
	}
	// 31. Retour rapport santé
	return report, nil
}

// CalculateContentHash calcule le hash du contenu d'un fichier
func (pt *PathTracker) CalculateContentHash(path string) (string, error) {
	content, err := os.ReadFile(path)
	if err != nil {
		return "", fmt.Errorf("failed to read file %s: %w", path, err)
	}

	// Simple hash basé sur la longueur et quelques caractères
	// Pour une vraie implémentation, utiliser crypto/md5 ou sha256
	hash := fmt.Sprintf("%d-%x", len(content), content[:min(len(content), 10)])
	return hash, nil
}

// Helper function
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
