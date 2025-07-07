// Package main implements the entry point for the plan generator application
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"

	"plan-generator/pkg/generator"
	"plan-generator/pkg/interactive"
	"plan-generator/pkg/io"
	"plan-generator/pkg/models"
)

func main() {
	// Définir les options en ligne de commande
	version := flag.String("version", "v1", "Numéro de version du plan (ex: v33b)")
	title := flag.String("title", "Plan par défaut", "Titre du plan de développement")
	description := flag.String("description", "Description du plan de développement", "Description du plan")
	phaseCount := flag.Int("phases", 5, "Nombre de phases (1-6)")
	phaseDetailsJSON := flag.String("phaseDetails", "{}", "Détails des phases (JSON)")
	taskDepth := flag.Int("taskDepth", 4, "Profondeur maximale des tâches (1-7). 1=simple, 4=standard, 7=très détaillé")
	outputDir := flag.String("output", "d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/projet/roadmaps/plans/consolidated", "Répertoire de sortie")

	// Options pour les nouvelles fonctionnalités
	importJSON := flag.String("import", "", "Importer un plan à partir d'un fichier JSON")
	importMD := flag.String("importMD", "", "Importer et mettre à jour un plan à partir d'un fichier Markdown existant")
	exportJSON := flag.Bool("exportJSON", false, "Exporter le plan au format JSON en plus du Markdown")
	interactiveMode := flag.Bool("interactive", false, "Exécuter en mode interactif")

	flag.Parse()

	var plan *models.Plan
	var err error

	// Trois modes possibles:
	// 1. Import JSON
	// 2. Import MD
	// 3. Création à partir des arguments CLI
	if *importJSON != "" {
		// Mode 1: Import depuis JSON
		fmt.Printf("Import du plan depuis %s...\n", *importJSON)
		plan, err = io.ImportPlanFromJSON(*importJSON)
		if err != nil {
			fmt.Printf("Erreur lors de l'import du JSON: %v\n", err)
			os.Exit(1)
		}

		// Mise à jour des champs si spécifiés
		if *title != "Plan par défaut" {
			plan.Title = *title
		}
		if *description != "Description du plan de développement" {
			plan.Description = *description
		}
		if *version != "v1" {
			plan.Version = *version
		}

	} else if *importMD != "" {
		// Mode 2: Import depuis Markdown
		fmt.Printf("Import du plan depuis %s...\n", *importMD)
		plan, err = io.ReadExistingPlanMD(*importMD)
		if err != nil {
			fmt.Printf("Erreur lors de l'import du Markdown: %v\n", err)
			os.Exit(1)
		}

		// Mise à jour des champs si spécifiés
		if *title != "Plan par défaut" {
			plan.Title = *title
		}
		if *description != "Description du plan de développement" {
			plan.Description = *description
		}
		if *version != "v1" {
			plan.Version = *version
		}

	} else {
		// Mode 3: Création à partir des arguments en ligne de commande
		// Valider les entrées
		if *phaseCount < 1 || *phaseCount > 6 {
			fmt.Println("Erreur: Le nombre de phases doit être entre 1 et 6")
			flag.Usage()
			os.Exit(1)
		}

		// Parser les détails de phase (JSON)
		phaseDetails := make(map[string]interface{})
		if *phaseDetailsJSON != "{}" {
			err = json.Unmarshal([]byte(*phaseDetailsJSON), &phaseDetails)
			if err != nil {
				fmt.Printf("Erreur lors du parsing du JSON des détails de phase: %v\n", err)
				flag.Usage()
				os.Exit(1)
			}
		}
		// Mode interactif si demandé
		if *interactiveMode {
			plan, err = interactive.RunInteractiveMode(*version, *title, *description, *phaseCount, *taskDepth)
			if err != nil {
				fmt.Printf("Erreur en mode interactif: %v\n", err)
				os.Exit(1)
			}
		} else {
			// Initialiser le plan en mode non-interactif
			plan = &models.Plan{
				Version:      *version,
				Title:        *title,
				Description:  *description,
				PhaseCount:   *phaseCount,
				Date:         "2023-05-23", // Date fixe pour les tests
				Progress:     0,            // Pour l'instant, progression à 0
				PhaseDetails: phaseDetails,
			}
		}
		// Générer les phases avec la profondeur de tâches spécifiée
		plan.GeneratedPhases = generator.GeneratePhases(*phaseCount, *taskDepth)
	}

	// Générer le contenu Markdown
	content := io.GenerateMarkdown(plan)

	// Sauvegarder dans un fichier Markdown
	outputPath, err := io.SavePlanToFile(content, *outputDir, plan.Version, plan.Title)
	if err != nil {
		fmt.Printf("Erreur lors de la sauvegarde du plan: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Plan de développement généré avec succès: %s\n", outputPath)

	// Exporter en JSON si demandé
	if *exportJSON {
		jsonPath, err := io.ExportPlanToJSON(plan, *outputDir, plan.Version, plan.Title)
		if err != nil {
			fmt.Printf("Erreur lors de l'export JSON: %v\n", err)
		} else {
			fmt.Printf("Plan exporté en JSON: %s\n", jsonPath)
		}
	}
}
