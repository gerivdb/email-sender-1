package security

import (
	"fmt"
	"math"
	"strings"
	"time"
)

// === MÉTHODES UTILITAIRES POUR LA VECTORISATION SÉCURITÉ ===

// EnableSecurityVectorization active la vectorisation sécurité
func (sm *SecurityManagerImpl) EnableSecurityVectorization() error {
	sm.vectorizationEnabled = true
	sm.logger.Info("Security vectorization enabled")
	return nil
}

// DisableSecurityVectorization désactive la vectorisation sécurité
func (sm *SecurityManagerImpl) DisableSecurityVectorization() error {
	sm.vectorizationEnabled = false
	sm.logger.Info("Security vectorization disabled")
	return nil
}

// GetSecurityVectorizationStatus retourne le statut de la vectorisation
func (sm *SecurityManagerImpl) GetSecurityVectorizationStatus() bool {
	return sm.vectorizationEnabled
}

// GetSecurityVectorizationMetrics retourne les métriques de vectorisation
func (sm *SecurityManagerImpl) GetSecurityVectorizationMetrics() SecurityVectorizationMetrics {
	sm.policyVectorizer.mu.RLock()
	policyCount := len(sm.policyVectorizer.policies)
	sm.policyVectorizer.mu.RUnlock()

	sm.vulnerabilityClassifier.mu.RLock()
	vulnCount := len(sm.vulnerabilityClassifier.knownVulns)
	sm.vulnerabilityClassifier.mu.RUnlock()

	sm.anomalyDetector.eventsMu.RLock()
	eventCount := len(sm.anomalyDetector.recentEvents)
	sm.anomalyDetector.eventsMu.RUnlock()

	// Compter les anomalies détectées (simulation)
	anomalyCount := 0

	return SecurityVectorizationMetrics{
		IndexedPolicies:      policyCount,
		IndexedVulns:         vulnCount,
		ProcessedEvents:      eventCount,
		DetectedAnomalies:    anomalyCount,
		LastUpdate:           time.Now(),
		VectorizationEnabled: sm.vectorizationEnabled,
		Collections: map[string]int{
			"security_policies": policyCount,
			"vulnerabilities":   vulnCount,
			"security_events":   eventCount,
		},
	}
}

// eventToText convertit un événement de sécurité en texte pour la vectorisation
func (sm *SecurityManagerImpl) eventToText(event SecurityEvent) string {
	var text strings.Builder

	text.WriteString(fmt.Sprintf("Security Event Type: %s\n", event.Type))
	text.WriteString(fmt.Sprintf("Source: %s\n", event.Source))
	text.WriteString(fmt.Sprintf("Severity: %s\n", event.Severity))
	text.WriteString(fmt.Sprintf("Description: %s\n", event.Description))

	if event.Target != "" {
		text.WriteString(fmt.Sprintf("Target: %s\n", event.Target))
	}

	// Ajouter les métadonnées importantes
	for key, value := range event.Metadata {
		text.WriteString(fmt.Sprintf("%s: %v\n", key, value))
	}

	return text.String()
}

// calculateMeanEmbedding calcule la moyenne d'un ensemble d'embeddings
func (sm *SecurityManagerImpl) calculateMeanEmbedding(embeddings [][]float32) []float32 {
	if len(embeddings) == 0 {
		return nil
	}

	embeddingSize := len(embeddings[0])
	mean := make([]float32, embeddingSize)

	for _, embedding := range embeddings {
		for i, value := range embedding {
			mean[i] += value
		}
	}

	// Diviser par le nombre d'embeddings
	for i := range mean {
		mean[i] /= float32(len(embeddings))
	}

	return mean
}

// calculateCosineSimilarity calcule la similarité cosinus entre deux embeddings
func (sm *SecurityManagerImpl) calculateCosineSimilarity(a, b []float32) float64 {
	if len(a) != len(b) {
		return 0.0
	}

	var dotProduct, normA, normB float64

	for i := range a {
		dotProduct += float64(a[i]) * float64(b[i])
		normA += float64(a[i]) * float64(a[i])
		normB += float64(b[i]) * float64(b[i])
	}

	if normA == 0 || normB == 0 {
		return 0.0
	}

	return dotProduct / (math.Sqrt(normA) * math.Sqrt(normB))
}

// calculateAnomalySeverity calcule la sévérité d'une anomalie basée sur la similarité
func (sm *SecurityManagerImpl) calculateAnomalySeverity(similarity float64) string {
	if similarity < 0.3 {
		return "critical"
	} else if similarity < 0.5 {
		return "high"
	} else if similarity < 0.7 {
		return "medium"
	} else {
		return "low"
	}
}

