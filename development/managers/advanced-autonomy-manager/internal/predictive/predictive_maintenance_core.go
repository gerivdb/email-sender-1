// Package predictive implements the Predictive Maintenance Core component
// of the AdvancedAutonomyManager - ML-powered predictive maintenance system
package predictive

import (
	"context"
	"fmt"
	"math"
	"sync"
	"time"

	"advanced-autonomy-manager/interfaces"
)

// PredictiveConfig configure la maintenance prédictive
type PredictiveConfig struct {
	PredictionHorizon    time.Duration `yaml:"prediction_horizon" json:"prediction_horizon"`
	AnalysisDepth        int           `yaml:"analysis_depth" json:"analysis_depth"`
	MLModelPath          string        `yaml:"ml_model_path" json:"ml_model_path"`
	AccuracyThreshold    float64       `yaml:"accuracy_threshold" json:"accuracy_threshold"`
	UpdateFrequency      time.Duration `yaml:"update_frequency" json:"update_frequency"`
}

// PredictionModel représente un modèle de prédiction
type PredictionModel struct {
	ID          string    `json:"id"`
	Version     string    `json:"version"`
	Accuracy    float64   `json:"accuracy"`
	LastTrained time.Time `json:"last_trained"`
	ModelType   string    `json:"model_type"`
}

// ModelTrainer entraîne les modèles ML
type ModelTrainer struct {
	config    *TrainingConfig
	datasets  []Dataset
}

// ModelEvaluator évalue les modèles
type ModelEvaluator struct {
	metrics map[string]float64
}

// AnomalyDetector détecte les anomalies (redéclaré pour predictive)
type AnomalyDetector struct {
	threshold   float64
	sensitivity float64
}

// TrainingConfig configuration pour l'entraînement
type TrainingConfig struct {
	BatchSize    int           `json:"batch_size"`
	Epochs       int           `json:"epochs"`
	LearningRate float64       `json:"learning_rate"`
	Timeout      time.Duration `json:"timeout"`
}

// Dataset représente un jeu de données
type Dataset struct {
	Name     string                   `json:"name"`
	Features []string                 `json:"features"`
	Data     []map[string]interface{} `json:"data"`
	Size     int                      `json:"size"`
}

// CachedPrediction représente une prédiction mise en cache
type CachedPrediction struct {
	Prediction  interface{} `json:"prediction"`
	Timestamp   time.Time   `json:"timestamp"`
	TTL         time.Duration `json:"ttl"`
	Confidence  float64     `json:"confidence"`
}

// PredictiveMaintenanceCore est le cœur de la maintenance prédictive qui utilise
// le machine learning pour prédire les pannes, optimiser la maintenance proactive
// et gérer automatiquement les ressources avec une précision >85%.
type PredictiveMaintenanceCore struct {
	config          *PredictiveConfig
	logger          interfaces.Logger
	
	// Composants ML et prédiction
	mlEngine        *MachineLearningEngine
	patternAnalyzer *PatternAnalyzer
	forecastEngine  *ForecastEngine
	scheduler       *ProactiveScheduler
	optimizer       *ResourceOptimizer
	
	// Base de données et historique
	historicalData  *HistoricalDataManager
	predictionCache map[string]*CachedPrediction
	
	// État et synchronisation
	mutex           sync.RWMutex
	initialized     bool
	metrics         *PredictiveMetrics
	
	// Surveillance continue
	monitoringTicker *time.Ticker
	predictionUpdater *time.Ticker
}

// MachineLearningEngine moteur ML pour l'analyse prédictive
type MachineLearningEngine struct {
	config     *MLEngineConfig
	logger     interfaces.Logger
	models     map[string]*PredictionModel
	trainer    *ModelTrainer
	evaluator  *ModelEvaluator
}

// PatternAnalyzer analyseur de patterns de dégradation
type PatternAnalyzer struct {
	config          *AnalyzerConfig
	logger          interfaces.Logger
	patterns        map[string]*DegradationPattern
	anomalyDetector *AnomalyDetector
}

// ForecastEngine moteur de prévision des pannes
type ForecastEngine struct {
	config     *ForecastConfig
	logger     interfaces.Logger
	forecasts  map[string]*MaintenanceForecast
	validator  *ForecastValidator
}

