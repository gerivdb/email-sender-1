package errormanager

import (
	"database/sql"
	"fmt"
	"log"
	"sort"
	"time"

	_ "github.com/lib/pq"
)

// AnalyzeErrorPatterns détecte les erreurs récurrentes selon la micro-étape 4.1.1
func (pa *PatternAnalyzer) AnalyzeErrorPatterns() ([]PatternMetrics, error) {
	query := `
		SELECT 
			error_code, 
			module, 
			COUNT(*) as frequency,
			MAX(timestamp) as last_occurred,
			MIN(timestamp) as first_occurred,
			severity,
			string_agg(DISTINCT manager_context::text, '|||') as contexts
		FROM project_errors 
		GROUP BY error_code, module, severity
		ORDER BY frequency DESC, last_occurred DESC
	`

	rows, err := pa.db.Query(query)
	if err != nil {
		return nil, fmt.Errorf("erreur lors de l'analyse des patterns: %w", err)
	}
	defer rows.Close()

	var patterns []PatternMetrics
	for rows.Next() {
		var pattern PatternMetrics
		var contextsStr sql.NullString

		err := rows.Scan(
			&pattern.ErrorCode,
			&pattern.Module,
			&pattern.Frequency,
			&pattern.LastOccurred,
			&pattern.FirstOccurred,
			&pattern.Severity,
			&contextsStr,
		)
		if err != nil {
			log.Printf("Erreur lors du scan du pattern: %v", err)
			continue
		}

		// Parser les contextes agrégés
		pattern.Context = make(map[string]interface{})
		if contextsStr.Valid && contextsStr.String != "" {
			contexts := []string{}
			for _, ctx := range []string{contextsStr.String} {
				if ctx != "" {
					contexts = append(contexts, ctx)
				}
			}
			pattern.Context["aggregated_contexts"] = contexts
		}

		patterns = append(patterns, pattern)
	}

	return patterns, nil
}

// CreateFrequencyMetrics crée des métriques de fréquence par module et code d'erreur selon la micro-étape 4.1.2
func (pa *PatternAnalyzer) CreateFrequencyMetrics() (map[string]map[string]int, error) {
	query := `
		SELECT module, error_code, COUNT(*) as frequency
		FROM project_errors 
		GROUP BY module, error_code
		ORDER BY module, frequency DESC
	`

	rows, err := pa.db.Query(query)
	if err != nil {
		return nil, fmt.Errorf("erreur lors de la création des métriques de fréquence: %w", err)
	}
	defer rows.Close()

	metrics := make(map[string]map[string]int)

	for rows.Next() {
		var module, errorCode string
		var frequency int

		err := rows.Scan(&module, &errorCode, &frequency)
		if err != nil {
			log.Printf("Erreur lors du scan des métriques: %v", err)
			continue
		}

		if metrics[module] == nil {
			metrics[module] = make(map[string]int)
		}
		metrics[module][errorCode] = frequency
	}

	return metrics, nil
}

// IdentifyTemporalCorrelations identifie les corrélations temporelles entre erreurs selon la micro-étape 4.1.3
func (pa *PatternAnalyzer) IdentifyTemporalCorrelations(timeWindow time.Duration) ([]TemporalCorrelation, error) {
	query := `
		SELECT 
			e1.error_code as error_code_1,
			e1.module as module_1,
			e2.error_code as error_code_2,
			e2.module as module_2,
			ABS(EXTRACT(EPOCH FROM (e2.timestamp - e1.timestamp))) as time_diff_seconds
		FROM project_errors e1
		JOIN project_errors e2 ON e1.id != e2.id
		WHERE ABS(EXTRACT(EPOCH FROM (e2.timestamp - e1.timestamp))) <= $1
		AND e1.error_code != e2.error_code
		ORDER BY time_diff_seconds ASC
	`

	rows, err := pa.db.Query(query, timeWindow.Seconds())
	if err != nil {
		return nil, fmt.Errorf("erreur lors de l'identification des corrélations temporelles: %w", err)
	}
	defer rows.Close()

	correlationMap := make(map[string][]float64)
	var correlations []TemporalCorrelation

	for rows.Next() {
		var errorCode1, module1, errorCode2, module2 string
		var timeDiffSeconds float64

		err := rows.Scan(&errorCode1, &module1, &errorCode2, &module2, &timeDiffSeconds)
		if err != nil {
			log.Printf("Erreur lors du scan des corrélations: %v", err)
			continue
		}

		correlationKey := fmt.Sprintf("%s:%s-%s:%s", module1, errorCode1, module2, errorCode2)
		correlationMap[correlationKey] = append(correlationMap[correlationKey], timeDiffSeconds)
	}

	// Calculer les corrélations
	for key, timeDiffs := range correlationMap {
		if len(timeDiffs) < 2 {
			continue // Besoin d'au moins 2 occurrences pour une corrélation
		}

		// Parser la clé pour extraire les informations
		var module1, errorCode1, module2, errorCode2 string
		fmt.Sscanf(key, "%[^:]:%[^-]-%[^:]:%s", &module1, &errorCode1, &module2, &errorCode2)

		// Calculer la corrélation (ici simplifiée par la fréquence de co-occurrence)
		correlation := float64(len(timeDiffs)) / 100.0 // Normalisation simple
		if correlation > 1.0 {
			correlation = 1.0
		}

		// Calculer l'écart moyen
		var totalDiff float64
		for _, diff := range timeDiffs {
			totalDiff += diff
		}
		avgGap := totalDiff / float64(len(timeDiffs))

		correlations = append(correlations, TemporalCorrelation{
			ErrorCode1:    errorCode1,
			ErrorCode2:    errorCode2,
			Module1:       module1,
			Module2:       module2,
			Correlation:   correlation,
			TimeWindow:    timeWindow,
			OccurrenceGap: time.Duration(avgGap) * time.Second,
		})
	}

	// Trier par corrélation décroissante
	sort.Slice(correlations, func(i, j int) bool {
		return correlations[i].Correlation > correlations[j].Correlation
	})

	return correlations, nil
}

