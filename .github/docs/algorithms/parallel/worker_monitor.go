// File: .github/docs/algorithms/parallel/worker_monitor.go
// EMAIL_SENDER_1 Worker Monitor
// Module de surveillance des workers et collecte de métriques système

package parallel

import (
	"context"
	"fmt"
	"log"
	"runtime"
	"sync"
	"time"
)

// WorkerMonitorConfig définit la configuration du moniteur de workers
type WorkerMonitorConfig struct {
	MonitorInterval    time.Duration // Intervalle entre les collectes de métriques
	EnableMemoryStats  bool          // Activer les statistiques de mémoire
	EnableGCStats      bool          // Activer les statistiques du garbage collector
	EnableSystemStats  bool          // Activer les statistiques système (CPU, etc.)
	MaxHistorySize     int           // Taille maximum de l'historique
	EnableAlerts       bool          // Activer les alertes
	CriticalCPUUsage   float64       // Seuil d'alerte pour utilisation CPU
	CriticalMemoryUsage float64      // Seuil d'alerte pour utilisation mémoire
	LogMetrics         bool          // Logger les métriques à chaque intervalle
}

// DefaultWorkerMonitorConfig retourne une configuration par défaut
func DefaultWorkerMonitorConfig() WorkerMonitorConfig {
	return WorkerMonitorConfig{
		MonitorInterval:    5 * time.Second,
		EnableMemoryStats:  true,
		EnableGCStats:      true,
		EnableSystemStats:  true,
		MaxHistorySize:     100,
		EnableAlerts:       true,
		CriticalCPUUsage:   0.9,
		CriticalMemoryUsage: 0.85,
		LogMetrics:         true,
	}
}

// WorkerMetrics contient les métriques d'un point dans le temps
type WorkerMetrics struct {
	Timestamp          time.Time
	Workers            int
	ActiveJobs         int
	QueuedJobs         int
	CompletedJobs      int
	FailedJobs         int
	AverageJobDuration time.Duration
	CPUUsage           float64
	MemoryUsage        uint64
	MemorySystem       uint64
	GCPause            time.Duration
	GCCycles           uint32
	SystemLoad         float64
}

// WorkerMonitor surveille et collecte des métriques sur les workers
type WorkerMonitor struct {
	config      WorkerMonitorConfig
	metrics     []WorkerMetrics
	workerPools []*WorkerPool
	mu          sync.RWMutex
	ctx         context.Context
	cancel      context.CancelFunc
	alertChan   chan string
	startTime   time.Time
}

// NewWorkerMonitor crée un nouveau moniteur de workers
func NewWorkerMonitor(config WorkerMonitorConfig) *WorkerMonitor {
	ctx, cancel := context.WithCancel(context.Background())
	
	return &WorkerMonitor{
		config:      config,
		metrics:     make([]WorkerMetrics, 0, config.MaxHistorySize),
		workerPools: make([]*WorkerPool, 0),
		ctx:         ctx,
		cancel:      cancel,
		alertChan:   make(chan string, 100),
		startTime:   time.Now(),
	}
}

// RegisterWorkerPool enregistre un worker pool à surveiller
func (wm *WorkerMonitor) RegisterWorkerPool(pool *WorkerPool) {
	wm.mu.Lock()
	defer wm.mu.Unlock()
	
	wm.workerPools = append(wm.workerPools, pool)
}

// Start démarre la surveillance
func (wm *WorkerMonitor) Start() {
	go wm.monitorLoop()
	
	if wm.config.EnableAlerts {
		go wm.alertProcessor()
	}
	
	log.Printf("Worker Monitor démarré (interval: %v, history: %d)",
		wm.config.MonitorInterval, wm.config.MaxHistorySize)
}

// Stop arrête la surveillance
func (wm *WorkerMonitor) Stop() {
	wm.cancel()
	close(wm.alertChan)
	log.Printf("Worker Monitor arrêté après %v", time.Since(wm.startTime))
}

// GetLatestMetrics retourne les dernières métriques collectées
func (wm *WorkerMonitor) GetLatestMetrics() *WorkerMetrics {
	wm.mu.RLock()
	defer wm.mu.RUnlock()
	
	if len(wm.metrics) == 0 {
		return nil
	}
	
	latest := wm.metrics[len(wm.metrics)-1]
	return &latest
}

// GetMetricsHistory retourne l'historique des métriques
func (wm *WorkerMonitor) GetMetricsHistory() []WorkerMetrics {
	wm.mu.RLock()
	defer wm.mu.RUnlock()
	
	// Faire une copie profonde pour éviter les modifications concurrentes
	history := make([]WorkerMetrics, len(wm.metrics))
	copy(history, wm.metrics)
	
	return history
}

// monitorLoop est la boucle principale de collecte des métriques
func (wm *WorkerMonitor) monitorLoop() {
	ticker := time.NewTicker(wm.config.MonitorInterval)
	defer ticker.Stop()
	
	for {
		select {
		case <-ticker.C:
			wm.collectMetrics()
		case <-wm.ctx.Done():
			return
		}
	}
}

