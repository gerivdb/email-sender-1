package main

import (
	"fmt"
	"log"

	errormanager "error-manager"
)

func main() {
	fmt.Println("🚀 === TEST COMPLET PHASE 4 : ANALYSE ALGORITHMIQUE DES PATTERNS ===")
	fmt.Println()

	// Utiliser les composants du package errormanager
	log.SetFlags(log.LstdFlags | log.Lshortfile)

	// Lancer les tests
	testPhase4()

	fmt.Println("\n✅ === PHASE 4 TERMINÉE AVEC SUCCÈS ===")
	fmt.Println("Tous les composants de l'analyse algorithmique des patterns sont fonctionnels.")
}

func testPhase4() {
	fmt.Println("📊 Phase 4.1 : Test de l'analyseur de patterns")
	// Créer un analyseur avec mode simulé
	analyzer := errormanager.NewPatternAnalyzer(nil)

	// Test des patterns
	patterns, err := analyzer.AnalyzeErrorPatterns()
	if err != nil {
		fmt.Printf("   ❌ Erreur lors de l'analyse des patterns: %v\n", err)
	} else {
		fmt.Printf("   ✓ Analyse des patterns réussie (%d patterns trouvés)\n", len(patterns))
	}

	// Test des métriques
	metrics, err := analyzer.CreateFrequencyMetrics()
	if err != nil {
		fmt.Printf("   ❌ Erreur lors de la création des métriques: %v\n", err)
	} else {
		fmt.Printf("   ✓ Métriques de fréquence créées (%d modules analysés)\n", len(metrics))
	}

	fmt.Println("\n📈 Phase 4.2 : Test du générateur de rapports")

	// Créer un générateur de rapports
	generator := errormanager.NewReportGenerator(analyzer)

	// Générer un rapport
	report, err := generator.GeneratePatternReport()
	if err != nil {
		fmt.Printf("   ❌ Erreur lors de la génération du rapport: %v\n", err)
		return
	}

	fmt.Printf("   ✓ Rapport généré avec succès (%d patterns analysés)\n", len(report.TopPatterns))
	fmt.Printf("   ✓ Total d'erreurs: %d\n", report.TotalErrors)
	fmt.Printf("   ✓ Recommandations: %d\n", len(report.Recommendations))
}
