// Package monitoring implements the Real-Time Monitoring Dashboard component
package monitoring

import (
	"fmt"
	"time"
)

// SystemEvent représente un événement système
type SystemEvent struct {
	ID          string                 `json:"id"`
	Type        string                 `json:"type"`
	Source      string                 `json:"source"`
	Description string                 `json:"description"`
	Timestamp   time.Time              `json:"timestamp"`
	Severity    EventSeverity          `json:"severity"`
	Data        map[string]interface{} `json:"data"`
}

// NewSystemEvent crée une nouvelle instance de SystemEvent
func NewSystemEvent(eventType, source, description string, severity EventSeverity, data map[string]interface{}) *SystemEvent {
	return &SystemEvent{
		ID:          fmt.Sprintf("sys-event-%d", time.Now().UnixNano()),
		Type:        eventType,
		Source:      source,
		Description: description,
		Timestamp:   time.Now(),
		Severity:    severity,
		Data:        data,
	}
}