// detectPatternAnomaly détecte une anomalie basée sur les patterns
func (sm *SecurityManagerImpl) detectPatternAnomaly(event SecurityEvent, embedding []float32) *Anomaly {
	if sm.anomalyDetector.baselineProfile == nil {
		return nil
	}

	// Chercher des patterns similaires dans la baseline
	maxSimilarity := 0.0
	for _, pattern := range sm.anomalyDetector.baselineProfile.NormalPatterns {
		similarity := sm.calculateCosineSimilarity(embedding, pattern.Embedding)
		if similarity > maxSimilarity {
			maxSimilarity = similarity
		}
	}

	// Si aucun pattern similaire n'est trouvé
	if maxSimilarity < 0.6 {
		return &Anomaly{
			ID:             fmt.Sprintf("pattern_anomaly_%s", event.ID),
			EventID:        event.ID,
			Type:           "pattern_anomaly",
			Severity:       "medium",
			DeviationScore: 1.0 - maxSimilarity,
			Description:    "Event does not match any known normal patterns",
			Recommendation: "Review this unusual event pattern for potential security threats",
			DetectedAt:     time.Now(),
			Metadata: map[string]interface{}{
				"max_pattern_similarity": maxSimilarity,
				"event_type":             event.Type,
			},
		}
	}

	return nil
}

// calculateAnomalySummary calcule un résumé des anomalies
func (sm *SecurityManagerImpl) calculateAnomalySummary(anomalies []Anomaly) AnomalySummary {
	summary := AnomalySummary{
		TotalAnomalies: len(anomalies),
	}

	if len(anomalies) == 0 {
		return summary
	}

	var totalDeviation float64

	for _, anomaly := range anomalies {
		switch anomaly.Severity {
		case "critical", "high":
			summary.HighSeverity++
		case "medium":
			summary.MediumSeverity++
		case "low":
			summary.LowSeverity++
		}
		totalDeviation += anomaly.DeviationScore
	}

	summary.AverageDeviation = totalDeviation / float64(len(anomalies))
	return summary
}

// generateMatchReason génère une raison de correspondance pour les politiques
func (sm *SecurityManagerImpl) generateMatchReason(payload map[string]interface{}) string {
	var reasons []string

	if category, ok := payload["category"].(string); ok {
		reasons = append(reasons, fmt.Sprintf("Same category: %s", category))
	}

	if severity, ok := payload["severity"].(string); ok {
		reasons = append(reasons, fmt.Sprintf("Same severity: %s", severity))
	}

	if len(reasons) == 0 {
		return "Similar content pattern"
	}

	return strings.Join(reasons, ", ")
}

// analyzeVulnSimilarity analyse la similarité des vulnérabilités
func (sm *SecurityManagerImpl) analyzeVulnSimilarity(vuln Vulnerability, results []QdrantSearchResult) *VulnClassification {
	if len(results) == 0 {
		return &VulnClassification{
			ID:           fmt.Sprintf("classification_%s", vuln.ID),
			Category:     "unknown",
			Subcategory:  "unclassified",
			Confidence:   0.1,
			Reasoning:    "No similar vulnerabilities found",
			SuggestedFix: "Manual classification required",
			Priority:     5,
			CreatedAt:    time.Now(),
		}
	}

	// Analyser le meilleur match
	bestMatch := results[0]
	confidence := float64(bestMatch.Score)

	category := "unknown"
	subcategory := "unclassified"

	if categoryVal, ok := bestMatch.Payload["category"].(string); ok {
		category = categoryVal
	}
	if subcategoryVal, ok := bestMatch.Payload["subcategory"].(string); ok {
		subcategory = subcategoryVal
	}

	priority := sm.calculatePriority(vuln.Severity, vuln.CVSS)

	return &VulnClassification{
		ID:           fmt.Sprintf("classification_%s", vuln.ID),
		Category:     category,
		Subcategory:  subcategory,
		Confidence:   confidence,
		Reasoning:    fmt.Sprintf("Similar to %s (similarity: %.3f)", bestMatch.ID, confidence),
		SuggestedFix: sm.generateSuggestedFix(category, vuln.Severity),
		Priority:     priority,
		CreatedAt:    time.Now(),
	}
}

// buildSimilarVulns construit la liste des vulnérabilités similaires
func (sm *SecurityManagerImpl) buildSimilarVulns(results []QdrantSearchResult, currentVulnID string) []SimilarVuln {
	var similarVulns []SimilarVuln

	for _, result := range results {
		if result.ID != currentVulnID {
			similarVuln := SimilarVuln{
				ID:         result.ID,
				Similarity: float64(result.Score),
			}

			if cve, ok := result.Payload["cve"].(string); ok {
				similarVuln.CVE = cve
			}
			if category, ok := result.Payload["category"].(string); ok {
				similarVuln.Category = category
			}

			similarVulns = append(similarVulns, similarVuln)
		}
	}

	return similarVulns
}

// analyzeTrends analyse les tendances d'une vulnérabilité
func (sm *SecurityManagerImpl) analyzeTrends(vuln Vulnerability) TrendAnalysis {
	// Simulation d'analyse de tendances
	return TrendAnalysis{
		Frequency:     1,
		Trend:         "stable",
		Seasonality:   false,
		PredictedRisk: sm.calculateRiskScore(vuln),
	}
}

