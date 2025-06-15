package monitoring

import (
	"context"
	"fmt"
	"log"
	"sync"
	"time"
)

// AlertSeverity définit le niveau de sévérité d'une alerte
type AlertSeverity int

const (
	AlertInfo AlertSeverity = iota
	AlertWarning
	AlertError
	AlertCritical
)

func (s AlertSeverity) String() string {
	switch s {
	case AlertInfo:
		return "INFO"
	case AlertWarning:
		return "WARNING"
	case AlertError:
		return "ERROR"
	case AlertCritical:
		return "CRITICAL"
	}
	return "UNKNOWN"
}

// Alert représente une alerte du système
type Alert struct {
	ID          string                 `json:"id"`
	Title       string                 `json:"title"`
	Description string                 `json:"description"`
	Severity    AlertSeverity          `json:"severity"`
	Component   string                 `json:"component"`
	Manager     string                 `json:"manager,omitempty"`
	Timestamp   time.Time              `json:"timestamp"`
	Metadata    map[string]interface{} `json:"metadata,omitempty"`
	Resolved    bool                   `json:"resolved"`
	ResolvedAt  *time.Time             `json:"resolved_at,omitempty"`
}

// AlertRule définit une règle d'alerte
type AlertRule struct {
	ID                string        `json:"id"`
	Name              string        `json:"name"`
	Description       string        `json:"description"`
	Severity          AlertSeverity `json:"severity"`
	Component         string        `json:"component"`
	MetricName        string        `json:"metric_name"`
	Threshold         float64       `json:"threshold"`
	ComparisonType    string        `json:"comparison_type"` // "gt", "lt", "eq", "gte", "lte"
	EvaluationWindow  time.Duration `json:"evaluation_window"`
	MinDataPoints     int           `json:"min_data_points"`
	ConsecutiveAlerts int           `json:"consecutive_alerts"`
	Enabled           bool          `json:"enabled"`
}

// AlertManager gère les alertes du système de vectorisation
type AlertManager struct {
	rules        map[string]*AlertRule
	activeAlerts map[string]*Alert
	alertHistory []*Alert
	metrics      *VectorizationMetrics
	handlers     []AlertHandler
	mu           sync.RWMutex

	// Configuration
	maxHistorySize     int
	evaluationInterval time.Duration

	// État interne
	consecutiveFailures map[string]int
	lastEvaluations     map[string]time.Time
}

// AlertHandler interface pour gérer les alertes
type AlertHandler interface {
	HandleAlert(ctx context.Context, alert *Alert) error
}

// NewAlertManager crée un nouveau gestionnaire d'alertes
func NewAlertManager(metrics *VectorizationMetrics) *AlertManager {
	am := &AlertManager{
		rules:               make(map[string]*AlertRule),
		activeAlerts:        make(map[string]*Alert),
		alertHistory:        make([]*Alert, 0),
		metrics:             metrics,
		handlers:            make([]AlertHandler, 0),
		maxHistorySize:      1000,
		evaluationInterval:  30 * time.Second,
		consecutiveFailures: make(map[string]int),
		lastEvaluations:     make(map[string]time.Time),
	}

	// Initialisation des règles par défaut
	am.initDefaultRules()

	return am
}