// ProactiveScheduler planificateur de maintenance proactive
type ProactiveScheduler struct {
	config            *SchedulerConfig
	logger            interfaces.Logger
	schedule          *MaintenanceSchedule
	windowOptimizer   *MaintenanceWindowOptimizer
	resourceAllocator *ResourceAllocator
}

// ResourceOptimizer optimiseur de ressources automatique
type ResourceOptimizer struct {
	config         *OptimizerConfig
	logger         interfaces.Logger
	allocations    map[string]*ResourceAllocation
	optimizer      *OptimizationEngine
	costCalculator *CostCalculator
}

// HistoricalDataManager gestionnaire des données historiques
type HistoricalDataManager struct {
	config      *DataManagerConfig
	logger      interfaces.Logger
	storage     *DataStorage
	aggregator  *DataAggregator
	cleaner     *DataCleaner
}

// PredictiveMetrics métriques du système prédictif
type PredictiveMetrics struct {
	TotalPredictions     int64
	AccuratePredictions  int64
	AverageAccuracy      float64
	PredictionTime       time.Duration
	FalsePositives       int64
	FalseNegatives       int64
	ResourceSavings      float64
	PreventedFailures    int64
	mutex                sync.RWMutex
}

// NewPredictiveMaintenanceCore crée une nouvelle instance du cœur prédictif
func NewPredictiveMaintenanceCore(config *PredictiveConfig, logger interfaces.Logger) (*PredictiveMaintenanceCore, error) {
	if config == nil {
		return nil, fmt.Errorf("predictive config is required")
	}
	
	if logger == nil {
		return nil, fmt.Errorf("logger is required")
	}

	// Valider la configuration
	if err := validatePredictiveConfig(config); err != nil {
		return nil, fmt.Errorf("invalid predictive config: %w", err)
	}

	core := &PredictiveMaintenanceCore{
		config:          config,
		logger:          logger,
		predictionCache: make(map[string]*CachedPrediction),
		metrics:         NewPredictiveMetrics(),
	}

	// Initialiser les composants
	if err := core.initializeComponents(); err != nil {
		return nil, fmt.Errorf("failed to initialize predictive components: %w", err)
	}

	return core, nil
}

// Initialize initialise le système de maintenance prédictive
func (pmc *PredictiveMaintenanceCore) Initialize(ctx context.Context) error {
	pmc.mutex.Lock()
	defer pmc.mutex.Unlock()

	if pmc.initialized {
		return fmt.Errorf("predictive maintenance core already initialized")
	}

	pmc.logger.Info("Initializing Predictive Maintenance Core")

	// Initialiser les composants dans l'ordre
	components := []struct {
		name string
		init func(context.Context) error
	}{
		{"HistoricalDataManager", pmc.historicalData.Initialize},
		{"MachineLearningEngine", pmc.mlEngine.Initialize},
		{"PatternAnalyzer", pmc.patternAnalyzer.Initialize},
		{"ForecastEngine", pmc.forecastEngine.Initialize},
		{"ProactiveScheduler", pmc.scheduler.Initialize},
		{"ResourceOptimizer", pmc.optimizer.Initialize},
	}

	for _, component := range components {
		if err := component.init(ctx); err != nil {
			return fmt.Errorf("failed to initialize %s: %w", component.name, err)
		}
	}

	// Démarrer la surveillance continue
	pmc.startContinuousMonitoring()

	// Démarrer la mise à jour des prédictions
	pmc.startPredictionUpdates()

	pmc.initialized = true
	pmc.logger.Info("Predictive Maintenance Core initialized successfully")

	return nil
}

// HealthCheck vérifie la santé du système prédictif
func (pmc *PredictiveMaintenanceCore) HealthCheck(ctx context.Context) error {
	pmc.mutex.RLock()
	defer pmc.mutex.RUnlock()

	if !pmc.initialized {
		return fmt.Errorf("predictive maintenance core not initialized")
	}

	// Vérifier tous les composants
	checks := []struct {
		name string
		check func(context.Context) error
	}{
		{"MachineLearningEngine", pmc.mlEngine.HealthCheck},
		{"PatternAnalyzer", pmc.patternAnalyzer.HealthCheck},
		{"ForecastEngine", pmc.forecastEngine.HealthCheck},
		{"ProactiveScheduler", pmc.scheduler.HealthCheck},
		{"ResourceOptimizer", pmc.optimizer.HealthCheck},
		{"HistoricalDataManager", pmc.historicalData.HealthCheck},
	}

	for _, check := range checks {
		if err := check.check(ctx); err != nil {
			return fmt.Errorf("%s health check failed: %w", check.name, err)
		}
	}

	// Vérifier la précision des prédictions
	pmc.metrics.mutex.RLock()
	accuracy := pmc.metrics.AverageAccuracy
	pmc.metrics.mutex.RUnlock()

	if accuracy < pmc.config.AccuracyThreshold {
		return fmt.Errorf("prediction accuracy below threshold: %.2f < %.2f", 
			accuracy, pmc.config.AccuracyThreshold)
	}

	return nil
}

