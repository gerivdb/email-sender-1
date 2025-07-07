package monitoring

import (
	"context"
	"fmt"
	"log"
	"os/exec"
	"sync"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

// NeuralAutoHealingSystem système d'auto-guérison intelligent
type NeuralAutoHealingSystem struct {
	// Métriques pour l'auto-healing
	autoHealingAttempts  *prometheus.CounterVec
	autoHealingSuccesses *prometheus.CounterVec
	autoHealingFailures  *prometheus.CounterVec
	escalationCounter    *prometheus.CounterVec

	// Configuration
	maxRetries          int
	retryDelay          time.Duration
	escalationThreshold int
	recoveryStrategies  map[string][]RecoveryStrategy

	// État interne
	serviceFailures    map[string]*ServiceFailureTracker
	autonomyManager    AdvancedAutonomyManager
	notificationSystem NotificationSystem
	mutex              sync.RWMutex
	isActive           bool
}

// RecoveryStrategy représente une stratégie de récupération
type RecoveryStrategy struct {
	Name       string
	Priority   int
	Action     RecoveryAction
	Timeout    time.Duration
	Conditions []RecoveryCondition
}

// RecoveryAction définit une action de récupération
type RecoveryAction func(ctx context.Context, service string, failure *ServiceFailureTracker) error

// RecoveryCondition définit une condition pour appliquer une stratégie
type RecoveryCondition func(service string, failure *ServiceFailureTracker) bool

// ServiceFailureTracker suit les échecs d'un service
type ServiceFailureTracker struct {
	Service             string
	FailureCount        int
	FirstFailure        time.Time
	LastFailure         time.Time
	ConsecutiveFailures int
	LastRecoveryAttempt time.Time
	RecoveryAttempts    []RecoveryAttempt
	CurrentStatus       ServiceStatus
}

// RecoveryAttempt représente une tentative de récupération
type RecoveryAttempt struct {
	Timestamp time.Time
	Strategy  string
	Success   bool
	Error     error
	Duration  time.Duration
}

// ServiceStatus énumération pour l'état du service
type ServiceStatus int

const (
	StatusUnknown ServiceStatus = iota
	StatusHealthy
	StatusDegraded
	StatusFailed
	StatusRecovering
)

// AdvancedAutonomyManager interface pour l'escalade vers le système d'autonomie
type AdvancedAutonomyManager interface {
	HandleServiceFailure(ctx context.Context, service string, failure *ServiceFailureTracker) error
	NotifyEscalation(service string, reason string) error
}

// NotificationSystem interface pour les notifications
type NotificationSystem interface {
	SendAlert(level string, service string, message string) error
	LogEvent(event string, details map[string]interface{}) error
}

// NewNeuralAutoHealingSystem crée une nouvelle instance du système d'auto-healing
func NewNeuralAutoHealingSystem(autonomyManager AdvancedAutonomyManager, notifications NotificationSystem) *NeuralAutoHealingSystem {
	nahs := &NeuralAutoHealingSystem{
		maxRetries:          3,
		retryDelay:          30 * time.Second,
		escalationThreshold: 5,
		serviceFailures:     make(map[string]*ServiceFailureTracker),
		autonomyManager:     autonomyManager,
		notificationSystem:  notifications,
		recoveryStrategies:  make(map[string][]RecoveryStrategy),
	}

	// Initialisation des métriques Prometheus
	nahs.autoHealingAttempts = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Namespace: "smart_infrastructure",
			Subsystem: "auto_healing",
			Name:      "attempts_total",
			Help:      "Total number of auto-healing attempts",
		},
		[]string{"service", "strategy"},
	)

	nahs.autoHealingSuccesses = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Namespace: "smart_infrastructure",
			Subsystem: "auto_healing",
			Name:      "successes_total",
			Help:      "Total number of successful auto-healing attempts",
		},
		[]string{"service", "strategy"},
	)

	nahs.autoHealingFailures = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Namespace: "smart_infrastructure",
			Subsystem: "auto_healing",
			Name:      "failures_total",
			Help:      "Total number of failed auto-healing attempts",
		},
		[]string{"service", "strategy"},
	)

	nahs.escalationCounter = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Namespace: "smart_infrastructure",
			Subsystem: "auto_healing",
			Name:      "escalations_total",
			Help:      "Total number of escalations to AdvancedAutonomyManager",
		},
		[]string{"service", "reason"},
	)

	// Configuration des stratégies de récupération par défaut
	nahs.setupDefaultRecoveryStrategies()

	return nahs
}

