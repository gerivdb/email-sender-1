// Package coordination - Cross-Manager Event Bus implementation
// Gère la communication asynchrone entre tous les managers de l'écosystème
package coordination

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/gerivdb/email-sender-1/development/managers/advanced-autonomy-manager/interfaces"
)

// CrossManagerEventBus implémentation détaillée
type CrossManagerEventBus struct {
	config         *EventBusConfig
	logger         interfaces.Logger
	eventChannels  map[string]chan *CoordinationEvent
	eventRouter    *EventRouter
	eventFilter    *EventFilter
	eventAnalytics *EventAnalytics
	subscribers    map[string][]EventSubscriber
	initialized    bool
	ctx            context.Context
	cancel         context.CancelFunc
	mutex          sync.RWMutex
}

// EventRouter route les événements vers les bonnes destinations
type EventRouter struct {
	config       *RouterConfig
	logger       interfaces.Logger
	routingTable map[EventType][]string
	routingRules []RoutingRule
	metrics      *RoutingMetrics
	mutex        sync.RWMutex
}

// EventFilter filtre les événements selon la priorité et les règles
type EventFilter struct {
	config        *FilterConfig
	logger        interfaces.Logger
	filterRules   []FilterRule
	priorityQueue *PriorityQueue
	rateLimiter   *RateLimiter
	mutex         sync.RWMutex
}

// EventAnalytics analyse et corrèle les événements
type EventAnalytics struct {
	config          *AnalyticsConfig
	logger          interfaces.Logger
	eventHistory    []HistoricalEvent
	correlations    map[string]*EventCorrelation
	patterns        []EventPattern
	anomalyDetector *AnomalyDetector
	mutex           sync.RWMutex
}

// Structures de données pour les événements

type HistoricalEvent struct {
	Event     *CoordinationEvent
	Timestamp time.Time
	Source    string
	Target    string
	Processed bool
	Duration  time.Duration
}

type EventCorrelation struct {
	CorrelationID string
	Events        []*CoordinationEvent
	StartTime     time.Time
	EndTime       time.Time
	Pattern       string
	Confidence    float64
}

type EventPattern struct {
	Name        string
	Description string
	Matcher     func(*CoordinationEvent) bool
	Handler     func([]*CoordinationEvent) error
	Frequency   int
	LastSeen    time.Time
}

type RoutingRule struct {
	Name      string
	Condition func(*CoordinationEvent) bool
	Target    string
	Priority  int
	Enabled   bool
}

type FilterRule struct {
	Name      string
	Condition func(*CoordinationEvent) bool
	Action    FilterAction
	Priority  int
	Enabled   bool
}

type FilterAction string

const (
	FilterActionAllow  FilterAction = "allow"
	FilterActionBlock  FilterAction = "block"
	FilterActionModify FilterAction = "modify"
	FilterActionDelay  FilterAction = "delay"
)

// PriorityQueue pour la gestion des priorités d'événements
type PriorityQueue struct {
	events []*PriorityEvent
	mutex  sync.Mutex
}

type PriorityEvent struct {
	Event    *CoordinationEvent
	Priority int
	AddedAt  time.Time
}

// RateLimiter pour limiter le débit d'événements
type RateLimiter struct {
	maxEvents   int
	windowSize  time.Duration
	eventCounts map[string]int
	windows     map[string]time.Time
	mutex       sync.Mutex
}

// AnomalyDetector détecte les anomalies dans les patterns d'événements
type AnomalyDetector struct {
	config          *AnomalyConfig
	logger          interfaces.Logger
	baselineMetrics map[string]float64
	thresholds      map[string]float64
	alerts          []AnomalyAlert
	mutex           sync.RWMutex
}

type AnomalyAlert struct {
	Type        string
	Description string
	Severity    AlertSeverity
	Timestamp   time.Time
	Context     map[string]interface{}
}

type AlertSeverity int

const (
	AlertSeverityLow AlertSeverity = iota
	AlertSeverityMedium
	AlertSeverityHigh
	AlertSeverityCritical
)

// Configurations

type RouterConfig struct {
	MaxRoutingLatency time.Duration
	RoutingBufferSize int
	EnableRouting     bool
}

type FilterConfig struct {
	MaxFilterLatency   time.Duration
	FilterBufferSize   int
	EnableRateLimiting bool
	MaxEventsPerSecond int
}

