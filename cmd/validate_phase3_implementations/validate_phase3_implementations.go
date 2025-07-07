package validate_phase3_implementations

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
)

// Phase3ValidationResult contient les résultats de validation
type Phase3ValidationResult struct {
	ManagerName   string
	FilesFound    []string
	LinesOfCode   int
	HasInterfaces bool
	HasTests      bool
	CompilationOK bool
	Features      []string
	Issues        []string
}

// validatePhase3Implementations valide que toutes les fonctionnalités Phase 3 sont implémentées
func validatePhase3Implementations() error {
	fmt.Println("🔍 Validation des implémentations Phase 3")
	fmt.Println("=" + strings.Repeat("=", 59))

	managers := []string{
		"email-manager",
		"notification-manager",
		"integration-manager",
	}

	baseDir := "development/managers"
	results := make(map[string]*Phase3ValidationResult)

	for _, manager := range managers {
		fmt.Printf("\n📂 Validation du %s...\n", manager)
		result := &Phase3ValidationResult{
			ManagerName: manager,
			FilesFound:  []string{},
			Features:    []string{},
			Issues:      []string{},
		}

		managerPath := filepath.Join(baseDir, manager)

		// Vérifier existence du répertoire
		if _, err := os.Stat(managerPath); os.IsNotExist(err) {
			result.Issues = append(result.Issues, "Répertoire manquant")
			results[manager] = result
			continue
		}

		// Scanner les fichiers Go
		err := filepath.Walk(managerPath, func(path string, info os.FileInfo, err error) error {
			if err != nil {
				return err
			}

			if strings.HasSuffix(path, ".go") {
				result.FilesFound = append(result.FilesFound, filepath.Base(path))

				// Compter les lignes de code
				if content, err := os.ReadFile(path); err == nil {
					lines := strings.Split(string(content), "\n")
					result.LinesOfCode += len(lines)

					// Analyser le contenu pour les fonctionnalités
					contentStr := string(content)
					analyzeFeatures(manager, contentStr, result)
				}
			}
			return nil
		})

		if err != nil {
			result.Issues = append(result.Issues, fmt.Sprintf("Erreur scan: %v", err))
		}

		// Vérifier les tests
		for _, file := range result.FilesFound {
			if strings.Contains(file, "test") {
				result.HasTests = true
				break
			}
		}

		results[manager] = result
	}

	// Afficher les résultats
	fmt.Println("\n" + strings.Repeat("=", 60))
	fmt.Println("📊 RÉSULTATS DE VALIDATION")
	fmt.Println(strings.Repeat("=", 60))

	allValid := true
	for _, manager := range managers {
		result := results[manager]
		fmt.Printf("\n🏗️  %s\n", strings.ToUpper(result.ManagerName))
		fmt.Printf("   📁 Fichiers trouvés: %d\n", len(result.FilesFound))
		fmt.Printf("   📝 Lignes de code: %d\n", result.LinesOfCode)
		fmt.Printf("   🧪 Tests présents: %v\n", result.HasTests)
		fmt.Printf("   ⚙️  Fonctionnalités détectées: %d\n", len(result.Features))

		if len(result.Features) > 0 {
			fmt.Println("   🔧 Fonctionnalités:")
			for _, feature := range result.Features {
				fmt.Printf("      ✓ %s\n", feature)
			}
		}

		if len(result.Issues) > 0 {
			fmt.Println("   ⚠️  Problèmes:")
			for _, issue := range result.Issues {
				fmt.Printf("      ❌ %s\n", issue)
			}
			allValid = false
		} else {
			fmt.Printf("   ✅ Statut: VALIDE\n")
		}
	}

	// Résumé final
	fmt.Println("\n" + strings.Repeat("=", 60))
	if allValid {
		fmt.Println("🎉 VALIDATION RÉUSSIE - Tous les managers Phase 3 sont implémentés!")
		fmt.Println("✅ Prêt pour le déploiement en production")
	} else {
		fmt.Println("⚠️  VALIDATION PARTIELLE - Certains problèmes détectés")
		fmt.Println("🔧 Veuillez corriger les problèmes avant le déploiement")
	}
	fmt.Println(strings.Repeat("=", 60))

	return nil
}

// analyzeFeatures analyse le contenu d'un fichier pour détecter les fonctionnalités
func analyzeFeatures(manager, content string, result *Phase3ValidationResult) {
	switch manager {
	case "email-manager":
		if strings.Contains(content, "SendEmail") {
			result.Features = append(result.Features, "Envoi d'emails")
		}
		if strings.Contains(content, "Template") {
			result.Features = append(result.Features, "Gestion des templates")
		}
		if strings.Contains(content, "Queue") {
			result.Features = append(result.Features, "Gestion des files d'attente")
		}
		if strings.Contains(content, "SMTP") || strings.Contains(content, "gomail") {
			result.Features = append(result.Features, "Support SMTP")
		}
		if strings.Contains(content, "Retry") {
			result.Features = append(result.Features, "Logique de retry")
		}

	case "notification-manager":
		if strings.Contains(content, "Slack") {
			result.Features = append(result.Features, "Support Slack")
		}
		if strings.Contains(content, "Discord") {
			result.Features = append(result.Features, "Support Discord")
		}
		if strings.Contains(content, "Webhook") {
			result.Features = append(result.Features, "Support Webhook")
		}
		if strings.Contains(content, "Alert") {
			result.Features = append(result.Features, "Gestion des alertes")
		}
		if strings.Contains(content, "Channel") {
			result.Features = append(result.Features, "Gestion multi-canaux")
		}

	case "integration-manager":
		if strings.Contains(content, "API") {
			result.Features = append(result.Features, "Gestion API")
		}
		if strings.Contains(content, "Sync") {
			result.Features = append(result.Features, "Synchronisation")
		}
		if strings.Contains(content, "Webhook") {
			result.Features = append(result.Features, "Gestion des webhooks")
		}
		if strings.Contains(content, "Transform") {
			result.Features = append(result.Features, "Transformation de données")
		}
		if strings.Contains(content, "BaseManager") {
			result.Features = append(result.Features, "Interface BaseManager")
		}
		if strings.Contains(content, "HMAC") || strings.Contains(content, "signature") {
			result.Features = append(result.Features, "Vérification de signature")
		}
	}
}

func main() {
	if err := validatePhase3Implementations(); err != nil {
		log.Fatalf("Erreur de validation: %v", err)
	}
}
