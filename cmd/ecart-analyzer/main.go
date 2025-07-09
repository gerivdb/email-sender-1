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

	// Ouvrir le fichier de sortie pour l'analyse d'écart
	outputFile, err := os.Create("ecart_jan_vs_multiagent.md")
	if err != nil {
		fmt.Printf("Erreur lors de la création de ecart_jan_vs_multiagent.md: %v\n", err)
		os.Exit(1)
	}
	defer outputFile.Close()

	outputFile.WriteString("# Analyse d'écart : Jan vs Multi-agent\n\n")
	outputFile.WriteString("| Plan | Fonctionnalité à adapter | Logique actuelle (Multi-agent/LLM) | Logique cible (Jan séquentiel) |\n")
	outputFile.WriteString("|---|---|---|---|\n")

	for _, planPath := range plans {
		planPath = strings.TrimSpace(planPath)
		if planPath == "" {
			continue
		}

		content, err := ioutil.ReadFile(planPath)
		if err != nil {
			fmt.Printf("Erreur lors de la lecture du plan %s: %v\n", planPath, err)
			continue
		}

		planContent := string(content)

		// Exemple d'analyse simple : remplacement de termes clés
		// Ceci est une version simplifiée, une analyse plus complexe nécessiterait une logique NLP ou regex plus avancée
		if strings.Contains(planContent, "multi-agent") || strings.Contains(planContent, "AgentZero") || strings.Contains(planContent, "CrewAI") {
			outputFile.WriteString(fmt.Sprintf("| %s | Orchestration | Multi-agent, AgentZero, CrewAI | Orchestration séquentielle via Jan (mono-agent) |\n", planPath))
		}
		if strings.Contains(planContent, "multi-LLM") {
			outputFile.WriteString(fmt.Sprintf("| %s | Modèles LLM | Multiples modèles LLM | Un seul LLM (Jan) avec personas via prompts |\n", planPath))
		}
		if strings.Contains(planContent, "dialogue") || strings.Contains(planContent, "conversation") {
			outputFile.WriteString(fmt.Sprintf("| %s | Gestion du dialogue | Historique par agent/LLM | Historique centralisé par ContextManager |\n", planPath))
		}
		// Ajoutez d'autres règles d'analyse ici
	}

	fmt.Println("Analyse d'écart terminée. Voir ecart_jan_vs_multiagent.md")
}
