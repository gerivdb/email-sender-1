package security

import (
	"context"
	"fmt"
	"sort"
	"time"

	"github.com/google/uuid"
)

// === IMPLÉMENTATION PHASE 4.2.2.1: VECTORISATION DES POLITIQUES DE SÉCURITÉ ===

// IndexSecurityPolicy indexe une politique de sécurité
func (sm *SecurityManagerImpl) IndexSecurityPolicy(ctx context.Context, policy SecurityPolicy) error {
	if !sm.vectorizationEnabled {
		return fmt.Errorf("security vectorization is disabled")
	}

	// Générer l'embedding de la politique
	embedding, err := sm.vectorizer.GeneratePolicyEmbedding(ctx, policy)
	if err != nil {
		return fmt.Errorf("failed to generate policy embedding: %w", err)
	}

	// Stocker dans le vectoriseur de politiques
	sm.policyVectorizer.mu.Lock()
	sm.policyVectorizer.policies[policy.ID] = &policy
	sm.policyVectorizer.embeddings[policy.ID] = embedding
	sm.policyVectorizer.mu.Unlock()

	// Stocker dans Qdrant
	payload := map[string]interface{}{
		"policy_id":   policy.ID,
		"name":        policy.Name,
		"category":    policy.Category,
		"severity":    policy.Severity,
		"rules_count": len(policy.Rules),
		"enabled":     policy.Enabled,
		"created_at":  policy.CreatedAt.Unix(),
		"updated_at":  policy.UpdatedAt.Unix(),
		"tags":        policy.Tags,
	}

	err = sm.qdrant.StoreVector(ctx, "security_policies", policy.ID, embedding, payload)
	if err != nil {
		return fmt.Errorf("failed to store policy vector: %w", err)
	}

	sm.logger.Info("Security policy indexed", "policy_id", policy.ID, "name", policy.Name)
	return nil
}

// UpdatePolicyIndex met à jour l'index d'une politique
func (sm *SecurityManagerImpl) UpdatePolicyIndex(ctx context.Context, policyID string) error {
	sm.policyVectorizer.mu.RLock()
	policy, exists := sm.policyVectorizer.policies[policyID]
	sm.policyVectorizer.mu.RUnlock()

	if !exists {
		return fmt.Errorf("policy not found: %s", policyID)
	}

	// Mettre à jour le timestamp
	policy.UpdatedAt = time.Now()

	// Ré-indexer la politique
	return sm.IndexSecurityPolicy(ctx, *policy)
}

// RemovePolicyIndex supprime une politique de l'index
func (sm *SecurityManagerImpl) RemovePolicyIndex(ctx context.Context, policyID string) error {
	// Supprimer du vectoriseur local
	sm.policyVectorizer.mu.Lock()
	delete(sm.policyVectorizer.policies, policyID)
	delete(sm.policyVectorizer.embeddings, policyID)
	sm.policyVectorizer.mu.Unlock()

	// Supprimer de Qdrant
	err := sm.qdrant.DeleteVector(ctx, "security_policies", policyID)
	if err != nil {
		return fmt.Errorf("failed to delete policy vector: %w", err)
	}

	sm.logger.Info("Security policy removed from index", "policy_id", policyID)
	return nil
}

// SearchSimilarPolicies recherche des politiques similaires
func (sm *SecurityManagerImpl) SearchSimilarPolicies(ctx context.Context, policyID string, threshold float64) ([]PolicyMatch, error) {
	sm.policyVectorizer.mu.RLock()
	embedding, exists := sm.policyVectorizer.embeddings[policyID]
	sm.policyVectorizer.mu.RUnlock()

	if !exists {
		return nil, fmt.Errorf("policy embedding not found: %s", policyID)
	}

	// Rechercher dans Qdrant
	results, err := sm.qdrant.SearchVector(ctx, "security_policies", embedding, 10)
	if err != nil {
		return nil, fmt.Errorf("failed to search similar policies: %w", err)
	}

	var matches []PolicyMatch
	for _, result := range results {
		if result.ID != policyID && float64(result.Score) >= threshold {
			match := PolicyMatch{
				PolicyID:    result.ID,
				PolicyName:  result.Payload["name"].(string),
				Similarity:  float64(result.Score),
				MatchReason: sm.generateMatchReason(result.Payload),
			}
			matches = append(matches, match)
		}
	}

	return matches, nil
}

