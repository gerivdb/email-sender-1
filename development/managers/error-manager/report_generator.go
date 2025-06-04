package errormanager

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"html/template"
	"os"
	"path/filepath"
	"time"

	_ "github.com/lib/pq"
)

// GeneratePatternReport génère un rapport complet d'analyse des patterns selon la micro-étape 4.2.1
func (rg *ReportGenerator) GeneratePatternReport() (*PatternReport, error) {
	report := &PatternReport{
		GeneratedAt:      time.Now(),
		Recommendations:  make([]string, 0),
		CriticalFindings: make([]string, 0),
	}

	// Analyser les patterns
	patterns, err := rg.analyzer.AnalyzeErrorPatterns()
	if err != nil {
		return nil, fmt.Errorf("erreur lors de l'analyse des patterns: %w", err)
	}
	report.TopPatterns = patterns
	report.UniquePatterns = len(patterns)

	// Calculer le total des erreurs
	totalErrors := 0
	for _, pattern := range patterns {
		totalErrors += pattern.Frequency
	}
	report.TotalErrors = totalErrors

	// Obtenir les métriques de fréquence
	metrics, err := rg.analyzer.CreateFrequencyMetrics()
	if err != nil {
		return nil, fmt.Errorf("erreur lors de la création des métriques: %w", err)
	}
	report.FrequencyMetrics = metrics

	// Obtenir les corrélations temporelles
	correlations, err := rg.analyzer.IdentifyTemporalCorrelations(1 * time.Hour)
	if err != nil {
		return nil, fmt.Errorf("erreur lors de l'identification des corrélations: %w", err)
	}
	report.TemporalCorrelations = correlations

	// Générer les recommandations et findings critiques
	rg.generateRecommendations(report)
	rg.identifyCriticalFindings(report)

	return report, nil
}

// generateRecommendations génère des recommandations basées sur l'analyse
func (rg *ReportGenerator) generateRecommendations(report *PatternReport) {
	// Recommandations basées sur les patterns les plus fréquents
	if len(report.TopPatterns) > 0 {
		topPattern := report.TopPatterns[0]
		if topPattern.Frequency > 10 {
			report.Recommendations = append(report.Recommendations,
				fmt.Sprintf("Prioriser la correction du pattern %s:%s (fréquence: %d)",
					topPattern.Module, topPattern.ErrorCode, topPattern.Frequency))
		}
	}

	// Recommandations basées sur les corrélations
	for _, corr := range report.TemporalCorrelations {
		if corr.Correlation > 0.5 {
			report.Recommendations = append(report.Recommendations,
				fmt.Sprintf("Investiguer la corrélation entre %s:%s et %s:%s (score: %.2f)",
					corr.Module1, corr.ErrorCode1, corr.Module2, corr.ErrorCode2, corr.Correlation))
		}
	}

	// Recommandations générales
	if report.TotalErrors > 100 {
		report.Recommendations = append(report.Recommendations,
			"Mettre en place une stratégie de réduction d'erreurs proactive")
	}

	// Recommandations par module
	for module, codes := range report.FrequencyMetrics {
		moduleTotal := 0
		for _, freq := range codes {
			moduleTotal += freq
		}
		if moduleTotal > 20 {
			report.Recommendations = append(report.Recommendations,
				fmt.Sprintf("Réviser la robustesse du module %s (%d erreurs total)", module, moduleTotal))
		}
	}
}

// identifyCriticalFindings identifie les findings critiques
func (rg *ReportGenerator) identifyCriticalFindings(report *PatternReport) {
	// Findings basés sur la sévérité
	for _, pattern := range report.TopPatterns {
		if pattern.Severity == "CRITICAL" && pattern.Frequency > 5 {
			report.CriticalFindings = append(report.CriticalFindings,
				fmt.Sprintf("CRITIQUE: Pattern %s:%s récurrent (%d occurrences)",
					pattern.Module, pattern.ErrorCode, pattern.Frequency))
		}
	}

	// Findings basés sur les tendances temporelles
	for _, pattern := range report.TopPatterns {
		if time.Since(pattern.LastOccurred) < 24*time.Hour && pattern.Frequency > 15 {
			report.CriticalFindings = append(report.CriticalFindings,
				fmt.Sprintf("URGENT: Pattern actif %s:%s (dernière occurrence: %s)",
					pattern.Module, pattern.ErrorCode, pattern.LastOccurred.Format("2006-01-02 15:04:05")))
		}
	}

	// Findings basés sur les corrélations élevées
	for _, corr := range report.TemporalCorrelations {
		if corr.Correlation > 0.8 {
			report.CriticalFindings = append(report.CriticalFindings,
				fmt.Sprintf("ATTENTION: Corrélation forte détectée %s:%s <-> %s:%s (%.2f)",
					corr.Module1, corr.ErrorCode1, corr.Module2, corr.ErrorCode2, corr.Correlation))
		}
	}
}

