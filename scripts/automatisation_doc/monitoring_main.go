//go:build ignore

package main

import (
	"context"
	"log"
	"time"

	"email-sender-1/scripts/automatisation_doc"
)

func main() {
	ctx := context.Background()
	mgr := automatisation_doc.NewMonitoringManager()

	if err := mgr.Initialize(ctx); err != nil {
		log.Fatalf("Erreur d'initialisation du MonitoringManager : %v", err)
	}

	if err := mgr.StartMonitoring(ctx); err != nil {
		log.Fatalf("Erreur au démarrage de la surveillance : %v", err)
	}

	log.Println("Surveillance continue démarrée (MonitoringManager Roo)")

	for {
		status, err := mgr.CheckSystemHealth(ctx)
		if err != nil {
			log.Printf("Erreur lors du contrôle de santé : %v", err)
		} else {
			log.Printf("Statut de santé : %+v", status)
		}
		time.Sleep(60 * time.Second)
	}
}