// Cleanup nettoie les ressources du système prédictif
func (pmc *PredictiveMaintenanceCore) Cleanup() error {
	pmc.mutex.Lock()
	defer pmc.mutex.Unlock()

	pmc.logger.Info("Cleaning up Predictive Maintenance Core")

	// Arrêter les tickers
	if pmc.monitoringTicker != nil {
		pmc.monitoringTicker.Stop()
	}
	if pmc.predictionUpdater != nil {
		pmc.predictionUpdater.Stop()
	}

	// Nettoyer tous les composants
	var errors []error

	components := []struct {
		name string
		cleanup func() error
	}{
		{"ResourceOptimizer", pmc.optimizer.Cleanup},
		{"ProactiveScheduler", pmc.scheduler.Cleanup},
		{"ForecastEngine", pmc.forecastEngine.Cleanup},
		{"PatternAnalyzer", pmc.patternAnalyzer.Cleanup},
		{"MachineLearningEngine", pmc.mlEngine.Cleanup},
		{"HistoricalDataManager", pmc.historicalData.Cleanup},
	}

	for _, component := range components {
		if err := component.cleanup(); err != nil {
			errors = append(errors, fmt.Errorf("%s cleanup failed: %w", component.name, err))
		}
	}

	// Vider les caches
	pmc.predictionCache = make(map[string]*CachedPrediction)

	pmc.initialized = false

	if len(errors) > 0 {
		return fmt.Errorf("cleanup completed with errors: %v", errors)
	}

	pmc.logger.Info("Predictive Maintenance Core cleanup completed successfully")
	return nil
}

// GenerateMaintenanceForecast génère une prévision de maintenance ML
func (pmc *PredictiveMaintenanceCore) GenerateMaintenanceForecast(ctx context.Context, timeHorizon time.Duration) (*interfaces.MaintenanceForecast, error) {
	startTime := time.Now()
	defer func() {
		pmc.updateMetrics(time.Since(startTime))
	}()

	pmc.logger.Info(fmt.Sprintf("Generating maintenance forecast for horizon: %v", timeHorizon))

	// 1. Vérifier le cache pour des prévisions similaires
	if pmc.config.CacheEnabled {
		if cachedForecast := pmc.checkForecastCache(timeHorizon); cachedForecast != nil {
			pmc.logger.Debug("Using cached forecast for similar time horizon")
			return cachedForecast, nil
		}
	}

	// 2. Collecter les données historiques
	historicalData, err := pmc.historicalData.GetRelevantData(ctx, timeHorizon)
	if err != nil {
		return nil, fmt.Errorf("failed to collect historical data: %w", err)
	}

	// 3. Analyser les patterns de dégradation
	patterns, err := pmc.patternAnalyzer.AnalyzeDegradationPatterns(ctx, historicalData)
	if err != nil {
		return nil, fmt.Errorf("pattern analysis failed: %w", err)
	}

	// 4. Générer des prédictions ML
	mlPredictions, err := pmc.mlEngine.GeneratePredictions(ctx, historicalData, patterns, timeHorizon)
	if err != nil {
		return nil, fmt.Errorf("ML predictions failed: %w", err)
	}

	// 5. Créer la prévision structurée
	forecast, err := pmc.forecastEngine.CreateForecast(ctx, mlPredictions, timeHorizon)
	if err != nil {
		return nil, fmt.Errorf("forecast creation failed: %w", err)
	}

	// 6. Optimiser les fenêtres de maintenance
	if pmc.config.ProactiveScheduling {
		optimizedWindows, err := pmc.scheduler.OptimizeMaintenanceWindows(ctx, forecast)
		if err != nil {
			pmc.logger.WithError(err).Warn("Failed to optimize maintenance windows")
		} else {
			forecast.MaintenanceWindows = optimizedWindows
		}
	}

	// 7. Calculer les exigences de ressources
	if pmc.config.ResourceOptimization {
		resourceReqs, err := pmc.optimizer.CalculateResourceRequirements(ctx, forecast)
		if err != nil {
			pmc.logger.WithError(err).Warn("Failed to calculate resource requirements")
		} else {
			forecast.ResourceRequirements = resourceReqs
		}
	}

	// 8. Valider la prévision
	validationResult, err := pmc.forecastEngine.ValidateForecast(ctx, forecast)
	if err != nil {
		return nil, fmt.Errorf("forecast validation failed: %w", err)
	}

	forecast.Confidence = validationResult.Confidence
	forecast.AlgorithmDetails = validationResult.AlgorithmDetails

	// 9. Mettre en cache la prévision
	if pmc.config.CacheEnabled {
		pmc.cacheForecast(timeHorizon, forecast)
	}

	// 10. Enregistrer les métriques
	pmc.recordPredictionGeneration(forecast, time.Since(startTime))

	pmc.logger.Info(fmt.Sprintf("Generated maintenance forecast with %d predicted issues in %v", 
		len(forecast.PredictedIssues), time.Since(startTime)))

	return forecast, nil
}

