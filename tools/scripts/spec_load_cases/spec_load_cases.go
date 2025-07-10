// tools/scripts/spec_load_cases/spec_load_cases.go
package main

import (
	"fmt"
)

func main() {
	fmt.Println("# Spécification des scénarios de charge\n")
	fmt.Println("- 1000 utilisateurs simultanés sur Authentification")
	fmt.Println("- 500 requêtes/s sur Orchestration")
	fmt.Println("- 200 uploads concurrents")
}
