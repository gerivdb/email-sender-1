package logging

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

// ELKExporter exporte les logs structurés vers Elasticsearch
type ELKExporter struct {
	ElasticsearchURL string
	IndexName        string
	HTTPClient       *http.Client
}

// NewELKExporter crée un exporter ELK
func NewELKExporter(url, index string) *ELKExporter {
	return &ELKExporter{
		ElasticsearchURL: url,
		IndexName:        index,
		HTTPClient:       &http.Client{Timeout: 5 * time.Second},
	}
}

// LogEntry structure d'un log exporté
type LogEntry struct {
	Timestamp     time.Time              `json:"@timestamp"`
	Level         string                 `json:"level"`
	Message       string                 `json:"message"`
	Source        string                 `json:"source"`
	TraceID       string                 `json:"trace_id,omitempty"`
	CorrelationID string                 `json:"correlation_id,omitempty"`
	Fields        map[string]interface{} `json:"fields,omitempty"`
}

// Export envoie un log à Elasticsearch
func (e *ELKExporter) Export(ctx context.Context, entry *LogEntry) error {
	entry.Timestamp = time.Now()
	data, err := json.Marshal(entry)
	if err != nil {
		return err
	}
	url := fmt.Sprintf("%s/%s/_doc", e.ElasticsearchURL, e.IndexName)
	req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewReader(data))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	resp, err := e.HTTPClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 300 {
		return fmt.Errorf("ELK export failed: %s", resp.Status)
	}
	return nil
}

// Example usage:
/*
func main() {
elk := logging.NewELKExporter("http://localhost:9200", "go-logs")
elk.Export(context.Background(), &logging.LogEntry{
Level: "info",
Message: "Job completed",
Source: "queue",
TraceID: "trace-abc",
Fields: map[string]interface{}{"job_id": "123"},
})
}
*/
