package errormanager

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
)

var qdrantClient *QdrantClient

// QdrantClient represents a Qdrant REST API client
type QdrantClient struct {
	BaseURL    string
	HTTPClient *http.Client
}

// Point represents a vector point in Qdrant
type Point struct {
	ID      interface{}            `json:"id"`
	Vector  []float32              `json:"vector"`
	Payload map[string]interface{} `json:"payload"`
}

// InitializeQdrant initializes the Qdrant client
func InitializeQdrant(endpoint string) error {
	qdrantClient = &QdrantClient{
		BaseURL:    endpoint,
		HTTPClient: &http.Client{},
	}
	return nil
}

// StoreErrorVector stores an error vector in Qdrant
func StoreErrorVector(collection string, vector []float32, payload map[string]interface{}) error {
	if qdrantClient == nil {
		return fmt.Errorf("Qdrant client is not initialized")
	}

	// Create points array for upsert
	points := []Point{
		{
			ID:      fmt.Sprintf("error_%d", len(vector)), // Generate a simple ID
			Vector:  vector,
			Payload: payload,
		},
	}

	// Create request payload
	requestPayload := map[string]interface{}{
		"points": points,
	}

	// Make HTTP request
	return qdrantClient.makeRequest("PUT", fmt.Sprintf("/collections/%s/points", collection), requestPayload, nil)
}

// makeRequest performs HTTP request to Qdrant
func (q *QdrantClient) makeRequest(method, endpoint string, payload interface{}, result interface{}) error {
	var body *bytes.Buffer
	if payload != nil {
		jsonData, err := json.Marshal(payload)
		if err != nil {
			return fmt.Errorf("marshal payload: %w", err)
		}
		body = bytes.NewBuffer(jsonData)
	}

	req, err := http.NewRequest(method, q.BaseURL+endpoint, body)
	if err != nil {
		return fmt.Errorf("create request: %w", err)
	}

	if payload != nil {
		req.Header.Set("Content-Type", "application/json")
	}

	resp, err := q.HTTPClient.Do(req)
	if err != nil {
		return fmt.Errorf("execute request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("request failed with status: %d", resp.StatusCode)
	}

	return nil
}