type AnalyticsConfig struct {
	HistoryRetention  time.Duration
	CorrelationWindow time.Duration
	PatternDetection  bool
	AnomalyDetection  bool
}

type AnomalyConfig struct {
	SensitivityLevel float64
	DetectionWindow  time.Duration
	AlertThreshold   float64
}

// Métriques

type RoutingMetrics struct {
	EventsRouted   int64
	AverageLatency time.Duration
	RoutingErrors  int64
	LastUpdate     time.Time
}

// NewCrossManagerEventBus crée un nouveau bus d'événements
func NewCrossManagerEventBus(config *EventBusConfig, logger interfaces.Logger) (*CrossManagerEventBus, error) {
	if config == nil {
		return nil, fmt.Errorf("event bus config is required")
	}

	if logger == nil {
		return nil, fmt.Errorf("logger is required")
	}

	ctx, cancel := context.WithCancel(context.Background())

	eventBus := &CrossManagerEventBus{
		config:        config,
		logger:        logger,
		eventChannels: make(map[string]chan *CoordinationEvent),
		subscribers:   make(map[string][]EventSubscriber),
		initialized:   false,
		ctx:           ctx,
		cancel:        cancel,
	}

	// Initialiser le routeur d'événements
	eventRouter, err := NewEventRouter(&RouterConfig{
		MaxRoutingLatency: 100 * time.Millisecond,
		RoutingBufferSize: config.BufferSize,
		EnableRouting:     true,
	}, logger)
	if err != nil {
		return nil, fmt.Errorf("failed to create event router: %w", err)
	}
	eventBus.eventRouter = eventRouter

	// Initialiser le filtre d'événements
	eventFilter, err := NewEventFilter(&FilterConfig{
		MaxFilterLatency:   50 * time.Millisecond,
		FilterBufferSize:   config.BufferSize,
		EnableRateLimiting: true,
		MaxEventsPerSecond: 1000,
	}, logger)
	if err != nil {
		return nil, fmt.Errorf("failed to create event filter: %w", err)
	}
	eventBus.eventFilter = eventFilter

	// Initialiser l'analytics d'événements
	eventAnalytics, err := NewEventAnalytics(&AnalyticsConfig{
		HistoryRetention:  24 * time.Hour,
		CorrelationWindow: 5 * time.Minute,
		PatternDetection:  true,
		AnomalyDetection:  true,
	}, logger)
	if err != nil {
		return nil, fmt.Errorf("failed to create event analytics: %w", err)
	}
	eventBus.eventAnalytics = eventAnalytics

	return eventBus, nil
}

// Initialize initialise le bus d'événements
func (cmeb *CrossManagerEventBus) Initialize(ctx context.Context) error {
	cmeb.mutex.Lock()
	defer cmeb.mutex.Unlock()

	if cmeb.initialized {
		return fmt.Errorf("event bus already initialized")
	}

	cmeb.logger.Info("Initializing Cross-Manager Event Bus")

	// Créer les canaux d'événements pour chaque type
	eventTypes := []EventType{
		EventTypeManagerStateChange,
		EventTypeDecisionExecuted,
		EventTypeHealthAlert,
		EventTypePerformanceMetric,
		EventTypeEmergencyTrigger,
		EventTypeSystemNotification,
	}

	for _, eventType := range eventTypes {
		channelName := string(eventType)
		cmeb.eventChannels[channelName] = make(chan *CoordinationEvent, cmeb.config.BufferSize)
	}

	// Démarrer les processus de traitement d'événements
	go cmeb.startEventProcessing()
	go cmeb.startEventAnalytics()
	go cmeb.startEventCleanup()

	cmeb.initialized = true
	cmeb.logger.Info("Cross-Manager Event Bus initialized successfully")

	return nil
}

// PublishEvent publie un événement dans le bus
func (cmeb *CrossManagerEventBus) PublishEvent(event *CoordinationEvent) error {
	if !cmeb.initialized {
		return fmt.Errorf("event bus not initialized")
	}

	// Appliquer les filtres
	if !cmeb.eventFilter.ShouldProcess(event) {
		cmeb.logger.Debug(fmt.Sprintf("Event %s filtered out", event.ID))
		return nil
	}

	// Router l'événement
	targets, err := cmeb.eventRouter.GetTargets(event)
	if err != nil {
		return fmt.Errorf("failed to route event: %w", err)
	}

	// Publier l'événement vers tous les canaux cibles
	for _, target := range targets {
		select {
		case cmeb.eventChannels[target] <- event:
			cmeb.logger.Debug(fmt.Sprintf("Event %s published to %s", event.ID, target))
		default:
			cmeb.logger.Warn(fmt.Sprintf("Event channel %s is full, dropping event %s", target, event.ID))
		}
	}

	// Enregistrer l'événement pour l'analytics
	cmeb.eventAnalytics.RecordEvent(event)

	return nil
}

