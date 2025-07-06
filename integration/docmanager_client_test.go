package integration

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
)

// MockDocManagerClient est une implémentation mock de DocManagerClient pour les tests.
type MockDocManagerClient struct {
	AuthenticateFunc func(username, password string) (string, error)
	SyncDocsFunc     func(sourcePath string, forceUpdate bool) (string, error)
	UpdateDocFunc    func(docID string, content map[string]interface{}) (string, error)
}

func (m *MockDocManagerClient) Authenticate(username, password string) (string, error) {
	if m.AuthenticateFunc != nil {
		return m.AuthenticateFunc(username, password)
	}
	return "", fmt.Errorf("Authenticate not implemented")
}

func (m *MockDocManagerClient) SyncDocs(sourcePath string, forceUpdate bool) (string, error) {
	if m.SyncDocsFunc != nil {
		return m.SyncDocsFunc(sourcePath, forceUpdate)
	}
	return "", fmt.Errorf("SyncDocs not implemented")
}

func (m *MockDocManagerClient) UpdateDoc(docID string, content map[string]interface{}) (string, error) {
	if m.UpdateDocFunc != nil {
		return m.UpdateDocFunc(docID, content)
	}
	return "", fmt.Errorf("UpdateDoc not implemented")
}

func TestNewDocManagerClient(t *testing.T) {
	client := NewDocManagerClient("http://localhost:8080")
	if client == nil {
		t.Error("NewDocManagerClient should not return nil")
	}
}

func TestHttpClient_Authenticate_Success(t *testing.T) {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/auth/login" && r.Method == "POST" {
			w.WriteHeader(http.StatusOK)
			_, err := w.Write([]byte(`{"token": "test-token", "expires_in": 3600}`))
			if err != nil {
				t.Fatalf("Failed to write response: %v", err)
			}
		} else {
			w.WriteHeader(http.StatusNotFound)
		}
	}))
	defer ts.Close()

	client := NewDocManagerClient(ts.URL).(*httpClient)
	token, err := client.Authenticate("user", "pass")
	if err != nil {
		t.Fatalf("Authenticate failed: %v", err)
	}
	if token != "test-token" {
		t.Errorf("Expected token 'test-token', got '%s'", token)
	}
	if client.token != "test-token" {
		t.Errorf("Client token not set correctly, expected 'test-token', got '%s'", client.token)
	}
}

func TestHttpClient_Authenticate_Failure(t *testing.T) {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/auth/login" && r.Method == "POST" {
			w.WriteHeader(http.StatusUnauthorized)
			_, err := w.Write([]byte(`{"error": "Invalid credentials"}`))
			if err != nil {
				t.Fatalf("Failed to write response: %v", err)
			}
		} else {
			w.WriteHeader(http.StatusNotFound)
		}
	}))
	defer ts.Close()

	client := NewDocManagerClient(ts.URL)
	_, err := client.Authenticate("user", "wrong-pass")
	if err == nil {
		t.Fatal("Authenticate should have failed")
	}
	expectedErr := "échec de l'authentification avec le code de statut 401: {\"error\": \"Invalid credentials\"}"
	if err.Error() != expectedErr {
		t.Errorf("Expected error '%s', got '%s'", expectedErr, err.Error())
	}
}

func TestHttpClient_SyncDocs_Success(t *testing.T) {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/docs/sync" && r.Method == "POST" {
			w.WriteHeader(http.StatusOK)
			_, err := w.Write([]byte(`{"status": "synchronization_started", "task_id": "sync-123"}`))
			if err != nil {
				t.Fatalf("Failed to write response: %v", err)
			}
		} else {
			w.WriteHeader(http.StatusNotFound)
		}
	}))
	defer ts.Close()

	client := NewDocManagerClient(ts.URL).(*httpClient)
	client.token = "test-token" // Simule un jeton authentifié
	status, err := client.SyncDocs("./docs", false)
	if err != nil {
		t.Fatalf("SyncDocs failed: %v", err)
	}
	if status != "synchronization_started" {
		t.Errorf("Expected status 'synchronization_started', got '%s'", status)
	}
}

func TestHttpClient_SyncDocs_Failure(t *testing.T) {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/docs/sync" && r.Method == "POST" {
			w.WriteHeader(http.StatusInternalServerError)
			_, err := w.Write([]byte(`{"error": "Internal server error"}`))
			if err != nil {
				t.Fatalf("Failed to write response: %v", err)
			}
		} else {
			w.WriteHeader(http.StatusNotFound)
		}
	}))
	defer ts.Close()

	client := NewDocManagerClient(ts.URL).(*httpClient)
	client.token = "test-token"
	_, err := client.SyncDocs("./docs", true)
	if err == nil {
		t.Fatal("SyncDocs should have failed")
	}
	expectedErr := "échec de la synchronisation avec le code de statut 500: {\"error\": \"Internal server error\"}"
	if err.Error() != expectedErr {
		t.Errorf("Expected error '%s', got '%s'", expectedErr, err.Error())
	}
}

