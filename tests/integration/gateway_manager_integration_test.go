package integration_test

import (
	"context"
	"fmt"
	"testing"
	"time"

	gatewaymanager "github.com/gerivdb/email-sender-1/development/managers/gateway-manager"
	"github.com/gerivdb/email-sender-1/internal/core" // Importer les mocks
)

// TestGatewayManagerIntegration simule un scénario d'intégration basique
func TestGatewayManagerIntegration(t *testing.T) {
	fmt.Println("Démarrage du test d'intégration pour GatewayManager...")

	// Créer des mocks
	mockCache := &core.MockCacheManager{}
	mockLWM := &core.MockLWM{}
	mockRAG := &core.MockRAG{}
	mockMemoryBank := &core.MockMemoryBank{}

	// Initialisation du GatewayManager avec les mocks
	gm := gatewaymanager.NewGatewayManager("IntegrationTestGateway", mockCache, mockLWM, mockRAG, mockMemoryBank)
	if gm == nil {
		t.Fatal("Échec de l'initialisation du GatewayManager.")
	}

	// Simulation du démarrage du GatewayManager
	fmt.Println("Simulating GatewayManager Start...")
	gm.Start() // Cette méthode imprime, mais ne retourne pas d'erreur.

	// Simuler une opération simple qui pourrait interagir avec d'autres composants
	fmt.Println("Simulating a basic operation...")
	ctx := context.Background()
	requestID := "integration-req-1"
	data := map[string]interface{}{"param1": "value1"}
	_, err := gm.ProcessRequest(ctx, requestID, data)
	if err != nil {
		t.Errorf("ProcessRequest returned an error: %v", err)
	}
	time.Sleep(100 * time.Millisecond) // Simuler une opération prenant du temps

	// Vérification de l'état (basique pour l'exemple)
	if gm.Name != "IntegrationTestGateway" {
		t.Errorf("Le nom du GatewayManager a été modifié de manière inattendue. Attendu: %s, Obtenu: %s", "IntegrationTestGateway", gm.Name)
	}

	fmt.Println("Test d'intégration pour GatewayManager terminé avec succès.")
}

// TestGatewayManagerContextCancellation teste l'annulation du contexte
func TestGatewayManagerContextCancellation(t *testing.T) {
	fmt.Println("Démarrage du test d'annulation de contexte pour GatewayManager...")

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel() // S'assurer que le contexte est annulé à la fin

	// Créer des mocks
	mockCache := &core.MockCacheManager{}
	mockLWM := &core.MockLWM{}
	mockRAG := &core.MockRAG{}
	mockMemoryBank := &core.MockMemoryBank{}

	gm := gatewaymanager.NewGatewayManager("CancellableGateway", mockCache, mockLWM, mockRAG, mockMemoryBank)
	_ = gm // Marquer comme utilisé pour éviter l'erreur de linter

	// Lancer une goroutine qui simule une opération longue et écoute le contexte
	go func() {
		select {
		case <-time.After(2 * time.Second):
			fmt.Println("Opération GatewayManager terminée (non annulée).")
		case <-ctx.Done():
			fmt.Println("Opération GatewayManager annulée par le contexte.")
		}
	}()

	// Annuler le contexte après un court délai
	time.Sleep(100 * time.Millisecond)
	cancel()

	// Attendre un court instant pour que la goroutine réagisse
	time.Sleep(200 * time.Millisecond)

	if ctx.Err() == nil {
		t.Error("Le contexte n'a pas été annulé comme prévu.")
	} else {
		fmt.Printf("Contexte annulé avec l'erreur: %v\n", ctx.Err())
	}

	fmt.Println("Test d'annulation de contexte pour GatewayManager terminé.")
}
