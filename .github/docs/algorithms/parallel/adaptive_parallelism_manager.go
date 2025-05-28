// File: .github/docs/algorithms/parallel/adaptive_parallelism_manager.go
// EMAIL_SENDER_1 Adaptive Parallelism Manager
// Module de gestion adaptative du parallélisme et de contrôle de charge

package parallel

import (
	"context"
	"fmt"
	"log"
	"math"
	"runtime"
	"sync"
	"sync/atomic"
	"time"
)

// ParallelismMode définit le mode de parallélisation
type ParallelismMode string

const (
	// Conservative mode - utilisation minimale des ressources
	Conservative ParallelismMode = "conservative"
	// Balanced mode - équilibre entre performance et utilisation des ressources
	Balanced ParallelismMode = "balanced"
	// Aggressive mode - utilisation maximale des ressources pour la performance
	Aggressive ParallelismMode = "aggressive"
	// Adaptive mode - s'adapte automatiquement en fonction de la charge
	Adaptive ParallelismMode = "adaptive"
)

// SystemMetrics contient les métriques système utilisées pour l'adaptation
type SystemMetrics struct {
	CPUUsage         float64   // Utilisation CPU (0-1)
	MemoryUsage      float64   // Utilisation mémoire (0-1)
	LoadAverage      float64   // Charge système moyenne
	NetworkBandwidth float64   // Bande passante réseau utilisée (Mo/s)
	DiskIORate       float64   // Taux d'E/S disque (Mo/s)
	QueueLength      int       // Longueur de la file d'attente
	ResponseTime     float64   // Temps de réponse moyen (ms)
	Throughput       float64   // Débit de traitement (tâches/sec)
	ErrorRate        float64   // Taux d'erreur (0-1)
	CollectionTime   time.Time // Heure de collecte des métriques
}

// AdaptiveParallelismConfig définit la configuration du gestionnaire de parallélisme adaptatif
type AdaptiveParallelismConfig struct {
	InitialWorkers      int             // Nombre initial de workers
	MinWorkers          int             // Nombre minimum de workers
	MaxWorkers          int             // Nombre maximum de workers
	ScaleFactor         float64         // Facteur d'échelle pour l'adaptation (1.0 = 100%)
	ScaleUpThreshold    float64         // Seuil d'utilisation pour augmenter (0-1)
	ScaleDownThreshold  float64         // Seuil d'utilisation pour diminuer (0-1)
	CooldownPeriod      time.Duration   // Période d'attente entre deux ajustements
	Mode                ParallelismMode // Mode de parallélisme
	AdaptiveInterval    time.Duration   // Intervalle entre les adaptations automatiques
	EnableAutoTuning    bool            // Activer l'auto-tuning
	TargetResponseTime  float64         // Temps de réponse cible (ms)
	TargetThroughput    float64         // Débit cible (tâches/sec)
	MaxQueueLength      int             // Longueur maximale de la file d'attente
	BackpressureEnabled bool            // Activer le mécanisme de contre-pression
}

// DefaultAdaptiveParallelismConfig retourne une configuration par défaut
func DefaultAdaptiveParallelismConfig() AdaptiveParallelismConfig {
	numCPU := runtime.NumCPU()
	return AdaptiveParallelismConfig{
		InitialWorkers:      numCPU,
		MinWorkers:          1,
		MaxWorkers:          numCPU * 4,
		ScaleFactor:         1.5,
		ScaleUpThreshold:    0.7,
		ScaleDownThreshold:  0.3,
		CooldownPeriod:      30 * time.Second,
		Mode:                Balanced,
		AdaptiveInterval:    10 * time.Second,
		EnableAutoTuning:    true,
		TargetResponseTime:  200, // ms
		TargetThroughput:    100, // tâches/sec
		MaxQueueLength:      1000,
		BackpressureEnabled: true,
	}
}

// AdaptiveParallelismManager gère l'adaptation dynamique du parallélisme
type AdaptiveParallelismManager struct {
	config        AdaptiveParallelismConfig
	currentWorkers int32
	metrics       []SystemMetrics
	lastScaleTime time.Time
	workerPools   []*WorkerPool
	mu            sync.RWMutex
	ctx           context.Context
	cancel        context.CancelFunc
}

// NewAdaptiveParallelismManager crée un nouveau gestionnaire de parallélisme adaptatif
func NewAdaptiveParallelismManager(config AdaptiveParallelismConfig) *AdaptiveParallelismManager {
	// Valider la configuration
	if config.MinWorkers < 1 {
		config.MinWorkers = 1
	}
	if config.MaxWorkers < config.MinWorkers {
		config.MaxWorkers = config.MinWorkers
	}
	if config.InitialWorkers < config.MinWorkers {
		config.InitialWorkers = config.MinWorkers
	} else if config.InitialWorkers > config.MaxWorkers {
		config.InitialWorkers = config.MaxWorkers
	}
	
	ctx, cancel := context.WithCancel(context.Background())
	
	manager := &AdaptiveParallelismManager{
		config:        config,
		currentWorkers: int32(config.InitialWorkers),
		metrics:       make([]SystemMetrics, 0, 100),
		lastScaleTime: time.Now(),
		workerPools:   make([]*WorkerPool, 0),
		ctx:           ctx,
		cancel:        cancel,
	}
	
	return manager
}