// PredictFailures prédit les pannes avec ML
func (pmc *PredictiveMaintenanceCore) PredictFailures(ctx context.Context, components []string, timeHorizon time.Duration) ([]*interfaces.PredictedIssue, error) {
	pmc.logger.Info(fmt.Sprintf("Predicting failures for %d components", len(components)))

	// Collecter les données de santé actuelles des composants
	componentHealth, err := pmc.collectComponentHealth(ctx, components)
	if err != nil {
		return nil, fmt.Errorf("failed to collect component health: %w", err)
	}

	// Analyser les patterns de dégradation pour chaque composant
	predictions := make([]*interfaces.PredictedIssue, 0)

	for _, component := range components {
		if health, exists := componentHealth[component]; exists {
			prediction, err := pmc.mlEngine.PredictComponentFailure(ctx, component, health, timeHorizon)
			if err != nil {
				pmc.logger.WithError(err).Warn(fmt.Sprintf("Failed to predict failure for component %s", component))
				continue
			}

			if prediction != nil && prediction.Confidence >= pmc.config.AccuracyThreshold {
				predictions = append(predictions, prediction)
			}
		}
	}

	return predictions, nil
}

// ScheduleProactiveMaintenance planifie une maintenance proactive
func (pmc *PredictiveMaintenanceCore) ScheduleProactiveMaintenance(ctx context.Context, forecast *interfaces.MaintenanceForecast) (*MaintenanceSchedule, error) {
	if !pmc.config.ProactiveScheduling {
		return nil, fmt.Errorf("proactive scheduling is disabled")
	}

	pmc.logger.Info("Scheduling proactive maintenance based on forecast")

	// Utiliser le planificateur pour créer un calendrier optimal
	schedule, err := pmc.scheduler.CreateOptimalSchedule(ctx, forecast)
	if err != nil {
		return nil, fmt.Errorf("failed to create maintenance schedule: %w", err)
	}

	// Optimiser l'allocation des ressources
	if pmc.config.ResourceOptimization {
		optimizedAllocation, err := pmc.optimizer.OptimizeResourceAllocation(ctx, schedule)
		if err != nil {
			pmc.logger.WithError(err).Warn("Failed to optimize resource allocation")
		} else {
			schedule.ResourceAllocation = optimizedAllocation
		}
	}

	return schedule, nil
}

// OptimizeResources optimise automatiquement l'allocation des ressources
func (pmc *PredictiveMaintenanceCore) OptimizeResources(ctx context.Context, currentAllocation *ResourceAllocation) (*ResourceOptimizationResult, error) {
	if !pmc.config.ResourceOptimization {
		return nil, fmt.Errorf("resource optimization is disabled")
	}

	return pmc.optimizer.OptimizeAllocation(ctx, currentAllocation)
}

// Méthodes internes