// initDefaultRules initialise les règles d'alerte par défaut
func (am *AlertManager) initDefaultRules() {
	defaultRules := []*AlertRule{
		{
			ID:                "vectorization_error_rate_high",
			Name:              "Taux d'erreur de vectorisation élevé",
			Description:       "Le taux d'erreur de vectorisation dépasse le seuil acceptable",
			Severity:          AlertWarning,
			Component:         "vectorization",
			MetricName:        "vectorization_error_rate",
			Threshold:         0.1, // 10%
			ComparisonType:    "gt",
			EvaluationWindow:  5 * time.Minute,
			MinDataPoints:     5,
			ConsecutiveAlerts: 2,
			Enabled:           true,
		},
		{
			ID:                "vectorization_error_rate_critical",
			Name:              "Taux d'erreur de vectorisation critique",
			Description:       "Le taux d'erreur de vectorisation atteint un niveau critique",
			Severity:          AlertCritical,
			Component:         "vectorization",
			MetricName:        "vectorization_error_rate",
			Threshold:         0.25, // 25%
			ComparisonType:    "gt",
			EvaluationWindow:  3 * time.Minute,
			MinDataPoints:     3,
			ConsecutiveAlerts: 1,
			Enabled:           true,
		},
		{
			ID:                "qdrant_connection_failure",
			Name:              "Échec de connexion Qdrant",
			Description:       "Impossible de se connecter à Qdrant",
			Severity:          AlertError,
			Component:         "qdrant",
			MetricName:        "qdrant_connection_errors",
			Threshold:         3,
			ComparisonType:    "gte",
			EvaluationWindow:  2 * time.Minute,
			MinDataPoints:     1,
			ConsecutiveAlerts: 1,
			Enabled:           true,
		},
		{
			ID:                "vectorization_latency_high",
			Name:              "Latence de vectorisation élevée",
			Description:       "La latence de vectorisation dépasse le seuil acceptable",
			Severity:          AlertWarning,
			Component:         "vectorization",
			MetricName:        "vectorization_latency_p95",
			Threshold:         30.0, // 30 secondes
			ComparisonType:    "gt",
			EvaluationWindow:  5 * time.Minute,
			MinDataPoints:     10,
			ConsecutiveAlerts: 3,
			Enabled:           true,
		},
		{
			ID:                "embedding_quality_low",
			Name:              "Qualité des embeddings faible",
			Description:       "La qualité des embeddings est en dessous du seuil acceptable",
			Severity:          AlertWarning,
			Component:         "embedding",
			MetricName:        "embedding_quality_score",
			Threshold:         0.7, // 70%
			ComparisonType:    "lt",
			EvaluationWindow:  10 * time.Minute,
			MinDataPoints:     5,
			ConsecutiveAlerts: 2,
			Enabled:           true,
		},
		{
			ID:                "queue_size_critical",
			Name:              "Taille de queue critique",
			Description:       "La queue de vectorisation atteint une taille critique",
			Severity:          AlertError,
			Component:         "queue",
			MetricName:        "vectorization_queue_size",
			Threshold:         1000,
			ComparisonType:    "gt",
			EvaluationWindow:  2 * time.Minute,
			MinDataPoints:     2,
			ConsecutiveAlerts: 1,
			Enabled:           true,
		},
		{
			ID:                "memory_usage_high",
			Name:              "Utilisation mémoire élevée",
			Description:       "L'utilisation mémoire du système de vectorisation est élevée",
			Severity:          AlertWarning,
			Component:         "system",
			MetricName:        "vectorization_memory_usage",
			Threshold:         1024 * 1024 * 1024, // 1GB
			ComparisonType:    "gt",
			EvaluationWindow:  5 * time.Minute,
			MinDataPoints:     5,
			ConsecutiveAlerts: 3,
			Enabled:           true,
		},
		{
			ID:                "no_successful_operation",
			Name:              "Aucune opération réussie récente",
			Description:       "Aucune opération de vectorisation réussie depuis un certain temps",
			Severity:          AlertCritical,
			Component:         "vectorization",
			MetricName:        "last_successful_operation_age",
			Threshold:         3600, // 1 heure
			ComparisonType:    "gt",
			EvaluationWindow:  1 * time.Minute,
			MinDataPoints:     1,
			ConsecutiveAlerts: 1,
			Enabled:           true,
		},
	}

	for _, rule := range defaultRules {
		am.rules[rule.ID] = rule
	}
}

// AddRule ajoute une nouvelle règle d'alerte
func (am *AlertManager) AddRule(rule *AlertRule) {
	am.mu.Lock()
	defer am.mu.Unlock()
	am.rules[rule.ID] = rule
}

// RemoveRule supprime une règle d'alerte
func (am *AlertManager) RemoveRule(ruleID string) {
	am.mu.Lock()
	defer am.mu.Unlock()
	delete(am.rules, ruleID)
}