// === IMPLÉMENTATION PHASE 4.2.2.2: DÉTECTION D'ANOMALIES BASÉE SUR EMBEDDINGS ===

// BuildBaselineProfile construit un profil de référence à partir d'événements
func (sm *SecurityManagerImpl) BuildBaselineProfile(ctx context.Context, events []SecurityEvent) error {
	if len(events) == 0 {
		return fmt.Errorf("no events provided for baseline")
	}

	// Générer les embeddings pour tous les événements
	var embeddings [][]float32
	var patterns []PatternEmbedding

	for _, event := range events {
		eventText := sm.eventToText(event)
		embedding, err := sm.vectorizer.GenerateEmbedding(ctx, eventText)
		if err != nil {
			sm.logger.Warn("Failed to generate embedding for event", "event_id", event.ID, "error", err)
			continue
		}

		embeddings = append(embeddings, embedding)

		// Créer un pattern embedding
		patterns = append(patterns, PatternEmbedding{
			Pattern:   eventText,
			Embedding: embedding,
			Frequency: 1,
		})
	}

	// Calculer l'embedding de référence (moyenne)
	baselineEmbedding := sm.calculateMeanEmbedding(embeddings)

	// Créer le profil de sécurité
	profile := &SecurityProfile{
		ID:                uuid.New().String(),
		Name:              "Baseline Security Profile",
		BaselineEmbedding: baselineEmbedding,
		NormalPatterns:    patterns,
		CreatedAt:         time.Now(),
		UpdatedAt:         time.Now(),
		EventCount:        len(events),
	}

	// Stocker le profil
	sm.anomalyDetector.baselineProfile = profile

	sm.logger.Info("Baseline security profile built", "events_count", len(events))
	return nil
}

// DetectAnomalies détecte les anomalies dans un événement
func (sm *SecurityManagerImpl) DetectAnomalies(ctx context.Context, event SecurityEvent) ([]Anomaly, error) {
	if sm.anomalyDetector.baselineProfile == nil {
		return nil, fmt.Errorf("no baseline profile available")
	}

	var anomalies []Anomaly

	// Générer l'embedding de l'événement
	eventText := sm.eventToText(event)
	eventEmbedding, err := sm.vectorizer.GenerateEmbedding(ctx, eventText)
	if err != nil {
		return nil, fmt.Errorf("failed to generate event embedding: %w", err)
	}

	// Calculer la similarité avec la baseline
	similarity := sm.calculateCosineSimilarity(
		eventEmbedding,
		sm.anomalyDetector.baselineProfile.BaselineEmbedding,
	)

	// Vérifier si c'est une anomalie basée sur la similarité
	if similarity < sm.anomalyDetector.thresholds.SimilarityThreshold {
		anomaly := Anomaly{
			ID:             uuid.New().String(),
			EventID:        event.ID,
			Type:           "similarity_anomaly",
			Severity:       sm.calculateAnomalySeverity(similarity),
			DeviationScore: 1.0 - similarity,
			Description:    fmt.Sprintf("Event deviates from normal baseline (similarity: %.3f)", similarity),
			Recommendation: "Investigate this unusual security event pattern",
			DetectedAt:     time.Now(),
			Metadata: map[string]interface{}{
				"similarity":   similarity,
				"threshold":    sm.anomalyDetector.thresholds.SimilarityThreshold,
				"event_type":   event.Type,
				"event_source": event.Source,
			},
		}
		anomalies = append(anomalies, anomaly)
	}

	// Vérifier les patterns fréquents
	patternAnomaly := sm.detectPatternAnomaly(event, eventEmbedding)
	if patternAnomaly != nil {
		anomalies = append(anomalies, *patternAnomaly)
	}

	// Ajouter l'événement aux événements récents
	sm.anomalyDetector.eventsMu.Lock()
	sm.anomalyDetector.recentEvents = append(sm.anomalyDetector.recentEvents, event)
	// Garder seulement les 1000 derniers événements
	if len(sm.anomalyDetector.recentEvents) > 1000 {
		sm.anomalyDetector.recentEvents = sm.anomalyDetector.recentEvents[1:]
	}
	sm.anomalyDetector.eventsMu.Unlock()

	return anomalies, nil
}

