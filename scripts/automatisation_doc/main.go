// main.go
//
// Point d’entrée principal pour l’automatisation documentaire Roo-Code.
// Orchestration des modules : recensement, synchronisation, reporting.
// Respecte l’architecture manager/agent Roo (voir AGENTS.md, rules-code.md).
// © 2025 Roo — Documentation et conventions : .roo/rules/
package automatisation_doc

import (
	"fmt"
	"log"
)

func main() {
	root := "."
	output := "besoins_automatisation.yaml"

	err := RunRecensementAutomatisation(root, output)
	if err != nil {
		log.Fatalf("Erreur génération besoins automatisation documentaire : %v", err)
	}
	fmt.Printf("Rapport généré : %s\n", output)
}