// SubscribeToManager souscrit aux événements d'un manager
func (cmeb *CrossManagerEventBus) SubscribeToManager(managerName string, subscriber EventSubscriber) error {
	cmeb.mutex.Lock()
	defer cmeb.mutex.Unlock()

	if cmeb.subscribers[managerName] == nil {
		cmeb.subscribers[managerName] = make([]EventSubscriber, 0)
	}

	cmeb.subscribers[managerName] = append(cmeb.subscribers[managerName], subscriber)
	cmeb.logger.Info(fmt.Sprintf("Subscriber added for manager %s", managerName))

	return nil
}

// ProcessPendingEvents traite les événements en attente
func (cmeb *CrossManagerEventBus) ProcessPendingEvents() {
	// Les événements sont traités automatiquement par les processus en arrière-plan
	// Cette méthode peut être utilisée pour forcer le traitement
	cmeb.eventAnalytics.ProcessPendingAnalytics()
}

// Cleanup nettoie les ressources du bus d'événements
func (cmeb *CrossManagerEventBus) Cleanup() error {
	cmeb.mutex.Lock()
	defer cmeb.mutex.Unlock()

	cmeb.logger.Info("Starting Cross-Manager Event Bus cleanup")

	// Annuler le contexte pour arrêter tous les processus
	if cmeb.cancel != nil {
		cmeb.cancel()
	}

	// Fermer tous les canaux d'événements
	for name, channel := range cmeb.eventChannels {
		close(channel)
		delete(cmeb.eventChannels, name)
	}

	// Nettoyer les composants
	var errors []error

	if cmeb.eventAnalytics != nil {
		if err := cmeb.eventAnalytics.cleanup(); err != nil {
			errors = append(errors, fmt.Errorf("event analytics cleanup failed: %w", err))
		}
	}

	if cmeb.eventFilter != nil {
		if err := cmeb.eventFilter.cleanup(); err != nil {
			errors = append(errors, fmt.Errorf("event filter cleanup failed: %w", err))
		}
	}

	if cmeb.eventRouter != nil {
		if err := cmeb.eventRouter.cleanup(); err != nil {
			errors = append(errors, fmt.Errorf("event router cleanup failed: %w", err))
		}
	}

	cmeb.initialized = false

	if len(errors) > 0 {
		return fmt.Errorf("cleanup completed with errors: %v", errors)
	}

	cmeb.logger.Info("Cross-Manager Event Bus cleanup completed successfully")
	return nil
}

// Méthodes internes

func (cmeb *CrossManagerEventBus) startEventProcessing() {
	ticker := time.NewTicker(cmeb.config.ProcessingRate)
	defer ticker.Stop()

	for {
		select {
		case <-cmeb.ctx.Done():
			return
		case <-ticker.C:
			cmeb.processEventsFromChannels()
		}
	}
}

func (cmeb *CrossManagerEventBus) startEventAnalytics() {
	ticker := time.NewTicker(1 * time.Minute)
	defer ticker.Stop()

	for {
		select {
		case <-cmeb.ctx.Done():
			return
		case <-ticker.C:
			cmeb.eventAnalytics.AnalyzePatterns()
			cmeb.eventAnalytics.DetectAnomalies()
		}
	}
}

func (cmeb *CrossManagerEventBus) startEventCleanup() {
	ticker := time.NewTicker(cmeb.config.RetentionTime / 10)
	defer ticker.Stop()

	for {
		select {
		case <-cmeb.ctx.Done():
			return
		case <-ticker.C:
			cmeb.eventAnalytics.CleanupOldEvents()
		}
	}
}

func (cmeb *CrossManagerEventBus) processEventsFromChannels() {
	for channelName, channel := range cmeb.eventChannels {
		select {
		case event := <-channel:
			cmeb.processEvent(channelName, event)
		default:
			// Pas d'événement dans ce canal
		}
	}
}

