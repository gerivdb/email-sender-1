// Package interactive implements the interactive mode for the plan generator
package interactive

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	"plan-generator/pkg/generator"
	"plan-generator/pkg/models"
	"plan-generator/pkg/utils"
)

// RunInteractiveMode exécute le générateur en mode interactif
func RunInteractiveMode(defaultVersion, defaultTitle, defaultDescription string, defaultPhaseCount int, defaultTaskDepth int) (*models.Plan, error) {
	reader := bufio.NewReader(os.Stdin)
	fmt.Println("=== Mode Interactif: Générateur de Plans en Go ===")

	// Fonction utilitaire pour lire l'entrée utilisateur avec une valeur par défaut
	readInput := func(prompt, defaultValue string) string {
		fmt.Printf("%s [%s]: ", prompt, defaultValue)
		input, _ := reader.ReadString('\n')
		input = strings.TrimSpace(input)
		if input == "" {
			return defaultValue
		}
		return input
	}

	// Lire les informations de base
	version := readInput("Version du plan", defaultVersion)
	title := readInput("Titre du plan", defaultTitle)

	fmt.Println("\nEntrez la description du plan (validez avec une ligne vide):")
	lines := []string{}
	for {
		line, _ := reader.ReadString('\n')
		line = strings.TrimSpace(line)
		if line == "" {
			break
		}
		lines = append(lines, line)
	}

	var description string
	if len(lines) > 0 {
		description = strings.Join(lines, "\n")
	} else {
		description = defaultDescription
	}
	// Lire le nombre de phases
	phaseCountStr := readInput(fmt.Sprintf("Nombre de phases (1-6) [défaut: %d]", defaultPhaseCount), strconv.Itoa(defaultPhaseCount))
	phaseCount, err := strconv.Atoi(phaseCountStr)
	if err != nil || phaseCount < 1 || phaseCount > 6 {
		if err != nil {
			fmt.Printf("Erreur: %v. Utilisation du nombre par défaut: %d\n", err, defaultPhaseCount)
		} else {
			fmt.Printf("Nombre hors limites. Utilisation du nombre par défaut: %d\n", defaultPhaseCount)
		}
		phaseCount = defaultPhaseCount
	}

	// Demander l'état d'avancement (progression)
	progressStr := readInput("Progression globale (0-100%)", "0")
	progress, err := strconv.Atoi(progressStr)
	if err != nil || progress < 0 || progress > 100 {
		if err != nil {
			fmt.Printf("Erreur: %v. Progression mise à 0%%\n", err)
		} else {
			fmt.Printf("Progression hors limites. Mise à 0%%\n")
		}
		progress = 0
	}

	// Initialiser le plan avec les infos recueillies
	plan := &models.Plan{
		Version:     version,
		Title:       title,
		Description: description,
		PhaseCount:  phaseCount,
		Date:        time.Now().Format("2006-01-02"),
		Progress:    progress,
	}

	// Demander si l'utilisateur veut personnaliser chaque phase
	customizePhases := readInput("Voulez-vous personnaliser les phases? (o/n)", "n")
	if strings.ToLower(customizePhases) == "o" || strings.ToLower(customizePhases) == "oui" {
		phases := make([]models.Phase, phaseCount)
		for i := 1; i <= phaseCount; i++ {
			fmt.Printf("\n=== Configuration de la Phase %d ===\n", i)
			phaseDesc := readInput(fmt.Sprintf("Description de la phase %d", i), utils.PhaseDescription(i)) // Créer la phase avec description personnalisée
			phase := models.Phase{
				Number:      i,
				Description: phaseDesc,
				Tasks:       generator.GenerateTasksForPhase(i, defaultTaskDepth), // Utiliser la profondeur de tâches spécifiée
				Subtasks: []string{
					"Étape 1 : Définir les objectifs",
					"Étape 2 : Identifier les parties prenantes",
					"Étape 3 : Documenter les résultats",
					// Ces étapes peuvent être personnalisées si besoin
				},
			}

			phases[i-1] = phase
		}

		plan.GeneratedPhases = phases
	}

	return plan, nil
}
