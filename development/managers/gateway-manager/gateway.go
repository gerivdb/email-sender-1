package gatewaymanager

import "fmt"

// GatewayManager représente le gestionnaire de passerelle.
type GatewayManager struct {
	Name string
}

// NewGatewayManager crée une nouvelle instance de GatewayManager.
func NewGatewayManager(name string) *GatewayManager {
	return &GatewayManager{Name: name}
}

// Start démarre le gestionnaire de passerelle.
func (gm *GatewayManager) Start() {
	fmt.Printf("GatewayManager %s démarré.\n", gm.Name)
}
