package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"

	"email_sender/eventbus"
)

// Service représente un service qui écoute et publie des événements
type Service struct {
	bus  *eventbus.EventBus
	name string
}

// NewService crée un nouveau service
func NewService(name string, bus *eventbus.EventBus) *Service {
	return &Service{
		bus:  bus,
		name: name,
	}
}

// Start lance l'écoute des événements
func (s *Service) Start(ctx context.Context) {
	for {
		select {
		case evt := <-s.bus.Events:
			// Traiter l'événement
			if evt.Type == "script.executed" {
				log.Printf("%s received event: %+v", s.name, evt)
				// Publier un événement en réponse
				response := eventbus.Event{
					ID:        fmt.Sprintf("%s-response-%s", s.name, evt.ID),
					Type:      "service.response",
					Source:    s.name,
					Payload:   fmt.Sprintf("Processed %s", evt.Payload),
					Timestamp: evt.Timestamp,
				}
				s.bus.Events <- response
			}
		case <-ctx.Done():
			log.Printf("%s stopped", s.name)
			return
		}
	}
}

func main() {
	// Initialiser le bus d'événements
	bus := eventbus.NewEventBus()

	// Créer un service
	service := NewService("example-service", bus)

	// Créer un contexte annulable
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Capturer les signaux d'arrêt (Ctrl+C, SIGTERM)
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	// Démarrer le service
	log.Printf("Starting %s", service.name)
	go service.Start(ctx)

	// Simuler un événement
	go func() {
		defer cancel() // Annuler le contexte après l'envoi de l'événement
		evt := eventbus.Event{
			ID:        "evt1",
			Type:      "script.executed",
			Source:    "test-script",
			Payload:   `{"action": "run"}`,
			Timestamp: "2025-07-11T18:42:00Z",
		}
		bus.Events <- evt
	}()

	// Consommer les événements de réponse
	go func() {
		for {
			select {
			case evt := <-bus.Events:
				log.Printf("Réponse reçue: %+v", evt)
			case <-ctx.Done():
				log.Println("Arrêt de la consommation des réponses")
				return
			}
		}
	}()

	// Attendre un signal d'arrêt
	select {
	case <-sigChan:
		log.Println("Signal d'arrêt reçu, arrêt du programme")
		cancel()
	case <-ctx.Done():
		log.Println("Contexte annulé")
	}
}