func (pmc *PredictiveMaintenanceCore) initializeComponents() error {
	// Initialiser le gestionnaire de données historiques
	historicalData, err := NewHistoricalDataManager(&DataManagerConfig{}, pmc.logger)
	if err != nil {
		return fmt.Errorf("failed to create historical data manager: %w", err)
	}
	pmc.historicalData = historicalData

	// Initialiser le moteur ML
	mlEngine, err := NewMachineLearningEngine(&MLEngineConfig{}, pmc.logger)
	if err != nil {
		return fmt.Errorf("failed to create ML engine: %w", err)
	}
	pmc.mlEngine = mlEngine

	// Initialiser l'analyseur de patterns
	patternAnalyzer, err := NewPatternAnalyzer(&AnalyzerConfig{}, pmc.logger)
	if err != nil {
		return fmt.Errorf("failed to create pattern analyzer: %w", err)
	}
	pmc.patternAnalyzer = patternAnalyzer

	// Initialiser le moteur de prévision
	forecastEngine, err := NewForecastEngine(&ForecastConfig{}, pmc.logger)
	if err != nil {
		return fmt.Errorf("failed to create forecast engine: %w", err)
	}
	pmc.forecastEngine = forecastEngine

	// Initialiser le planificateur proactif
	scheduler, err := NewProactiveScheduler(&SchedulerConfig{}, pmc.logger)
	if err != nil {
		return fmt.Errorf("failed to create proactive scheduler: %w", err)
	}
	pmc.scheduler = scheduler

	// Initialiser l'optimiseur de ressources
	optimizer, err := NewResourceOptimizer(&OptimizerConfig{}, pmc.logger)
	if err != nil {
		return fmt.Errorf("failed to create resource optimizer: %w", err)
	}
	pmc.optimizer = optimizer

	return nil
}

func (pmc *PredictiveMaintenanceCore) startContinuousMonitoring() {
	pmc.monitoringTicker = time.NewTicker(pmc.config.DataSamplingRate)
	
	go func() {
		for range pmc.monitoringTicker.C {
			if err := pmc.collectAndAnalyzeData(); err != nil {
				pmc.logger.WithError(err).Error("Failed to collect and analyze data")
			}
		}
	}()
}

func (pmc *PredictiveMaintenanceCore) startPredictionUpdates() {
	pmc.predictionUpdater = time.NewTicker(pmc.config.UpdateFrequency)
	
	go func() {
		for range pmc.predictionUpdater.C {
			if err := pmc.updatePredictions(); err != nil {
				pmc.logger.WithError(err).Error("Failed to update predictions")
			}
		}
	}()
}

func (pmc *PredictiveMaintenanceCore) collectAndAnalyzeData() error {
	// Collecter les nouvelles données
	newData, err := pmc.historicalData.CollectCurrentData()
	if err != nil {
		return fmt.Errorf("failed to collect current data: %w", err)
	}

	// Analyser les nouveaux patterns
	patterns, err := pmc.patternAnalyzer.AnalyzeNewPatterns(newData)
	if err != nil {
		return fmt.Errorf("failed to analyze new patterns: %w", err)
	}

	// Détecter les anomalies
	anomalies, err := pmc.patternAnalyzer.DetectAnomalies(newData)
	if err != nil {
		return fmt.Errorf("failed to detect anomalies: %w", err)
	}

	// Mettre à jour les modèles ML si nécessaire
	if len(anomalies) > 0 || pmc.shouldUpdateModels(patterns) {
		if err := pmc.mlEngine.UpdateModels(newData, patterns); err != nil {
			pmc.logger.WithError(err).Warn("Failed to update ML models")
		}
	}

	return nil
}

func (pmc *PredictiveMaintenanceCore) updatePredictions() error {
	// Mettre à jour toutes les prédictions actives
	ctx := context.Background()
	
	// Supprimer les prédictions expirées du cache
	pmc.cleanExpiredPredictions()

	// Régénérer les prédictions critiques
	criticalForecasts, err := pmc.forecastEngine.GetCriticalForecasts(ctx)
	if err != nil {
		return fmt.Errorf("failed to get critical forecasts: %w", err)
	}

	for _, forecast := range criticalForecasts {
		updatedForecast, err := pmc.GenerateMaintenanceForecast(ctx, forecast.TimeHorizon)
		if err != nil {
			pmc.logger.WithError(err).Warn(fmt.Sprintf("Failed to update forecast for horizon %v", forecast.TimeHorizon))
			continue
		}

		// Comparer avec l'ancienne prédiction pour détecter les changements significatifs
		if pmc.hasSignificantChange(forecast, updatedForecast) {
			pmc.logger.Info(fmt.Sprintf("Significant change detected in forecast for horizon %v", forecast.TimeHorizon))
			// Ici, on pourrait déclencher des alertes ou des actions automatiques
		}
	}

	return nil
}