// collectMetrics collecte toutes les métriques actuelles
func (wm *WorkerMonitor) collectMetrics() {
	// Collecter les métriques de base
	metrics := WorkerMetrics{
		Timestamp: time.Now(),
	}
	
	// Collecter les métriques des worker pools
	wm.mu.RLock()
	workerPools := wm.workerPools
	wm.mu.RUnlock()
	
	for _, pool := range workerPools {
		if pool == nil {
			continue
		}
		
		// Collecter les statistiques du worker pool
		stats := pool.GetStats()
		
		metrics.Workers += pool.maxWorkers
		metrics.CompletedJobs += int(stats.JobsProcessed)
		metrics.FailedJobs += int(stats.JobsFailed)
		
		// Estimation du nombre de jobs actifs et dans la queue
		// Ceci est une approximation car ces chiffres peuvent changer rapidement
		queueLen := len(pool.taskQueue)
		metrics.QueuedJobs += queueLen
		
		// L'estimation des jobs actifs est approximative
		// Elle suppose que la différence entre les jobs traités et la somme des jobs réussis/échoués
		// correspond aux jobs actuellement en traitement
		activeJobs := int(stats.JobsProcessed - stats.JobsSucceeded - stats.JobsFailed)
		if activeJobs < 0 {
			activeJobs = 0
		}
		metrics.ActiveJobs += activeJobs
		
		if stats.AverageTime > metrics.AverageJobDuration {
			metrics.AverageJobDuration = stats.AverageTime
		}
	}
	
	// Collecter les métriques mémoire si activé
	if wm.config.EnableMemoryStats {
		var memStats runtime.MemStats
		runtime.ReadMemStats(&memStats)
		
		metrics.MemoryUsage = memStats.Alloc
		metrics.MemorySystem = memStats.Sys
		
		if wm.config.EnableGCStats {
			metrics.GCPause = time.Duration(memStats.PauseTotalNs)
			metrics.GCCycles = memStats.NumGC
		}
		
		// Estimation de l'utilisation mémoire (par rapport à la mémoire système allouée)
		metrics.CPUUsage = float64(memStats.Alloc) / float64(memStats.Sys)
	}
	
	// Collecter les métriques système si activé (simulation)
	if wm.config.EnableSystemStats {
		// Dans une implémentation réelle, on utiliserait des bibliothèques comme 
		// github.com/shirou/gopsutil pour obtenir les véritables métriques système
		
		// Pour cette simulation, on utilise une valeur aléatoire mais réaliste
		metrics.SystemLoad = 0.5 + (float64(metrics.ActiveJobs) / float64(max(1, metrics.Workers))) * 0.3
		if metrics.SystemLoad > 1.0 {
			metrics.SystemLoad = 1.0
		}
	}
	
	// Stocker les métriques
	wm.mu.Lock()
	wm.metrics = append(wm.metrics, metrics)
	
	// Limiter la taille de l'historique
	if len(wm.metrics) > wm.config.MaxHistorySize {
		wm.metrics = wm.metrics[len(wm.metrics)-wm.config.MaxHistorySize:]
	}
	wm.mu.Unlock()
	
	// Logger les métriques si activé
	if wm.config.LogMetrics {
		log.Printf("Métriques Workers: %d workers, %d actifs, %d en attente, %d terminés, %d échoués, CPU: %.1f%%, Mem: %s",
			metrics.Workers,
			metrics.ActiveJobs,
			metrics.QueuedJobs,
			metrics.CompletedJobs,
			metrics.FailedJobs,
			metrics.CPUUsage*100.0,
			formatBytes(metrics.MemoryUsage))
	}
	
	// Vérifier les seuils d'alerte
	wm.checkAlerts(metrics)
}

// checkAlerts vérifie si des seuils d'alerte sont dépassés
func (wm *WorkerMonitor) checkAlerts(metrics WorkerMetrics) {
	if !wm.config.EnableAlerts {
		return
	}
	
	// Vérifier l'utilisation CPU
	if metrics.CPUUsage >= wm.config.CriticalCPUUsage {
		wm.alertChan <- fmt.Sprintf("ALERTE: Utilisation CPU élevée (%.1f%%)", metrics.CPUUsage*100.0)
	}
	
	// Vérifier l'utilisation mémoire
	memUsageRatio := float64(metrics.MemoryUsage) / float64(metrics.MemorySystem)
	if memUsageRatio >= wm.config.CriticalMemoryUsage {
		wm.alertChan <- fmt.Sprintf("ALERTE: Utilisation mémoire élevée (%.1f%% - %s/%s)",
			memUsageRatio*100.0,
			formatBytes(metrics.MemoryUsage),
			formatBytes(metrics.MemorySystem))
	}
	
	// Vérifier la longueur de la file d'attente
	if metrics.QueuedJobs > 0 && metrics.ActiveJobs == 0 {
		wm.alertChan <- fmt.Sprintf("ALERTE: File d'attente non vide (%d) mais aucun job actif", metrics.QueuedJobs)
	}
}

// alertProcessor traite les alertes générées
func (wm *WorkerMonitor) alertProcessor() {
	for {
		select {
		case alert, ok := <-wm.alertChan:
			if !ok {
				return
			}
			log.Printf("⚠️ %s", alert)
		case <-wm.ctx.Done():
			return
		}
	}
}

// formatBytes formate un nombre d'octets en une chaîne lisible
func formatBytes(bytes uint64) string {
	const unit = 1024
	if bytes < unit {
		return fmt.Sprintf("%d B", bytes)
	}
	div, exp := uint64(unit), 0
	for n := bytes / unit; n >= unit; n /= unit {
		div *= unit
		exp++
	}
	return fmt.Sprintf("%.1f %ciB", float64(bytes)/float64(div), "KMGTPE"[exp])
}

// max retourne le maximum de deux entiers
func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}