// UpdateBaseline met à jour la baseline avec un nouvel événement
func (sm *SecurityManagerImpl) UpdateBaseline(ctx context.Context, event SecurityEvent) error {
	if sm.anomalyDetector.baselineProfile == nil {
		return fmt.Errorf("no baseline profile to update")
	}

	// Générer l'embedding de l'événement
	eventText := sm.eventToText(event)
	eventEmbedding, err := sm.vectorizer.GenerateEmbedding(ctx, eventText)
	if err != nil {
		return fmt.Errorf("failed to generate event embedding: %w", err)
	}

	// Mettre à jour la baseline avec une moyenne pondérée
	profile := sm.anomalyDetector.baselineProfile

	// Facteur de lissage pour la mise à jour incrémentale
	alpha := 0.1
	for i := range profile.BaselineEmbedding {
		profile.BaselineEmbedding[i] = float32(
			(1-alpha)*float64(profile.BaselineEmbedding[i]) +
				alpha*float64(eventEmbedding[i]),
		)
	}

	profile.EventCount++
	profile.UpdatedAt = time.Now()

	sm.logger.Debug("Baseline profile updated", "event_id", event.ID)
	return nil
}

// GetAnomalyReport génère un rapport d'anomalies
func (sm *SecurityManagerImpl) GetAnomalyReport(ctx context.Context, timeRange TimeRange) (*AnomalyReport, error) {
	sm.anomalyDetector.eventsMu.RLock()
	defer sm.anomalyDetector.eventsMu.RUnlock()

	var anomalies []Anomaly
	totalEvents := 0

	// Traiter tous les événements récents dans la plage de temps
	for _, event := range sm.anomalyDetector.recentEvents {
		if event.Timestamp.After(timeRange.Start) && event.Timestamp.Before(timeRange.End) {
			totalEvents++

			// Détecter les anomalies pour cet événement
			eventAnomalies, err := sm.DetectAnomalies(ctx, event)
			if err == nil {
				anomalies = append(anomalies, eventAnomalies...)
			}
		}
	}

	// Calculer le résumé
	summary := sm.calculateAnomalySummary(anomalies)

	report := &AnomalyReport{
		TimeRange:   timeRange,
		TotalEvents: totalEvents,
		Anomalies:   anomalies,
		Summary:     summary,
		GeneratedAt: time.Now(),
	}

	return report, nil
}

// === IMPLÉMENTATION PHASE 4.2.2.3: CLASSIFICATION AUTOMATIQUE DES VULNÉRABILITÉS ===

// ClassifyVulnerability classe une vulnérabilité automatiquement
func (sm *SecurityManagerImpl) ClassifyVulnerability(ctx context.Context, vuln Vulnerability) (*VulnClassification, error) {
	if !sm.vectorizationEnabled {
		return nil, fmt.Errorf("security vectorization is disabled")
	}

	// Générer l'embedding de la vulnérabilité
	embedding, err := sm.vectorizer.GenerateVulnerabilityEmbedding(ctx, vuln)
	if err != nil {
		return nil, fmt.Errorf("failed to generate vulnerability embedding: %w", err)
	}

	// Rechercher des vulnérabilités similaires
	results, err := sm.qdrant.SearchVector(ctx, "vulnerabilities", embedding, 5)
	if err != nil {
		return nil, fmt.Errorf("failed to search similar vulnerabilities: %w", err)
	}

	// Analyser les résultats pour déterminer la classification
	classification := sm.analyzeVulnSimilarity(vuln, results)

	// Stocker la classification
	sm.vulnerabilityClassifier.mu.Lock()
	sm.vulnerabilityClassifier.knownVulns[vuln.ID] = &vuln
	sm.vulnerabilityClassifier.classifications[vuln.ID] = classification
	sm.vulnerabilityClassifier.mu.Unlock()

	sm.logger.Info("Vulnerability classified", "vuln_id", vuln.ID, "category", classification.Category)
	return classification, nil
}