// Start démarre le gestionnaire de parallélisme adaptatif
func (apm *AdaptiveParallelismManager) Start() {
	log.Printf("Démarrage du gestionnaire de parallélisme adaptatif (mode: %s, workers: %d)", 
		apm.config.Mode, apm.config.InitialWorkers)
	
	// Si le mode adaptatif est activé, démarrer le moniteur d'adaptation
	if apm.config.Mode == Adaptive && apm.config.EnableAutoTuning {
		go apm.adaptiveMonitor()
	}
}

// Stop arrête le gestionnaire de parallélisme adaptatif
func (apm *AdaptiveParallelismManager) Stop() {
	log.Printf("Arrêt du gestionnaire de parallélisme adaptatif")
	apm.cancel()
}

// RegisterWorkerPool enregistre un worker pool pour la gestion adaptative
func (apm *AdaptiveParallelismManager) RegisterWorkerPool(wp *WorkerPool) {
	apm.mu.Lock()
	defer apm.mu.Unlock()
	
	apm.workerPools = append(apm.workerPools, wp)
}

// SetMode change le mode de parallélisme
func (apm *AdaptiveParallelismManager) SetMode(mode ParallelismMode) {
	log.Printf("Changement du mode de parallélisme: %s -> %s", apm.config.Mode, mode)
	
	apm.mu.Lock()
	oldMode := apm.config.Mode
	apm.config.Mode = mode
	apm.mu.Unlock()
	
	// Ajuster immédiatement les ressources si le mode a changé
	if oldMode != mode {
		apm.adjustResourcesForMode()
	}
}

// adjustResourcesForMode ajuste les ressources en fonction du mode de parallélisme
func (apm *AdaptiveParallelismManager) adjustResourcesForMode() {
	apm.mu.RLock()
	mode := apm.config.Mode
	apm.mu.RUnlock()
	
	var targetWorkers int
	numCPU := runtime.NumCPU()
	
	// Calculer le nombre cible de workers en fonction du mode
	switch mode {
	case Conservative:
		targetWorkers = int(math.Max(float64(numCPU)/2, float64(apm.config.MinWorkers)))
	case Balanced:
		targetWorkers = numCPU
	case Aggressive:
		targetWorkers = int(math.Min(float64(numCPU*2), float64(apm.config.MaxWorkers)))
	case Adaptive:
		// En mode adaptatif, on ne fait rien ici car c'est géré par le moniteur
		return
	}
	
	// Mettre à jour le nombre de workers
	apm.SetWorkers(targetWorkers)
}

// UpdateMetrics met à jour les métriques du système
func (apm *AdaptiveParallelismManager) UpdateMetrics(metrics SystemMetrics) {
	apm.mu.Lock()
	defer apm.mu.Unlock()
	
	// Ajouter les nouvelles métriques
	metrics.CollectionTime = time.Now()
	apm.metrics = append(apm.metrics, metrics)
	
	// Limiter la taille de l'historique
	if len(apm.metrics) > 100 {
		apm.metrics = apm.metrics[len(apm.metrics)-100:]
	}
}

// SetWorkers définit le nombre de workers pour tous les worker pools enregistrés
func (apm *AdaptiveParallelismManager) SetWorkers(workers int) {
	apm.mu.RLock()
	minWorkers := apm.config.MinWorkers
	maxWorkers := apm.config.MaxWorkers
	workerPools := apm.workerPools
	apm.mu.RUnlock()
	
	// Valider les bornes
	if workers < minWorkers {
		workers = minWorkers
	} else if workers > maxWorkers {
		workers = maxWorkers
	}
	
	// Si le nombre de workers est déjà celui demandé, ne rien faire
	currentWorkers := atomic.LoadInt32(&apm.currentWorkers)
	if int(currentWorkers) == workers {
		return
	}
	
	log.Printf("Ajustement du nombre de workers: %d -> %d", currentWorkers, workers)
	atomic.StoreInt32(&apm.currentWorkers, int32(workers))
	
	// Mettre à jour le timestamp du dernier ajustement
	apm.mu.Lock()
	apm.lastScaleTime = time.Now()
	apm.mu.Unlock()
	
	// Appliquer le changement sur tous les worker pools
	// Note: Cette implémentation est simplifiée car les worker pools actuels
	// ne supportent pas le redimensionnement dynamique. Il faudrait implémenter
	// cette fonctionnalité dans la classe WorkerPool.
	for _, wp := range workerPools {
		// Exemple d'implémentation qui serait nécessaire:
		// wp.Resize(workers)
		
		// Pour l'instant, on se contente de logguer l'intention
		log.Printf("Worker pool %p serait redimensionné à %d workers", wp, workers)
	}
}

