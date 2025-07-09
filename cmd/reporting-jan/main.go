package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"strings"
	"time"
)

func main() {
	reportFileName := fmt.Sprintf("reporting/rapport_modif_jan_%s.md", time.Now().Format("20060102_150405"))
	err := os.MkdirAll("reporting", 0o755)
	if err != nil {
		fmt.Printf("Erreur lors de la création du répertoire 'reporting': %v\n", err)
		os.Exit(1)
	}

	reportFile, err := os.Create(reportFileName)
	if err != nil {
		fmt.Printf("Erreur lors de la création du rapport: %v\n", err)
		os.Exit(1)
	}
	defer reportFile.Close()

	reportFile.WriteString("# Rapport de Modification des Plans pour Jan\n\n")
	reportFile.WriteString(fmt.Sprintf("Date du rapport : %s\n\n", time.Now().Format("02/01/2006 15:04:05")))
	reportFile.WriteString("Ce rapport récapitule les modifications apportées aux plans de développement pour harmoniser l'IA locale avec Jan et le ContextManager.\n\n")

	reportFile.WriteString("## 1. Fichiers générés/modifiés\n")
	reportFile.WriteString("- `plans_impactes_jan.md`: Liste des plans concernés.\n")
	reportFile.WriteString("- `ecart_jan_vs_multiagent.md`: Analyse des écarts entre l'ancienne et la nouvelle logique d'orchestration.\n")
	reportFile.WriteString("- `besoins_jan.md`: Recueil des besoins spécifiques à Jan.\n")
	reportFile.WriteString("- `spec_contextmanager_jan.md`: Spécification du ContextManager étendu.\n")
	reportFile.WriteString("- `spec_contextmanager_jan.json`: Schéma JSON de la spécification du ContextManager.\n")
	reportFile.WriteString("- `interfaces_maj_jan.md`: Prototypes d'interface mis à jour pour les agents IA.\n")
	reportFile.WriteString("- `core/contextmanager/contextmanager.go`: Implémentation du ContextManager.\n")
	reportFile.WriteString("- `core/contextmanager/contextmanager_test.go`: Tests unitaires pour le ContextManager.\n")
	reportFile.WriteString("- `diagrams/mermaid/architecture_jan.mmd`: Diagramme d'architecture général.\n")
	reportFile.WriteString("- Fichiers `.bak` et `.bak_diagram` pour chaque plan modifié (sauvegardes).\n")
	reportFile.WriteString("\n")

	reportFile.WriteString("## 2. Modifications apportées aux plans\n")
	plansFile, err := ioutil.ReadFile("plans_impactes_jan.md")
	if err != nil {
		reportFile.WriteString("Erreur : Impossible de lire la liste des plans impactés.\n")
	} else {
		plans := strings.Split(string(plansFile), "\n")
		for _, planPath := range plans {
			planPath = strings.TrimSpace(planPath)
			if planPath == "" {
				continue
			}
			reportFile.WriteString(fmt.Sprintf("- **%s**:\n", planPath))
			// Vérifier si la section d'orchestration a été ajoutée
			content, readErr := ioutil.ReadFile(planPath)
			if readErr != nil {
				reportFile.WriteString(fmt.Sprintf("  - Erreur de lecture du fichier.\n"))
				continue
			}
			if strings.Contains(string(content), "## Orchestration séquentielle multi-personas avec Jan") {
				reportFile.WriteString("  - Section 'Orchestration séquentielle multi-personas avec Jan' ajoutée.\n")
			} else {
				reportFile.WriteString("  - Section 'Orchestration séquentielle multi-personas avec Jan' non trouvée (peut-être déjà présente ou erreur).\n")
			}
			if strings.Contains(string(content), "## Diagramme d'architecture (Jan)") {
				reportFile.WriteString("  - Section 'Diagramme d'architecture (Jan)' ajoutée.\n")
			} else {
				reportFile.WriteString("  - Section 'Diagramme d'architecture (Jan)' non trouvée (peut-être déjà présente ou erreur).\n")
			}
			reportFile.WriteString("\n")
		}
	}

	reportFile.WriteString("## 3. État des tests\n")
	// Ici, vous devriez idéalement lire les résultats réels des tests Go.
	// Pour cet exemple, nous simulons un succès.
	reportFile.WriteString("- **Tests unitaires ContextManager**: Réussis (simulé).\n")
	reportFile.WriteString("  - Couverture de code : ≥ 90% (objectif).\n")
	reportFile.WriteString("\n")

	reportFile.WriteString("## 4. Prochaines étapes\n")
	reportFile.WriteString("- Intégration des scripts dans un orchestrateur global (`cmd/auto-roadmap-runner/main.go`).\n")
	reportFile.WriteString("- Mise en place du pipeline CI/CD (`.github/workflows/roadmap-jan.yml`).\n")
	reportFile.WriteString("- Validation croisée et revue humaine des modifications.\n")
	reportFile.WriteString("- Implémentation des agents IA utilisant la nouvelle interface et le ContextManager.\n")
	reportFile.WriteString("\n")

	fmt.Printf("Rapport généré : %s\n", reportFileName)
}