func (cmeb *CrossManagerEventBus) processEvent(channelName string, event *CoordinationEvent) {
	// Traiter l'événement et le distribuer aux abonnés
	if subscribers, exists := cmeb.subscribers[event.Target]; exists {
		for _, subscriber := range subscribers {
			go func(s EventSubscriber, e *CoordinationEvent) {
				if err := s.HandleEvent(e); err != nil {
					cmeb.logger.Error(fmt.Sprintf("Subscriber failed to handle event %s: %v", e.ID, err))
				}
			}(subscriber, event)
		}
	}
}

// Implémentation EventRouter

func NewEventRouter(config *RouterConfig, logger interfaces.Logger) (*EventRouter, error) {
	router := &EventRouter{
		config:       config,
		logger:       logger,
		routingTable: make(map[EventType][]string),
		routingRules: createDefaultRoutingRules(),
		metrics: &RoutingMetrics{
			EventsRouted:   0,
			AverageLatency: 0,
			RoutingErrors:  0,
			LastUpdate:     time.Now(),
		},
	}

	// Initialiser la table de routage par défaut
	router.initializeDefaultRoutingTable()

	return router, nil
}

func (er *EventRouter) GetTargets(event *CoordinationEvent) ([]string, error) {
	startTime := time.Now()
	defer func() {
		duration := time.Since(startTime)
		er.updateMetrics(duration, true)
	}()

	targets := make([]string, 0)

	// Appliquer les règles de routage
	for _, rule := range er.routingRules {
		if rule.Enabled && rule.Condition(event) {
			targets = append(targets, rule.Target)
		}
	}

	// Si aucune règle ne correspond, utiliser la table de routage par défaut
	if len(targets) == 0 {
		if defaultTargets, exists := er.routingTable[event.Type]; exists {
			targets = defaultTargets
		} else {
			targets = []string{string(event.Type)} // Canal par défaut basé sur le type
		}
	}

	return targets, nil
}

func (er *EventRouter) updateMetrics(duration time.Duration, success bool) {
	er.mutex.Lock()
	defer er.mutex.Unlock()

	er.metrics.EventsRouted++
	if er.metrics.AverageLatency == 0 {
		er.metrics.AverageLatency = duration
	} else {
		er.metrics.AverageLatency = (er.metrics.AverageLatency + duration) / 2
	}

	if !success {
		er.metrics.RoutingErrors++
	}

	er.metrics.LastUpdate = time.Now()
}

func (er *EventRouter) initializeDefaultRoutingTable() {
	er.routingTable[EventTypeManagerStateChange] = []string{"manager_state_change"}
	er.routingTable[EventTypeDecisionExecuted] = []string{"decision_executed"}
	er.routingTable[EventTypeHealthAlert] = []string{"health_alert"}
	er.routingTable[EventTypePerformanceMetric] = []string{"performance_metric"}
	er.routingTable[EventTypeEmergencyTrigger] = []string{"emergency_trigger"}
	er.routingTable[EventTypeSystemNotification] = []string{"system_notification"}
}

func (er *EventRouter) cleanup() error {
	// Nettoyer les ressources du routeur
	return nil
}

func createDefaultRoutingRules() []RoutingRule {
	return []RoutingRule{
		{
			Name: "CriticalEventRoute",
			Condition: func(event *CoordinationEvent) bool {
				return event.Priority >= EventPriorityCritical
			},
			Target:   "critical_events",
			Priority: 10,
			Enabled:  true,
		},
		{
			Name: "EmergencyEventRoute",
			Condition: func(event *CoordinationEvent) bool {
				return event.Type == EventTypeEmergencyTrigger
			},
			Target:   "emergency_response",
			Priority: 9,
			Enabled:  true,
		},
	}
}

// Implémentation EventFilter

func NewEventFilter(config *FilterConfig, logger interfaces.Logger) (*EventFilter, error) {
	filter := &EventFilter{
		config:        config,
		logger:        logger,
		filterRules:   createDefaultFilterRules(),
		priorityQueue: NewPriorityQueue(),
		rateLimiter:   NewRateLimiter(config.MaxEventsPerSecond, time.Second),
	}

	return filter, nil
}

func (ef *EventFilter) ShouldProcess(event *CoordinationEvent) bool {
	// Vérifier la limitation de débit
	if ef.config.EnableRateLimiting && !ef.rateLimiter.Allow(event.Source) {
		return false
	}

	// Appliquer les règles de filtrage
	for _, rule := range ef.filterRules {
		if rule.Enabled && rule.Condition(event) {
			switch rule.Action {
			case FilterActionBlock:
				return false
			case FilterActionAllow:
				return true
			case FilterActionModify:
				ef.modifyEvent(event, rule)
				return true
			case FilterActionDelay:
				ef.priorityQueue.Add(event, int(event.Priority))
				return false // Traité plus tard
			}
		}
	}

	return true // Par défaut, autoriser l'événement
}

