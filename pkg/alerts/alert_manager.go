package alerts

import (
	"context"
	"fmt"
	"sync"
	"time"
)

// AlertType définit le type d'alerte
type AlertType string

const (
	AlertTypeError   AlertType = "error"
	AlertTypeWarning AlertType = "warning"
	AlertTypeInfo    AlertType = "info"
)

// Alert structure d'une alerte
type Alert struct {
	ID        string
	Type      AlertType
	Message   string
	Source    string
	CreatedAt time.Time
	Resolved  bool
	Channels  []string // "email", "slack", "webhook"
}

// AlertManager gère les alertes et notifications
type AlertManager struct {
	alerts   []*Alert
	mu       sync.RWMutex
	handlers map[string]AlertHandler
}

// AlertHandler interface pour canaux de notification
type AlertHandler interface {
	Send(alert *Alert) error
}

// NewAlertManager crée un gestionnaire d'alertes
func NewAlertManager() *AlertManager {
	return &AlertManager{
		alerts:   make([]*Alert, 0),
		handlers: make(map[string]AlertHandler),
	}
}

// RegisterHandler enregistre un canal (email, slack, webhook...)
func (am *AlertManager) RegisterHandler(channel string, handler AlertHandler) {
	am.mu.Lock()
	defer am.mu.Unlock()
	am.handlers[channel] = handler
}

// Raise crée et envoie une alerte sur les canaux spécifiés
func (am *AlertManager) Raise(ctx context.Context, alertType AlertType, message, source string, channels []string) (*Alert, error) {
	alert := &Alert{
		ID:        fmt.Sprintf("%d-%s", time.Now().UnixNano(), source),
		Type:      alertType,
		Message:   message,
		Source:    source,
		CreatedAt: time.Now(),
		Resolved:  false,
		Channels:  channels,
	}
	am.mu.Lock()
	am.alerts = append(am.alerts, alert)
	am.mu.Unlock()

	// Envoi sur chaque canal
	for _, ch := range channels {
		if handler, ok := am.handlers[ch]; ok {
			go handler.Send(alert)
		}
	}
	return alert, nil
}

// Resolve marque une alerte comme résolue
func (am *AlertManager) Resolve(alertID string) {
	am.mu.Lock()
	defer am.mu.Unlock()
	for _, alert := range am.alerts {
		if alert.ID == alertID {
			alert.Resolved = true
		}
	}
}

// List retourne les alertes actives
func (am *AlertManager) List(activeOnly bool) []*Alert {
	am.mu.RLock()
	defer am.mu.RUnlock()
	result := make([]*Alert, 0)
	for _, alert := range am.alerts {
		if !activeOnly || !alert.Resolved {
			result = append(result, alert)
		}
	}
	return result
}

// EmailHandler exemple de handler email (stub)
type EmailHandler struct {
	To string
}

func (eh *EmailHandler) Send(alert *Alert) error {
	fmt.Printf("[EMAIL] To: %s | %s: %s\n", eh.To, alert.Type, alert.Message)
	return nil
}

// SlackHandler exemple de handler Slack (stub)
type SlackHandler struct {
	WebhookURL string
}

func (sh *SlackHandler) Send(alert *Alert) error {
	fmt.Printf("[SLACK] Webhook: %s | %s: %s\n", sh.WebhookURL, alert.Type, alert.Message)
	return nil
}

// WebhookHandler exemple de handler Webhook (stub)
type WebhookHandler struct {
	URL string
}

func (wh *WebhookHandler) Send(alert *Alert) error {
	fmt.Printf("[WEBHOOK] URL: %s | %s: %s\n", wh.URL, alert.Type, alert.Message)
	return nil
}