// ExportToJSON exporte le rapport en JSON selon la micro-étape 4.2.2
func (rg *ReportGenerator) ExportToJSON(report *PatternReport, filename string) error {
	file, err := os.Create(filename)
	if err != nil {
		return fmt.Errorf("erreur lors de la création du fichier JSON: %w", err)
	}
	defer file.Close()

	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")

	err = encoder.Encode(report)
	if err != nil {
		return fmt.Errorf("erreur lors de l'encodage JSON: %w", err)
	}

	fmt.Printf("Rapport JSON exporté vers: %s\n", filename)
	return nil
}

// ExportToHTML exporte le rapport en HTML selon la micro-étape 4.2.2
func (rg *ReportGenerator) ExportToHTML(report *PatternReport, filename string) error {
	htmlTemplate := `
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport d'Analyse des Patterns d'Erreurs</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1, h2 { color: #333; border-bottom: 2px solid #4CAF50; padding-bottom: 10px; }
        .summary { background: #e8f5e8; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .critical { background: #ffebee; border-left: 4px solid #f44336; padding: 15px; margin: 10px 0; }
        .recommendation { background: #e3f2fd; border-left: 4px solid #2196F3; padding: 15px; margin: 10px 0; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #4CAF50; color: white; }
        tr:hover { background-color: #f5f5f5; }
        .timestamp { color: #666; font-size: 0.9em; }
        .frequency { font-weight: bold; color: #4CAF50; }
        .severity { padding: 4px 8px; border-radius: 4px; color: white; font-size: 0.8em; }
        .severity.CRITICAL { background-color: #f44336; }
        .severity.ERROR { background-color: #ff9800; }
        .severity.WARNING { background-color: #ffeb3b; color: #333; }
        .severity.INFO { background-color: #2196F3; }
    </style>
</head>
<body>
    <div class="container">
        <h1>📊 Rapport d'Analyse des Patterns d'Erreurs</h1>
        
        <div class="summary">
            <h3>📈 Résumé Exécutif</h3>
            <p><strong>Généré le:</strong> <span class="timestamp">{{.GeneratedAt.Format "2006-01-02 15:04:05"}}</span></p>
            <p><strong>Total des erreurs:</strong> <span class="frequency">{{.TotalErrors}}</span></p>
            <p><strong>Patterns uniques:</strong> {{.UniquePatterns}}</p>
            <p><strong>Corrélations détectées:</strong> {{len .TemporalCorrelations}}</p>
        </div>

        {{if .CriticalFindings}}
        <h2>🚨 Findings Critiques</h2>
        {{range .CriticalFindings}}
        <div class="critical">{{.}}</div>
        {{end}}
        {{end}}

        {{if .Recommendations}}
        <h2>💡 Recommandations</h2>
        {{range .Recommendations}}
        <div class="recommendation">{{.}}</div>
        {{end}}
        {{end}}

        <h2>📋 Top Patterns d'Erreurs</h2>
        <table>
            <thead>
                <tr>
                    <th>Module</th>
                    <th>Code d'Erreur</th>
                    <th>Fréquence</th>
                    <th>Sévérité</th>
                    <th>Première Occurrence</th>
                    <th>Dernière Occurrence</th>
                </tr>
            </thead>
            <tbody>
                {{range .TopPatterns}}
                <tr>
                    <td>{{.Module}}</td>
                    <td>{{.ErrorCode}}</td>
                    <td><span class="frequency">{{.Frequency}}</span></td>
                    <td><span class="severity {{.Severity}}">{{.Severity}}</span></td>
                    <td class="timestamp">{{.FirstOccurred.Format "2006-01-02 15:04:05"}}</td>
                    <td class="timestamp">{{.LastOccurred.Format "2006-01-02 15:04:05"}}</td>
                </tr>
                {{end}}
            </tbody>
        </table>

        {{if .TemporalCorrelations}}
        <h2>⏱️ Corrélations Temporelles</h2>
        <table>
            <thead>
                <tr>
                    <th>Erreur 1</th>
                    <th>Erreur 2</th>
                    <th>Score de Corrélation</th>
                    <th>Écart Moyen</th>
                </tr>
            </thead>
            <tbody>
                {{range .TemporalCorrelations}}
                <tr>
                    <td>{{.Module1}}:{{.ErrorCode1}}</td>
                    <td>{{.Module2}}:{{.ErrorCode2}}</td>
                    <td><span class="frequency">{{printf "%.2f" .Correlation}}</span></td>
                    <td class="timestamp">{{.OccurrenceGap}}</td>
                </tr>
                {{end}}
            </tbody>
        </table>
        {{end}}

        <h2>📊 Métriques de Fréquence par Module</h2>
        {{range $module, $codes := .FrequencyMetrics}}
        <h3>{{$module}}</h3>
        <table>
            <thead>
                <tr>
                    <th>Code d'Erreur</th>
                    <th>Fréquence</th>
                </tr>
            </thead>
            <tbody>
                {{range $code, $freq := $codes}}
                <tr>
                    <td>{{$code}}</td>
                    <td><span class="frequency">{{$freq}}</span></td>
                </tr>
                {{end}}
            </tbody>
        </table>
        {{end}}

        <div class="timestamp" style="text-align: center; margin-top: 40px; padding-top: 20px; border-top: 1px solid #ddd;">
            Rapport généré automatiquement par le Gestionnaire d'Erreurs EMAIL_SENDER_1
        </div>
    </div>
</body>
</html>`

	tmpl, err := template.New("report").Parse(htmlTemplate)
	if err != nil {
		return fmt.Errorf("erreur lors du parsing du template HTML: %w", err)
	}

	file, err := os.Create(filename)
	if err != nil {
		return fmt.Errorf("erreur lors de la création du fichier HTML: %w", err)
	}
	defer file.Close()

	err = tmpl.Execute(file, report)
	if err != nil {
		return fmt.Errorf("erreur lors de l'exécution du template HTML: %w", err)
	}

	fmt.Printf("Rapport HTML exporté vers: %s\n", filename)
	return nil
}

