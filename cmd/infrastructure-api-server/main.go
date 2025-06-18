package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"email_sender/internal/api"
	"email_sender/internal/infrastructure"
)

const (
	defaultPort = 8080
	version     = "v1.0.0"
)

func main() {
	var (
		port    = flag.Int("port", defaultPort, "Port pour l'API server")
		help    = flag.Bool("help", false, "Afficher l'aide")
		version = flag.Bool("version", false, "Afficher la version")
	)
	flag.Parse()

	if *help {
		printHelp()
		return
	}

	if *version {
		fmt.Printf("Smart Infrastructure API Server %s\n", version)
		return
	}

	log.Println("🚀 Starting Smart Infrastructure API Server...")

	// Initialiser le SmartInfrastructureManager
	orchestrator, err := infrastructure.NewSmartInfrastructureManager()
	if err != nil {
		log.Fatalf("❌ Failed to create infrastructure manager: %v", err)
	}

	// Créer le handler API
	apiHandler := api.NewInfrastructureAPIHandler(orchestrator)

	// Démarrer le serveur dans une goroutine
	serverErrors := make(chan error, 1)
	go func() {
		serverErrors <- apiHandler.StartServer(*port)
	}()

	// Gérer l'arrêt gracieux
	shutdown := make(chan os.Signal, 1)
	signal.Notify(shutdown, os.Interrupt, syscall.SIGTERM)

	select {
	case err := <-serverErrors:
		log.Fatalf("❌ Server error: %v", err)

	case sig := <-shutdown:
		log.Printf("🛑 Received signal %v, shutting down gracefully...", sig)

		// Créer un contexte avec timeout pour l'arrêt
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		// Arrêter le serveur
		if err := apiHandler.StopServer(ctx); err != nil {
			log.Printf("⚠️  Warning: Error stopping server: %v", err)
		}

		log.Println("✅ Server stopped gracefully")
	}
}

func printHelp() {
	fmt.Printf(`Smart Infrastructure API Server %s

DESCRIPTION:
    Serveur API pour l'orchestration et le monitoring de l'infrastructure Smart Email Sender.
    Fournit des endpoints REST pour contrôler les services, le monitoring avancé et l'auto-healing.

USAGE:
    %s [OPTIONS]

OPTIONS:
    -port <int>     Port pour l'API server (défaut: %d)
    -help           Afficher cette aide
    -version        Afficher la version

ENDPOINTS DISPONIBLES:

Infrastructure de base:
    GET  /api/v1/infrastructure/status     - Statut des services
    GET  /api/v1/infrastructure/health     - Health check complet
    POST /api/v1/infrastructure/start      - Démarrer tous les services
    POST /api/v1/infrastructure/stop       - Arrêter tous les services
    POST /api/v1/infrastructure/recover    - Récupération automatique

Monitoring avancé (Phase 2):
    POST /api/v1/monitoring/start          - Démarrer monitoring avancé
    POST /api/v1/monitoring/stop           - Arrêter monitoring avancé
    GET  /api/v1/monitoring/status         - Statut du monitoring
    GET  /api/v1/monitoring/health-advanced - Health status avancé

Auto-healing (Phase 2):
    POST /api/v1/auto-healing/enable       - Activer l'auto-healing
    POST /api/v1/auto-healing/disable      - Désactiver l'auto-healing

EXEMPLES:

    # Démarrer le serveur sur le port par défaut
    %s

    # Démarrer sur un port spécifique
    %s -port 9090

    # Tester les endpoints avec curl
    curl http://localhost:8080/api/v1/infrastructure/status
    curl -X POST http://localhost:8080/api/v1/monitoring/start
    curl -X POST http://localhost:8080/api/v1/auto-healing/enable

    # Démarrer monitoring avancé et auto-healing
    curl -X POST http://localhost:8080/api/v1/monitoring/start && \
    curl -X POST http://localhost:8080/api/v1/auto-healing/enable

INTÉGRATION VS CODE:
    Ce serveur peut être utilisé avec les tâches VS Code configurées pour automatiser
    le démarrage de l'infrastructure lors de l'ouverture du workspace.

LOGS:
    Les logs sont écrits dans 'logs/smart-infrastructure-notifications.log'
    et directement dans la console.

`, version, os.Args[0], defaultPort, os.Args[0], os.Args[0])
}
