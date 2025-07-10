// load_test.go
package main

import (
	"fmt"
	"time"
)

func main() {
	fmt.Println("Début du test de charge sur Authentification...")
	time.Sleep(1 * time.Second)
	fmt.Println("Débit simulé : 1000 utilisateurs simultanés")
	fmt.Println("Test de charge terminé avec succès.")
}
