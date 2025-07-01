package scanmodules

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

// ScanOptions représente les options de scan
type ScanOptions struct {
	TreeLevels int
	OutputDir  string
}

// ScanModules effectue le scan des modules et génère la structure du dépôt
func ScanModules(options ScanOptions) (*RepositoryStructure, error) {
	// Obtenir le répertoire de travail actuel
	pwd, err := os.Getwd()
	if err != nil {
		return nil, fmt.Errorf("erreur lors de l'obtention du répertoire de travail: %v", err)
	}

	// Exécuter tree pour obtenir la structure
	log.Println("Génération de l'arborescence...")
	treeCmd := exec.Command("tree", "-L", fmt.Sprintf("%d", options.TreeLevels))
	treeOutput, err := treeCmd.Output()
	if err != nil {
		log.Printf("Attention: impossible d'exécuter tree: %v", err)
		// Fallback pour Windows ou si tree n'est pas disponible
		treeOutput = []byte("Structure d'arborescence non disponible (tree non installé)")
	}

	// Sauvegarder l'arborescence dans un fichier
	treeFile := filepath.Join(options.OutputDir, "arborescence.txt")
	err = ioutil.WriteFile(treeFile, treeOutput, 0o644)
	if err != nil {
		log.Printf("Erreur lors de l'écriture de %s: %v", treeFile, err)
	}

	// Exécuter go list pour obtenir les modules
	log.Println("Scan des modules Go...")
	goListCmd := exec.Command("go", "list", "./...")
	goListOutput, err := goListCmd.Output()
	if err != nil {
		return nil, fmt.Errorf("erreur lors de l'exécution de go list: %v", err)
	}

	// Sauvegarder la liste des modules dans un fichier
	modulesFile := filepath.Join(options.OutputDir, "modules.txt")
	err = ioutil.WriteFile(modulesFile, goListOutput, 0o644)
	if err != nil {
		log.Printf("Erreur lors de l'écriture de %s: %v", modulesFile, err)
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
	repoStructure := &RepositoryStructure{
		TreeOutput:   string(treeOutput),
		Modules:      modules,
		TotalModules: len(modules),
		GeneratedAt:  time.Now(),
		RootPath:     pwd,
	}

	return repoStructure, nil
}

// SaveToJSON sauvegarde la structure du dépôt en JSON
func SaveToJSON(structure *RepositoryStructure, outputDir string) error {
	jsonData, err := json.MarshalIndent(structure, "", "  ")
	if err != nil {
		return fmt.Errorf("erreur lors de la sérialisation JSON: %v", err)
	}

	jsonFile := filepath.Join(outputDir, "modules.json")
	err = ioutil.WriteFile(jsonFile, jsonData, 0o644)
	if err != nil {
		return fmt.Errorf("erreur lors de l'écriture de %s: %v", jsonFile, err)
	}

	log.Printf("Structure sauvegardée dans %s", jsonFile)
	return nil
}

// PrintSummary affiche un résumé du scan
func PrintSummary(structure *RepositoryStructure, outputDir string) {
	fmt.Printf("✅ Scan terminé avec succès!\n")
	fmt.Printf("📁 Répertoire racine: %s\n", structure.RootPath)
	fmt.Printf("📦 Modules trouvés: %d\n", len(structure.Modules))
	fmt.Printf("📄 Fichiers générés:\n")
	fmt.Printf("   - %s\n", filepath.Join(outputDir, "arborescence.txt"))
	fmt.Printf("   - %s\n", filepath.Join(outputDir, "modules.txt"))
	fmt.Printf("   - %s\n", filepath.Join(outputDir, "modules.json"))

	// Afficher quelques modules trouvés
	fmt.Printf("\n📋 Premiers modules détectés:\n")
	for i, module := range structure.Modules {
		if i >= 5 { // Limiter l'affichage aux 5 premiers
			fmt.Printf("   ... et %d autres\n", len(structure.Modules)-5)
			break
		}
		fmt.Printf("   - %s\n", module.Name)
	}
}