// TrainClassifier entraîne le classificateur avec des données d'entraînement
func (sm *SecurityManagerImpl) TrainClassifier(ctx context.Context, trainData []VulnTrainingData) error {
	sm.logger.Info("Starting vulnerability classifier training", "data_count", len(trainData))

	for _, data := range trainData {
		// Générer l'embedding
		embedding, err := sm.vectorizer.GenerateVulnerabilityEmbedding(ctx, data.Vulnerability)
		if err != nil {
			sm.logger.Warn("Failed to generate training embedding", "vuln_id", data.Vulnerability.ID)
			continue
		}

		// Stocker dans Qdrant avec la classification
		payload := map[string]interface{}{
			"vuln_id":     data.Vulnerability.ID,
			"cve":         data.Vulnerability.CVE,
			"category":    data.Classification.Category,
			"subcategory": data.Classification.Subcategory,
			"severity":    data.Vulnerability.Severity,
			"cvss":        data.Vulnerability.CVSS,
			"confidence":  data.Classification.Confidence,
		}

		err = sm.qdrant.StoreVector(ctx, "vulnerabilities", data.Vulnerability.ID, embedding, payload)
		if err != nil {
			sm.logger.Warn("Failed to store training vector", "vuln_id", data.Vulnerability.ID)
			continue
		}

		// Stocker localement
		sm.vulnerabilityClassifier.mu.Lock()
		sm.vulnerabilityClassifier.knownVulns[data.Vulnerability.ID] = &data.Vulnerability
		sm.vulnerabilityClassifier.classifications[data.Vulnerability.ID] = &data.Classification
		sm.vulnerabilityClassifier.mu.Unlock()
	}

	sm.logger.Info("Vulnerability classifier training completed")
	return nil
}

// GetVulnerabilityInsights fournit des insights sur une vulnérabilité
func (sm *SecurityManagerImpl) GetVulnerabilityInsights(ctx context.Context, vulnID string) (*VulnInsights, error) {
	sm.vulnerabilityClassifier.mu.RLock()
	vuln, exists := sm.vulnerabilityClassifier.knownVulns[vulnID]
	sm.vulnerabilityClassifier.mu.RUnlock()

	if !exists {
		return nil, fmt.Errorf("vulnerability not found: %s", vulnID)
	}

	// Générer l'embedding
	embedding, err := sm.vectorizer.GenerateVulnerabilityEmbedding(ctx, *vuln)
	if err != nil {
		return nil, fmt.Errorf("failed to generate vulnerability embedding: %w", err)
	}

	// Rechercher des vulnérabilités similaires
	results, err := sm.qdrant.SearchVector(ctx, "vulnerabilities", embedding, 10)
	if err != nil {
		return nil, fmt.Errorf("failed to search similar vulnerabilities: %w", err)
	}

	// Construire les insights
	insights := &VulnInsights{
		VulnID:             vulnID,
		SimilarVulns:       sm.buildSimilarVulns(results, vulnID),
		TrendAnalysis:      sm.analyzeTrends(*vuln),
		ImpactAssessment:   sm.assessImpact(*vuln),
		RecommendedActions: sm.generateRecommendedActions(*vuln),
	}

	return insights, nil
}

// SuggestMitigations suggère des mesures d'atténuation
func (sm *SecurityManagerImpl) SuggestMitigations(ctx context.Context, vulnID string) ([]Mitigation, error) {
	sm.vulnerabilityClassifier.mu.RLock()
	vuln, exists := sm.vulnerabilityClassifier.knownVulns[vulnID]
	classification, classExists := sm.vulnerabilityClassifier.classifications[vulnID]
	sm.vulnerabilityClassifier.mu.RUnlock()

	if !exists {
		return nil, fmt.Errorf("vulnerability not found: %s", vulnID)
	}

	var mitigations []Mitigation

	// Suggestions basées sur la catégorie
	if classExists {
		mitigations = append(mitigations, sm.getCategoryMitigations(classification.Category)...)
	}

	// Suggestions basées sur la sévérité
	mitigations = append(mitigations, sm.getSeverityMitigations(vuln.Severity)...)

	// Suggestions basées sur les composants affectés
	for _, component := range vuln.Affected {
		mitigations = append(mitigations, sm.getComponentMitigations(component)...)
	}

	// Trier par efficacité décroissante
	sort.Slice(mitigations, func(i, j int) bool {
		return mitigations[i].Effectiveness > mitigations[j].Effectiveness
	})

	return mitigations, nil
}
