// SPDX-License-Identifier: Apache-2.0
// Roo Code — BatchManager
//
// Implémentation du BatchManager Roo : orchestration de lots documentaires, extension dynamique via PluginInterface, gestion des hooks, rollback automatique, centralisation logs/statuts, documentation GoDoc Roo.
//
// Cohérence : Respecte le pattern manager/agent Roo, points d’extension compatibles PipelineManager/DocManager.
// Ce fichier ne modifie ni n’implémente de logique hors du scope BatchManager.

/*
Package automatisation_doc fournit le BatchManager Roo pour l’orchestration des lots documentaires.
*/
package automatisation_doc

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"time"
)

/*
PluginInterface Roo : interface d’extension dynamique importée de [`interfaces.go`](scripts/automatisation_doc/interfaces.go).
Utilisée pour l’extension dynamique des managers Roo (BatchManager, PipelineManager, FallbackManager, etc.).
Les plugins doivent implémenter la méthode Execute(ctx, input) attendue par tous les managers Roo.
*/

// Batch représente un lot documentaire Roo.
type Batch struct {
	ID        string
	Docs      []string // Identifiants ou chemins des documents à traiter
	CreatedAt time.Time
	Meta      map[string]interface{}
}

// BatchResult centralise le statut, logs et reporting d’un lot.
type BatchResult struct {
	BatchID    string
	Success    bool
	Logs       []string
	Error      error
	RolledBack bool
	StartedAt  time.Time
	EndedAt    time.Time
}

// BatchManagerInterface Roo : interface principale du BatchManager.
type BatchManagerInterface interface {
	// RegisterPlugin enregistre dynamiquement un plugin Roo.
	RegisterPlugin(plugin PluginInterface) error
	// ExecuteBatch orchestre l’exécution d’un lot documentaire.
	ExecuteBatch(ctx context.Context, batch *Batch) (*BatchResult, error)
	// RollbackBatch effectue un rollback automatique sur un lot en échec.
	RollbackBatch(ctx context.Context, batch *Batch, reason error) error
	// Report retourne le reporting détaillé d’un lot.
	Report(ctx context.Context, batchID string) (*BatchResult, error)
	// ListPlugins retourne la liste des plugins enregistrés.
	ListPlugins() []string
}

// BatchManager Roo : implémentation du BatchManager Roo.
// Supporte l’extension dynamique via PluginInterface, hooks, rollback automatique, centralisation logs/statuts.
type BatchManager struct {
	mu      sync.RWMutex
	plugins map[string]PluginInterface
	results map[string]*BatchResult
}

// NewBatchManager crée une instance BatchManager Roo.
func NewBatchManager() *BatchManager {
	return &BatchManager{
		plugins: make(map[string]PluginInterface),
		results: make(map[string]*BatchResult),
	}
}

// RegisterPlugin enregistre dynamiquement un plugin Roo.
// Les plugins doivent avoir un nom unique.
func (bm *BatchManager) RegisterPlugin(plugin PluginInterface) error {
	bm.mu.Lock()
	defer bm.mu.Unlock()
	if plugin == nil || plugin.Name() == "" {
		return errors.New("plugin invalide")
	}
	if _, exists := bm.plugins[plugin.Name()]; exists {
		return fmt.Errorf("plugin déjà enregistré : %s", plugin.Name())
	}
	bm.plugins[plugin.Name()] = plugin
	return nil
}

// ListPlugins retourne la liste des plugins enregistrés.
func (bm *BatchManager) ListPlugins() []string {
	bm.mu.RLock()
	defer bm.mu.RUnlock()
	var names []string
	for n := range bm.plugins {
		names = append(names, n)
	}
	return names
}

/*
ExecuteBatch orchestre l’exécution d’un lot documentaire Roo.
Déroulé Roo :
- Appel de tous les plugins via Execute(ctx, batch) (avant exécution principale, pour hooks ou extension).
- Exécution principale du lot (méthode executeBatchLogic).
- Appel de tous les plugins via Execute(ctx, batch) (après exécution principale, pour hooks ou extension).
- Gestion des erreurs : si un plugin ou l’exécution principale échoue, rollback automatique et reporting.
*/
func (bm *BatchManager) ExecuteBatch(ctx context.Context, batch *Batch) (*BatchResult, error) {
	if batch == nil || batch.ID == "" {
		return nil, errors.New("batch invalide")
	}
	result := &BatchResult{
		BatchID:   batch.ID,
		StartedAt: time.Now(),
		Logs:      []string{},
	}
	bm.mu.Lock()
	bm.results[batch.ID] = result
	bm.mu.Unlock()

	// Plugins: hook avant exécution principale (usage Roo: extension, validation, etc.)
	for _, plugin := range bm.getPlugins() {
		if err := plugin.Execute(ctx, batchToMap(batch)); err != nil {
			result.Error = fmt.Errorf("plugin %s (avant lot): %w", plugin.Name(), err)
			result.Logs = append(result.Logs, result.Error.Error())
			bm.handleError(ctx, batch, result, result.Error)
			return result, result.Error
		}
	}

	// Exécution principale du lot (placeholder Roo : à spécialiser selon logique projet)
	execErr := bm.executeBatchLogic(ctx, batch, result)
	if execErr != nil {
		result.Error = execErr
		result.Logs = append(result.Logs, execErr.Error())
		bm.handleError(ctx, batch, result, execErr)
		return result, execErr
	}

	result.Success = true
	result.EndedAt = time.Now()

	// Plugins: hook après exécution principale (usage Roo: reporting, extension, etc.)
	for _, plugin := range bm.getPlugins() {
		if err := plugin.Execute(ctx, batchToMap(batch)); err != nil {
			result.Logs = append(result.Logs, fmt.Sprintf("plugin %s (après lot): %v", plugin.Name(), err))
		}
	}

	return result, nil
}

