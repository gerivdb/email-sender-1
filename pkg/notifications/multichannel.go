// SPDX-License-Identifier: MIT
// Package notifications : notifications multi-canal (v65)
package notifications

import (
	"time"
)

// NotificationManager gère les notifications multi-canal
type NotificationManager struct {
	Channels  map[string]Channel
	Templater *TemplateEngine
	Router    *NotificationRouter
	Tracker   *DeliveryTracker
	Scheduler *NotificationScheduler
}

// Notification structure principale
type Notification struct {
	ID          string
	Type        string
	Recipients  []Recipient
	Subject     string
	Body        string
	Template    string
	Data        map[string]interface{}
	Channels    []string
	Priority    Priority
	ScheduledAt *time.Time
}

// DeliveryResult résultat de livraison
type DeliveryResult struct {
	NotificationID string
	Channel        string
	Recipient      string
	Status         DeliveryStatus
	AttemptedAt    time.Time
	DeliveredAt    *time.Time
	Error          string
}

// Channel, TemplateEngine, NotificationRouter, DeliveryTracker, NotificationScheduler, Recipient, Priority, DeliveryStatus à implémenter selon besoins
