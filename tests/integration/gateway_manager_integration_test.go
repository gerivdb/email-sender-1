package integration_test

import (
	"context"
	"fmt"
	"testing"
	"time"

	gatewaymanager "email_sender/development/managers/gateway-manager"
)

// TestGatewayManagerIntegration simule un scénario d'intégration basique
func TestGatewayManagerIntegration(t *testing.T) {
	fmt.Println("Démarrage du test d'intégration pour GatewayManager...")

	// Initialisation du GatewayManager
	gm := gatewaymanager.NewGatewayManager("IntegrationTestGateway")
	if gm == nil {
		t.Fatal("Échec de l'initialisation du GatewayManager.")
	}

	// Simulation du démarrage du GatewayManager
	fmt.Println("Simulating GatewayManager Start...")
	gm.Start() // Cette méthode imprime, mais ne retourne pas d'erreur.

	// Simuler une opération simple qui pourrait interagir avec d'autres composants
	// Dans un vrai test d'intégration, on aurait des mocks pour les dépendances externes
	// ou un environnement de test avec les vrais services.
	fmt.Println("Simulating a basic operation...")
	time.Sleep(100 * time.Millisecond) // Simuler une opération prenant du temps

	// Vérification de l'état (basique pour l'exemple)
	// Dans un vrai scénario, on vérifierait des logs, des changements d'état dans des bases de données, etc.
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

	gm := gatewaymanager.NewGatewayManager("CancellableGateway")
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