func (pmc *PredictiveMaintenanceCore) updateMetrics(duration time.Duration) {
	pmc.metrics.mutex.Lock()
	defer pmc.metrics.mutex.Unlock()

	pmc.metrics.TotalPredictions++
	
	// Calculer la moyenne mobile du temps de prédiction
	alpha := 0.1
	if pmc.metrics.PredictionTime == 0 {
		pmc.metrics.PredictionTime = duration
	} else {
		pmc.metrics.PredictionTime = time.Duration(
			float64(pmc.metrics.PredictionTime)*(1-alpha) + float64(duration)*alpha,
		)
	}
}

func (pmc *PredictiveMaintenanceCore) checkForecastCache(timeHorizon time.Duration) *interfaces.MaintenanceForecast {
	pmc.mutex.RLock()
	defer pmc.mutex.RUnlock()

	cacheKey := fmt.Sprintf("horizon-%v", timeHorizon)
	
	if cached, exists := pmc.predictionCache[cacheKey]; exists {
		if time.Now().Before(cached.ValidUntil) {
			cached.AccessCount++
			return cached.Prediction
		} else {
			delete(pmc.predictionCache, cacheKey)
		}
	}

	return nil
}

func (pmc *PredictiveMaintenanceCore) cacheForecast(timeHorizon time.Duration, forecast *interfaces.MaintenanceForecast) {
	pmc.mutex.Lock()
	defer pmc.mutex.Unlock()

	cacheKey := fmt.Sprintf("horizon-%v", timeHorizon)
	
	pmc.predictionCache[cacheKey] = &CachedPrediction{
		Prediction:  forecast,
		Context:     cacheKey,
		CreatedAt:   time.Now(),
		AccessCount: 0,
		Accuracy:    forecast.Confidence,
		ValidUntil:  time.Now().Add(pmc.config.CacheExpirationTime),
	}
}

func (pmc *PredictiveMaintenanceCore) recordPredictionGeneration(forecast *interfaces.MaintenanceForecast, duration time.Duration) {
	// Enregistrer les métriques de génération de prédiction
	pmc.updateMetrics(duration)

	// Mettre à jour les statistiques de précision si nous avons des données historiques
	if historical := pmc.historicalData.GetHistoricalAccuracy(forecast.TimeHorizon); historical > 0 {
		pmc.metrics.mutex.Lock()
		pmc.metrics.AverageAccuracy = (pmc.metrics.AverageAccuracy + historical) / 2.0
		pmc.metrics.mutex.Unlock()
	}
}

func (pmc *PredictiveMaintenanceCore) collectComponentHealth(ctx context.Context, components []string) (map[string]*ComponentHealth, error) {
	health := make(map[string]*ComponentHealth)

	for _, component := range components {
		componentHealth, err := pmc.historicalData.GetComponentHealth(ctx, component)
		if err != nil {
			pmc.logger.WithError(err).Warn(fmt.Sprintf("Failed to get health for component %s", component))
			continue
		}
		health[component] = componentHealth
	}

	return health, nil
}

func (pmc *PredictiveMaintenanceCore) shouldUpdateModels(patterns []*DegradationPattern) bool {
	// Logique pour déterminer si les modèles ML doivent être mis à jour
	for _, pattern := range patterns {
		if pattern.Confidence < 0.8 || pattern.IsNovel {
			return true
		}
	}
	return false
}

func (pmc *PredictiveMaintenanceCore) cleanExpiredPredictions() {
	pmc.mutex.Lock()
	defer pmc.mutex.Unlock()

	now := time.Now()
	for key, cached := range pmc.predictionCache {
		if now.After(cached.ValidUntil) {
			delete(pmc.predictionCache, key)
		}
	}
}

func (pmc *PredictiveMaintenanceCore) hasSignificantChange(old, new *interfaces.MaintenanceForecast) bool {
	// Comparer les prévisions pour détecter des changements significatifs
	confidenceDiff := math.Abs(old.Confidence - new.Confidence)
	issueCountDiff := math.Abs(float64(len(old.PredictedIssues) - len(new.PredictedIssues)))
	
	return confidenceDiff > 0.1 || issueCountDiff > 2.0
}