// AddHandler ajoute un gestionnaire d'alertes
func (am *AlertManager) AddHandler(handler AlertHandler) {
	am.mu.Lock()
	defer am.mu.Unlock()
	am.handlers = append(am.handlers, handler)
}

// Start démarre le système d'alertes
func (am *AlertManager) Start(ctx context.Context) {
	ticker := time.NewTicker(am.evaluationInterval)
	defer ticker.Stop()

	go func() {
		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				am.evaluateRules(ctx)
			}
		}
	}()
}

// evaluateRules évalue toutes les règles d'alerte actives
func (am *AlertManager) evaluateRules(ctx context.Context) {
	am.mu.RLock()
	rules := make([]*AlertRule, 0, len(am.rules))
	for _, rule := range am.rules {
		if rule.Enabled {
			rules = append(rules, rule)
		}
	}
	am.mu.RUnlock()

	for _, rule := range rules {
		if err := am.evaluateRule(ctx, rule); err != nil {
			log.Printf("Erreur lors de l'évaluation de la règle %s: %v", rule.ID, err)
		}
	}
}

// evaluateRule évalue une règle d'alerte spécifique
func (am *AlertManager) evaluateRule(ctx context.Context, rule *AlertRule) error {
	// Récupération de la valeur métrique (simulation)
	metricValue, err := am.getMetricValue(rule.MetricName, rule.Component)
	if err != nil {
		return fmt.Errorf("impossible de récupérer la métrique %s: %w", rule.MetricName, err)
	}

	// Évaluation du seuil
	shouldAlert := am.evaluateThreshold(metricValue, rule.Threshold, rule.ComparisonType)

	ruleKey := fmt.Sprintf("%s_%s", rule.Component, rule.ID)

	if shouldAlert {
		am.consecutiveFailures[ruleKey]++

		// Vérification si nous avons atteint le seuil d'alertes consécutives
		if am.consecutiveFailures[ruleKey] >= rule.ConsecutiveAlerts {
			if err := am.fireAlert(ctx, rule, metricValue); err != nil {
				return fmt.Errorf("erreur lors du déclenchement de l'alerte: %w", err)
			}
		}
	} else {
		// Reset du compteur d'échecs consécutifs
		am.consecutiveFailures[ruleKey] = 0

		// Résolution de l'alerte si elle était active
		am.resolveAlert(rule.ID)
	}

	am.lastEvaluations[ruleKey] = time.Now()
	return nil
}

// getMetricValue récupère la valeur d'une métrique (simulation)
func (am *AlertManager) getMetricValue(metricName, component string) (float64, error) {
	// Dans un vrai système, ceci interrogerait Prometheus ou une autre source de métriques
	// Pour cette implémentation, nous simulons les valeurs

	switch metricName {
	case "vectorization_error_rate":
		return 0.05, nil // 5% d'erreurs
	case "qdrant_connection_errors":
		return 0, nil // Aucune erreur de connexion
	case "vectorization_latency_p95":
		return 15.0, nil // 15 secondes
	case "embedding_quality_score":
		return 0.85, nil // 85% de qualité
	case "vectorization_queue_size":
		return 150, nil // 150 éléments en queue
	case "vectorization_memory_usage":
		return 512 * 1024 * 1024, nil // 512MB
	case "last_successful_operation_age":
		return 300, nil // 5 minutes
	default:
		return 0, fmt.Errorf("métrique inconnue: %s", metricName)
	}
}

// evaluateThreshold évalue si la valeur déclenche le seuil
func (am *AlertManager) evaluateThreshold(value, threshold float64, comparisonType string) bool {
	switch comparisonType {
	case "gt":
		return value > threshold
	case "lt":
		return value < threshold
	case "eq":
		return value == threshold
	case "gte":
		return value >= threshold
	case "lte":
		return value <= threshold
	default:
		return false
	}
}

