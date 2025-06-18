package infrastructure

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/prometheus/client_golang/api"
	v1 "github.com/prometheus/client_golang/api/prometheus/v1"
	"email_sender/internal/monitoring"
)

// InfrastructureOrchestrator définit l'interface pour l'orchestration de l'infrastructure
type InfrastructureOrchestrator interface {
	StartServices(ctx context.Context) error
	StopServices(ctx context.Context) error
	GetServiceStatus(ctx context.Context) (ServiceStatus, error)
	HealthCheck(ctx context.Context) error
	DetectEnvironment() (*EnvironmentInfo, error)
	AutoRecover(ctx context.Context) error
	
	// Nouvelles méthodes Phase 2
	StartAdvancedMonitoring(ctx context.Context) error
	StopAdvancedMonitoring() error
	GetAdvancedHealthStatus(ctx context.Context) (map[string]monitoring.ServiceHealthStatus, error)
	EnableAutoHealing(enabled bool) error
}

// ServiceStatus représente l'état des services
type ServiceStatus struct {
	Qdrant       ServiceState `json:"qdrant"`
	Redis        ServiceState `json:"redis"`
	Prometheus   ServiceState `json:"prometheus"`
	Grafana      ServiceState `json:"grafana"`
	RAGServer    ServiceState `json:"rag_server"`
	Overall      string       `json:"overall"`
	LastChecked  time.Time    `json:"last_checked"`
}

// ServiceState représente l'état d'un service individuel
type ServiceState struct {
	Status      string    `json:"status"`      // running, stopped, error, unknown
	Health      string    `json:"health"`      // healthy, unhealthy, unknown
	LastHealthy time.Time `json:"last_healthy"`
	Errors      []string  `json:"errors,omitempty"`
}

// EnvironmentInfo contient les informations sur l'environnement détecté
type EnvironmentInfo struct {
	Profile           string            `json:"profile"`            // development, staging, production
	DockerComposeFile string            `json:"docker_compose_file"`
	Services          map[string]string `json:"services"`
	Resources         ResourceInfo      `json:"resources"`
	Dependencies      []string          `json:"dependencies"`
}

// ResourceInfo contient les informations sur les ressources système
type ResourceInfo struct {
	CPUCores     int    `json:"cpu_cores"`
	Memory       int64  `json:"memory_mb"`
	DiskSpace    int64  `json:"disk_space_gb"`
	DockerStatus string `json:"docker_status"`
}

// SmartInfrastructureManager implémente InfrastructureOrchestrator
type SmartInfrastructureManager struct {
	prometheusClient v1.API
	dockerComposePath string
	environment      *EnvironmentInfo
	retryAttempts    int
	retryDelay       time.Duration
	healthCheckTimeout time.Duration
	
	// Phase 2: Composants de monitoring avancé
	advancedMonitor     *monitoring.AdvancedInfrastructureMonitor
	autoHealingSystem   *monitoring.NeuralAutoHealingSystem
	autonomyManager     *monitoring.DefaultAdvancedAutonomyManager
	notificationSystem  *monitoring.DefaultNotificationSystem
	monitoringActive    bool
	autoHealingEnabled  bool
	monitoringContext   context.Context
	monitoringCancel    context.CancelFunc
}

// NewSmartInfrastructureManager crée une nouvelle instance du manager
func NewSmartInfrastructureManager() (*SmartInfrastructureManager, error) {
	// Configuration Prometheus
	promClient, err := api.NewClient(api.Config{
		Address: "http://localhost:9090",
	})
	if err != nil {
		log.Printf("Warning: Could not connect to Prometheus: %v", err)
	}

	manager := &SmartInfrastructureManager{
		retryAttempts:      3,
		retryDelay:         10 * time.Second,
		healthCheckTimeout: 30 * time.Second,
		monitoringActive:   false,
		autoHealingEnabled: false,
	}

	if promClient != nil {
		manager.prometheusClient = v1.NewAPI(promClient)
	}

	// Phase 2: Initialisation des composants de monitoring avancé
	manager.initializeAdvancedMonitoring()

	// Détection automatique de l'environnement
	env, err := manager.DetectEnvironment()
	if err != nil {
		return nil, fmt.Errorf("failed to detect environment: %w", err)
	}
	manager.environment = env

	return manager, nil
}

