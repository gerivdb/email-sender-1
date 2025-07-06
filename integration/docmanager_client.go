package integration

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"time"
)

// DocManagerClient est une interface pour interagir avec l'API du Doc Manager.
type DocManagerClient interface {
	Authenticate(username, password string) (string, error)
	SyncDocs(sourcePath string, forceUpdate bool) (string, error)
	UpdateDoc(docID string, content map[string]interface{}) (string, error)
}

// httpClient implémente DocManagerClient en utilisant des requêtes HTTP.
type httpClient struct {
	baseURL string
	token   string
	client  *http.Client
}

// NewDocManagerClient crée une nouvelle instance de DocManagerClient.
func NewDocManagerClient(baseURL string) DocManagerClient {
	return &httpClient{
		baseURL: baseURL,
		client: &http.Client{
			Timeout: 10 * time.Second,
		},
	}
}

// Authenticate gère l'authentification et récupère un jeton.
func (c *httpClient) Authenticate(username, password string) (string, error) {
	authPayload := map[string]string{
		"username": username,
		"password": password,
	}
	body, err := json.Marshal(authPayload)
	if err != nil {
		return "", fmt.Errorf("erreur lors de la sérialisation de l'authentification: %w", err)
	}

	resp, err := c.client.Post(c.baseURL+"/auth/login", "application/json", bytes.NewBuffer(body))
	if err != nil {
		return "", fmt.Errorf("erreur lors de la requête d'authentification: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		respBody, _ := ioutil.ReadAll(resp.Body)
		return "", fmt.Errorf("échec de l'authentification avec le code de statut %d: %s", resp.StatusCode, respBody)
	}

	var result map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return "", fmt.Errorf("erreur lors de la désérialisation de la réponse d'authentification: %w", err)
	}

	token, ok := result["token"].(string)
	if !ok {
		return "", fmt.Errorf("le jeton n'a pas été trouvé dans la réponse d'authentification")
	}
	c.token = token // Stocke le jeton pour les requêtes futures
	return token, nil
}

// SyncDocs déclenche une synchronisation de la documentation.
func (c *httpClient) SyncDocs(sourcePath string, forceUpdate bool) (string, error) {
	syncPayload := map[string]interface{}{
		"source_path":  sourcePath,
		"force_update": forceUpdate,
	}
	body, err := json.Marshal(syncPayload)
	if err != nil {
		return "", fmt.Errorf("erreur lors de la sérialisation de la synchronisation: %w", err)
	}

	req, err := http.NewRequest("POST", c.baseURL+"/docs/sync", bytes.NewBuffer(body))
	if err != nil {
		return "", fmt.Errorf("erreur lors de la création de la requête de synchronisation: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	if c.token != "" {
		req.Header.Set("Authorization", "Bearer "+c.token)
	}

	resp, err := c.client.Do(req)
	if err != nil {
		return "", fmt.Errorf("erreur lors de la requête de synchronisation: %w", err)
	}
	defer resp.Body.Close()

	respBody, _ := ioutil.ReadAll(resp.Body)
	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusAccepted {
		return "", fmt.Errorf("échec de la synchronisation avec le code de statut %d: %s", resp.StatusCode, respBody)
	}

	var result map[string]interface{}
	if err := json.Unmarshal(respBody, &result); err != nil {
		return "", fmt.Errorf("erreur lors de la désérialisation de la réponse de synchronisation: %w", err)
	}

	status, ok := result["status"].(string)
	if !ok {
		return "", fmt.Errorf("le statut n'a pas été trouvé dans la réponse de synchronisation")
	}
	return status, nil
}

// UpdateDoc met à jour un document spécifique.
func (c *httpClient) UpdateDoc(docID string, content map[string]interface{}) (string, error) {
	body, err := json.Marshal(content)
	if err != nil {
		return "", fmt.Errorf("erreur lors de la sérialisation de la mise à jour du document: %w", err)
	}

	req, err := http.NewRequest("PUT", c.baseURL+"/docs/"+docID, bytes.NewBuffer(body))
	if err != nil {
		return "", fmt.Errorf("erreur lors de la création de la requête de mise à jour du document: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	if c.token != "" {
		req.Header.Set("Authorization", "Bearer "+c.token)
	}

	resp, err := c.client.Do(req)
	if err != nil {
		return "", fmt.Errorf("erreur lors de la requête de mise à jour du document: %w", err)
	}
	defer resp.Body.Close()

	respBody, _ := ioutil.ReadAll(resp.Body)
	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("échec de la mise à jour du document avec le code de statut %d: %s", resp.StatusCode, respBody)
	}

	var result map[string]interface{}
	if err := json.Unmarshal(respBody, &result); err != nil {
		return "", fmt.Errorf("erreur lors de la désérialisation de la réponse de mise à jour du document: %w", err)
	}

	status, ok := result["status"].(string)
	if !ok {
		return "", fmt.Errorf("le statut n'a pas été trouvé dans la réponse de mise à jour du document")
	}
	return status, nil
}
