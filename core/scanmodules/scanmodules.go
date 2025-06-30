// core/scanmodules/scanmodules.go
package scanmodules

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
)

// RunScanModules exécute les commandes de scan et écrit les résultats dans des fichiers.
func RunScanModules() error {
	// Exécute la commande tree -L 3 et écrit la sortie dans arborescence.txt
	treeCmd := exec.Command("tree", "-L", "3")
	treeOutput, err := treeCmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("erreur lors de l'exécution de 'tree': %w", err)
	}
	err = os.WriteFile("arborescence.txt", treeOutput, 0o644)
	if err != nil {
		return fmt.Errorf("erreur lors de l'écriture de arborescence.txt: %w", err)
	}
	fmt.Println("Arborescence du dépôt écrite dans arborescence.txt")

	// Exécute la commande go list ./... et écrit la sortie dans modules.txt
	goListCmd := exec.Command("go", "list", "./...")
	goListOutput, err := goListCmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("erreur lors de l'exécution de 'go list': %w", err)
	}
	err = os.WriteFile("modules.txt", goListOutput, 0o644)
	if err != nil {
		return fmt.Errorf("erreur lors de l'écriture de modules.txt: %w", err)
	}
	fmt.Println("Liste des modules Go écrite dans modules.txt")

	// Convertir modules.txt en modules.json
	modules := strings.Split(string(goListOutput), "\n")
	var jsonModules []string
	for _, module := range modules {
		if strings.TrimSpace(module) != "" {
			jsonModules = append(jsonModules, fmt.Sprintf("%q", module))
		}
	}
	jsonContent := fmt.Sprintf("[\n%s\n]", strings.Join(jsonModules, ",\n"))
	err = os.WriteFile("modules.json", []byte(jsonContent), 0o644)
	if err != nil {
		return fmt.Errorf("erreur lors de l'écriture de modules.json: %w", err)
	}
	fmt.Println("Liste des modules Go convertie en modules.json")
	return nil
}

func main() {
	if err := RunScanModules(); err != nil {
		fmt.Printf("Erreur lors de l'exécution de ScanModules: %s\n", err)
		os.Exit(1)
	}
}