// initializeAdvancedMonitoring initialise les composants de monitoring avancé (Phase 2)
func (sim *SmartInfrastructureManager) initializeAdvancedMonitoring() {
	log.Println("🔧 Initializing advanced monitoring components (Phase 2)...")

	// Initialiser le système de notifications
	logFile := filepath.Join("logs", "smart-infrastructure-notifications.log")
	sim.notificationSystem = monitoring.NewDefaultNotificationSystem(logFile)

	// Initialiser l'AdvancedAutonomyManager
	sim.autonomyManager = monitoring.NewDefaultAdvancedAutonomyManager(sim.notificationSystem)

	// Initialiser le système d'auto-healing
	sim.autoHealingSystem = monitoring.NewNeuralAutoHealingSystem(sim.autonomyManager, sim.notificationSystem)

	// Initialiser le monitor avancé
	sim.advancedMonitor = monitoring.NewAdvancedInfrastructureMonitor()

	log.Println("✅ Advanced monitoring components initialized")
}

// DetectEnvironment détecte automatiquement l'environnement et la configuration
func (sim *SmartInfrastructureManager) DetectEnvironment() (*EnvironmentInfo, error) {
	log.Println("🔍 Detecting environment configuration...")

	// Recherche du fichier docker-compose
	dockerComposeFile, err := sim.findDockerComposeFile()
	if err != nil {
		return nil, fmt.Errorf("docker-compose file not found: %w", err)
	}

	// Détermination du profil d'environnement
	profile := sim.determineProfile()

	// Collecte des informations sur les ressources
	resources, err := sim.collectResourceInfo()
	if err != nil {
		log.Printf("Warning: Could not collect resource info: %v", err)
		resources = ResourceInfo{DockerStatus: "unknown"}
	}

	// Détection des services disponibles
	services, err := sim.detectServices(dockerComposeFile)
	if err != nil {
		log.Printf("Warning: Could not detect services: %v", err)
		services = make(map[string]string)
	}

	// Détection des dépendances
	dependencies := sim.detectDependencies()

	env := &EnvironmentInfo{
		Profile:           profile,
		DockerComposeFile: dockerComposeFile,
		Services:          services,
		Resources:         resources,
		Dependencies:      dependencies,
	}

	sim.dockerComposePath = dockerComposeFile

	log.Printf("✅ Environment detected: Profile=%s, Services=%d, Docker=%s",
		env.Profile, len(env.Services), env.Resources.DockerStatus)

	return env, nil
}

// findDockerComposeFile recherche le fichier docker-compose dans le projet
func (sim *SmartInfrastructureManager) findDockerComposeFile() (string, error) {
	possiblePaths := []string{
		"docker-compose.yml",
		"docker-compose.yaml",
		"compose.yml",
		"compose.yaml",
	}

	// Recherche dans le répertoire courant et parent
	for _, path := range possiblePaths {
		if _, err := os.Stat(path); err == nil {
			abs, _ := filepath.Abs(path)
			return abs, nil
		}
		
		parentPath := filepath.Join("..", path)
		if _, err := os.Stat(parentPath); err == nil {
			abs, _ := filepath.Abs(parentPath)
			return abs, nil
		}
	}

	return "", fmt.Errorf("no docker-compose file found")
}

// determineProfile détermine le profil d'environnement
func (sim *SmartInfrastructureManager) determineProfile() string {
	// Vérification des variables d'environnement
	if profile := os.Getenv("DEPLOYMENT_PROFILE"); profile != "" {
		return profile
	}
	if profile := os.Getenv("NODE_ENV"); profile != "" {
		return profile
	}
	if profile := os.Getenv("ENVIRONMENT"); profile != "" {
		return profile
	}

	// Détection basée sur le répertoire ou les fichiers de configuration
	if _, err := os.Stat("config/deploy-production.json"); err == nil {
		return "production"
	}
	if _, err := os.Stat("config/deploy-staging.json"); err == nil {
		return "staging"
	}

	// Par défaut : development
	return "development"
}

