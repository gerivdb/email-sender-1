// package_conflict_resolver.go - Résolution des conflits de packages
package main

import (
	"fmt"
	"io/fs"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"
)

type PackageConflict struct {
	Directory string
	MainFiles []string
	TestFiles []string
}

type ConflictReport struct {
	ConflictsFound  int               `json:"conflicts_found"`
	ConflictsFixed  int               `json:"conflicts_fixed"`
	FilesRelocated  int               `json:"files_relocated"`
	PackagesCreated []string          `json:"packages_created"`
	ProcessingTime  string            `json:"processing_time"`
	Details         []PackageConflict `json:"details"`
}

func main() {
	fmt.Println("🔧 EMAIL_SENDER_1 - Résolveur de conflits de packages")
	fmt.Println("====================================================")

	start := time.Now()
	projectRoot := "d:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1"

	report := &ConflictReport{
		PackagesCreated: []string{},
	}

	// Analyser les conflits de packages
	conflicts := findPackageConflicts(projectRoot)
	report.ConflictsFound = len(conflicts)
	report.Details = conflicts

	fmt.Printf("📊 Conflits détectés: %d\n", len(conflicts))

	// Résoudre chaque conflit
	for _, conflict := range conflicts {
		fmt.Printf("🔧 Résolution conflit dans: %s\n", conflict.Directory)
		fixed := resolvePackageConflict(conflict, report)
		if fixed {
			report.ConflictsFixed++
		}
	}

	report.ProcessingTime = time.Since(start).String()

	// Générer le rapport
	generateConflictReport(report, projectRoot)

	fmt.Printf("\n✅ Résolution terminée en %s\n", report.ProcessingTime)
	fmt.Printf("🔧 Conflits résolus: %d/%d\n", report.ConflictsFixed, report.ConflictsFound)
}

func findPackageConflicts(projectRoot string) []PackageConflict {
	conflicts := []PackageConflict{}

	// Parcourir tous les dossiers contenant des fichiers Go
	err := filepath.WalkDir(projectRoot, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return nil // Continuer même en cas d'erreur
		}

		if !d.IsDir() {
			return nil
		}

		// Vérifier si le dossier contient des fichiers Go
		goFiles, err := filepath.Glob(filepath.Join(path, "*.go"))
		if err != nil || len(goFiles) == 0 {
			return nil
		}

		// Analyser les packages dans ce dossier
		packages := analyzePackagesInDirectory(path, goFiles)
		if len(packages) > 1 {
			conflict := PackageConflict{
				Directory: path,
				MainFiles: []string{},
				TestFiles: []string{},
			}

			for pkg, files := range packages {
				if pkg == "main" {
					conflict.MainFiles = files
				} else {
					conflict.TestFiles = append(conflict.TestFiles, files...)
				}
			}

			if len(conflict.MainFiles) > 0 && len(conflict.TestFiles) > 0 {
				conflicts = append(conflicts, conflict)
			}
		}

		return nil
	})

	if err != nil {
		log.Printf("Erreur lors du scan: %v", err)
	}

	return conflicts
}

func analyzePackagesInDirectory(dirPath string, goFiles []string) map[string][]string {
	packages := make(map[string][]string)

	for _, file := range goFiles {
		content, err := ioutil.ReadFile(file)
		if err != nil {
			continue
		}

		// Extraire le nom du package
		packageRegex := regexp.MustCompile(`(?m)^package\s+(\w+)`)
		matches := packageRegex.FindStringSubmatch(string(content))
		if len(matches) > 1 {
			pkgName := matches[1]
			relPath, _ := filepath.Rel(dirPath, file)
			packages[pkgName] = append(packages[pkgName], relPath)
		}
	}

	return packages
}

func resolvePackageConflict(conflict PackageConflict, report *ConflictReport) bool {
	fmt.Printf("  📁 Dossier: %s\n", conflict.Directory)
	fmt.Printf("  📦 Fichiers main: %v\n", conflict.MainFiles)
	fmt.Printf("  🧪 Fichiers test: %v\n", conflict.TestFiles)

	// Stratégie: Déplacer les fichiers de test dans un sous-dossier
	testDir := filepath.Join(conflict.Directory, "test")

	// Créer le dossier test s'il n'existe pas
	if _, err := os.Stat(testDir); os.IsNotExist(err) {
		err = os.MkdirAll(testDir, 0755)
		if err != nil {
			fmt.Printf("    ❌ Erreur création dossier test: %v\n", err)
			return false
		}
		report.PackagesCreated = append(report.PackagesCreated, testDir)
	}

	// Déplacer les fichiers de test
	for _, testFile := range conflict.TestFiles {
		srcPath := filepath.Join(conflict.Directory, testFile)
		dstPath := filepath.Join(testDir, testFile)

		err := moveFile(srcPath, dstPath)
		if err != nil {
			fmt.Printf("    ❌ Erreur déplacement %s: %v\n", testFile, err)
			continue
		}

		fmt.Printf("    ✅ Déplacé: %s → test/%s\n", testFile, testFile)
		report.FilesRelocated++
	}

	return true
}

func moveFile(src, dst string) error {
	// Lire le contenu source
	content, err := ioutil.ReadFile(src)
	if err != nil {
		return err
	}

	// Écrire dans la destination
	err = ioutil.WriteFile(dst, content, 0644)
	if err != nil {
		return err
	}

	// Supprimer le fichier source
	return os.Remove(src)
}

func generateConflictReport(report *ConflictReport, projectRoot string) {
	reportContent := fmt.Sprintf(`# 📦 Rapport de Résolution des Conflits de Packages

**Date :** %s  
**Durée :** %s

## 📊 Résumé
- **Conflits détectés :** %d
- **Conflits résolus :** %d
- **Fichiers relocalisés :** %d
- **Nouveaux packages créés :** %d

## 📁 Packages créés
%s

## 🎯 Résultats
%s

*Rapport généré automatiquement par le résolveur de conflits EMAIL_SENDER_1*
`,
		time.Now().Format("2006-01-02 15:04:05"),
		report.ProcessingTime,
		report.ConflictsFound,
		report.ConflictsFixed,
		report.FilesRelocated,
		len(report.PackagesCreated),
		strings.Join(report.PackagesCreated, "\n- "),
		func() string {
			if report.ConflictsFixed == report.ConflictsFound {
				return "✅ Tous les conflits de packages ont été résolus avec succès!"
			}
			return fmt.Sprintf("⚠️ %d conflits restent à résoudre manuellement",
				report.ConflictsFound-report.ConflictsFixed)
		}(),
	)

	reportFile := filepath.Join(projectRoot, "package_conflict_resolution.md")
	err := ioutil.WriteFile(reportFile, []byte(reportContent), 0644)
	if err != nil {
		log.Printf("Erreur génération rapport: %v", err)
		return
	}

	fmt.Printf("📋 Rapport généré: %s\n", reportFile)
}
