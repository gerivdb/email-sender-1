// cmd/auto-roadmap-runner/project_state_checker.go
// Vérification état projet avant/après modification majeure

package main

import (
	"fmt"
	"os"
	"time"
)

func LogProjectState(phase string) {
	f, err := os.OpenFile("project_state.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		fmt.Printf("Erreur ouverture log: %v\n", err)
		return
	}
	defer f.Close()
	timestamp := time.Now().Format(time.RFC3339)
	state := fmt.Sprintf("%s | %s | Fichiers modifiés: TODO | Tests: TODO | Artefacts: TODO\n", timestamp, phase)
	f.WriteString(state)
	fmt.Printf("État projet loggé pour phase: %s\n", phase)
}

// Exemple d'utilisation
func ExampleProjectStateChecker() {
	LogProjectState("Avant modification majeure")
	LogProjectState("Après modification majeure")
}