// collectResourceInfo collecte les informations sur les ressources système
func (sim *SmartInfrastructureManager) collectResourceInfo() (ResourceInfo, error) {
	resources := ResourceInfo{}

	// Vérification du statut Docker
	cmd := exec.Command("docker", "version", "--format", "{{.Server.Version}}")
	if err := cmd.Run(); err != nil {
		resources.DockerStatus = "not_available"
	} else {
		resources.DockerStatus = "available"
	}

	// Informations basiques du système (simplifiées)
	resources.CPUCores = 4 // Valeur par défaut, peut être améliorée
	resources.Memory = 8192 // 8GB par défaut
	resources.DiskSpace = 100 // 100GB par défaut

	return resources, nil
}

// detectServices détecte les services configurés dans docker-compose
func (sim *SmartInfrastructureManager) detectServices(dockerComposeFile string) (map[string]string, error) {
	services := make(map[string]string)

	// Lecture simple du fichier docker-compose pour détecter les services
	content, err := os.ReadFile(dockerComposeFile)
	if err != nil {
		return services, err
	}

	lines := strings.Split(string(content), "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if strings.Contains(line, "qdrant:") {
			services["qdrant"] = "vector_database"
		}
		if strings.Contains(line, "redis:") {
			services["redis"] = "cache"
		}
		if strings.Contains(line, "prometheus:") {
			services["prometheus"] = "monitoring"
		}
		if strings.Contains(line, "grafana:") {
			services["grafana"] = "dashboard"
		}
		if strings.Contains(line, "rag-server:") || strings.Contains(line, "rag_server:") {
			services["rag_server"] = "api"
		}
	}

	return services, nil
}

// detectDependencies détecte les dépendances du projet
func (sim *SmartInfrastructureManager) detectDependencies() []string {
	var dependencies []string

	// Vérification des fichiers de dépendances
	depFiles := map[string]string{
		"go.mod":            "Go modules",
		"requirements.txt":  "Python packages",
		"package.json":      "Node.js packages",
		"Dockerfile":        "Docker container",
	}

	for file, desc := range depFiles {
		if _, err := os.Stat(file); err == nil {
			dependencies = append(dependencies, desc)
		}
	}

	return dependencies
}

// StartServices démarre les services dans l'ordre approprié
func (sim *SmartInfrastructureManager) StartServices(ctx context.Context) error {
	log.Println("🚀 Starting infrastructure services...")

	// Séquence de démarrage : Qdrant → Redis → Prometheus → Grafana → RAG Server
	serviceSequence := []string{"qdrant", "redis", "prometheus", "grafana", "rag_server"}

	for _, service := range serviceSequence {
		if _, exists := sim.environment.Services[service]; !exists {
			log.Printf("⏭️  Service %s not configured, skipping", service)
			continue
		}

		log.Printf("🔄 Starting service: %s", service)
		
		if err := sim.startSingleService(ctx, service); err != nil {
			return fmt.Errorf("failed to start service %s: %w", service, err)
		}

		// Attendre que le service soit prêt avant de continuer
		if err := sim.waitForServiceHealth(ctx, service); err != nil {
			log.Printf("⚠️  Service %s started but health check failed: %v", service, err)
		} else {
			log.Printf("✅ Service %s is healthy", service)
		}

		// Petit délai entre les services
		time.Sleep(2 * time.Second)
	}

	log.Println("🎉 All services started successfully!")
	return nil
}

// startSingleService démarre un service individuel
func (sim *SmartInfrastructureManager) startSingleService(ctx context.Context, service string) error {
	cmd := exec.CommandContext(ctx, "docker-compose", "-f", sim.dockerComposePath, "up", "-d", service)
	
	if output, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("docker-compose up failed for %s: %w\nOutput: %s", service, err, string(output))
	}

	return nil
}

// waitForServiceHealth attend qu'un service soit en bonne santé
func (sim *SmartInfrastructureManager) waitForServiceHealth(ctx context.Context, service string) error {
	timeout := time.NewTimer(sim.healthCheckTimeout)
	defer timeout.Stop()

	ticker := time.NewTicker(2 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-timeout.C:
			return fmt.Errorf("health check timeout for service %s", service)
		case <-ticker.C:
			if healthy, err := sim.checkSingleServiceHealth(ctx, service); err == nil && healthy {
				return nil
			}
		case <-ctx.Done():
			return ctx.Err()
		}
	}
}

