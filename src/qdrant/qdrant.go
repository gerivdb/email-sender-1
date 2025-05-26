package qdrant

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

type QdrantClient struct {
	BaseURL    string
	HTTPClient *http.Client
}

type Collection struct {
	Name   string `json:"name"`
	Status string `json:"status"`
}

type Point struct {
	ID      interface{}            `json:"id"`
	Vector  []float32              `json:"vector"`
	Payload map[string]interface{} `json:"payload"`
}

type SearchRequest struct {
	Vector      []float32 `json:"vector"`
	Limit       int       `json:"limit"`
	WithPayload bool      `json:"with_payload"`
}

type SearchResult struct {
	ID      interface{}            `json:"id"`
	Score   float32                `json:"score"`
	Payload map[string]interface{} `json:"payload"`
}

func NewQdrantClient(baseURL string) *QdrantClient {
	return &QdrantClient{
		BaseURL: baseURL,
		HTTPClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

func (q *QdrantClient) HealthCheck() error {
	resp, err := q.HTTPClient.Get(q.BaseURL + "/")
	if err != nil {
		return fmt.Errorf("health check failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("health check failed with status: %d", resp.StatusCode)
	}

	return nil
}

func (q *QdrantClient) CreateCollection(name string, vectorSize int) error {
	payload := map[string]interface{}{
		"vectors": map[string]interface{}{
			"size":     vectorSize,
			"distance": "Cosine",
		},
	}

	return q.makeRequest("PUT", fmt.Sprintf("/collections/%s", name), payload, nil)
}

func (q *QdrantClient) UpsertPoints(collectionName string, points []Point) error {
	payload := map[string]interface{}{
		"points": points,
	}

	return q.makeRequest("PUT", fmt.Sprintf("/collections/%s/points", collectionName), payload, nil)
}

func (q *QdrantClient) Search(collectionName string, req SearchRequest) ([]SearchResult, error) {
	var results []SearchResult
	err := q.makeRequest("POST", fmt.Sprintf("/collections/%s/points/search", collectionName), req, &results)
	return results, err
}

func (q *QdrantClient) makeRequest(method, endpoint string, payload interface{}, result interface{}) error {
	var body io.Reader
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

	if result != nil {
		respBody, err := io.ReadAll(resp.Body)
		if err != nil {
			return fmt.Errorf("read response: %w", err)
		}

		var response map[string]interface{}
		if err := json.Unmarshal(respBody, &response); err != nil {
			return fmt.Errorf("unmarshal response: %w", err)
		}

		if resultData, ok := response["result"]; ok {
			resultJSON, _ := json.Marshal(resultData)
			return json.Unmarshal(resultJSON, result)
		}
	}

	return nil
}