// fireAlert déclenche une nouvelle alerte
func (am *AlertManager) fireAlert(ctx context.Context, rule *AlertRule, metricValue float64) error {
	am.mu.Lock()
	defer am.mu.Unlock()

	// Vérification si l'alerte est déjà active
	if _, exists := am.activeAlerts[rule.ID]; exists {
		return nil // Alerte déjà active
	}

	alert := &Alert{
		ID:          rule.ID,
		Title:       rule.Name,
		Description: rule.Description,
		Severity:    rule.Severity,
		Component:   rule.Component,
		Timestamp:   time.Now(),
		Metadata: map[string]interface{}{
			"metric_name":  rule.MetricName,
			"metric_value": metricValue,
			"threshold":    rule.Threshold,
			"comparison":   rule.ComparisonType,
		},
		Resolved: false,
	}

	// Ajout à la liste des alertes actives
	am.activeAlerts[rule.ID] = alert

	// Ajout à l'historique
	am.addToHistory(alert)

	// Notification aux gestionnaires
	for _, handler := range am.handlers {
		if err := handler.HandleAlert(ctx, alert); err != nil {
			log.Printf("Erreur dans le gestionnaire d'alerte: %v", err)
		}
	}

	log.Printf("ALERTE [%s] %s: %s (valeur: %.2f, seuil: %.2f)",
		alert.Severity, alert.Title, alert.Description, metricValue, rule.Threshold)

	return nil
}

// resolveAlert résout une alerte active
func (am *AlertManager) resolveAlert(ruleID string) {
	am.mu.Lock()
	defer am.mu.Unlock()

	if alert, exists := am.activeAlerts[ruleID]; exists {
		now := time.Now()
		alert.Resolved = true
		alert.ResolvedAt = &now

		// Suppression de la liste des alertes actives
		delete(am.activeAlerts, ruleID)

		log.Printf("ALERTE RÉSOLUE [%s] %s", alert.Severity, alert.Title)
	}
}

// addToHistory ajoute une alerte à l'historique
func (am *AlertManager) addToHistory(alert *Alert) {
	am.alertHistory = append(am.alertHistory, alert)

	// Limitation de la taille de l'historique
	if len(am.alertHistory) > am.maxHistorySize {
		am.alertHistory = am.alertHistory[1:]
	}
}

// GetActiveAlerts retourne toutes les alertes actives
func (am *AlertManager) GetActiveAlerts() []*Alert {
	am.mu.RLock()
	defer am.mu.RUnlock()

	alerts := make([]*Alert, 0, len(am.activeAlerts))
	for _, alert := range am.activeAlerts {
		alerts = append(alerts, alert)
	}

	return alerts
}

// GetAlertHistory retourne l'historique des alertes
func (am *AlertManager) GetAlertHistory(limit int) []*Alert {
	am.mu.RLock()
	defer am.mu.RUnlock()

	if limit <= 0 || limit > len(am.alertHistory) {
		limit = len(am.alertHistory)
	}

	// Retourne les alertes les plus récentes
	start := len(am.alertHistory) - limit
	return am.alertHistory[start:]
}

// LogAlertHandler gestionnaire d'alertes qui log dans les logs
type LogAlertHandler struct{}

func (h *LogAlertHandler) HandleAlert(ctx context.Context, alert *Alert) error {
	log.Printf("🚨 ALERTE [%s] %s: %s (Composant: %s)",
		alert.Severity, alert.Title, alert.Description, alert.Component)
	return nil
}

// WebhookAlertHandler gestionnaire d'alertes qui envoie vers un webhook
type WebhookAlertHandler struct {
	WebhookURL string
	Timeout    time.Duration
}

func (h *WebhookAlertHandler) HandleAlert(ctx context.Context, alert *Alert) error {
	// Dans un vrai système, ceci enverrait l'alerte vers un webhook
	log.Printf("📡 WEBHOOK ALERT: Envoi vers %s - %s", h.WebhookURL, alert.Title)
	return nil
}

// EmailAlertHandler gestionnaire d'alertes qui envoie des emails
type EmailAlertHandler struct {
	Recipients []string
	SMTPConfig map[string]string
}

func (h *EmailAlertHandler) HandleAlert(ctx context.Context, alert *Alert) error {
	// Dans un vrai système, ceci enverrait l'alerte par email
	log.Printf("📧 EMAIL ALERT: Envoi vers %v - %s", h.Recipients, alert.Title)
	return nil
}
