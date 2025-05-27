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

// Client is an alias for QdrantClient for compatibility
type Client = QdrantClient

type Collection struct {
	Name   string `json:"name"`
	Status string `json:"status"`
}

type CollectionConfig struct {
	VectorSize int    `json:"vector_size"`
	Distance   string `json:"distance"`
}

type CollectionInfo struct {
	Status      string `json:"status"`
	PointsCount int    `json:"points_count"`
	VectorSize  int    `json:"vector_size"`
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

// NewClient is an alias for NewQdrantClient for compatibility
func NewClient(baseURL string) *Client {
	return NewQdrantClient(baseURL)
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

func (q *QdrantClient) CreateCollection(name string, config CollectionConfig) error {
	payload := map[string]interface{}{
		"vectors": map[string]interface{}{
			"size":     config.VectorSize,
			"distance": config.Distance,
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

func (q *QdrantClient) DeleteCollection(name string) error {
	return q.makeRequest("DELETE", fmt.Sprintf("/collections/%s", name), nil, nil)
}

func (q *QdrantClient) GetCollectionInfo(name string) (*CollectionInfo, error) {
	var info CollectionInfo
	err := q.makeRequest("GET", fmt.Sprintf("/collections/%s", name), nil, &info)
	if err != nil {
		return nil, err
	}
	return &info, nil
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