// checkSingleServiceHealth vérifie la santé d'un service individuel
func (sim *SmartInfrastructureManager) checkSingleServiceHealth(ctx context.Context, service string) (bool, error) {
	// Vérification basique via docker-compose
	cmd := exec.CommandContext(ctx, "docker-compose", "-f", sim.dockerComposePath, "ps", service)
	output, err := cmd.Output()
	if err != nil {
		return false, err
	}

	// Analyse simple de la sortie
	outputStr := string(output)
	if strings.Contains(outputStr, "Up") && !strings.Contains(outputStr, "Exit") {
		return true, nil
	}

	return false, nil
}

// StopServices arrête tous les services
func (sim *SmartInfrastructureManager) StopServices(ctx context.Context) error {
	log.Println("🛑 Stopping infrastructure services...")

	cmd := exec.CommandContext(ctx, "docker-compose", "-f", sim.dockerComposePath, "down")
	if output, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("failed to stop services: %w\nOutput: %s", err, string(output))
	}

	log.Println("✅ All services stopped successfully!")
	return nil
}

// GetServiceStatus retourne l'état actuel de tous les services
func (sim *SmartInfrastructureManager) GetServiceStatus(ctx context.Context) (ServiceStatus, error) {
	status := ServiceStatus{
		LastChecked: time.Now(),
	}

	// Vérification de chaque service
	services := []string{"qdrant", "redis", "prometheus", "grafana", "rag_server"}
	allHealthy := true

	for _, service := range services {
		if _, exists := sim.environment.Services[service]; !exists {
			continue
		}

		healthy, err := sim.checkSingleServiceHealth(ctx, service)
		state := ServiceState{
			Status: "unknown",
			Health: "unknown",
		}

		if err != nil {
			state.Status = "error"
			state.Health = "unhealthy"
			state.Errors = []string{err.Error()}
			allHealthy = false
		} else if healthy {
			state.Status = "running"
			state.Health = "healthy"
			state.LastHealthy = time.Now()
		} else {
			state.Status = "stopped"
			state.Health = "unhealthy"
			allHealthy = false
		}

		// Affectation du statut selon le service
		switch service {
		case "qdrant":
			status.Qdrant = state
		case "redis":
			status.Redis = state
		case "prometheus":
			status.Prometheus = state
		case "grafana":
			status.Grafana = state
		case "rag_server":
			status.RAGServer = state
		}
	}

	if allHealthy {
		status.Overall = "healthy"
	} else {
		status.Overall = "degraded"
	}

	return status, nil
}

// HealthCheck effectue une vérification globale de la santé du système
func (sim *SmartInfrastructureManager) HealthCheck(ctx context.Context) error {
	log.Println("🏥 Performing system health check...")

	status, err := sim.GetServiceStatus(ctx)
	if err != nil {
		return fmt.Errorf("failed to get service status: %w", err)
	}

	if status.Overall != "healthy" {
		return fmt.Errorf("system is not healthy: %s", status.Overall)
	}

	log.Println("✅ System health check passed!")
	return nil
}

// AutoRecover tente de récupérer automatiquement les services défaillants
func (sim *SmartInfrastructureManager) AutoRecover(ctx context.Context) error {
	log.Println("🔧 Starting auto-recovery process...")

	status, err := sim.GetServiceStatus(ctx)
	if err != nil {
		return fmt.Errorf("failed to get service status for recovery: %w", err)
	}

	// Liste des services à vérifier
	serviceStates := map[string]ServiceState{
		"qdrant":     status.Qdrant,
		"redis":      status.Redis,
		"prometheus": status.Prometheus,
		"grafana":    status.Grafana,
		"rag_server": status.RAGServer,
	}

	recoveredCount := 0
	for service, state := range serviceStates {
		if state.Health == "unhealthy" || state.Status == "stopped" {
			log.Printf("🔄 Attempting to recover service: %s", service)
			
			// Tentative de redémarrage
			if err := sim.restartService(ctx, service); err != nil {
				log.Printf("❌ Failed to recover service %s: %v", service, err)
				continue
			}

			// Vérification après redémarrage
			if err := sim.waitForServiceHealth(ctx, service); err != nil {
				log.Printf("⚠️  Service %s restarted but health check failed: %v", service, err)
			} else {
				log.Printf("✅ Service %s recovered successfully", service)
				recoveredCount++
			}
		}
	}

	if recoveredCount > 0 {
		log.Printf("🎉 Auto-recovery completed: %d services recovered", recoveredCount)
	} else {
		log.Println("ℹ️  No services required recovery")
	}

	return nil
}