// assessImpact évalue l'impact d'une vulnérabilité
func (sm *SecurityManagerImpl) assessImpact(vuln Vulnerability) ImpactAssessment {
	businessImpact := "medium"
	technicalImpact := "medium"

	if vuln.CVSS >= 9.0 {
		businessImpact = "critical"
		technicalImpact = "critical"
	} else if vuln.CVSS >= 7.0 {
		businessImpact = "high"
		technicalImpact = "high"
	} else if vuln.CVSS >= 4.0 {
		businessImpact = "medium"
		technicalImpact = "medium"
	} else {
		businessImpact = "low"
		technicalImpact = "low"
	}

	return ImpactAssessment{
		BusinessImpact:  businessImpact,
		TechnicalImpact: technicalImpact,
		RiskScore:       sm.calculateRiskScore(vuln),
		AffectedSystems: vuln.Affected,
	}
}

// generateRecommendedActions génère des actions recommandées
func (sm *SecurityManagerImpl) generateRecommendedActions(vuln Vulnerability) []RecommendedAction {
	var actions []RecommendedAction

	if vuln.CVSS >= 9.0 {
		actions = append(actions, RecommendedAction{
			Priority:    1,
			Action:      "Immediate patching",
			Description: "Apply security patch immediately",
			Effort:      "high",
		})
	}

	actions = append(actions, RecommendedAction{
		Priority:    2,
		Action:      "Risk assessment",
		Description: "Conduct thorough risk assessment",
		Effort:      "medium",
	})

	return actions
}

// calculatePriority calcule la priorité d'une vulnérabilité
func (sm *SecurityManagerImpl) calculatePriority(severity string, cvss float64) int {
	if cvss >= 9.0 || severity == "critical" {
		return 1
	} else if cvss >= 7.0 || severity == "high" {
		return 2
	} else if cvss >= 4.0 || severity == "medium" {
		return 3
	} else {
		return 4
	}
}

// calculateRiskScore calcule le score de risque
func (sm *SecurityManagerImpl) calculateRiskScore(vuln Vulnerability) float64 {
	return vuln.CVSS / 10.0
}

// generateSuggestedFix génère une correction suggérée
func (sm *SecurityManagerImpl) generateSuggestedFix(category, severity string) string {
	fixes := map[string]string{
		"injection":      "Implement input validation and parameterized queries",
		"authentication": "Strengthen authentication mechanisms",
		"authorization":  "Review and update access controls",
		"encryption":     "Implement proper encryption standards",
		"configuration":  "Review and harden system configuration",
	}

	if fix, ok := fixes[category]; ok {
		return fix
	}

	return "Review security best practices for this vulnerability type"
}

// getCategoryMitigations retourne les mesures d'atténuation par catégorie
func (sm *SecurityManagerImpl) getCategoryMitigations(category string) []Mitigation {
	mitigations := map[string][]Mitigation{
		"injection": {
			{
				ID:             "mit_injection_01",
				Type:           "technical",
				Description:    "Implement input validation",
				Effectiveness:  0.9,
				Implementation: "Add validation library and sanitize all inputs",
				Cost:           "medium",
				Timeline:       "1-2 weeks",
			},
		},
		"authentication": {
			{
				ID:             "mit_auth_01",
				Type:           "technical",
				Description:    "Implement multi-factor authentication",
				Effectiveness:  0.95,
				Implementation: "Deploy MFA solution",
				Cost:           "high",
				Timeline:       "2-4 weeks",
			},
		},
	}

	if mits, ok := mitigations[category]; ok {
		return mits
	}

	return []Mitigation{
		{
			ID:             "mit_generic_01",
			Type:           "process",
			Description:    "Review security policies",
			Effectiveness:  0.6,
			Implementation: "Conduct security review",
			Cost:           "low",
			Timeline:       "1 week",
		},
	}
}

// getSeverityMitigations retourne les mesures d'atténuation par sévérité
func (sm *SecurityManagerImpl) getSeverityMitigations(severity string) []Mitigation {
	if severity == "critical" {
		return []Mitigation{
			{
				ID:             "mit_critical_01",
				Type:           "immediate",
				Description:    "Emergency patch deployment",
				Effectiveness:  0.98,
				Implementation: "Deploy patch immediately",
				Cost:           "high",
				Timeline:       "24 hours",
			},
		}
	}

	return []Mitigation{}
}

// getComponentMitigations retourne les mesures d'atténuation par composant
func (sm *SecurityManagerImpl) getComponentMitigations(component string) []Mitigation {
	return []Mitigation{
		{
			ID:             fmt.Sprintf("mit_comp_%s", component),
			Type:           "component",
			Description:    fmt.Sprintf("Update %s component", component),
			Effectiveness:  0.8,
			Implementation: fmt.Sprintf("Update %s to latest secure version", component),
			Cost:           "medium",
			Timeline:       "1-2 weeks",
		},
	}
}
