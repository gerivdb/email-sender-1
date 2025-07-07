package tools

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"net/smtp"
	"sync"
	"time"
)

// AlertManager handles sending alerts via multiple channels
type AlertManager struct {
	config       *AlertConfig
	emailSender  *EmailSender
	slackWebhook string
	alertHistory []Alert
	mutex        sync.RWMutex
	logger       *log.Logger
	httpClient   *http.Client
}

// AlertConfig contains configuration for alert management
type AlertConfig struct {
	EmailEnabled     bool     `json:"email_enabled"`
	SlackEnabled     bool     `json:"slack_enabled"`
	SMTPHost         string   `json:"smtp_host"`
	SMTPPort         int      `json:"smtp_port"`
	SMTPUsername     string   `json:"smtp_username"`
	SMTPPassword     string   `json:"smtp_password"`
	FromEmail        string   `json:"from_email"`
	ToEmails         []string `json:"to_emails"`
	SlackWebhookURL  string   `json:"slack_webhook_url"`
	SlackChannel     string   `json:"slack_channel"`
	SlackUsername    string   `json:"slack_username"`
	MaxHistorySize   int      `json:"max_history_size"`
	RetryAttempts    int      `json:"retry_attempts"`
	RetryDelay       int      `json:"retry_delay_seconds"`
	RateLimitPerHour int      `json:"rate_limit_per_hour"`
}

// EmailSender handles email delivery
type EmailSender struct {
	config *AlertConfig
	logger *log.Logger
}

// SlackMessage represents a Slack webhook payload
type SlackMessage struct {
	Text        string       `json:"text"`
	Channel     string       `json:"channel,omitempty"`
	Username    string       `json:"username,omitempty"`
	IconEmoji   string       `json:"icon_emoji,omitempty"`
	Attachments []Attachment `json:"attachments,omitempty"`
}

// Attachment represents a Slack message attachment
type Attachment struct {
	Color     string  `json:"color,omitempty"`
	Title     string  `json:"title,omitempty"`
	Text      string  `json:"text,omitempty"`
	Fields    []Field `json:"fields,omitempty"`
	Timestamp int64   `json:"ts,omitempty"`
}

// Field represents a Slack attachment field
type Field struct {
	Title string `json:"title"`
	Value string `json:"value"`
	Short bool   `json:"short"`
}

// AlertStats holds statistics about alerts
type AlertStats struct {
	TotalAlerts      int            `json:"total_alerts"`
	AlertsByType     map[string]int `json:"alerts_by_type"`
	AlertsBySeverity map[string]int `json:"alerts_by_severity"`
	RecentAlerts     []Alert        `json:"recent_alerts"`
	LastAlert        *time.Time     `json:"last_alert,omitempty"`
	EmailsSent       int            `json:"emails_sent"`
	SlacksSent       int            `json:"slacks_sent"`
	FailedDeliveries int            `json:"failed_deliveries"`
}

// NewAlertManager creates a new alert manager
func NewAlertManager(config *AlertConfig, logger *log.Logger) *AlertManager {
	am := &AlertManager{
		config:       config,
		alertHistory: make([]Alert, 0),
		logger:       logger,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}

	if config.EmailEnabled {
		am.emailSender = &EmailSender{
			config: config,
			logger: logger,
		}
	}

	if config.SlackEnabled {
		am.slackWebhook = config.SlackWebhookURL
	}

	return am
}

// SendAlert sends an alert through all configured channels
func (am *AlertManager) SendAlert(alert Alert) error {
	am.mutex.Lock()
	defer am.mutex.Unlock()

	// Check rate limiting
	if !am.isWithinRateLimit() {
		am.logger.Printf("⚠️ Alert rate limit exceeded, dropping alert: %s", alert.ID)
		return fmt.Errorf("rate limit exceeded")
	}

	// Add to history
	am.addToHistory(alert)

	var errors []error

	// Send email if enabled
	if am.config.EmailEnabled && am.emailSender != nil {
		if err := am.sendEmailAlert(alert); err != nil {
			am.logger.Printf("❌ Failed to send email alert: %v", err)
			errors = append(errors, fmt.Errorf("email: %v", err))
		} else {
			am.logger.Printf("📧 Email alert sent successfully: %s", alert.ID)
		}
	}

	// Send Slack if enabled
	if am.config.SlackEnabled && am.slackWebhook != "" {
		if err := am.sendSlackAlert(alert); err != nil {
			am.logger.Printf("❌ Failed to send Slack alert: %v", err)
			errors = append(errors, fmt.Errorf("slack: %v", err))
		} else {
			am.logger.Printf("💬 Slack alert sent successfully: %s", alert.ID)
		}
	}

	am.logger.Printf("🚨 Alert processed: %s [%s] %s", alert.Severity, alert.Type, alert.Message)

	if len(errors) > 0 {
		return fmt.Errorf("partial failure: %v", errors)
	}

	return nil
}

