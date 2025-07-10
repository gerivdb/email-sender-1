package main

import (
	"fmt"
)

func main() {
	fmt.Println("# Spécification des cas de test")
	fmt.Println("- Authentification : test login succès, test login échec, test expiration session")
	fmt.Println("- Gestion des utilisateurs : test création, test suppression, test modification")
	fmt.Println("- Orchestration CLI : test exécution commande, test rollback, test erreur syntaxe")
}