func TestHttpClient_UpdateDoc_Success(t *testing.T) {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/docs/doc-123" && r.Method == "PUT" {
			w.WriteHeader(http.StatusOK)
			_, err := w.Write([]byte(`{"status": "document_updated", "doc_id": "doc-123"}`))
			if err != nil {
				t.Fatalf("Failed to write response: %v", err)
			}
		} else {
			w.WriteHeader(http.StatusNotFound)
		}
	}))
	defer ts.Close()

	client := NewDocManagerClient(ts.URL).(*httpClient)
	client.token = "test-token"
	content := map[string]interface{}{"title": "New Title", "content": "Updated content"}
	status, err := client.UpdateDoc("doc-123", content)
	if err != nil {
		t.Fatalf("UpdateDoc failed: %v", err)
	}
	if status != "document_updated" {
		t.Errorf("Expected status 'document_updated', got '%s'", status)
	}
}

func TestHttpClient_UpdateDoc_Failure(t *testing.T) {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/docs/doc-404" && r.Method == "PUT" {
			w.WriteHeader(http.StatusNotFound)
			_, err := w.Write([]byte(`{"error": "Document not found"}`))
			if err != nil {
				t.Fatalf("Failed to write response: %v", err)
			}
		} else {
			w.WriteHeader(http.StatusNotFound)
		}
	}))
	defer ts.Close()

	client := NewDocManagerClient(ts.URL).(*httpClient)
	client.token = "test-token"
	content := map[string]interface{}{"title": "New Title", "content": "Updated content"}
	_, err := client.UpdateDoc("doc-404", content)
	if err == nil {
		t.Fatal("UpdateDoc should have failed")
	}
	expectedErr := "échec de la mise à jour du document avec le code de statut 404: {\"error\": \"Document not found\"}"
	if err.Error() != expectedErr {
		t.Errorf("Expected error '%s', got '%s'", expectedErr, err.Error())
	}
}

func TestDocManager_Authenticate_Success(t *testing.T) {
	mockClient := &MockDocManagerClient{
		AuthenticateFunc: func(username, password string) (string, error) {
			return "mock-token", nil
		},
	}
	manager := NewDocManager(mockClient, "http://localhost:8080", "testuser", "testpass")
	err := manager.Authenticate("testuser", "testpass")
	if err != nil {
		t.Fatalf("Authenticate failed: %v", err)
	}
}

func TestDocManager_Authenticate_Failure(t *testing.T) {
	mockClient := &MockDocManagerClient{
		AuthenticateFunc: func(username, password string) (string, error) {
			return "", fmt.Errorf("mock auth error")
		},
	}
	manager := NewDocManager(mockClient, "http://localhost:8080", "testuser", "testpass")
	err := manager.Authenticate("testuser", "testpass")
	if err == nil {
		t.Fatal("Authenticate should have failed")
	}
	expectedErr := "échec de l'authentification: mock auth error"
	if err.Error() != expectedErr {
		t.Errorf("Expected error '%s', got '%s'", expectedErr, err.Error())
	}
}

func TestDocManager_SyncDocs_Success(t *testing.T) {
	mockClient := &MockDocManagerClient{
		SyncDocsFunc: func(sourcePath string, forceUpdate bool) (string, error) {
			return "mock-status", nil
		},
	}
	manager := NewDocManager(mockClient, "http://localhost:8080", "testuser", "testpass")
	err := manager.SyncDocs("./docs", false)
	if err != nil {
		t.Fatalf("SyncDocs failed: %v", err)
	}
}

func TestDocManager_SyncDocs_Failure(t *testing.T) {
	mockClient := &MockDocManagerClient{
		SyncDocsFunc: func(sourcePath string, forceUpdate bool) (string, error) {
			return "", fmt.Errorf("mock sync error")
		},
	}
	manager := NewDocManager(mockClient, "http://localhost:8080", "testuser", "testpass")
	err := manager.SyncDocs("./docs", true)
	if err == nil {
		t.Fatal("SyncDocs should have failed")
	}
	expectedErr := "échec de la synchronisation: mock sync error"
	if err.Error() != expectedErr {
		t.Errorf("Expected error '%s', got '%s'", expectedErr, err.Error())
	}
}

func TestDocManager_TriggerUpdate_Success(t *testing.T) {
	mockClient := &MockDocManagerClient{
		UpdateDocFunc: func(docID string, content map[string]interface{}) (string, error) {
			return "mock-update-status", nil
		},
	}
	manager := NewDocManager(mockClient, "http://localhost:8080", "testuser", "testpass")
	content := map[string]interface{}{"key": "value"}
	err := manager.TriggerUpdate("doc-id-123", content)
	if err != nil {
		t.Fatalf("TriggerUpdate failed: %v", err)
	}
}

func TestDocManager_TriggerUpdate_Failure(t *testing.T) {
	mockClient := &MockDocManagerClient{
		UpdateDocFunc: func(docID string, content map[string]interface{}) (string, error) {
			return "", fmt.Errorf("mock update error")
		},
	}
	manager := NewDocManager(mockClient, "http://localhost:8080", "testuser", "testpass")
	content := map[string]interface{}{"key": "value"}
	err := manager.TriggerUpdate("doc-id-456", content)
	if err == nil {
		t.Fatal("TriggerUpdate should have failed")
	}
	expectedErr := "échec de la mise à jour du document: mock update error"
	if err.Error() != expectedErr {
		t.Errorf("Expected error '%s', got '%s'", expectedErr, err.Error())
	}
}