func (ef *EventFilter) modifyEvent(event *CoordinationEvent, rule FilterRule) {
	// Modifier l'événement selon la règle
	// Implémentation spécifique selon les besoins
}

func (ef *EventFilter) cleanup() error {
	return nil
}

func createDefaultFilterRules() []FilterRule {
	return []FilterRule{
		{
			Name: "HighPriorityFilter",
			Condition: func(event *CoordinationEvent) bool {
				return event.Priority >= EventPriorityHigh
			},
			Action:   FilterActionAllow,
			Priority: 10,
			Enabled:  true,
		},
		{
			Name: "DuplicateFilter",
			Condition: func(event *CoordinationEvent) bool {
				// Logique pour détecter les doublons
				return false // Placeholder
			},
			Action:   FilterActionBlock,
			Priority: 5,
			Enabled:  true,
		},
	}
}

// Implémentation EventAnalytics

func NewEventAnalytics(config *AnalyticsConfig, logger interfaces.Logger) (*EventAnalytics, error) {
	analytics := &EventAnalytics{
		config:       config,
		logger:       logger,
		eventHistory: make([]HistoricalEvent, 0),
		correlations: make(map[string]*EventCorrelation),
		patterns:     createDefaultEventPatterns(),
		anomalyDetector: NewAnomalyDetector(&AnomalyConfig{
			SensitivityLevel: 0.8,
			DetectionWindow:  5 * time.Minute,
			AlertThreshold:   0.9,
		}, logger),
	}

	return analytics, nil
}

func (ea *EventAnalytics) RecordEvent(event *CoordinationEvent) {
	ea.mutex.Lock()
	defer ea.mutex.Unlock()

	historicalEvent := HistoricalEvent{
		Event:     event,
		Timestamp: time.Now(),
		Source:    event.Source,
		Target:    event.Target,
		Processed: false,
	}

	ea.eventHistory = append(ea.eventHistory, historicalEvent)
}

func (ea *EventAnalytics) AnalyzePatterns() {
	ea.mutex.RLock()
	events := ea.getRecentEvents()
	ea.mutex.RUnlock()

	// Analyser les patterns dans les événements récents
	for _, pattern := range ea.patterns {
		matchingEvents := make([]*CoordinationEvent, 0)
		for _, event := range events {
			if pattern.Matcher(event.Event) {
				matchingEvents = append(matchingEvents, event.Event)
			}
		}

		if len(matchingEvents) > 0 {
			pattern.Frequency = len(matchingEvents)
			pattern.LastSeen = time.Now()

			if err := pattern.Handler(matchingEvents); err != nil {
				ea.logger.Error(fmt.Sprintf("Pattern handler failed for %s: %v", pattern.Name, err))
			}
		}
	}
}

func (ea *EventAnalytics) DetectAnomalies() {
	if !ea.config.AnomalyDetection {
		return
	}

	ea.mutex.RLock()
	events := ea.getRecentEvents()
	ea.mutex.RUnlock()

	alerts := ea.anomalyDetector.DetectAnomalies(events)
	for _, alert := range alerts {
		ea.logger.Warn(fmt.Sprintf("Anomaly detected: %s - %s", alert.Type, alert.Description))
	}
}

func (ea *EventAnalytics) ProcessPendingAnalytics() {
	ea.AnalyzePatterns()
	ea.DetectAnomalies()
	ea.CorrelateEvents()
}

func (ea *EventAnalytics) CorrelateEvents() {
	// Implémenter la corrélation d'événements
	// Cette méthode analyse les relations entre événements
}

func (ea *EventAnalytics) CleanupOldEvents() {
	ea.mutex.Lock()
	defer ea.mutex.Unlock()

	cutoff := time.Now().Add(-ea.config.HistoryRetention)
	filteredHistory := make([]HistoricalEvent, 0)

	for _, event := range ea.eventHistory {
		if event.Timestamp.After(cutoff) {
			filteredHistory = append(filteredHistory, event)
		}
	}

	ea.eventHistory = filteredHistory
}

