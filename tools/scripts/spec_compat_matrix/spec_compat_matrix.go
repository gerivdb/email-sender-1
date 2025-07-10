package main

import (
	"fmt"
)

func main() {
	fmt.Println("# Matrice de compatibilité")
	fmt.Println("| Fonction | Go 1.20 Linux | Go 1.20 Windows | Go 1.21 Mac |")
	fmt.Println("|----------|---------------|-----------------|-------------|")
	fmt.Println("| CalculScore | OK | OK | OK |")
	fmt.Println("| TraitementBatch | OK | NOK | OK |")
	fmt.Println("| ExportCSV | OK | OK | NOK |")
}