// setupDefaultRecoveryStrategies configure les stratégies de récupération par défaut
func (nahs *NeuralAutoHealingSystem) setupDefaultRecoveryStrategies() {
	// Stratégies pour QDrant
	nahs.recoveryStrategies["qdrant"] = []RecoveryStrategy{
		{
			Name:     "qdrant_simple_restart",
			Priority: 1,
			Action:   nahs.dockerRestartAction,
			Timeout:  60 * time.Second,
			Conditions: []RecoveryCondition{
				nahs.conditionConsecutiveFailuresBelow(3),
			},
		},
		{
			Name:     "qdrant_force_restart",
			Priority: 2,
			Action:   nahs.dockerForceRestartAction,
			Timeout:  120 * time.Second,
			Conditions: []RecoveryCondition{
				nahs.conditionConsecutiveFailuresAbove(2),
			},
		},
		{
			Name:     "qdrant_recreate_container",
			Priority: 3,
			Action:   nahs.dockerRecreateAction,
			Timeout:  180 * time.Second,
			Conditions: []RecoveryCondition{
				nahs.conditionConsecutiveFailuresAbove(5),
			},
		},
	}

	// Stratégies pour Redis
	nahs.recoveryStrategies["redis"] = []RecoveryStrategy{
		{
			Name:     "redis_simple_restart",
			Priority: 1,
			Action:   nahs.dockerRestartAction,
			Timeout:  30 * time.Second,
			Conditions: []RecoveryCondition{
				nahs.conditionConsecutiveFailuresBelow(3),
			},
		},
		{
			Name:     "redis_flush_and_restart",
			Priority: 2,
			Action:   nahs.redisFlushAndRestartAction,
			Timeout:  60 * time.Second,
			Conditions: []RecoveryCondition{
				nahs.conditionConsecutiveFailuresAbove(2),
			},
		},
	}

	// Stratégies pour RAG Server
	nahs.recoveryStrategies["rag-server"] = []RecoveryStrategy{
		{
			Name:     "rag_server_restart",
			Priority: 1,
			Action:   nahs.dockerRestartAction,
			Timeout:  90 * time.Second,
		},
		{
			Name:     "rag_server_rebuild",
			Priority: 2,
			Action:   nahs.ragServerRebuildAction,
			Timeout:  300 * time.Second,
			Conditions: []RecoveryCondition{
				nahs.conditionConsecutiveFailuresAbove(3),
			},
		},
	}

	// Stratégies pour Prometheus
	nahs.recoveryStrategies["prometheus"] = []RecoveryStrategy{
		{
			Name:     "prometheus_restart",
			Priority: 1,
			Action:   nahs.dockerRestartAction,
			Timeout:  45 * time.Second,
		},
		{
			Name:     "prometheus_config_reload",
			Priority: 2,
			Action:   nahs.prometheusReloadConfigAction,
			Timeout:  30 * time.Second,
		},
	}

	// Stratégies pour Grafana
	nahs.recoveryStrategies["grafana"] = []RecoveryStrategy{
		{
			Name:     "grafana_restart",
			Priority: 1,
			Action:   nahs.dockerRestartAction,
			Timeout:  60 * time.Second,
		},
	}
}

// DetectAndHeal détecte les pannes et lance le processus d'auto-healing
func (nahs *NeuralAutoHealingSystem) DetectAndHeal(ctx context.Context, healthStatuses map[string]ServiceHealthStatus) error {
	nahs.mutex.Lock()
	defer nahs.mutex.Unlock()

	log.Println("🔧 Neural Auto-Healing System: Analyzing service health...")

	for serviceName, status := range healthStatuses {
		if !status.Healthy {
			log.Printf("⚠️  Service failure detected: %s", serviceName)

			// Mettre à jour ou créer le tracker de failure
			tracker := nahs.updateFailureTracker(serviceName, status)

			// Décider si on doit tenter une récupération
			if nahs.shouldAttemptRecovery(tracker) {
				go nahs.attemptRecovery(ctx, serviceName, tracker)
			} else if nahs.shouldEscalate(tracker) {
				go nahs.escalateToAutonomyManager(ctx, serviceName, tracker)
			}
		} else {
			// Service is healthy, reset failure tracker if it exists
			if tracker, exists := nahs.serviceFailures[serviceName]; exists {
				tracker.CurrentStatus = StatusHealthy
				tracker.ConsecutiveFailures = 0
				log.Printf("✅ Service %s recovered", serviceName)
			}
		}
	}

	return nil
}

