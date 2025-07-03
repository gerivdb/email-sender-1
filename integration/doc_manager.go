package integration

import (
	"fmt"
)

// DocManagerClientInterface définit l'interface pour interagir avec le client Doc Manager.
// C'est une interface distincte pour permettre l'injection de dépendances et faciliter les tests.
type DocManagerClientInterface interface {
	SyncDocs(sourcePath string, forceUpdate bool) (string, error)
	UpdateDoc(docID string, content map[string]interface{}) (string, error)
	Authenticate(username, password string) (string, error)
}

// IDocManagerInterface définit l'interface pour interagir avec le gestionnaire de documents.
type IDocManagerInterface interface {
	SyncDocs(sourcePath string, forceUpdate bool) error
	TriggerUpdate(docID string, content map[string]interface{}) error
	Authenticate(username, password string) error
}

// DocManager implémente l'IDocManagerInterface.
type DocManager struct {
	client   DocManagerClientInterface
	baseURL  string
	username string
	password string
}

// NewDocManager crée une nouvelle instance de DocManager.
func NewDocManager(client DocManagerClientInterface, baseURL, username, password string) *DocManager {
	return &DocManager{
		client:   client,
		baseURL:  baseURL,
		username: username,
		password: password,
	}
}

// Authenticate gère l'authentification auprès du Doc Manager.
func (d *DocManager) Authenticate(username, password string) error {
	fmt.Println("Authentification auprès du Doc Manager...")
	_, err := d.client.Authenticate(username, password)
	if err != nil {
		return fmt.Errorf("échec de l'authentification: %w", err)
	}
	fmt.Println("Authentification réussie.")
	return nil
}

// SyncDocs synchronise la documentation.
func (d *DocManager) SyncDocs(sourcePath string, forceUpdate bool) error {
	fmt.Printf("Synchronisation de la documentation depuis %s (forcer la mise à jour: %t)...\n", sourcePath, forceUpdate)
	status, err := d.client.SyncDocs(sourcePath, forceUpdate)
	if err != nil {
		return fmt.Errorf("échec de la synchronisation: %w", err)
	}
	fmt.Printf("Synchronisation terminée avec le statut: %s\n", status)
	return nil
}

// TriggerUpdate déclenche une mise à jour d'un document spécifique dans le doc manager.
func (d *DocManager) TriggerUpdate(docID string, content map[string]interface{}) error {
	fmt.Printf("Déclenchement de la mise à jour du document %s...\n", docID)
	status, err := d.client.UpdateDoc(docID, content)
	if err != nil {
		return fmt.Errorf("échec de la mise à jour du document: %w", err)
	}
	fmt.Printf("Mise à jour du document terminée avec le statut: %s\n", status)
	return nil
}
