// scripts/automatisation_doc/monitoring/main.go
package main

import (
	"context"
	"log"
	"time"

	"scripts/automatisation_doc"
)

func main() {
	ctx := context.Background()
	monitoringManager := automatisation_doc.NewMonitoringManager()
	if err := monitoringManager.Initialize(ctx); err != nil {
		log.Fatalf("Erreur d'initialisation du MonitoringManager: %v", err)
	}
	log.Println("Surveillance continue Roo-Code : démarrage...")
	if err := monitoringManager.StartMonitoring(ctx); err != nil {
		log.Fatalf("Erreur lors du démarrage de la surveillance continue: %v", err)
	}
	// Boucle de surveillance continue (exemple simple, peut être adapté)
	for {
		time.Sleep(60 * time.Second)
		status, err := monitoringManager.CheckSystemHealth(ctx)
		if err != nil {
			log.Printf("Erreur lors du check de santé: %v", err)
		} else {
			log.Printf("Statut de santé: %+v", status)
		}
	}
}
