package monitoring

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"time"
)

// NotificationInfo représente les informations d'une notification
type NotificationInfo struct {
	Type      string                 `json:"type"`
	Level     string                 `json:"level"`
	Service   string                 `json:"service"`
	Message   string                 `json:"message"`
	Timestamp time.Time              `json:"timestamp"`
	Details   map[string]interface{} `json:"details,omitempty"`
}

// DefaultNotificationSystem implémentation par défaut du système de notifications
type DefaultNotificationSystem struct {
	logFile     string
	alertLevels map[string]int
	enableFile  bool
	enableLog   bool
}

// AlertLevel énumération pour les niveaux d'alerte
type AlertLevel struct {
	Name     string
	Priority int
	Icon     string
}

// LogEvent représente un événement à logger
type LogEventData struct {
	Timestamp time.Time              `json:"timestamp"`
	Event     string                 `json:"event"`
	Details   map[string]interface{} `json:"details"`
}

// AlertData représente une alerte
type AlertData struct {
	Timestamp time.Time `json:"timestamp"`
	Level     string    `json:"level"`
	Service   string    `json:"service"`
	Message   string    `json:"message"`
	Icon      string    `json:"icon"`
	Priority  int       `json:"priority"`
}

// NewDefaultNotificationSystem crée une nouvelle instance du système de notifications
func NewDefaultNotificationSystem(logFile string) *DefaultNotificationSystem {
	// Créer le répertoire de logs s'il n'existe pas
	logDir := filepath.Dir(logFile)
	os.MkdirAll(logDir, 0755)

	system := &DefaultNotificationSystem{
		logFile:    logFile,
		enableFile: true,
		enableLog:  true,
		alertLevels: map[string]int{
			"debug":               1,
			"info":                2,
			"warning":             3,
			"error":               4,
			"critical":            5,
			"escalation":          6,
			"manual_intervention": 7,
		},
	}

	return system
}

// SendAlert envoie une alerte
func (dns *DefaultNotificationSystem) SendAlert(level string, service string, message string) error {
	alert := AlertData{
		Timestamp: time.Now(),
		Level:     level,
		Service:   service,
		Message:   message,
		Icon:      dns.getIconForLevel(level),
		Priority:  dns.getPriorityForLevel(level),
	}

	// Log dans la console
	if dns.enableLog {
		dns.logToConsole(alert)
	}

	// Log dans le fichier
	if dns.enableFile {
		return dns.logToFile(alert)
	}

	return nil
}

// SendNotification envoie une notification générale
func (dns *DefaultNotificationSystem) SendNotification(notification NotificationInfo) error {
	// Convertir la notification en alerte pour utiliser l'infrastructure existante
	alert := AlertData{
		Timestamp: notification.Timestamp,
		Level:     notification.Level,
		Service:   notification.Service,
		Message:   notification.Message,
		Icon:      dns.getIconForLevel(notification.Level),
		Priority:  dns.getPriorityForLevel(notification.Level),
	}

	// Log dans la console
	if dns.enableLog {
		dns.logToConsole(alert)
	}

	// Log dans le fichier
	if dns.enableFile {
		return dns.logToFile(alert)
	}

	return nil
}

// LogEvent enregistre un événement
func (dns *DefaultNotificationSystem) LogEvent(event string, details map[string]interface{}) error {
	eventData := LogEventData{
		Timestamp: time.Now(),
		Event:     event,
		Details:   details,
	}

	// Log dans la console
	if dns.enableLog {
		dns.logEventToConsole(eventData)
	}

	// Log dans le fichier
	if dns.enableFile {
		return dns.logEventToFile(eventData)
	}

	return nil
}

// logToConsole affiche l'alerte dans la console
func (dns *DefaultNotificationSystem) logToConsole(alert AlertData) {
	timestamp := alert.Timestamp.Format("2006-01-02 15:04:05")

	switch alert.Level {
	case "debug":
		log.Printf("🔍 [%s] DEBUG [%s]: %s", timestamp, alert.Service, alert.Message)
	case "info":
		log.Printf("ℹ️  [%s] INFO [%s]: %s", timestamp, alert.Service, alert.Message)
	case "warning":
		log.Printf("⚠️  [%s] WARNING [%s]: %s", timestamp, alert.Service, alert.Message)
	case "error":
		log.Printf("❌ [%s] ERROR [%s]: %s", timestamp, alert.Service, alert.Message)
	case "critical":
		log.Printf("🚨 [%s] CRITICAL [%s]: %s", timestamp, alert.Service, alert.Message)
	case "escalation":
		log.Printf("🚀 [%s] ESCALATION [%s]: %s", timestamp, alert.Service, alert.Message)
	case "manual_intervention":
		log.Printf("🆘 [%s] MANUAL INTERVENTION [%s]: %s", timestamp, alert.Service, alert.Message)
	default:
		log.Printf("%s [%s] %s [%s]: %s", alert.Icon, timestamp, alert.Level, alert.Service, alert.Message)
	}
}

