// SPDX-License-Identifier: MIT
// Mode d’exécution Roo: code
// Module QualityGateManager — Orchestration SOTA des plugins QualityGatePlugin
// Documentation technique et traçabilité : AGENTS.md, rules-plugins.md, plan-dev-v113-autmatisation-doc-roo.md

package automatisation_doc

import (
	"context"
	"errors"
	"fmt"
	"sync"
)

// Interface QualityGatePlugin (déjà référencée dans smart_template.go)
/*
	QualityGatePlugin : interface importée de smart_template.go
	Ne pas redéclarer ici pour éviter les conflits.
*/

// Struct QualityGateManager — manager/agent SOTA
type QualityGateManager struct {
	mu      sync.Mutex
	plugins map[string]QualityGatePlugin
	trace   []string // Traçabilité Roo
}

// Initialisation du manager
func NewQualityGateManager() *QualityGateManager {
	return &QualityGateManager{
		plugins: make(map[string]QualityGatePlugin),
		trace:   []string{},
	}
}

// Enregistrement dynamique d’un plugin QualityGate
func (qm *QualityGateManager) RegisterPlugin(name string, plugin QualityGatePlugin) error {
	qm.mu.Lock()
	defer qm.mu.Unlock()
	if plugin == nil {
		return errors.New("plugin QualityGate nul interdit")
	}
	if _, exists := qm.plugins[name]; exists {
		return fmt.Errorf("plugin déjà enregistré: %s", name)
	}
	qm.plugins[name] = plugin
	qm.trace = append(qm.trace, fmt.Sprintf("RegisterPlugin:%s", name))
	return nil
}

// Désactivation d’un plugin QualityGate
func (qm *QualityGateManager) UnregisterPlugin(name string) error {
	qm.mu.Lock()
	defer qm.mu.Unlock()
	if _, exists := qm.plugins[name]; !exists {
		return fmt.Errorf("plugin non trouvé: %s", name)
	}
	delete(qm.plugins, name)
	qm.trace = append(qm.trace, fmt.Sprintf("UnregisterPlugin:%s", name))
	return nil
}

// Liste des plugins QualityGate actifs
func (qm *QualityGateManager) ListPlugins() []string {
	qm.mu.Lock()
	defer qm.mu.Unlock()
	var names []string
	for name := range qm.plugins {
		names = append(names, name)
	}
	return names
}

// Orchestration séquentielle : vérification de conformité sur tous les plugins
func (qm *QualityGateManager) CheckAllCompliance(ctx context.Context, tpl *GeneratedTemplate) ([]*ValidationReport, error) {
	qm.mu.Lock()
	defer qm.mu.Unlock()
	var reports []*ValidationReport
	for name, plugin := range qm.plugins {
		rep, err := plugin.CheckCompliance(ctx, tpl)
		qm.trace = append(qm.trace, fmt.Sprintf("CheckCompliance:%s", name))
		if err != nil {
			return reports, fmt.Errorf("plugin %s: %w", name, err)
		}
		reports = append(reports, rep)
	}
	return reports, nil
}

// Orchestration séquentielle : exécution des tests sur tous les plugins
func (qm *QualityGateManager) RunAllTests(ctx context.Context, tpl *GeneratedTemplate) ([]*ValidationReport, error) {
	qm.mu.Lock()
	defer qm.mu.Unlock()
	var reports []*ValidationReport
	for name, plugin := range qm.plugins {
		rep, err := plugin.RunTests(ctx, tpl)
		qm.trace = append(qm.trace, fmt.Sprintf("RunTests:%s", name))
		if err != nil {
			return reports, fmt.Errorf("plugin %s: %w", name, err)
		}
		reports = append(reports, rep)
	}
	return reports, nil
}

// Traçabilité Roo : accès à l’historique des opérations
func (qm *QualityGateManager) Trace() []string {
	qm.mu.Lock()
	defer qm.mu.Unlock()
	return append([]string{}, qm.trace...)
}

// Documentation technique SOTA
/*
# QualityGateManager — Documentation technique Roo

- Respect du modèle manager/agent, extension dynamique via QualityGatePlugin
- Traçabilité du mode d’exécution (champ trace, méthodes Trace)
- Orchestration séquentielle des plugins, gestion centralisée des erreurs
- Points d’extension : RegisterPlugin, UnregisterPlugin, ListPlugins, CheckAllCompliance, RunAllTests
- Conformité AGENTS.md, rules-plugins.md, plan-dev-v113-autmatisation-doc-roo.md
- Cas limites : plugin nul, doublon, plugin absent, erreur plugin
- Usage :
    qm := NewQualityGateManager()
    // Enregistrement correct : passer le nom explicite du plugin
    qm.RegisterPlugin("nomPlugin", myPlugin)
    reports, err := qm.CheckAllCompliance(ctx, tpl)
    // ...
*/
