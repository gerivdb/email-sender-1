package smart_infrastructure

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gerivdb/email-sender-1/internal/infrastructure"
)

// SmartInfrastructureOrchestrator est le point d'entrée pour l'orchestration de l'infrastructure
func main() {
	log.SetFlags(log.LstdFlags | log.Lshortfile)
	log.Println("🚀 Starting Smart Infrastructure Orchestrator...")

	// Création du manager
	manager, err := infrastructure.NewSmartInfrastructureManager()
	if err != nil {
		log.Fatalf("❌ Failed to create infrastructure manager: %v", err)
	}

	// Contexte avec annulation pour une gestion propre des signaux
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Gestion des signaux pour un arrêt propre
	signalChan := make(chan os.Signal, 1)
	signal.Notify(signalChan, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		<-signalChan
		log.Println("📡 Received shutdown signal...")
		cancel()
	}()

	// Analyse des arguments de la ligne de commande
	if len(os.Args) > 1 {
		command := os.Args[1]

		switch command {
		case "start":
			handleStartCommand(ctx, manager)
		case "stop":
			handleStopCommand(ctx, manager)
		case "status":
			handleStatusCommand(ctx, manager)
		case "health":
			handleHealthCommand(ctx, manager)
		case "recover":
			handleRecoverCommand(ctx, manager)
		case "info":
			handleInfoCommand(manager)
		case "monitor":
			handleMonitorCommand(ctx, manager)
		default:
			printUsage()
		}
	} else {
		// Mode interactif par défaut
		runInteractiveMode(ctx, manager)
	}
}

// handleStartCommand gère la commande de démarrage des services
func handleStartCommand(ctx context.Context, manager *infrastructure.SmartInfrastructureManager) {
	log.Println("🎯 Starting all infrastructure services...")

	if err := manager.StartServices(ctx); err != nil {
		log.Fatalf("❌ Failed to start services: %v", err)
	}

	log.Println("✅ All services started successfully!")
}

// handleStopCommand gère la commande d'arrêt des services
func handleStopCommand(ctx context.Context, manager *infrastructure.SmartInfrastructureManager) {
	log.Println("🛑 Stopping all infrastructure services...")

	if err := manager.StopServices(ctx); err != nil {
		log.Fatalf("❌ Failed to stop services: %v", err)
	}

	log.Println("✅ All services stopped successfully!")
}

// handleStatusCommand gère la commande de statut des services
func handleStatusCommand(ctx context.Context, manager *infrastructure.SmartInfrastructureManager) {
	log.Println("📊 Checking services status...")

	status, err := manager.GetServiceStatus(ctx)
	if err != nil {
		log.Fatalf("❌ Failed to get services status: %v", err)
	}

	// Affichage formaté du statut
	printServiceStatus(status)
}

// handleHealthCommand gère la commande de vérification de santé
func handleHealthCommand(ctx context.Context, manager *infrastructure.SmartInfrastructureManager) {
	log.Println("🏥 Performing health check...")

	if err := manager.HealthCheck(ctx); err != nil {
		log.Printf("❌ Health check failed: %v", err)
		os.Exit(1)
	}

	log.Println("✅ Health check passed!")
}

// handleRecoverCommand gère la commande de récupération automatique
func handleRecoverCommand(ctx context.Context, manager *infrastructure.SmartInfrastructureManager) {
	log.Println("🔧 Starting auto-recovery...")

	if err := manager.AutoRecover(ctx); err != nil {
		log.Fatalf("❌ Auto-recovery failed: %v", err)
	}

	log.Println("✅ Auto-recovery completed!")
}

// handleInfoCommand gère la commande d'informations sur l'environnement
func handleInfoCommand(manager *infrastructure.SmartInfrastructureManager) {
	log.Println("ℹ️  Environment information:")

	env, err := manager.DetectEnvironment()
	if err != nil {
		log.Fatalf("❌ Failed to detect environment: %v", err)
	}

	// Affichage formaté des informations d'environnement
	printEnvironmentInfo(env)
}

// handleMonitorCommand lance le mode monitoring continu
func handleMonitorCommand(ctx context.Context, manager *infrastructure.SmartInfrastructureManager) {
	log.Println("📡 Starting continuous monitoring...")

	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	// Premier check immédiat
	checkAndReport(ctx, manager)

	for {
		select {
		case <-ticker.C:
			checkAndReport(ctx, manager)
		case <-ctx.Done():
			log.Println("🛑 Monitoring stopped")
			return
		}
	}
}

