package main

import (
	"fmt"
	"os/exec"
	"strings"
)

func main() {
	fmt.Println("Démarrage de l'analyse des dépendances Go du projet...")

	// Exécuter go mod graph
	fmt.Println("\n--- Analyse du graphe des modules (go mod graph) ---")
	graphOutput, err := runCommandAndCapture("go", "mod", "graph")
	if err != nil {
		fmt.Printf("Erreur lors de l'exécution de 'go mod graph': %v\n", err)
	} else {
		fmt.Println(graphOutput)
	}

	// Exécuter go mod tidy pour nettoyer et obtenir les informations sur les modules non utilisés/manquants
	fmt.Println("\n--- Exécution de 'go mod tidy' pour diagnostic ---")
	tidyOutput, err := runCommandAndCapture("go", "mod", "tidy")
	if err != nil {
		fmt.Printf("Erreur lors de l'exécution de 'go mod tidy': %v\n", err)
	} else {
		fmt.Println(tidyOutput)
	}

	// Analyser les erreurs et avertissements des logs précédents
	fmt.Println("\n--- Analyse des problèmes de dépendances identifiés ---")
	problematicModules := []string{
		"github.com/gerivdb/email-sender-1/tools/pkg/manager",
		"github.com/gerivdb/email-sender-1/tools/operations/validation",
		"github.com/gerivdb/email-sender-1/tools/core/toolkit",
		"github.com/gerivdb/email-sender-1/development/managers/dependency-manager",
		"github.com/gerivdb/email-sender-1/development/managers/security-manager",
		"github.com/gerivdb/email-sender-1/development/managers/storage-manager",
		"github.com/gerivdb/email-sender-1/development/managers/advanced-autonomy-manager/internal/config",
		"github.com/gerivdb/email-sender-1/development/managers/advanced-autonomy-manager/internal/logging",
		"github.com/chrlesur/Email_Sender/development/managers/ai-template-manager/interfaces",
		"github.com/chrlesur/Email_Sender/development/managers/ai-template-manager/internal/ai",
		"github.com/chrlesur/Email_Sender/development/managers/interfaces",
		"github.com/contextual-memory-manager/interfaces",
		"github.com/contextual-memory-manager/internal/ast",
		"github.com/contextual-memory-manager/internal/monitoring",
		"github.com/contextual-memory-manager/pkg/manager",
		"github.com/contextual-memory-manager/internal/hybrid",
		"github.com/contextual-memory-manager/internal/indexing",
		"github.com/contextual-memory-manager/internal/integration",
		"github.com/contextual-memory-manager/internal/retrieval",
		"github.com/contextual-memory-manager/pkg/interfaces",
		"github.com/email-sender-manager/interfaces",
		"github.com/email-sender-manager/dependency-manager",
		"github.com/email-sender-manager/security-manager",
		"github.com/email-sender-manager/storage-manager",
		"github.com/email-sender-notification-manager/interfaces",
		"github.com/chrlesur/Email_Sender/development/managers/smart-variable-manager/interfaces",
		"github.com/chrlesur/Email_Sender/development/managers/smart-variable-manager/internal/analyzer",
		"github.com/fmoua/email-sender/development/managers/template-performance-manager/interfaces",
		"github.com/fmoua/email-sender/development/managers/template-performance-manager/internal/analytics",
		"github.com/fmoua/email-sender/development/managers/template-performance-manager/internal/neural",
		"github.com/fmoua/email-sender/development/managers/template-performance-manager/internal/optimization",
		"github.com/your-org/email-sender/development/managers/interfaces",
		"github.com/your-org/email-sender/development/managers/integration-manager",
		"github.com/lib/pq", // Exemple de dépendance implicite
		"github.com/oapi-codegen/runtime",
		"github.com/go-sql-driver/mysql",
		"modernc.org/sqlite",
		"github.com/gomarkdown/markdown/ast",
		"github.com/gomarkdown/markdown/parser",
		"github.com/pdfcpu/pdfcpu/pkg/api",
		"github.com/saintfish/chardet",
		"github.com/schollz/progressbar/v3",
		"github.com/go-redis/redis/v8",
		"github.com/gorilla/websocket",
	}

	for _, mod := range problematicModules {
		fmt.Printf("\nAnalyse du module: %s\n", mod)
		// Tenter de trouver pourquoi le module est requis
		whyOutput, err := runCommandAndCapture("go", "mod", "why", mod)
		if err != nil {
			fmt.Printf("  'go mod why %s' a échoué: %v\n", mod, err)
			fmt.Printf("  Suggestion: Vérifier si le module est correctement référencé dans le code ou si un 'replace' est nécessaire dans go.mod.\n")
		} else {
			fmt.Printf("  Résultat de 'go mod why %s':\n%s\n", mod, whyOutput)
			if strings.Contains(whyOutput, "(main module does not need package") {
				fmt.Printf("  Suggestion: Ce module n'est pas directement requis par le module principal. Il pourrait être une dépendance transitive non utilisée ou un reste d'ancien code. Envisager de le supprimer si non utilisé ou d'ajouter une directive 'exclude' si nécessaire.\n")
			}
		}

		// Tenter de 'go get' le module pour voir les erreurs de téléchargement
		getOutput, err := runCommandAndCapture("go", "get", mod)
		if err != nil {
			fmt.Printf("  'go get %s' a échoué: %v\n", mod, err)
			fmt.Printf("  Suggestion: Le module pourrait être introuvable, privé, ou nécessiter des informations d'authentification. Vérifier le chemin d'accès au dépôt ou les permissions.\n")
		} else {
			fmt.Printf("  'go get %s' a réussi (ou trouvé en cache). Cela ne signifie pas que toutes les références sont valides.\n", mod)
		}
	}

	fmt.Println("\nAnalyse des dépendances Go terminée. Veuillez examiner la sortie ci-dessus pour les problèmes et les suggestions.")
	fmt.Println("Actions recommandées: Vérifier les chemins d'importation dans le code source, ajuster les directives 'replace' ou 'require' dans go.mod, ou supprimer les références aux modules non existants/non utilisés.")
}

func runCommandAndCapture(command string, args ...string) (string, error) {
	cmd := exec.Command(command, args...)
	var stdout, stderr strings.Builder
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	err := cmd.Run()
	if err != nil {
		return "", fmt.Errorf("commande '%s %s' a échoué avec: %s (stdout: %s)", command, strings.Join(args, " "), stderr.String(), stdout.String())
	}
	_ = stdout // Marquer comme utilisé
	return stdout.String(), nil
}