// TestReportGeneration teste la génération de rapports
func TestReportGeneration() {
	// Simuler une connexion à la base (à adapter selon votre configuration)
	db, err := sql.Open("postgres", "host=localhost port=5432 user=postgres password=postgres dbname=email_sender_errors sslmode=disable")
	if err != nil {
		fmt.Printf("Erreur de connexion à la base de données: %v\n", err)
		fmt.Println("Mode test avec données simulées activé...")
		TestReportGenerationWithMockData()
		return
	}
	defer db.Close()

	analyzer := NewPatternAnalyzer(db)
	generator := NewReportGenerator(analyzer)

	fmt.Println("=== Test de génération de rapport ===")

	// Générer le rapport
	report, err := generator.GeneratePatternReport()
	if err != nil {
		fmt.Printf("Erreur lors de la génération du rapport: %v\n", err)
		return
	}

	// Créer le dossier de sortie s'il n'existe pas
	outputDir := "development/managers/error-manager/reports"
	err = os.MkdirAll(outputDir, 0755)
	if err != nil {
		fmt.Printf("Erreur lors de la création du dossier: %v\n", err)
		return
	}

	// Exporter en JSON
	jsonFile := filepath.Join(outputDir, fmt.Sprintf("pattern_report_%s.json", time.Now().Format("20060102_150405")))
	err = generator.ExportToJSON(report, jsonFile)
	if err != nil {
		fmt.Printf("Erreur lors de l'export JSON: %v\n", err)
	}

	// Exporter en HTML
	htmlFile := filepath.Join(outputDir, fmt.Sprintf("pattern_report_%s.html", time.Now().Format("20060102_150405")))
	err = generator.ExportToHTML(report, htmlFile)
	if err != nil {
		fmt.Printf("Erreur lors de l'export HTML: %v\n", err)
	}

	fmt.Printf("Rapport généré avec succès:\n")
	fmt.Printf("- Total des erreurs: %d\n", report.TotalErrors)
	fmt.Printf("- Patterns uniques: %d\n", report.UniquePatterns)
	fmt.Printf("- Corrélations: %d\n", len(report.TemporalCorrelations))
	fmt.Printf("- Recommandations: %d\n", len(report.Recommendations))
	fmt.Printf("- Findings critiques: %d\n", len(report.CriticalFindings))
}

