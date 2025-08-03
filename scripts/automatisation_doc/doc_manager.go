// SPDX-License-Identifier: Apache-2.0
// Roo-Code — DocManager
//
// Orchestrateur central Roo de la gestion documentaire : création, coordination, cohérence, extension plugins.
// Injection Roo : MonitoringManager pour la collecte de métriques documentaire (conformité AGENTS.md, plan-dev-v113-autmatisation-doc-roo.md).
//
// Interfaces :
//   - Store(*Document) error
//   - Retrieve(string) (*Document, error)
//   - RegisterPlugin(PluginInterface) error
//
// Extension Roo : chaque opération appelle MonitoringManager.CollectMetrics pour la traçabilité et l’observabilité documentaire.
//
// Fichier généré pour conformité Roo-Code (voir AGENTS.md, plan-dev-v113-autmatisation-doc-roo.md).

package automatisation_doc

import (
	"context"
	"errors"
	"sync"
)

// Document struct Roo minimal (à étendre selon besoins)
type Document struct {
	ID   string
	Data map[string]interface{}
}

type DocManager struct {
	mu                sync.Mutex
	documents         map[string]*Document
	plugins           map[string]PluginInterface
	monitoringManager *MonitoringManager // Injection Roo (pointeur pour test nil)
}

// NewDocManager initialise un DocManager Roo avec injection MonitoringManager (pointeur).
func NewDocManager(monitoring *MonitoringManager) *DocManager {
	return &DocManager{
		documents:         make(map[string]*Document),
		plugins:           make(map[string]PluginInterface),
		monitoringManager: monitoring,
	}
}

// Store ajoute ou met à jour un document Roo, avec traçabilité MonitoringManager.
func (dm *DocManager) Store(doc *Document) error {
	dm.mu.Lock()
	defer dm.mu.Unlock()
	if doc == nil || doc.ID == "" {
		return errors.New("document invalide")
	}
	dm.documents[doc.ID] = doc
	// Extension Roo : collecte de métriques documentaire
	if dm.monitoringManager != nil {
		_, _ = dm.monitoringManager.CollectMetrics(context.Background())
	}
	return nil
}

// Retrieve récupère un document Roo par ID, avec traçabilité MonitoringManager.
func (dm *DocManager) Retrieve(id string) (*Document, error) {
	dm.mu.Lock()
	defer dm.mu.Unlock()
	doc, ok := dm.documents[id]
	if !ok {
		return nil, errors.New("document introuvable")
	}
	// Extension Roo : collecte de métriques documentaire
	if dm.monitoringManager != nil {
		_, _ = dm.monitoringManager.CollectMetrics(context.Background())
	}
	return doc, nil
}

// RegisterPlugin ajoute dynamiquement un plugin Roo.
func (dm *DocManager) RegisterPlugin(plugin PluginInterface) error {
	if plugin == nil {
		return errors.New("plugin invalide")
	}
	dm.mu.Lock()
	defer dm.mu.Unlock()
	dm.plugins[plugin.Name()] = plugin
	return nil
}

// TODO Roo : étendre avec hooks, reporting, rollback, audit documentaire.