// updateFailureTracker met à jour le tracker de failure pour un service
func (nahs *NeuralAutoHealingSystem) updateFailureTracker(serviceName string, status ServiceHealthStatus) *ServiceFailureTracker {
	tracker, exists := nahs.serviceFailures[serviceName]
	if !exists {
		tracker = &ServiceFailureTracker{
			Service:          serviceName,
			FirstFailure:     time.Now(),
			RecoveryAttempts: []RecoveryAttempt{},
		}
		nahs.serviceFailures[serviceName] = tracker
	}

	tracker.FailureCount++
	tracker.ConsecutiveFailures++
	tracker.LastFailure = time.Now()
	tracker.CurrentStatus = StatusFailed

	return tracker
}

// shouldAttemptRecovery détermine si on doit tenter une récupération
func (nahs *NeuralAutoHealingSystem) shouldAttemptRecovery(tracker *ServiceFailureTracker) bool {
	// Ne pas tenter si on a déjà essayé récemment
	if time.Since(tracker.LastRecoveryAttempt) < nahs.retryDelay {
		return false
	}

	// Ne pas tenter si on a dépassé le nombre max de tentatives
	if len(tracker.RecoveryAttempts) >= nahs.maxRetries {
		return false
	}

	return true
}

// shouldEscalate détermine si on doit escalader vers l'AdvancedAutonomyManager
func (nahs *NeuralAutoHealingSystem) shouldEscalate(tracker *ServiceFailureTracker) bool {
	return tracker.ConsecutiveFailures >= nahs.escalationThreshold
}

// attemptRecovery tente la récupération d'un service
func (nahs *NeuralAutoHealingSystem) attemptRecovery(ctx context.Context, serviceName string, tracker *ServiceFailureTracker) {
	log.Printf("🔄 Attempting recovery for service: %s", serviceName)

	tracker.CurrentStatus = StatusRecovering
	tracker.LastRecoveryAttempt = time.Now()

	strategies, exists := nahs.recoveryStrategies[serviceName]
	if !exists {
		log.Printf("⚠️  No recovery strategies defined for service: %s", serviceName)
		return
	}

	// Essayer les stratégies par ordre de priorité
	for _, strategy := range strategies {
		if nahs.evaluateConditions(strategy.Conditions, serviceName, tracker) {
			log.Printf("🎯 Applying recovery strategy: %s for %s", strategy.Name, serviceName)

			attempt := RecoveryAttempt{
				Timestamp: time.Now(),
				Strategy:  strategy.Name,
			}

			// Créer un contexte avec timeout pour la stratégie
			strategyCtx, cancel := context.WithTimeout(ctx, strategy.Timeout)
			defer cancel()

			// Exécuter la stratégie
			start := time.Now()
			err := strategy.Action(strategyCtx, serviceName, tracker)
			attempt.Duration = time.Since(start)
			attempt.Error = err
			attempt.Success = err == nil

			// Enregistrer la tentative
			tracker.RecoveryAttempts = append(tracker.RecoveryAttempts, attempt)

			// Mettre à jour les métriques
			nahs.autoHealingAttempts.WithLabelValues(serviceName, strategy.Name).Inc()

			if attempt.Success {
				nahs.autoHealingSuccesses.WithLabelValues(serviceName, strategy.Name).Inc()
				log.Printf("✅ Recovery successful for %s using strategy %s", serviceName, strategy.Name)

				// Notifier le succès
				nahs.notificationSystem.SendAlert("info", serviceName,
					fmt.Sprintf("Service recovered using strategy: %s", strategy.Name))

				tracker.CurrentStatus = StatusHealthy
				return
			} else {
				nahs.autoHealingFailures.WithLabelValues(serviceName, strategy.Name).Inc()
				log.Printf("❌ Recovery failed for %s using strategy %s: %v", serviceName, strategy.Name, err)
			}
		}
	}

	// Toutes les stratégies ont échoué
	log.Printf("❌ All recovery strategies failed for service: %s", serviceName)
	nahs.notificationSystem.SendAlert("error", serviceName, "All recovery strategies failed")
}

