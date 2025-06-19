package audit

import (
	"context"
	"encoding/json"
	"os"
	"sync"
	"time"
)

// AuditEvent représente un événement d'audit
type AuditEvent struct {
	Timestamp     time.Time
	User          string
	Action        string
	Resource      string
	Status        string
	Details       map[string]interface{}
	TraceID       string
	CorrelationID string
}

// AuditLogger gère la journalisation d'audit
type AuditLogger struct {
	file    *os.File
	mu      sync.Mutex
	enabled bool
}

// NewAuditLogger ouvre un fichier d'audit (append)
func NewAuditLogger(filename string, enabled bool) (*AuditLogger, error) {
	if !enabled {
		return &AuditLogger{enabled: false}, nil
	}
	f, err := os.OpenFile(filename, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
	if err != nil {
		return nil, err
	}
	return &AuditLogger{file: f, enabled: true}, nil
}

// Log écrit un événement d'audit
func (al *AuditLogger) Log(ctx context.Context, event *AuditEvent) error {
	if !al.enabled {
		return nil
	}
	al.mu.Lock()
	defer al.mu.Unlock()
	event.Timestamp = time.Now()
	line, err := json.Marshal(event)
	if err != nil {
		return err
	}
	_, err = al.file.Write(append(line, '\n'))
	return err
}

// Close ferme le fichier d'audit
func (al *AuditLogger) Close() error {
	if al.file != nil {
		return al.file.Close()
	}
	return nil
}

// Example usage:
/*
func main() {
auditLog, _ := audit.NewAuditLogger("audit.log", true)
defer auditLog.Close()
auditLog.Log(context.Background(), &audit.AuditEvent{
User: "admin",
Action: "create_job",
Resource: "queue:main",
Status: "success",
Details: map[string]interface{}{"job_id": "123"},
TraceID: "trace-abc",
CorrelationID: "corr-xyz",
})
}
*/