func (ea *EventAnalytics) getRecentEvents() []HistoricalEvent {
	cutoff := time.Now().Add(-ea.config.CorrelationWindow)
	recentEvents := make([]HistoricalEvent, 0)

	for _, event := range ea.eventHistory {
		if event.Timestamp.After(cutoff) {
			recentEvents = append(recentEvents, event)
		}
	}

	return recentEvents
}

func (ea *EventAnalytics) cleanup() error {
	return nil
}

func createDefaultEventPatterns() []EventPattern {
	return []EventPattern{
		{
			Name:        "HealthDegradationPattern",
			Description: "Détecte une dégradation progressive de la santé",
			Matcher: func(event *CoordinationEvent) bool {
				return event.Type == EventTypeHealthAlert
			},
			Handler: func(events []*CoordinationEvent) error {
				// Analyser la dégradation de santé
				return nil
			},
			Frequency: 0,
			LastSeen:  time.Time{},
		},
		{
			Name:        "PerformanceAnomalyPattern",
			Description: "Détecte les anomalies de performance",
			Matcher: func(event *CoordinationEvent) bool {
				return event.Type == EventTypePerformanceMetric
			},
			Handler: func(events []*CoordinationEvent) error {
				// Analyser les anomalies de performance
				return nil
			},
			Frequency: 0,
			LastSeen:  time.Time{},
		},
	}
}

// Implémentations utilitaires

func NewPriorityQueue() *PriorityQueue {
	return &PriorityQueue{
		events: make([]*PriorityEvent, 0),
	}
}

func (pq *PriorityQueue) Add(event *CoordinationEvent, priority int) {
	pq.mutex.Lock()
	defer pq.mutex.Unlock()

	priorityEvent := &PriorityEvent{
		Event:    event,
		Priority: priority,
		AddedAt:  time.Now(),
	}

	pq.events = append(pq.events, priorityEvent)
	// Tri simple par priorité (peut être optimisé avec un heap)
}

func NewRateLimiter(maxEvents int, window time.Duration) *RateLimiter {
	return &RateLimiter{
		maxEvents:   maxEvents,
		windowSize:  window,
		eventCounts: make(map[string]int),
		windows:     make(map[string]time.Time),
	}
}

func (rl *RateLimiter) Allow(source string) bool {
	rl.mutex.Lock()
	defer rl.mutex.Unlock()

	now := time.Now()

	// Vérifier si la fenêtre a expiré
	if window, exists := rl.windows[source]; !exists || now.Sub(window) > rl.windowSize {
		rl.windows[source] = now
		rl.eventCounts[source] = 0
	}

	// Vérifier la limite
	if rl.eventCounts[source] >= rl.maxEvents {
		return false
	}

	rl.eventCounts[source]++
	return true
}

func NewAnomalyDetector(config *AnomalyConfig, logger interfaces.Logger) *AnomalyDetector {
	return &AnomalyDetector{
		config:          config,
		logger:          logger,
		baselineMetrics: make(map[string]float64),
		thresholds:      make(map[string]float64),
		alerts:          make([]AnomalyAlert, 0),
	}
}

func (ad *AnomalyDetector) DetectAnomalies(events []HistoricalEvent) []AnomalyAlert {
	alerts := make([]AnomalyAlert, 0)

	// Analyser les événements pour détecter les anomalies
	eventCounts := make(map[EventType]int)
	for _, event := range events {
		eventCounts[event.Event.Type]++
	}

	// Détecter les pics d'événements
	for eventType, count := range eventCounts {
		baseline, exists := ad.baselineMetrics[string(eventType)]
		if !exists {
			ad.baselineMetrics[string(eventType)] = float64(count)
			continue
		}

		deviation := float64(count) / baseline
		if deviation > (1.0 + ad.config.SensitivityLevel) {
			alert := AnomalyAlert{
				Type:        "EventSpike",
				Description: fmt.Sprintf("Spike in %s events: %d vs baseline %.1f", eventType, count, baseline),
				Severity:    AlertSeverityMedium,
				Timestamp:   time.Now(),
				Context: map[string]interface{}{
					"event_type": eventType,
					"count":      count,
					"baseline":   baseline,
					"deviation":  deviation,
				},
			}
			alerts = append(alerts, alert)
		}

		// Mise à jour de la baseline (moyenne mobile)
		ad.baselineMetrics[string(eventType)] = (baseline*0.9 + float64(count)*0.1)
	}

	return alerts
}