// restartService redémarre un service spécifique
func (sim *SmartInfrastructureManager) restartService(ctx context.Context, service string) error {
	// Arrêt du service
	stopCmd := exec.CommandContext(ctx, "docker-compose", "-f", sim.dockerComposePath, "stop", service)
	if err := stopCmd.Run(); err != nil {
		log.Printf("Warning: Could not stop service %s: %v", service, err)
	}

	// Démarrage du service
	startCmd := exec.CommandContext(ctx, "docker-compose", "-f", sim.dockerComposePath, "up", "-d", service)
	if err := startCmd.Run(); err != nil {
		return fmt.Errorf("failed to start service %s: %w", service, err)
	}

	return nil
}

// PHASE 2: Nouvelles méthodes pour le monitoring avancé et l'auto-healing

// StartAdvancedMonitoring démarre le système de monitoring avancé
func (sim *SmartInfrastructureManager) StartAdvancedMonitoring(ctx context.Context) error {
	if sim.monitoringActive {
		return fmt.Errorf("advanced monitoring is already active")
	}

	log.Println("🚀 Starting advanced monitoring system...")

	// Créer un contexte avec annulation pour le monitoring
	sim.monitoringContext, sim.monitoringCancel = context.WithCancel(ctx)

	// Démarrer l'AdvancedInfrastructureMonitor
	if err := sim.advancedMonitor.Start(sim.monitoringContext); err != nil {
		return fmt.Errorf("failed to start advanced monitor: %w", err)
	}

	// Démarrer l'AdvancedAutonomyManager  
	if err := sim.autonomyManager.StartAdvancedMonitoring(sim.monitoringContext); err != nil {
		sim.advancedMonitor.Stop()
		return fmt.Errorf("failed to start autonomy manager: %w", err)
	}

	// Activer l'auto-healing si configuré
	if sim.autoHealingEnabled {
		if err := sim.autoHealingSystem.Start(sim.monitoringContext); err != nil {
			log.Printf("Warning: Failed to start auto-healing system: %v", err)
		} else {
			log.Println("✅ Auto-healing system started")
		}
	}

	sim.monitoringActive = true
	
	// Notification de démarrage
	sim.notificationSystem.SendNotification(monitoring.NotificationInfo{
		Type:      "system",
		Level:     "info", 
		Service:   "smart-infrastructure",
		Message:   "Advanced monitoring system started successfully",
		Timestamp: time.Now(),
	})

	log.Println("✅ Advanced monitoring system started successfully")
	return nil
}

// StopAdvancedMonitoring arrête le système de monitoring avancé
func (sim *SmartInfrastructureManager) StopAdvancedMonitoring() error {
	if !sim.monitoringActive {
		return fmt.Errorf("advanced monitoring is not active")
	}

	log.Println("🛑 Stopping advanced monitoring system...")

	// Arrêter l'auto-healing en premier
	if err := sim.autoHealingSystem.Stop(); err != nil {
		log.Printf("Warning: Error stopping auto-healing system: %v", err)
	}

	// Arrêter l'AdvancedAutonomyManager
	if err := sim.autonomyManager.StopAdvancedMonitoring(); err != nil {
		log.Printf("Warning: Error stopping autonomy manager: %v", err)
	}

	// Arrêter l'AdvancedInfrastructureMonitor
	sim.advancedMonitor.Stop()

	// Annuler le contexte de monitoring
	if sim.monitoringCancel != nil {
		sim.monitoringCancel()
	}

	sim.monitoringActive = false

	// Notification d'arrêt
	sim.notificationSystem.SendNotification(monitoring.NotificationInfo{
		Type:      "system",
		Level:     "info",
		Service:   "smart-infrastructure", 
		Message:   "Advanced monitoring system stopped",
		Timestamp: time.Now(),
	})

	log.Println("✅ Advanced monitoring system stopped")
	return nil
}

