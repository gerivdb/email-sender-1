package gatewaymanager_test

import (
	"testing"

	gatewaymanager "email_sender/development/managers/gateway-manager"
)

func TestNewGatewayManager(t *testing.T) {
	name := "TestGateway"
	gm := gatewaymanager.NewGatewayManager(name)

	if gm == nil {
		t.Fatal("NewGatewayManager returned nil")
	}

	if gm.Name != name {
		t.Errorf("Expected GatewayManager name to be %s, got %s", name, gm.Name)
	}
}

func TestGatewayManagerStart(t *testing.T) {
	// Comme la méthode Start imprime sur la console, nous allons la tester en vérifiant qu'elle ne panique pas.
	// Pour un test plus robuste, on pourrait rediriger la sortie standard.
	name := "TestGateway"
	gm := gatewaymanager.NewGatewayManager(name)

	// Appeler Start pour s'assurer qu'il n'y a pas d'erreurs d'exécution
	defer func() {
		if r := recover(); r != nil {
			t.Errorf("Start method panicked: %v", r)
		}
	}()
	gm.Start()
}