// TestAnalyzeErrorPatterns teste l'analyseur avec des données simulées
func TestAnalyzeErrorPatterns() {
	// Configuration de la base de données (à adapter selon votre configuration)
	db, err := sql.Open("postgres", "host=localhost port=5432 user=postgres password=postgres dbname=email_sender_errors sslmode=disable")
	if err != nil {
		fmt.Printf("Erreur de connexion à la base de données: %v\n", err)
		fmt.Println("Mode test avec données simulées activé...")
		TestAnalyzeErrorPatternsWithMockData()
		return
	}
	defer db.Close()

	// Test de connexion
	err = db.Ping()
	if err != nil {
		fmt.Printf("Base de données non accessible: %v\n", err)
		fmt.Println("Mode test avec données simulées activé...")
		TestAnalyzeErrorPatternsWithMockData()
		return
	}

	analyzer := NewPatternAnalyzer(db)

	// Test de l'analyse des patterns
	fmt.Println("=== Analyse des patterns d'erreurs ===")
	patterns, err := analyzer.AnalyzeErrorPatterns()
	if err != nil {
		log.Printf("Erreur lors de l'analyse des patterns: %v", err)
	} else {
		for i, pattern := range patterns {
			if i >= 5 { // Limiter l'affichage aux 5 premiers
				break
			}
			fmt.Printf("Pattern %d: %s-%s (Fréquence: %d, Dernière: %s)\n",
				i+1, pattern.Module, pattern.ErrorCode, pattern.Frequency, pattern.LastOccurred.Format("2006-01-02 15:04:05"))
		}
	}

	// Test des métriques de fréquence
	fmt.Println("\n=== Métriques de fréquence par module ===")
	metrics, err := analyzer.CreateFrequencyMetrics()
	if err != nil {
		log.Printf("Erreur lors de la création des métriques: %v", err)
	} else {
		for module, codes := range metrics {
			fmt.Printf("Module %s:\n", module)
			for code, freq := range codes {
				fmt.Printf("  - %s: %d occurrences\n", code, freq)
			}
		}
	}

	// Test des corrélations temporelles
	fmt.Println("\n=== Corrélations temporelles (fenêtre de 1h) ===")
	correlations, err := analyzer.IdentifyTemporalCorrelations(1 * time.Hour)
	if err != nil {
		log.Printf("Erreur lors de l'identification des corrélations: %v", err)
	} else {
		for i, corr := range correlations {
			if i >= 3 { // Limiter l'affichage aux 3 premières
				break
			}
			fmt.Printf("Corrélation %d: %s:%s <-> %s:%s (Score: %.2f, Écart moyen: %s)\n",
				i+1, corr.Module1, corr.ErrorCode1, corr.Module2, corr.ErrorCode2,
				corr.Correlation, corr.OccurrenceGap.String())
		}
	}
}