// sendEmailAlert sends an alert via email
func (am *AlertManager) sendEmailAlert(alert Alert) error {
	if am.emailSender == nil {
		return fmt.Errorf("email sender not configured")
	}

	subject := fmt.Sprintf("[%s] %s Alert - %s",
		alert.Severity, alert.Type, alert.Source)

	body := am.formatEmailBody(alert)

	return am.emailSender.SendEmail(am.config.ToEmails, subject, body)
}

// sendSlackAlert sends an alert via Slack webhook
func (am *AlertManager) sendSlackAlert(alert Alert) error {
	if am.slackWebhook == "" {
		return fmt.Errorf("Slack webhook not configured")
	}

	color := am.getSeverityColor(alert.Severity)
	emoji := am.getSeverityEmoji(alert.Severity)

	message := SlackMessage{
		Channel:   am.config.SlackChannel,
		Username:  am.config.SlackUsername,
		IconEmoji: emoji,
		Attachments: []Attachment{
			{
				Color: color,
				Title: fmt.Sprintf("%s Alert: %s", alert.Severity, alert.Type),
				Text:  alert.Message,
				Fields: []Field{
					{
						Title: "Source",
						Value: alert.Source,
						Short: true,
					},
					{
						Title: "Time",
						Value: alert.Timestamp.Format("2006-01-02 15:04:05"),
						Short: true,
					},
					{
						Title: "Alert ID",
						Value: alert.ID,
						Short: true,
					},
				},
				Timestamp: alert.Timestamp.Unix(),
			},
		},
	}

	// Add details if available
	if len(alert.Details) > 0 {
		for key, value := range alert.Details {
			message.Attachments[0].Fields = append(message.Attachments[0].Fields, Field{
				Title: key,
				Value: fmt.Sprintf("%v", value),
				Short: true,
			})
		}
	}

	payload, err := json.Marshal(message)
	if err != nil {
		return fmt.Errorf("failed to marshal Slack message: %v", err)
	}

	// Send with retry logic
	return am.sendWithRetry(am.slackWebhook, payload, "application/json")
}

// sendWithRetry sends HTTP request with retry logic
func (am *AlertManager) sendWithRetry(url string, payload []byte, contentType string) error {
	var lastErr error

	for attempt := 0; attempt < am.config.RetryAttempts; attempt++ {
		if attempt > 0 {
			time.Sleep(time.Duration(am.config.RetryDelay) * time.Second)
			am.logger.Printf("🔄 Retry attempt %d/%d for alert delivery", attempt+1, am.config.RetryAttempts)
		}

		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewBuffer(payload))
		cancel()

		if err != nil {
			lastErr = err
			continue
		}

		req.Header.Set("Content-Type", contentType)

		resp, err := am.httpClient.Do(req)
		if err != nil {
			lastErr = err
			continue
		}

		resp.Body.Close()

		if resp.StatusCode >= 200 && resp.StatusCode < 300 {
			return nil // Success
		}

		lastErr = fmt.Errorf("HTTP %d: %s", resp.StatusCode, resp.Status)
	}

	return fmt.Errorf("failed after %d attempts: %v", am.config.RetryAttempts, lastErr)
}

// SendEmail sends email using SMTP
func (es *EmailSender) SendEmail(toEmails []string, subject, body string) error {
	if es.config.SMTPHost == "" {
		return fmt.Errorf("SMTP host not configured")
	}

	auth := smtp.PlainAuth("", es.config.SMTPUsername, es.config.SMTPPassword, es.config.SMTPHost)

	msg := fmt.Sprintf("To: %s\r\nSubject: %s\r\nContent-Type: text/html; charset=UTF-8\r\n\r\n%s",
		toEmails[0], subject, body)

	addr := fmt.Sprintf("%s:%d", es.config.SMTPHost, es.config.SMTPPort)

	err := smtp.SendMail(addr, auth, es.config.FromEmail, toEmails, []byte(msg))
	if err != nil {
		return fmt.Errorf("failed to send email: %v", err)
	}

	return nil
}

// formatEmailBody formats the alert for email
func (am *AlertManager) formatEmailBody(alert Alert) string {
	html := fmt.Sprintf(`
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .alert-box { border: 2px solid %s; padding: 15px; border-radius: 5px; background-color: #f9f9f9; }
        .severity { color: %s; font-weight: bold; font-size: 18px; }
        .details { margin-top: 15px; }
        .detail-item { margin: 5px 0; }
        .timestamp { color: #666; font-size: 12px; }
    </style>
</head>
<body>
    <div class="alert-box">
        <h2>🚨 System Alert</h2>
        <p class="severity">Severity: %s</p>
        <p><strong>Type:</strong> %s</p>
        <p><strong>Source:</strong> %s</p>
        <p><strong>Message:</strong> %s</p>
        <p class="timestamp"><strong>Time:</strong> %s</p>
        <p><strong>Alert ID:</strong> %s</p>
`,
		am.getSeverityColor(alert.Severity),
		am.getSeverityColor(alert.Severity),
		alert.Severity,
		alert.Type,
		alert.Source,
		alert.Message,
		alert.Timestamp.Format("2006-01-02 15:04:05 MST"),
		alert.ID,
	)

	if len(alert.Details) > 0 {
		html += `<div class="details"><h3>Details:</h3>`
		for key, value := range alert.Details {
			html += fmt.Sprintf(`<div class="detail-item"><strong>%s:</strong> %v</div>`, key, value)
		}
		html += `</div>`
	}

	html += `
    </div>
</body>
</html>`

	return html
}

