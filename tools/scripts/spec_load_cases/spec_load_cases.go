package main

import (
	"fmt"
)

func main() {
	fmt.Println("# Spécification des scénarios de charge")
	fmt.Println("- gestionnaire de dépendances : 1000 requêtes simultanées")
	fmt.Println("- orchestration CLI : 500 exécutions concurrentes")
	fmt.Println("- gateway-manager : 10 000 requêtes/minute")
}