// runInteractiveMode lance le mode interactif par défaut
func runInteractiveMode(ctx context.Context, manager *infrastructure.SmartInfrastructureManager) {
	log.Println("🎮 Starting in interactive mode...")
	log.Println("Available commands: start, stop, status, health, recover, info, monitor")

	// Détection et affichage de l'environnement
	env, err := manager.DetectEnvironment()
	if err != nil {
		log.Printf("⚠️  Warning: Could not detect environment: %v", err)
	} else {
		log.Printf("🌍 Environment: %s with %d services", env.Profile, len(env.Services))
	}

	// Check initial du statut
	status, err := manager.GetServiceStatus(ctx)
	if err != nil {
		log.Printf("⚠️  Warning: Could not get initial status: %v", err)
	} else {
		log.Printf("📊 Current status: %s", status.Overall)
	}

	// Boucle d'attente avec monitoring périodique
	ticker := time.NewTicker(60 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			// Check périodique silencieux
			if status, err := manager.GetServiceStatus(ctx); err == nil {
				if status.Overall != "healthy" {
					log.Printf("⚠️  Status changed: %s", status.Overall)
				}
			}
		case <-ctx.Done():
			log.Println("👋 Smart Infrastructure Orchestrator stopped")
			return
		}
	}
}

// checkAndReport effectue une vérification et rapporte l'état
func checkAndReport(ctx context.Context, manager *infrastructure.SmartInfrastructureManager) {
	status, err := manager.GetServiceStatus(ctx)
	if err != nil {
		log.Printf("❌ Failed to get status: %v", err)
		return
	}

	log.Printf("📊 [%s] Overall status: %s",
		time.Now().Format("15:04:05"), status.Overall)

	// Auto-recovery si nécessaire
	if status.Overall != "healthy" {
		log.Println("🔧 Degraded status detected, attempting auto-recovery...")
		if err := manager.AutoRecover(ctx); err != nil {
			log.Printf("❌ Auto-recovery failed: %v", err)
		}
	}
}

// printServiceStatus affiche le statut des services de manière formatée
func printServiceStatus(status infrastructure.ServiceStatus) {
	fmt.Printf("\n🔍 Infrastructure Status Report\n")
	fmt.Printf("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
	fmt.Printf("📊 Overall: %s\n", getStatusEmoji(status.Overall)+status.Overall)
	fmt.Printf("🕐 Last Check: %s\n", status.LastChecked.Format("2006-01-02 15:04:05"))
	fmt.Printf("\n📋 Services:\n")

	services := map[string]infrastructure.ServiceState{
		"Qdrant":     status.Qdrant,
		"Redis":      status.Redis,
		"Prometheus": status.Prometheus,
		"Grafana":    status.Grafana,
		"RAG Server": status.RAGServer,
	}

	for name, state := range services {
		if state.Status != "" {
			fmt.Printf("  %s %s: %s/%s",
				getStatusEmoji(state.Status), name, state.Status, state.Health)

			if !state.LastHealthy.IsZero() {
				fmt.Printf(" (Last healthy: %s)", state.LastHealthy.Format("15:04:05"))
			}

			if len(state.Errors) > 0 {
				fmt.Printf(" - Errors: %v", state.Errors)
			}
			fmt.Println()
		}
	}
	fmt.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
}

// printEnvironmentInfo affiche les informations d'environnement de manière formatée
func printEnvironmentInfo(env *infrastructure.EnvironmentInfo) {
	fmt.Printf("\n🌍 Environment Information\n")
	fmt.Printf("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
	fmt.Printf("📝 Profile: %s\n", env.Profile)
	fmt.Printf("🐳 Docker Compose: %s\n", env.DockerComposeFile)
	fmt.Printf("💽 Docker Status: %s\n", env.Resources.DockerStatus)
	fmt.Printf("🔧 CPU Cores: %d\n", env.Resources.CPUCores)
	fmt.Printf("💾 Memory: %d MB\n", env.Resources.Memory)
	fmt.Printf("💿 Disk Space: %d GB\n", env.Resources.DiskSpace)

	fmt.Printf("\n📦 Configured Services (%d):\n", len(env.Services))
	for service, serviceType := range env.Services {
		fmt.Printf("  • %s (%s)\n", service, serviceType)
	}

	if len(env.Dependencies) > 0 {
		fmt.Printf("\n🔗 Dependencies (%d):\n", len(env.Dependencies))
		for _, dep := range env.Dependencies {
			fmt.Printf("  • %s\n", dep)
		}
	}

	fmt.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
}

// getStatusEmoji retourne l'emoji approprié pour un statut
func getStatusEmoji(status string) string {
	switch status {
	case "healthy", "running":
		return "✅ "
	case "unhealthy", "degraded", "error":
		return "❌ "
	case "stopped":
		return "🛑 "
	default:
		return "❓ "
	}
}

// printUsage affiche l'aide d'utilisation
func printUsage() {
	fmt.Printf(`
🚀 Smart Infrastructure Orchestrator

Usage: %s [command]

Commands:
  start     Start all infrastructure services
  stop      Stop all infrastructure services  
  status    Show services status
  health    Perform health check
  recover   Attempt auto-recovery of failed services
  info      Show environment information
  monitor   Start continuous monitoring

Without arguments, runs in interactive mode.

Examples:
  %s start                    # Start all services
  %s status                   # Check status
  %s monitor                  # Continuous monitoring
`, os.Args[0], os.Args[0], os.Args[0], os.Args[0])
}