// getSeverityColor returns color for severity level
func (am *AlertManager) getSeverityColor(severity string) string {
	switch severity {
	case "critical":
		return "#DC3545" // Red
	case "high":
		return "#FD7E14" // Orange
	case "medium":
		return "#FFC107" // Yellow
	case "low":
		return "#17A2B8" // Blue
	default:
		return "#6C757D" // Gray
	}
}

// getSeverityEmoji returns emoji for severity level
func (am *AlertManager) getSeverityEmoji(severity string) string {
	switch severity {
	case "critical":
		return ":rotating_light:"
	case "high":
		return ":warning:"
	case "medium":
		return ":information_source:"
	case "low":
		return ":blue_circle:"
	default:
		return ":question:"
	}
}

// addToHistory adds alert to history with size management
func (am *AlertManager) addToHistory(alert Alert) {
	am.alertHistory = append(am.alertHistory, alert)

	// Manage history size
	if len(am.alertHistory) > am.config.MaxHistorySize {
		// Keep only the most recent alerts
		copy(am.alertHistory, am.alertHistory[len(am.alertHistory)-am.config.MaxHistorySize:])
		am.alertHistory = am.alertHistory[:am.config.MaxHistorySize]
	}
}

// isWithinRateLimit checks if we're within the rate limit
func (am *AlertManager) isWithinRateLimit() bool {
	if am.config.RateLimitPerHour <= 0 {
		return true // No rate limiting
	}

	now := time.Now()
	oneHourAgo := now.Add(-time.Hour)

	recentAlerts := 0
	for _, alert := range am.alertHistory {
		if alert.Timestamp.After(oneHourAgo) {
			recentAlerts++
		}
	}

	return recentAlerts < am.config.RateLimitPerHour
}

// GetStats returns alert statistics
func (am *AlertManager) GetStats() AlertStats {
	am.mutex.RLock()
	defer am.mutex.RUnlock()

	stats := AlertStats{
		TotalAlerts:      len(am.alertHistory),
		AlertsByType:     make(map[string]int),
		AlertsBySeverity: make(map[string]int),
		RecentAlerts:     make([]Alert, 0),
	}

	// Get recent alerts (last 10)
	start := len(am.alertHistory) - 10
	if start < 0 {
		start = 0
	}
	stats.RecentAlerts = am.alertHistory[start:]

	// Count by type and severity
	for _, alert := range am.alertHistory {
		stats.AlertsByType[alert.Type]++
		stats.AlertsBySeverity[alert.Severity]++

		if stats.LastAlert == nil || alert.Timestamp.After(*stats.LastAlert) {
			stats.LastAlert = &alert.Timestamp
		}
	}

	return stats
}

// GetAlertHistory returns the alert history
func (am *AlertManager) GetAlertHistory(limit int) []Alert {
	am.mutex.RLock()
	defer am.mutex.RUnlock()

	if limit <= 0 || limit > len(am.alertHistory) {
		limit = len(am.alertHistory)
	}

	start := len(am.alertHistory) - limit
	if start < 0 {
		start = 0
	}

	result := make([]Alert, limit)
	copy(result, am.alertHistory[start:])
	return result
}

// ClearHistory clears the alert history
func (am *AlertManager) ClearHistory() {
	am.mutex.Lock()
	defer am.mutex.Unlock()

	am.alertHistory = make([]Alert, 0)
	am.logger.Println("🗑️ Alert history cleared")
}

// TestConnections tests the configured alert channels
func (am *AlertManager) TestConnections() map[string]error {
	results := make(map[string]error)

	// Test email
	if am.config.EmailEnabled {
		testAlert := Alert{
			ID:        "test_email",
			Type:      "test",
			Severity:  "low",
			Message:   "Test email alert",
			Timestamp: time.Now(),
			Source:    "alert_manager_test",
		}

		results["email"] = am.sendEmailAlert(testAlert)
	}

	// Test Slack
	if am.config.SlackEnabled {
		testAlert := Alert{
			ID:        "test_slack",
			Type:      "test",
			Severity:  "low",
			Message:   "Test Slack alert",
			Timestamp: time.Now(),
			Source:    "alert_manager_test",
		}

		results["slack"] = am.sendSlackAlert(testAlert)
	}

	return results
}

// GetRecentAlerts returns recent alerts (used by dashboard and reporting)
func (am *AlertManager) GetRecentAlerts(limit int) []Alert {
	am.mutex.RLock()
	defer am.mutex.RUnlock()

	if limit <= 0 || limit > len(am.alertHistory) {
		limit = len(am.alertHistory)
	}

	// Return the most recent alerts (from the end of the slice)
	start := len(am.alertHistory) - limit
	if start < 0 {
		start = 0
	}

	result := make([]Alert, limit)
	copy(result, am.alertHistory[start:])
	return result
}