// logEventToConsole affiche l'événement dans la console
func (dns *DefaultNotificationSystem) logEventToConsole(event LogEventData) {
	timestamp := event.Timestamp.Format("2006-01-02 15:04:05")
	log.Printf("📋 [%s] EVENT: %s - %v", timestamp, event.Event, event.Details)
}

// logToFile enregistre l'alerte dans le fichier de log
func (dns *DefaultNotificationSystem) logToFile(alert AlertData) error {
	file, err := os.OpenFile(dns.logFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return fmt.Errorf("failed to open log file: %w", err)
	}
	defer file.Close()

	alertJSON, err := json.Marshal(alert)
	if err != nil {
		return fmt.Errorf("failed to marshal alert: %w", err)
	}

	_, err = file.WriteString(string(alertJSON) + "\n")
	if err != nil {
		return fmt.Errorf("failed to write to log file: %w", err)
	}

	return nil
}

// logEventToFile enregistre l'événement dans le fichier de log
func (dns *DefaultNotificationSystem) logEventToFile(event LogEventData) error {
	file, err := os.OpenFile(dns.logFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return fmt.Errorf("failed to open log file: %w", err)
	}
	defer file.Close()

	eventJSON, err := json.Marshal(event)
	if err != nil {
		return fmt.Errorf("failed to marshal event: %w", err)
	}

	_, err = file.WriteString(string(eventJSON) + "\n")
	if err != nil {
		return fmt.Errorf("failed to write to log file: %w", err)
	}

	return nil
}

// getIconForLevel retourne l'icône appropriée pour un niveau d'alerte
func (dns *DefaultNotificationSystem) getIconForLevel(level string) string {
	icons := map[string]string{
		"debug":               "🔍",
		"info":                "ℹ️",
		"warning":             "⚠️",
		"error":               "❌",
		"critical":            "🚨",
		"escalation":          "🚀",
		"manual_intervention": "🆘",
	}

	if icon, exists := icons[level]; exists {
		return icon
	}
	return "📢"
}

// getPriorityForLevel retourne la priorité pour un niveau d'alerte
func (dns *DefaultNotificationSystem) getPriorityForLevel(level string) int {
	if priority, exists := dns.alertLevels[level]; exists {
		return priority
	}
	return 0
}

// SetFileLogging active/désactive le logging vers fichier
func (dns *DefaultNotificationSystem) SetFileLogging(enabled bool) {
	dns.enableFile = enabled
}

// SetConsoleLogging active/désactive le logging vers console
func (dns *DefaultNotificationSystem) SetConsoleLogging(enabled bool) {
	dns.enableLog = enabled
}

// GetRecentAlerts récupère les alertes récentes du fichier de log
func (dns *DefaultNotificationSystem) GetRecentAlerts(since time.Time) ([]AlertData, error) {
	file, err := os.Open(dns.logFile)
	if err != nil {
		return nil, fmt.Errorf("failed to open log file: %w", err)
	}
	defer file.Close()

	var alerts []AlertData
	decoder := json.NewDecoder(file)

	for decoder.More() {
		var alert AlertData
		if err := decoder.Decode(&alert); err != nil {
			continue // Skip malformed entries
		}

		if alert.Timestamp.After(since) {
			alerts = append(alerts, alert)
		}
	}

	return alerts, nil
}

// GetRecentEvents récupère les événements récents du fichier de log
func (dns *DefaultNotificationSystem) GetRecentEvents(since time.Time) ([]LogEventData, error) {
	file, err := os.Open(dns.logFile)
	if err != nil {
		return nil, fmt.Errorf("failed to open log file: %w", err)
	}
	defer file.Close()

	var events []LogEventData
	decoder := json.NewDecoder(file)

	for decoder.More() {
		var event LogEventData
		if err := decoder.Decode(&event); err != nil {
			continue // Skip malformed entries
		}

		if event.Timestamp.After(since) {
			events = append(events, event)
		}
	}

	return events, nil
}

// ClearOldLogs nettoie les anciens logs
func (dns *DefaultNotificationSystem) ClearOldLogs(olderThan time.Duration) error {
	cutoff := time.Now().Add(-olderThan)

	// Lire tous les logs
	file, err := os.Open(dns.logFile)
	if err != nil {
		return fmt.Errorf("failed to open log file for cleanup: %w", err)
	}
	defer file.Close()

	var recentEntries []string
	decoder := json.NewDecoder(file)

	for decoder.More() {
		var entry map[string]interface{}
		if err := decoder.Decode(&entry); err != nil {
			continue
		}

		if timestampStr, exists := entry["timestamp"]; exists {
			if timestamp, err := time.Parse(time.RFC3339, timestampStr.(string)); err == nil {
				if timestamp.After(cutoff) {
					entryJSON, _ := json.Marshal(entry)
					recentEntries = append(recentEntries, string(entryJSON))
				}
			}
		}
	}

	// Réécrire le fichier avec seulement les entrées récentes
	file, err = os.Create(dns.logFile)
	if err != nil {
		return fmt.Errorf("failed to recreate log file: %w", err)
	}
	defer file.Close()

	for _, entry := range recentEntries {
		file.WriteString(entry + "\n")
	}

	log.Printf("🧹 Cleaned old log entries, kept %d recent entries", len(recentEntries))
	return nil
}