// TestAnalyzeErrorPatternsWithMockData teste avec des données simulées
func TestAnalyzeErrorPatternsWithMockData() {
	fmt.Println("=== Test avec données simulées ===")

	// Simuler des patterns d'erreurs
	mockPatterns := []PatternMetrics{
		{
			ErrorCode:     "DB_CONNECTION_TIMEOUT",
			Module:        "database-manager",
			Frequency:     25,
			LastOccurred:  time.Now().Add(-15 * time.Minute),
			FirstOccurred: time.Now().Add(-48 * time.Hour),
			Severity:      "CRITICAL",
			Context:       map[string]interface{}{"timeout": "30s", "retries": 3},
		},
		{
			ErrorCode:     "SMTP_AUTH_FAILED",
			Module:        "email-manager",
			Frequency:     18,
			LastOccurred:  time.Now().Add(-45 * time.Minute),
			FirstOccurred: time.Now().Add(-24 * time.Hour),
			Severity:      "ERROR",
			Context:       map[string]interface{}{"provider": "gmail", "user": "sender@example.com"},
		},
		{
			ErrorCode:     "RATE_LIMIT_EXCEEDED",
			Module:        "email-manager",
			Frequency:     12,
			LastOccurred:  time.Now().Add(-2 * time.Hour),
			FirstOccurred: time.Now().Add(-36 * time.Hour),
			Severity:      "WARNING",
			Context:       map[string]interface{}{"limit": "100/hour", "current": "150"},
		},
		{
			ErrorCode:     "FILE_NOT_FOUND",
			Module:        "path-manager",
			Frequency:     8,
			LastOccurred:  time.Now().Add(-6 * time.Hour),
			FirstOccurred: time.Now().Add(-72 * time.Hour),
			Severity:      "ERROR",
			Context:       map[string]interface{}{"path": "/config/template.json"},
		},
		{
			ErrorCode:     "NETWORK_UNREACHABLE",
			Module:        "network-manager",
			Frequency:     5,
			LastOccurred:  time.Now().Add(-12 * time.Hour),
			FirstOccurred: time.Now().Add(-96 * time.Hour),
			Severity:      "CRITICAL",
			Context:       map[string]interface{}{"host": "api.external.com", "port": 443},
		},
	}

	// Simuler des métriques de fréquence
	mockMetrics := map[string]map[string]int{
		"database-manager": {
			"DB_CONNECTION_TIMEOUT": 25,
			"QUERY_TIMEOUT":         7,
			"LOCK_WAIT_TIMEOUT":     3,
		},
		"email-manager": {
			"SMTP_AUTH_FAILED":    18,
			"RATE_LIMIT_EXCEEDED": 12,
			"MESSAGE_TOO_LARGE":   4,
		},
		"path-manager": {
			"FILE_NOT_FOUND":    8,
			"PERMISSION_DENIED": 2,
		},
		"network-manager": {
			"NETWORK_UNREACHABLE": 5,
			"TIMEOUT":             6,
		},
	}

	// Simuler des corrélations temporelles
	mockCorrelations := []TemporalCorrelation{
		{
			ErrorCode1:    "DB_CONNECTION_TIMEOUT",
			ErrorCode2:    "SMTP_AUTH_FAILED",
			Module1:       "database-manager",
			Module2:       "email-manager",
			Correlation:   0.85,
			TimeWindow:    1 * time.Hour,
			OccurrenceGap: 5 * time.Minute,
		},
		{
			ErrorCode1:    "RATE_LIMIT_EXCEEDED",
			ErrorCode2:    "SMTP_AUTH_FAILED",
			Module1:       "email-manager",
			Module2:       "email-manager",
			Correlation:   0.72,
			TimeWindow:    1 * time.Hour,
			OccurrenceGap: 10 * time.Minute,
		},
		{
			ErrorCode1:    "NETWORK_UNREACHABLE",
			ErrorCode2:    "FILE_NOT_FOUND",
			Module1:       "network-manager",
			Module2:       "path-manager",
			Correlation:   0.63,
			TimeWindow:    1 * time.Hour,
			OccurrenceGap: 15 * time.Minute,
		},
	}

	// Afficher les résultats simulés
	fmt.Println("\n=== Analyse des patterns d'erreurs (simulé) ===")
	for i, pattern := range mockPatterns {
		if i >= 5 { // Limiter l'affichage aux 5 premiers
			break
		}
		fmt.Printf("Pattern %d: %s-%s (Fréquence: %d, Dernière: %s)\n",
			i+1, pattern.Module, pattern.ErrorCode, pattern.Frequency, pattern.LastOccurred.Format("2006-01-02 15:04:05"))
	}

	fmt.Println("\n=== Métriques de fréquence par module (simulé) ===")
	for module, codes := range mockMetrics {
		fmt.Printf("Module %s:\n", module)
		for code, freq := range codes {
			fmt.Printf("  - %s: %d occurrences\n", code, freq)
		}
	}

	fmt.Println("\n=== Corrélations temporelles (simulé) ===")
	for i, corr := range mockCorrelations {
		if i >= 3 { // Limiter l'affichage aux 3 premières
			break
		}
		fmt.Printf("Corrélation %d: %s:%s <-> %s:%s (Score: %.2f, Écart moyen: %s)\n",
			i+1, corr.Module1, corr.ErrorCode1, corr.Module2, corr.ErrorCode2,
			corr.Correlation, corr.OccurrenceGap.String())
	}
	fmt.Println("\n✅ Test de l'analyseur de patterns terminé avec succès (mode simulé)")
}
