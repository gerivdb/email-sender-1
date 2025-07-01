package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

// ModuleInfo représente les informations d'un module
type ModuleInfo struct {
	Name         string    `json:"name"`
	Path         string    `json:"path"`
	Description  string    `json:"description"`
	LastModified time.Time `json:"last_modified"`
}

// RepositoryStructure représente la structure complète du dépôt
type RepositoryStructure struct {
	TreeOutput   string       `json:"tree_output"`
	Modules      []ModuleInfo `json:"modules"`
	TotalModules int          `json:"total_modules"`
	GeneratedAt  time.Time    `json:"generated_at"`
	RootPath     string       `json:"root_path"`
}

func main() {
	fmt.Println("=== Scan des modules et structure du dépôt ===")

	// Obtenir le répertoire de travail actuel
	pwd, err := os.Getwd()
	if err != nil {
		log.Fatalf("Erreur lors de l'obtention du répertoire de travail: %v", err)
	}

	// Exécuter tree pour obtenir la structure
	fmt.Println("Génération de l'arborescence...")
	treeCmd := exec.Command("tree", "-L", "3")
	treeOutput, err := treeCmd.Output()
	if err != nil {
		log.Printf("Attention: impossible d'exécuter tree: %v", err)
		// Fallback pour Windows ou si tree n'est pas disponible
		treeOutput = []byte("Structure d'arborescence non disponible (tree non installé)")
	}

	// Sauvegarder l'arborescence dans un fichier
	err = ioutil.WriteFile("arborescence.txt", treeOutput, 0644)
	if err != nil {
		log.Printf("Erreur lors de l'écriture de arborescence.txt: %v", err)
	}

	// Exécuter go list pour obtenir les modules
	fmt.Println("Scan des modules Go...")
	goListCmd := exec.Command("go", "list", "./...")
	goListOutput, err := goListCmd.Output()
	if err != nil {
		log.Fatalf("Erreur lors de l'exécution de go list: %v", err)
	}

	// Sauvegarder la liste des modules dans un fichier
	err = ioutil.WriteFile("modules.txt", goListOutput, 0644)
	if err != nil {
		log.Printf("Erreur lors de l'écriture de modules.txt: %v", err)
	}

	// Parser les modules et collecter les informations
	moduleLines := strings.Split(strings.TrimSpace(string(goListOutput)), "\n")
	var modules []ModuleInfo

	for _, moduleLine := range moduleLines {
		if strings.TrimSpace(moduleLine) == "" {
			continue
		}

		// Convertir le nom du module en chemin de fichier
		modulePath := strings.ReplaceAll(moduleLine, "/", string(filepath.Separator))

		// Chercher le fichier principal du module
		var actualPath string
		possiblePaths := []string{
			modulePath,
			filepath.Join(modulePath, "main.go"),
			filepath.Join(modulePath, "*.go"),
		}

		for _, path := range possiblePaths {
			if _, err := os.Stat(path); err == nil {
				actualPath = path
				break
			}
		}

		// Obtenir les informations de modification
		var lastModified time.Time
		if actualPath != "" {
			if info, err := os.Stat(actualPath); err == nil {
				lastModified = info.ModTime()
			}
		}

		module := ModuleInfo{
			Name:         moduleLine,
			Path:         actualPath,
			Description:  fmt.Sprintf("Module Go: %s", moduleLine),
			LastModified: lastModified,
		}
		modules = append(modules, module)
	}

	// Créer la structure complète du dépôt
	repoStructure := RepositoryStructure{
		TreeOutput:   string(treeOutput),
		Modules:      modules,
		TotalModules: len(modules),
		GeneratedAt:  time.Now(),
		RootPath:     pwd,
	}

	// Sauvegarder en JSON
	jsonData, err := json.MarshalIndent(repoStructure, "", "  ")
	if err != nil {
		log.Fatalf("Erreur lors de la sérialisation JSON: %v", err)
	}

	err = ioutil.WriteFile("modules.json", jsonData, 0644)
	if err != nil {
		log.Fatalf("Erreur lors de l'écriture de modules.json: %v", err)
	}

	// Afficher un résumé
	fmt.Printf("✅ Scan terminé avec succès!\n")
	fmt.Printf("📁 Répertoire racine: %s\n", pwd)
	fmt.Printf("📦 Modules trouvés: %d\n", len(modules))
	fmt.Printf("📄 Fichiers générés:\n")
	fmt.Printf("   - arborescence.txt\n")
	fmt.Printf("   - modules.txt\n")
	fmt.Printf("   - modules.json\n")

	// Afficher quelques modules trouvés
	fmt.Printf("\n📋 Premiers modules détectés:\n")
	for i, module := range modules {
		if i >= 5 { // Limiter l'affichage aux 5 premiers
			fmt.Printf("   ... et %d autres\n", len(modules)-5)
			break
		}
		fmt.Printf("   - %s\n", module.Name)
	}
}
