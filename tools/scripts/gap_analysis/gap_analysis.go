package main

import (
	"fmt"
)

func main() {
	fmt.Println("# Rapport d’écart des tests existants")
	fmt.Println("- Authentification : tests unitaires présents, pas de tests d’intégration")
	fmt.Println("- Gestion des utilisateurs : couverture partielle")
	fmt.Println("- Orchestration CLI : pas de tests de non-régression")
}
