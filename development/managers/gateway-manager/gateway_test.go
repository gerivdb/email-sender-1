package gatewaymanager_test

import (
	"context"
	"fmt"
	"testing"

	gatewaymanager "email_sender/development/managers/gateway-manager"
	"email_sender/internal/core" // Importer les mocks
)

func TestNewGatewayManager(t *testing.T) {
	name := "TestGateway"

	// Créer des mocks
	mockCache := &core.MockCacheManager{}
	mockLWM := &core.MockLWM{}
	mockRAG := &core.MockRAG{}
	mockMemoryBank := &core.MockMemoryBank{}

	gm := gatewaymanager.NewGatewayManager(name, mockCache, mockLWM, mockRAG, mockMemoryBank)

	if gm == nil {
		t.Fatal("NewGatewayManager returned nil")
	}

	if gm.Name != name {
		t.Errorf("Expected GatewayManager name to be %s, got %s", name, gm.Name)
	}

	// Vérifier que les mocks sont bien assignés
	if gm.CacheManager == nil || gm.LWM == nil || gm.RAG == nil || gm.MemoryBank == nil {
		t.Error("One or more mock dependencies are nil")
	}
}

func TestGatewayManagerStart(t *testing.T) {
	name := "TestGateway"

	// Créer des mocks
	mockCache := &core.MockCacheManager{}
	mockLWM := &core.MockLWM{}
	mockRAG := &core.MockRAG{}
	mockMemoryBank := &core.MockMemoryBank{}

	gm := gatewaymanager.NewGatewayManager(name, mockCache, mockLWM, mockRAG, mockMemoryBank)

	defer func() {
		if r := recover(); r != nil {
			t.Errorf("Start method panicked: %v", r)
		}
	}()
	gm.Start()
}

func TestGatewayManagerProcessRequest(t *testing.T) {
	name := "TestGateway"

	// Créer des mocks
	mockCache := &core.MockCacheManager{}
	mockLWM := &core.MockLWM{}
	mockRAG := &core.MockRAG{}
	mockMemoryBank := &core.MockMemoryBank{}

	gm := gatewaymanager.NewGatewayManager(name, mockCache, mockLWM, mockRAG, mockMemoryBank)

	ctx := context.Background()
	requestID := "req-123"
	data := map[string]interface{}{"key": "value"}

	response, err := gm.ProcessRequest(ctx, requestID, data)
	if err != nil {
		t.Errorf("ProcessRequest returned an error: %v", err)
	}

	expectedResponse := fmt.Sprintf("Réponse pour la requête %s", requestID)
	if response != expectedResponse {
		t.Errorf("Expected response %s, got %s", expectedResponse, response)
	}
	// Dans un vrai test, on vérifierait que les méthodes des mocks ont été appelées
}
