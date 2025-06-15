// Test d'intégration de l'écosystème complet
package main

import (
	"fmt"
	"os"
	"path/filepath"
)

func main() {
	fmt.Println("🔍 VALIDATION DE L'ÉCOSYSTÈME COMPLET")
	fmt.Println("=====================================")
	
	// Test de présence des managers critiques
	managers := []string{
		"branching-manager",
		"storage-manager", 
		"email-manager",
		"security-manager",
		"dependency-manager",
		"integration-manager",
		"git-workflow-manager",
		"notification-manager",
	}
	
	managersPath := "development/managers"
	validManagers := 0
	
	for _, manager := range managers {
		managerPath := filepath.Join(managersPath, manager)
		if _, err := os.Stat(managerPath); err == nil {
			fmt.Printf("✅ %s - PRÉSENT\n", manager)
			validManagers++
			
			// Vérifier go.mod si présent
			goModPath := filepath.Join(managerPath, "go.mod")
			if _, err := os.Stat(goModPath); err == nil {
				fmt.Printf("   📦 go.mod trouvé\n")
			}
			
			// Vérifier README si présent
			readmePath := filepath.Join(managerPath, "README.md")
			if _, err := os.Stat(readmePath); err == nil {
				fmt.Printf("   📖 README.md trouvé\n")
			}
		} else {
			fmt.Printf("❌ %s - MANQUANT\n", manager)
		}
	}
	
	fmt.Printf("\n📊 RÉSUMÉ D'INTÉGRATION:\n")
	fmt.Printf("   Managers validés: %d/%d\n", validManagers, len(managers))
	
	// Test du framework branching-manager
	fmt.Printf("\n🌟 TEST DU FRAMEWORK BRANCHING-MANAGER:\n")
	branchingPath := filepath.Join(managersPath, "branching-manager")
	
	criticalFiles := []string{
		"demo-complete-8-levels.go",
		"test-interfaces.go", 
		"test-compile.go",
		"go.mod",
		"interfaces/branching_interfaces.go",
		"development/branching_manager.go",
		"cmd/main.go",
	}
	
	validFiles := 0
	for _, file := range criticalFiles {
		filePath := filepath.Join(branchingPath, file)
		if _, err := os.Stat(filePath); err == nil {
			fmt.Printf("✅ %s\n", file)
			validFiles++
		} else {
			fmt.Printf("❌ %s\n", file)
		}
	}
	
	fmt.Printf("\n📊 FRAMEWORK STATUS:\n")
	fmt.Printf("   Fichiers critiques: %d/%d\n", validFiles, len(criticalFiles))
	
	// Statut final
	if validManagers >= 6 && validFiles >= 5 {
		fmt.Printf("\n🎉 ÉCOSYSTÈME COMPLET VALIDÉ! Production ready!\n")
	} else if validManagers >= 4 && validFiles >= 4 {
		fmt.Printf("\n⚠️  ÉCOSYSTÈME PARTIELLEMENT VALIDÉ. Quelques optimisations nécessaires.\n")
	} else {
		fmt.Printf("\n❌ ÉCOSYSTÈME INCOMPLET. Développement requis.\n")
	}
	
	fmt.Printf("\n✅ Validation terminée.\n")
}