// TestReportGenerationWithMockData teste avec des données simulées
func TestReportGenerationWithMockData() {
	fmt.Println("=== Test avec données simulées ===")

	// Créer un rapport simulé
	mockReport := &PatternReport{
		GeneratedAt:    time.Now(),
		TotalErrors:    45,
		UniquePatterns: 8,
		TopPatterns: []PatternMetrics{
			{
				ErrorCode:     "DB_CONNECTION_FAILED",
				Module:        "database-manager",
				Frequency:     15,
				LastOccurred:  time.Now().Add(-30 * time.Minute),
				FirstOccurred: time.Now().Add(-24 * time.Hour),
				Severity:      "CRITICAL",
				Context:       map[string]interface{}{"type": "connection_timeout"},
			},
			{
				ErrorCode:     "SMTP_AUTH_ERROR",
				Module:        "email-manager",
				Frequency:     12,
				LastOccurred:  time.Now().Add(-1 * time.Hour),
				FirstOccurred: time.Now().Add(-48 * time.Hour),
				Severity:      "ERROR",
				Context:       map[string]interface{}{"type": "authentication"},
			},
		},
		FrequencyMetrics: map[string]map[string]int{
			"database-manager": {
				"DB_CONNECTION_FAILED": 15,
				"QUERY_TIMEOUT":        5,
			},
			"email-manager": {
				"SMTP_AUTH_ERROR": 12,
				"RATE_LIMIT":      8,
			},
		},
		TemporalCorrelations: []TemporalCorrelation{
			{
				ErrorCode1:    "DB_CONNECTION_FAILED",
				ErrorCode2:    "SMTP_AUTH_ERROR",
				Module1:       "database-manager",
				Module2:       "email-manager",
				Correlation:   0.75,
				TimeWindow:    1 * time.Hour,
				OccurrenceGap: 5 * time.Minute,
			},
		},
		Recommendations: []string{
			"Prioriser la correction du pattern database-manager:DB_CONNECTION_FAILED (fréquence: 15)",
			"Investiguer la corrélation entre database-manager:DB_CONNECTION_FAILED et email-manager:SMTP_AUTH_ERROR (score: 0.75)",
		},
		CriticalFindings: []string{
			"CRITIQUE: Pattern database-manager:DB_CONNECTION_FAILED récurrent (15 occurrences)",
			"URGENT: Pattern actif database-manager:DB_CONNECTION_FAILED (dernière occurrence: " + time.Now().Add(-30*time.Minute).Format("2006-01-02 15:04:05") + ")",
		},
	}

	generator := &ReportGenerator{}

	// Créer le dossier de sortie s'il n'existe pas
	outputDir := "development/managers/error-manager/reports"
	err := os.MkdirAll(outputDir, 0755)
	if err != nil {
		fmt.Printf("Erreur lors de la création du dossier: %v\n", err)
		return
	}

	// Exporter en JSON
	jsonFile := filepath.Join(outputDir, fmt.Sprintf("mock_pattern_report_%s.json", time.Now().Format("20060102_150405")))
	err = generator.ExportToJSON(mockReport, jsonFile)
	if err != nil {
		fmt.Printf("Erreur lors de l'export JSON: %v\n", err)
	}

	// Exporter en HTML
	htmlFile := filepath.Join(outputDir, fmt.Sprintf("mock_pattern_report_%s.html", time.Now().Format("20060102_150405")))
	err = generator.ExportToHTML(mockReport, htmlFile)
	if err != nil {
		fmt.Printf("Erreur lors de l'export HTML: %v\n", err)
	}
	fmt.Printf("Rapport simulé généré avec succès:\n")
	fmt.Printf("- Total des erreurs: %d\n", mockReport.TotalErrors)
	fmt.Printf("- Patterns uniques: %d\n", mockReport.UniquePatterns)
	fmt.Printf("- Corrélations: %d\n", len(mockReport.TemporalCorrelations))
	fmt.Printf("- Recommandations: %d\n", len(mockReport.Recommendations))
	fmt.Printf("- Findings critiques: %d\n", len(mockReport.CriticalFindings))
}