func validatePredictiveConfig(config *PredictiveConfig) error {
	if config.PredictionHorizon < time.Hour || config.PredictionHorizon > 30*24*time.Hour {
		return fmt.Errorf("prediction horizon must be between 1 hour and 30 days")
	}

	if config.AccuracyThreshold < 0.5 || config.AccuracyThreshold > 1.0 {
		return fmt.Errorf("accuracy threshold must be between 0.5 and 1.0")
	}

	if config.AnalysisDepth < 1 || config.AnalysisDepth > 10 {
		return fmt.Errorf("analysis depth must be between 1 and 10")
	}

	return nil
}

// NewPredictiveMetrics crée de nouvelles métriques prédictives
func NewPredictiveMetrics() *PredictiveMetrics {
	return &PredictiveMetrics{
		TotalPredictions:    0,
		AccuratePredictions: 0,
		AverageAccuracy:     0.0,
		PredictionTime:      0,
		FalsePositives:      0,
		FalseNegatives:      0,
		ResourceSavings:     0.0,
		PreventedFailures:   0,
	}
}

// Structures de support

type ComponentHealth struct {
	Name              string
	Status            string
	HealthScore       float64
	LastMaintenance   time.Time
	OperatingHours    float64
	ErrorRate         float64
	PerformanceMetrics map[string]float64
	DegradationRate   float64
}

type DegradationPattern struct {
	Type        string
	Component   string
	Pattern     []float64
	Confidence  float64
	IsNovel     bool
	Severity    int
	TimeFrame   time.Duration
}

type MaintenanceForecast struct {
	GeneratedAt          time.Time
	TimeHorizon          time.Duration
	PredictedIssues      []*interfaces.PredictedIssue
	MaintenanceWindows   []*interfaces.MaintenanceWindow
	ResourceRequirements *interfaces.ResourceRequirements
	Confidence           float64
	DataSources          []string
	AlgorithmDetails     map[string]interface{}
}

type MaintenanceSchedule struct {
	ScheduleID         string
	GeneratedAt        time.Time
	TimeFrame          *interfaces.TimeFrame
	MaintenanceTasks   []*MaintenanceTask
	ResourceAllocation *ResourceAllocation
	TotalCost          float64
	ExpectedDowntime   time.Duration
}

type MaintenanceTask struct {
	TaskID            string
	Type              string
	Component         string
	Priority          int
	EstimatedDuration time.Duration
	RequiredResources *interfaces.ResourceRequirements
	Dependencies      []string
	ScheduledWindow   *interfaces.MaintenanceWindow
}

type ResourceAllocation struct {
	AllocationID      string
	Resources         map[string]*AllocatedResource
	TotalCost         float64
	EfficiencyScore   float64
	OptimizationLevel int
}

type AllocatedResource struct {
	Type      string
	Quantity  int
	Duration  time.Duration
	Cost      float64
	Priority  int
}

type ResourceOptimizationResult struct {
	OptimizedAllocation *ResourceAllocation
	Savings             float64
	EfficiencyGain      float64
	RecommendedChanges  []string
	OptimizationReport  map[string]interface{}
}

// Configurations des composants

type MLEngineConfig struct {
	ModelTypes     []string `yaml:"model_types"`
	TrainingMode   string   `yaml:"training_mode"`
	ValidationSplit float64 `yaml:"validation_split"`
}

type AnalyzerConfig struct {
	WindowSize     time.Duration `yaml:"window_size"`
	Sensitivity    float64       `yaml:"sensitivity"`
	PatternTypes   []string      `yaml:"pattern_types"`
}

type ForecastConfig struct {
	Algorithms       []string `yaml:"algorithms"`
	EnsembleMethod   string   `yaml:"ensemble_method"`
	ConfidenceMode   string   `yaml:"confidence_mode"`
}

type SchedulerConfig struct {
	OptimizationGoal string  `yaml:"optimization_goal"`
	WindowConstraints map[string]interface{} `yaml:"window_constraints"`
	PreferredTimes   []string `yaml:"preferred_times"`
}

type OptimizerConfig struct {
	Algorithm        string  `yaml:"algorithm"`
	CostModel        string  `yaml:"cost_model"`
	EfficiencyWeight float64 `yaml:"efficiency_weight"`
}

type DataManagerConfig struct {
	StorageType    string        `yaml:"storage_type"`
	RetentionTime  time.Duration `yaml:"retention_time"`
	CompressionEnabled bool      `yaml:"compression_enabled"`
}
