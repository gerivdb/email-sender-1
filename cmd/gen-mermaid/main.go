package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	// Créer le répertoire pour les diagrammes si non existant
	diagramsDir := "diagrams/mermaid"
	err := os.MkdirAll(diagramsDir, 0o755)
	if err != nil {
		fmt.Printf("Erreur lors de la création du répertoire %s: %v\n", diagramsDir, err)
		os.Exit(1)
	}

	// Définir le contenu du diagramme d'architecture général
	architectureMermaidContent := `
flowchart TD
    subgraph Orchestration
        A[auto-roadmap-runner.go] --> B[Scan plans]
        B --> C[Ajout section Jan]
        C --> D[Refactor interfaces]
        D --> E[Maj ContextManager]
        E --> F[Tests & Reporting]
        F --> G[CI/CD]
        G --> H[Validation & Rollback]
    end
    subgraph Mémoire partagée
        X[ContextManager] <--> Y[Jan]
        X <--> Z[Managers IA]
    end
`

	// Écrire le diagramme d'architecture principal
	architectureFilePath := filepath.Join(diagramsDir, "architecture_jan.mmd")
	err = ioutil.WriteFile(architectureFilePath, []byte(architectureMermaidContent), 0o644)
	if err != nil {
		fmt.Printf("Erreur lors de l'écriture de %s: %v\n", architectureFilePath, err)
		os.Exit(1)
	}
	fmt.Printf("Diagramme d'architecture généré : %s\n", architectureFilePath)

	// Lire la liste des plans impactés pour ajouter les diagrammes dans chaque plan
	plansFile, err := ioutil.ReadFile("plans_impactes_jan.md")
	if err != nil {
		fmt.Printf("Erreur lors de la lecture de plans_impactes_jan.md: %v\n", err)
		// Continuer même si le fichier n'existe pas, car le diagramme principal est déjà généré
	} else {
		plans := strings.Split(string(plansFile), "\n")
		mermaidSection := "## Diagramme d'architecture (Jan)\n\n```mermaid%s```\n"

		for _, planPath := range plans {
			planPath = strings.TrimSpace(planPath)
			if planPath == "" {
				continue
			}

			fmt.Printf("Traitement du plan pour diagramme : %s\n", planPath)

			content, err := ioutil.ReadFile(planPath)
			if err != nil {
				fmt.Printf("Erreur lors de la lecture du plan %s: %v\n", planPath, err)
				continue
			}

			planContent := string(content)

			// Vérifier si la section Mermaid existe déjà
			if strings.Contains(planContent, "## Diagramme d'architecture (Jan)") {
				fmt.Printf("  La section de diagramme existe déjà dans %s. Mise à jour si nécessaire.\n", planPath)
				// Optionnel: implémenter une logique de mise à jour si le contenu du diagramme change
				// Pour l'instant, on se contente de sauter pour éviter les doublons ou de réécrire inutilement
				continue
			}

			// Sauvegarder l'original
			backupPath := planPath + ".bak_diagram"
			err = ioutil.WriteFile(backupPath, content, 0o644)
			if err != nil {
				fmt.Printf("Erreur lors de la sauvegarde du backup pour %s: %v\n", planPath, err)
				continue
			}
			fmt.Printf("  Backup créé : %s\n", backupPath)

			// Ajouter la section Mermaid à la fin du fichier
			// Ici, nous injectons le contenu du diagramme directement dans le Markdown
			newContent := planContent + fmt.Sprintf(mermaidSection, architectureMermaidContent)

			err = ioutil.WriteFile(planPath, []byte(newContent), 0o644)
			if err != nil {
				fmt.Printf("Erreur lors de l'écriture du nouveau contenu pour %s: %v\n", planPath, err)
				continue
			}
			fmt.Printf("  Section de diagramme ajoutée à %s.\n", planPath)
		}
	}

	fmt.Println("\nGénération des diagrammes Mermaid terminée.")
}
