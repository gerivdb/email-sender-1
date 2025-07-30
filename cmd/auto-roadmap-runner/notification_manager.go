// cmd/auto-roadmap-runner/notification_manager.go
// Implémentation NotificationManagerImpl pour Orchestration & CI/CD

package main

import (
	"fmt"
	"log"
)

type NotificationManagerImpl struct {
	enabled bool
}

func NewNotificationManager(enabled bool) *NotificationManagerImpl {
	return &NotificationManagerImpl{enabled: enabled}
}

func (n *NotificationManagerImpl) Send(message string) {
	if n.enabled {
		log.Printf("Notification envoyée: %s", message)
		fmt.Printf("Notification envoyée: %s\n", message)
	}
}

func (n *NotificationManagerImpl) Status() string {
	if n.enabled {
		return "Notifications activées"
	}
	return "Notifications désactivées"
}

// Exemple d'utilisation
func ExampleNotificationManager() {
	manager := NewNotificationManager(true)
	manager.Send("Déploiement terminé")
	fmt.Println(manager.Status())
}