// GetAdvancedHealthStatus retourne le statut de santé avancé de tous les services
func (sim *SmartInfrastructureManager) GetAdvancedHealthStatus(ctx context.Context) (map[string]monitoring.ServiceHealthStatus, error) {
	if !sim.monitoringActive {
		return nil, fmt.Errorf("advanced monitoring is not active")
	}

	log.Println("🔍 Retrieving advanced health status...")

	// Obtenir le statut depuis l'AdvancedInfrastructureMonitor
	healthStatus, err := sim.advancedMonitor.GetHealthStatus(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get advanced health status: %w", err)
	}

	// Enrichir avec les données de l'AdvancedAutonomyManager
	autonomyMetrics, err := sim.autonomyManager.GetMetrics()
	if err != nil {
		log.Printf("Warning: Could not retrieve autonomy metrics: %v", err)
	} else {
		// Ajouter les métriques d'autonomie au statut de santé
		for service, status := range healthStatus {
			if autonomyMetric, exists := autonomyMetrics[service]; exists {
				status.Metrics = map[string]interface{}{
					"autonomy_level":    autonomyMetric.AutonomyLevel,
					"self_healing_count": autonomyMetric.SelfHealingCount,
					"last_intervention": autonomyMetric.LastIntervention,
				}
				healthStatus[service] = status
			}
		}
	}

	log.Printf("✅ Retrieved health status for %d services", len(healthStatus))
	return healthStatus, nil
}

// EnableAutoHealing active ou désactive le système d'auto-healing
func (sim *SmartInfrastructureManager) EnableAutoHealing(enabled bool) error {
	log.Printf("🔧 %s auto-healing system...", map[bool]string{true: "Enabling", false: "Disabling"}[enabled])

	sim.autoHealingEnabled = enabled

	// Si le monitoring est actif, appliquer le changement immédiatement
	if sim.monitoringActive {
		if enabled {
			if err := sim.autoHealingSystem.Start(sim.monitoringContext); err != nil {
				return fmt.Errorf("failed to start auto-healing system: %w", err)
			}
			log.Println("✅ Auto-healing system started")
		} else {
			if err := sim.autoHealingSystem.Stop(); err != nil {
				return fmt.Errorf("failed to stop auto-healing system: %w", err)
			}
			log.Println("✅ Auto-healing system stopped")
		}
	}

	// Notification du changement de configuration
	sim.notificationSystem.SendNotification(monitoring.NotificationInfo{
		Type:      "config",
		Level:     "info",
		Service:   "smart-infrastructure",
		Message:   fmt.Sprintf("Auto-healing system %s", map[bool]string{true: "enabled", false: "disabled"}[enabled]),
		Timestamp: time.Now(),
	})

	log.Printf("✅ Auto-healing %s", map[bool]string{true: "enabled", false: "disabled"}[enabled])
	return nil
}

// GetMonitoringStatus retourne l'état actuel du système de monitoring avancé
func (sim *SmartInfrastructureManager) GetMonitoringStatus() monitoring.MonitoringStatus {
	return monitoring.MonitoringStatus{
		Active:             sim.monitoringActive,
		AutoHealingEnabled: sim.autoHealingEnabled,
		StartTime:          time.Now(), // TODO: tracker le vrai temps de démarrage
		ServicesMonitored:  sim.getMonitoredServicesCount(),
	}
}

// getMonitoredServicesCount retourne le nombre de services surveillés
func (sim *SmartInfrastructureManager) getMonitoredServicesCount() int {
	if !sim.monitoringActive {
		return 0
	}
	
	// Compter les services actifs dans docker-compose
	return 5 // qdrant, redis, prometheus, grafana, rag_server
}