// executeBatchLogic : logique principale d’exécution d’un lot Roo.
// À spécialiser selon le projet/documentation. Ici, simple simulation.
func (bm *BatchManager) executeBatchLogic(ctx context.Context, batch *Batch, result *BatchResult) error {
	// Simulation Roo : traiter chaque document (succès), peut être remplacé par logique réelle.
	for _, doc := range batch.Docs {
		select {
		case <-ctx.Done():
			return ctx.Err()
		default:
			result.Logs = append(result.Logs, fmt.Sprintf("Traitement doc: %s", doc))
			// Simuler un échec si doc == "fail"
			if doc == "fail" {
				return fmt.Errorf("échec traitement doc: %s", doc)
			}
		}
	}
	return nil
}

// handleError gère l’erreur d’exécution : hooks OnError, rollback automatique, logs.
func (bm *BatchManager) handleError(ctx context.Context, batch *Batch, result *BatchResult, execErr error) {
	// Hooks OnError
	for _, plugin := range bm.getPlugins() {
		if err := plugin.OnError(ctx, batch.ID, batchToMap(batch), execErr); err != nil {
			result.Logs = append(result.Logs, fmt.Sprintf("OnError plugin %s: %v", plugin.Name(), err))
		}
	}
	// Rollback automatique
	if rbErr := bm.RollbackBatch(ctx, batch, execErr); rbErr != nil {
		result.Logs = append(result.Logs, fmt.Sprintf("Rollback error: %v", rbErr))
	}
	result.RolledBack = true
	result.EndedAt = time.Now()
}

/*
RollbackBatch effectue un rollback automatique sur un lot en échec.

Points d’extension Roo :
- Tous les plugins enregistrés sont appelés via le hook RollbackHook(ctx, batchID, batch, reason) pour permettre une reprise personnalisée.
- Chaque rollback centralise les logs des plugins et reporte l’état dans la structure BatchResult.
- Les erreurs de rollback plugin sont journalisées mais n’interrompent pas la procédure globale.

@param ctx    contexte d’exécution Roo
@param batch  lot documentaire à rollbacker
@param reason erreur ayant déclenché le rollback

@return erreur globale (jamais bloquante sur erreur plugin)
*/
func (bm *BatchManager) RollbackBatch(ctx context.Context, batch *Batch, reason error) error {
	bm.mu.Lock()
	defer bm.mu.Unlock()
	if res, ok := bm.results[batch.ID]; ok {
		res.Logs = append(res.Logs, fmt.Sprintf("Rollback lot %s pour cause: %v", batch.ID, reason))
		// Extension Roo : appel du hook RollbackHook sur chaque plugin
		for _, plugin := range bm.plugins {
			if rh, ok := plugin.(interface {
				// RollbackHook permet à un plugin Roo d’intervenir lors d’un rollback automatique.
				// @param ctx contexte Roo, @param batchID identifiant du lot, @param batch map du lot, @param reason erreur d’origine
				// @return erreur éventuelle (journalisée)
				RollbackHook(ctx context.Context, batchID string, batch map[string]interface{}, reason error) error
			}); ok {
				if err := rh.RollbackHook(ctx, batch.ID, batchToMap(batch), reason); err != nil {
					res.Logs = append(res.Logs, fmt.Sprintf("RollbackHook plugin %s: %v", plugin.Name(), err))
				} else {
					res.Logs = append(res.Logs, fmt.Sprintf("RollbackHook plugin %s exécuté", plugin.Name()))
				}
			}
		}
	}
	return nil
}

// Report retourne le reporting détaillé d’un lot Roo.
func (bm *BatchManager) Report(ctx context.Context, batchID string) (*BatchResult, error) {
	bm.mu.RLock()
	defer bm.mu.RUnlock()
	if res, ok := bm.results[batchID]; ok {
		return res, nil
	}
	return nil, fmt.Errorf("aucun reporting pour lot %s", batchID)
}

// getPlugins retourne la liste des plugins enregistrés (thread-safe interne).
func (bm *BatchManager) getPlugins() []PluginInterface {
	bm.mu.RLock()
	defer bm.mu.RUnlock()
	var out []PluginInterface
	for _, p := range bm.plugins {
		out = append(out, p)
	}
	return out
}

// batchToMap convertit un Batch Roo en map[string]interface{} pour compatibilité PluginInterface.
func batchToMap(batch *Batch) map[string]interface{} {
	if batch == nil {
		return nil
	}
	return map[string]interface{}{
		"ID":        batch.ID,
		"Docs":      batch.Docs,
		"CreatedAt": batch.CreatedAt,
		"Meta":      batch.Meta,
	}
}