// adaptiveMonitor est la goroutine qui surveille et ajuste automatiquement le parallélisme
func (apm *AdaptiveParallelismManager) adaptiveMonitor() {
	ticker := time.NewTicker(apm.config.AdaptiveInterval)
	defer ticker.Stop()
	
	for {
		select {
		case <-ticker.C:
			apm.adaptWorkers()
		case <-apm.ctx.Done():
			return
		}
	}
}

// adaptWorkers ajuste automatiquement le nombre de workers en fonction des métriques
func (apm *AdaptiveParallelismManager) adaptWorkers() {
	apm.mu.RLock()
	cooldownPeriod := apm.config.CooldownPeriod
	lastScaleTime := apm.lastScaleTime
	metrics := apm.metrics
	scaleUpThreshold := apm.config.ScaleUpThreshold
	scaleDownThreshold := apm.config.ScaleDownThreshold
	scaleFactor := apm.config.ScaleFactor
	currentWorkers := atomic.LoadInt32(&apm.currentWorkers)
	minWorkers := apm.config.MinWorkers
	maxWorkers := apm.config.MaxWorkers
	apm.mu.RUnlock()
	
	// Vérifier si on est dans la période de cooldown
	if time.Since(lastScaleTime) < cooldownPeriod {
		return
	}
	
	// S'il n'y a pas assez de métriques, ne rien faire
	if len(metrics) < 3 {
		return
	}
	
	// Calculer les métriques moyennes récentes
	cpuUsage := 0.0
	memoryUsage := 0.0
	queueLength := 0
	responseTime := 0.0
	throughput := 0.0
	
	// Utiliser les 3 dernières métriques pour la moyenne
	for i := len(metrics) - 3; i < len(metrics); i++ {
		cpuUsage += metrics[i].CPUUsage
		memoryUsage += metrics[i].MemoryUsage
		queueLength += metrics[i].QueueLength
		responseTime += metrics[i].ResponseTime
		throughput += metrics[i].Throughput
	}
	
	cpuUsage /= 3
	memoryUsage /= 3
	queueLength /= 3
	responseTime /= 3
	throughput /= 3
	
	// Calculer le score d'utilisation composite (peut être personnalisé selon les besoins)
	// Ici on donne plus de poids au CPU et à la longueur de la file d'attente
	utilizationScore := cpuUsage*0.5 + memoryUsage*0.3 + float64(queueLength)/float64(apm.config.MaxQueueLength)*0.2
	
	var newWorkers int32
	
	// Prendre une décision d'adaptation
	if utilizationScore > scaleUpThreshold && throughput < apm.config.TargetThroughput {
		// Augmenter le nombre de workers
		scaleFactor := math.Min(scaleFactor, 2.0) // Limiter à un doublement
		newWorkers = int32(math.Min(float64(currentWorkers)*scaleFactor, float64(maxWorkers)))
		if newWorkers > currentWorkers {
			apm.SetWorkers(int(newWorkers))
		}
	} else if utilizationScore < scaleDownThreshold && 
		      (responseTime < apm.config.TargetResponseTime || throughput > apm.config.TargetThroughput) {
		// Diminuer le nombre de workers
		newWorkers = int32(math.Max(float64(currentWorkers)/scaleFactor, float64(minWorkers)))
		if newWorkers < currentWorkers {
			apm.SetWorkers(int(newWorkers))
		}
	}
	// Sinon, maintenir le nombre actuel de workers
}

// ApplyBackpressure applique une contre-pression si nécessaire
func (apm *AdaptiveParallelismManager) ApplyBackpressure(queueLength int) bool {
	if !apm.config.BackpressureEnabled {
		return false
	}
	
	// Si la file d'attente dépasse un certain seuil, appliquer une contre-pression
	backpressureThreshold := int(float64(apm.config.MaxQueueLength) * 0.8)
	if queueLength > backpressureThreshold {
		log.Printf("Contre-pression appliquée: file d'attente (%d) > seuil (%d)", 
			queueLength, backpressureThreshold)
		return true
	}
	
	return false
}

// GetStatus retourne l'état actuel du gestionnaire de parallélisme
func (apm *AdaptiveParallelismManager) GetStatus() map[string]interface{} {
	apm.mu.RLock()
	defer apm.mu.RUnlock()
	
	var recentMetrics SystemMetrics
	if len(apm.metrics) > 0 {
		recentMetrics = apm.metrics[len(apm.metrics)-1]
	}
	
	return map[string]interface{}{
		"mode":             string(apm.config.Mode),
		"current_workers":  atomic.LoadInt32(&apm.currentWorkers),
		"min_workers":      apm.config.MinWorkers,
		"max_workers":      apm.config.MaxWorkers,
		"last_scale_time":  apm.lastScaleTime,
		"cpu_usage":        recentMetrics.CPUUsage,
		"memory_usage":     recentMetrics.MemoryUsage,
		"queue_length":     recentMetrics.QueueLength,
		"response_time":    recentMetrics.ResponseTime,
		"throughput":       recentMetrics.Throughput,
		"worker_pools":     len(apm.workerPools),
		"auto_tuning":      apm.config.EnableAutoTuning,
	}
}