// evaluateConditions évalue si les conditions d'une stratégie sont remplies
func (nahs *NeuralAutoHealingSystem) evaluateConditions(conditions []RecoveryCondition, serviceName string, tracker *ServiceFailureTracker) bool {
	for _, condition := range conditions {
		if !condition(serviceName, tracker) {
			return false
		}
	}
	return true
}

// escalateToAutonomyManager escalade vers l'AdvancedAutonomyManager
func (nahs *NeuralAutoHealingSystem) escalateToAutonomyManager(ctx context.Context, serviceName string, tracker *ServiceFailureTracker) {
	log.Printf("🚨 Escalating service failure to AdvancedAutonomyManager: %s", serviceName)

	reason := fmt.Sprintf("Consecutive failures: %d, Total attempts: %d",
		tracker.ConsecutiveFailures, len(tracker.RecoveryAttempts))

	nahs.escalationCounter.WithLabelValues(serviceName, "max_retries_exceeded").Inc()

	err := nahs.autonomyManager.HandleServiceFailure(ctx, serviceName, tracker)
	if err != nil {
		log.Printf("❌ Escalation failed: %v", err)
		nahs.notificationSystem.SendAlert("critical", serviceName,
			fmt.Sprintf("Escalation failed: %v", err))
	} else {
		nahs.autonomyManager.NotifyEscalation(serviceName, reason)
		nahs.notificationSystem.SendAlert("warning", serviceName,
			fmt.Sprintf("Escalated to AdvancedAutonomyManager: %s", reason))
	}
}

// Actions de récupération spécifiques

// dockerRestartAction redémarre un conteneur Docker
func (nahs *NeuralAutoHealingSystem) dockerRestartAction(ctx context.Context, service string, tracker *ServiceFailureTracker) error {
	log.Printf("🔄 Docker restart action for service: %s", service)

	cmd := exec.CommandContext(ctx, "docker-compose", "restart", service)
	output, err := cmd.CombinedOutput()

	if err != nil {
		return fmt.Errorf("docker restart failed: %w, output: %s", err, string(output))
	}

	// Attendre un peu pour que le service redémarre
	time.Sleep(10 * time.Second)
	return nil
}

// dockerForceRestartAction force le redémarrage d'un conteneur Docker
func (nahs *NeuralAutoHealingSystem) dockerForceRestartAction(ctx context.Context, service string, tracker *ServiceFailureTracker) error {
	log.Printf("🔄 Docker force restart action for service: %s", service)

	// Stop forcé
	stopCmd := exec.CommandContext(ctx, "docker-compose", "kill", service)
	stopCmd.Run() // Ignorer les erreurs

	// Redémarrage
	startCmd := exec.CommandContext(ctx, "docker-compose", "up", "-d", service)
	output, err := startCmd.CombinedOutput()

	if err != nil {
		return fmt.Errorf("docker force restart failed: %w, output: %s", err, string(output))
	}

	time.Sleep(15 * time.Second)
	return nil
}

// dockerRecreateAction recrée complètement un conteneur Docker
func (nahs *NeuralAutoHealingSystem) dockerRecreateAction(ctx context.Context, service string, tracker *ServiceFailureTracker) error {
	log.Printf("🔄 Docker recreate action for service: %s", service)

	// Down
	downCmd := exec.CommandContext(ctx, "docker-compose", "down", service)
	downCmd.Run()

	// Up avec force recreate
	upCmd := exec.CommandContext(ctx, "docker-compose", "up", "-d", "--force-recreate", service)
	output, err := upCmd.CombinedOutput()

	if err != nil {
		return fmt.Errorf("docker recreate failed: %w, output: %s", err, string(output))
	}

	time.Sleep(30 * time.Second)
	return nil
}

// redisFlushAndRestartAction vide Redis et le redémarre
func (nahs *NeuralAutoHealingSystem) redisFlushAndRestartAction(ctx context.Context, service string, tracker *ServiceFailureTracker) error {
	log.Printf("🔄 Redis flush and restart action for service: %s", service)

	// Essayer de vider Redis avant redémarrage
	flushCmd := exec.CommandContext(ctx, "docker", "exec", "redis", "redis-cli", "FLUSHALL")
	flushCmd.Run() // Ignorer les erreurs

	return nahs.dockerRestartAction(ctx, service, tracker)
}

