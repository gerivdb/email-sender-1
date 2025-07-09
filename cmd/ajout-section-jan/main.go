package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"strings"
)

func main() {
	// Lire la liste des plans impactés
	plansFile, err := ioutil.ReadFile("plans_impactes_jan.md")
	if err != nil {
		fmt.Printf("Erreur lors de la lecture de plans_impactes_jan.md: %v\n", err)
		os.Exit(1)
	}
	plans := strings.Split(string(plansFile), "\n")

	sectionToAdd := `
## Orchestration séquentielle multi-personas avec Jan
Toutes les tâches IA sont orchestrées via Jan, en mode mono-agent séquentiel, chaque persona étant simulé par un prompt système/contextuel distinct. L’historique des échanges est géré par le ContextManager et injecté à chaque tour.
`

	for _, planPath := range plans {
		planPath = strings.TrimSpace(planPath)
		if planPath == "" {
			continue
		}

		fmt.Printf("Traitement du plan : %s\n", planPath)

		content, err := ioutil.ReadFile(planPath)
		if err != nil {
			fmt.Printf("Erreur lors de la lecture du plan %s: %v\n", planPath, err)
			continue
		}

		planContent := string(content)

		// Vérifier si la section existe déjà pour éviter les doublons
		if strings.Contains(planContent, "## Orchestration séquentielle multi-personas avec Jan") {
			fmt.Printf("  La section existe déjà dans %s. Sautée.\n", planPath)
			continue
		}

		// Sauvegarder l'original
		backupPath := planPath + ".bak"
		err = ioutil.WriteFile(backupPath, content, 0o644)
		if err != nil {
			fmt.Printf("Erreur lors de la sauvegarde du backup pour %s: %v\n", planPath, err)
			continue
		}
		fmt.Printf("  Backup créé : %s\n", backupPath)

		// Ajouter la section à la fin du fichier
		newContent := planContent + sectionToAdd

		err = ioutil.WriteFile(planPath, []byte(newContent), 0o644)
		if err != nil {
			fmt.Printf("Erreur lors de l'écriture du nouveau contenu pour %s: %v\n", planPath, err)
			continue
		}
		fmt.Printf("  Section ajoutée à %s.\n", planPath)
	}

	fmt.Println("\nAjout des sections 'Orchestration séquentielle multi-personas avec Jan' terminé.")
}