// ragServerRebuildAction reconstruit et redémarre le serveur RAG
func (nahs *NeuralAutoHealingSystem) ragServerRebuildAction(ctx context.Context, service string, tracker *ServiceFailureTracker) error {
	log.Printf("🔄 RAG Server rebuild action for service: %s", service)

	// Stop
	stopCmd := exec.CommandContext(ctx, "docker-compose", "stop", service)
	stopCmd.Run()

	// Build avec no-cache
	buildCmd := exec.CommandContext(ctx, "docker-compose", "build", "--no-cache", service)
	output, err := buildCmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("rag server build failed: %w, output: %s", err, string(output))
	}

	// Start
	startCmd := exec.CommandContext(ctx, "docker-compose", "up", "-d", service)
	output, err = startCmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("rag server start failed: %w, output: %s", err, string(output))
	}

	time.Sleep(60 * time.Second) // RAG server needs more time to start
	return nil
}

// prometheusReloadConfigAction recharge la configuration Prometheus
func (nahs *NeuralAutoHealingSystem) prometheusReloadConfigAction(ctx context.Context, service string, tracker *ServiceFailureTracker) error {
	log.Printf("🔄 Prometheus config reload action for service: %s", service)

	// Essayer de recharger la config via l'API
	reloadCmd := exec.CommandContext(ctx, "curl", "-X", "POST", "http://localhost:9091/-/reload")
	output, err := reloadCmd.CombinedOutput()

	if err != nil {
		// Si l'API ne répond pas, redémarrer le conteneur
		return nahs.dockerRestartAction(ctx, service, tracker)
	}

	log.Printf("Prometheus config reloaded: %s", string(output))
	time.Sleep(5 * time.Second)
	return nil
}

// Conditions de récupération

// conditionConsecutiveFailuresBelow retourne une condition basée sur le nombre d'échecs consécutifs
func (nahs *NeuralAutoHealingSystem) conditionConsecutiveFailuresBelow(threshold int) RecoveryCondition {
	return func(service string, tracker *ServiceFailureTracker) bool {
		return tracker.ConsecutiveFailures < threshold
	}
}

// conditionConsecutiveFailuresAbove retourne une condition basée sur le nombre d'échecs consécutifs
func (nahs *NeuralAutoHealingSystem) conditionConsecutiveFailuresAbove(threshold int) RecoveryCondition {
	return func(service string, tracker *ServiceFailureTracker) bool {
		return tracker.ConsecutiveFailures > threshold
	}
}

// GetServiceFailureStatus retourne le statut de failure d'un service
func (nahs *NeuralAutoHealingSystem) GetServiceFailureStatus(serviceName string) (*ServiceFailureTracker, bool) {
	nahs.mutex.RLock()
	defer nahs.mutex.RUnlock()

	tracker, exists := nahs.serviceFailures[serviceName]
	return tracker, exists
}

// GetAllFailureStatuses retourne tous les statuts de failure
func (nahs *NeuralAutoHealingSystem) GetAllFailureStatuses() map[string]*ServiceFailureTracker {
	nahs.mutex.RLock()
	defer nahs.mutex.RUnlock()

	// Copie pour éviter les race conditions
	copy := make(map[string]*ServiceFailureTracker)
	for k, v := range nahs.serviceFailures {
		copy[k] = v
	}
	return copy
}

// Start démarre le système d'auto-healing
func (nahs *NeuralAutoHealingSystem) Start(ctx context.Context) error {
	log.Println("🚀 Starting Neural Auto-Healing System...")

	nahs.isActive = true

	// Démarrer la surveillance continue
	go nahs.startContinuousMonitoring(ctx)

	log.Println("✅ Neural Auto-Healing System started")
	return nil
}

// Stop arrête le système d'auto-healing
func (nahs *NeuralAutoHealingSystem) Stop() error {
	log.Println("🛑 Stopping Neural Auto-Healing System...")

	nahs.isActive = false

	log.Println("✅ Neural Auto-Healing System stopped")
	return nil
}

// startContinuousMonitoring surveille en continu les services
func (nahs *NeuralAutoHealingSystem) startContinuousMonitoring(ctx context.Context) {
	ticker := time.NewTicker(60 * time.Second) // Vérifier toutes les minutes
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			if nahs.isActive {
				nahs.checkServiceHealth(ctx)
			}
		}
	}
}

// checkServiceHealth vérifie la santé des services et déclenche l'auto-healing si nécessaire
func (nahs *NeuralAutoHealingSystem) checkServiceHealth(ctx context.Context) {
	// Cette méthode sera implémentée avec la logique de vérification de santé
	// et de déclenchement d'auto-healing selon les besoins
}
