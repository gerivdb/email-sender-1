// FallbackManager Roo — Gestion centralisée des stratégies de fallback documentaire
package automatisation_doc

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"time"

	"gopkg.in/yaml.v3"
)

// FallbackStrategyType définit les types de fallback supportés
type FallbackStrategyType string

const (
	FallbackRetry      FallbackStrategyType = "retry"
	FallbackAlternate  FallbackStrategyType = "alternate"
	FallbackSkip       FallbackStrategyType = "skip"
	FallbackPluginType FallbackStrategyType = "plugin"
)

// FallbackStrategy représente une stratégie individuelle
type FallbackStrategy struct {
	Type    FallbackStrategyType   `yaml:"type"`
	Config  map[string]interface{} `yaml:"config"`
	Enabled bool                   `yaml:"enabled"`
}

// FallbackConfig structure Roo pour la configuration YAML
type FallbackConfig struct {
	ID          string             `yaml:"id"`
	Name        string             `yaml:"name"`
	Description string             `yaml:"description,omitempty"`
	Strategies  []FallbackStrategy `yaml:"strategies"`
}

/*
FallbackManager centralise la gestion des fallback documentaire.

Convention d’extension Roo — Plugins de fallback personnalisés :
  - Les plugins doivent implémenter PluginInterface (voir interfaces.go).
  - L’enregistrement dynamique se fait via RegisterPlugin(plugin).
  - Lorsqu’une stratégie de type "plugin" est activée dans la séquence de fallback,
    le plugin est appelé via son nom (champ "plugin_name" dans la config YAML).
  - Convention : le plugin peut modifier in-place la map d’entrée (input) pour transmettre un résultat.
    Si le plugin ne modifie pas input, la valeur d’entrée est retournée telle quelle.
  - Le plugin doit être idempotent et thread-safe.
  - La sécurité, la validation et la gestion d’erreur sont à la charge du plugin.
  - Hooks optionnels (BeforeStep, AfterStep, OnError) ne sont pas utilisés par FallbackManager mais peuvent l’être par d’autres managers Roo.

Exemple d’enregistrement :

	fm.RegisterPlugin(&MyFallbackPlugin{})

Exemple d’appel YAML :
  - type: plugin
    enabled: true
    config:
    plugin_name: "MyFallbackPlugin"
*/
type FallbackManager struct {
	mu      sync.RWMutex
	config  FallbackConfig
	plugins map[string]PluginInterface
}

// NewFallbackManager charge une config YAML Roo et initialise le manager
func NewFallbackManager(yamlData []byte) (*FallbackManager, error) {
	var cfg FallbackConfig
	if err := yaml.Unmarshal(yamlData, &cfg); err != nil {
		return nil, fmt.Errorf("échec parsing YAML fallback: %w", err)
	}
	if len(cfg.Strategies) == 0 {
		return nil, errors.New("aucune stratégie de fallback définie")
	}
	return &FallbackManager{
		config:  cfg,
		plugins: make(map[string]PluginInterface),
	}, nil
}

// RegisterPlugin permet d’ajouter dynamiquement un plugin de fallback
func (fm *FallbackManager) RegisterPlugin(plugin PluginInterface) error {
	fm.mu.Lock()
	defer fm.mu.Unlock()
	if plugin == nil || plugin.Name() == "" {
		return errors.New("plugin invalide")
	}
	fm.plugins[plugin.Name()] = plugin
	return nil
}

// ApplyFallback applique la séquence de fallback sur une opération documentaire
func (fm *FallbackManager) ApplyFallback(ctx context.Context, input map[string]interface{}) (map[string]interface{}, error) {
	var lastErr error
	for _, strat := range fm.config.Strategies {
		if !strat.Enabled {
			continue
		}
		switch strat.Type {
		case FallbackRetry:
			max, _ := strat.Config["max_attempts"].(int)
			delay, _ := strat.Config["delay_ms"].(int)
			for i := 0; i < max; i++ {
				result, err := fm.tryOperation(ctx, input)
				if err == nil {
					return result, nil
				}
				lastErr = err
				// Simuler un délai (omission réelle pour testabilité)
				_ = delay
			}
		case FallbackAlternate:
			alt, _ := strat.Config["alternate_source"].(string)
			result, err := fm.loadAlternate(ctx, alt)
			if err == nil {
				return result, nil
			}
			lastErr = err
		case FallbackSkip:
			return input, nil
		case FallbackPluginType:
			pluginName, _ := strat.Config["plugin_name"].(string)
			fm.mu.RLock()
			plugin, ok := fm.plugins[pluginName]
			fm.mu.RUnlock()
			if !ok {
				lastErr = fmt.Errorf("plugin %s non trouvé", pluginName)
				continue
			}
			// Convention Roo : le plugin peut modifier in-place la map input pour transmettre un résultat.
			// Si le plugin ne modifie pas input, la valeur d’entrée est retournée telle quelle.
			// Le plugin doit être idempotent et thread-safe.
			_, err := plugin.Execute(ctx, input)
			if err == nil {
				return input, nil
			}
			lastErr = err
		default:
			lastErr = fmt.Errorf("type de stratégie inconnu: %s", strat.Type)
		}
	}
	return nil, fmt.Errorf("échec fallback: %w", lastErr)
}

// tryOperation simule une opération documentaire (à mocker en test)
func (fm *FallbackManager) tryOperation(ctx context.Context, input map[string]interface{}) (map[string]interface{}, error) {
	// À surcharger/mocker selon le contexte
	return nil, errors.New("opération documentaire échouée (simulation)")
}

// loadAlternate simule le chargement d’une source alternative
func (fm *FallbackManager) loadAlternate(ctx context.Context, source string) (map[string]interface{}, error) {
	// À surcharger/mocker selon le contexte
	if source == "" {
		return nil, errors.New("source alternative non définie")
	}
	return map[string]interface{}{"source": source, "status": "alternate"}, nil
}

// --- Handlers Roo pour SmartMergeManager (stratégies fallback-strategies.yaml) ---

// SmartMergeManager centralise les handlers Roo pour chaque stratégie de fallback documentaire.
type SmartMergeManager struct {
	FallbackMgr *FallbackManager
	ErrorMgr    *ErrorManager // Injection du gestionnaire d’erreurs Roo (pointeur pour test != nil)
}

// Handler pour fallback-corruption-detect
// Détecte la corruption documentaire et déclenche la séquence de restauration.
func (sm *SmartMergeManager) HandleCorruptionDetect(ctx context.Context, docID string, meta map[string]interface{}) error {
	// Condition : détection d’une corruption (ex : checksum KO)
	if meta["corruption_detected"] == true {
		// Action : restauration depuis la dernière version saine
		_, err := sm.FallbackMgr.ApplyFallback(ctx, map[string]interface{}{
			"docID":  docID,
			"action": "restore_last_valid",
		})
		if err != nil && sm.ErrorMgr != nil {
			entry := ErrorEntry{
				ID:        docID,
				Timestamp: time.Now(),
				Component: "SmartMergeManager",
				Operation: "HandleCorruptionDetect",
				Message:   err.Error(),
				Details:   meta, // Ajout champ Details pour conformité ErrorEntry
			}
			_ = sm.ErrorMgr.ProcessError(ctx, err, "SmartMergeManager", "HandleCorruptionDetect", nil)
			_ = sm.ErrorMgr.CatalogError(entry)
			_ = sm.ErrorMgr.ValidateErrorEntry(entry)
		}
		return err
	}
	return nil
}

// Handler pour fallback-perte-document
// Gère la perte d’un document (ex : suppression accidentelle, IO error).
func (sm *SmartMergeManager) HandlePerteDocument(ctx context.Context, docID string, meta map[string]interface{}) error {
	// Condition : document absent ou inaccessible
	if meta["missing"] == true {
		// Action : tentative de récupération depuis la sauvegarde
		_, err := sm.FallbackMgr.ApplyFallback(ctx, map[string]interface{}{
			"docID":  docID,
			"action": "restore_from_backup",
		})
		if err != nil && sm.ErrorMgr != nil {
			entry := ErrorEntry{
				ID:        docID,
				Timestamp: time.Now(),
				Component: "SmartMergeManager",
				Operation: "HandlePerteDocument",
				Message:   err.Error(),
				Details:   meta, // Ajout champ Details pour conformité ErrorEntry
			}
			_ = sm.ErrorMgr.ProcessError(ctx, err, "SmartMergeManager", "HandlePerteDocument", nil)
			_ = sm.ErrorMgr.CatalogError(entry)
			_ = sm.ErrorMgr.ValidateErrorEntry(entry)
		}
		return err
	}
	return nil
}

// Handler pour fallback-conflit-fusion
// Résout un conflit de fusion documentaire avancé.
func (sm *SmartMergeManager) HandleConflitFusion(ctx context.Context, docID string, meta map[string]interface{}) error {
	// Condition : conflit détecté lors d’une fusion
	if meta["merge_conflict"] == true {
		// Action : appliquer une stratégie de smart-merge ou fallback manuel
		_, err := sm.FallbackMgr.ApplyFallback(ctx, map[string]interface{}{
			"docID":  docID,
			"action": "smart_merge_or_manual",
		})
		if err != nil && sm.ErrorMgr != nil {
			entry := ErrorEntry{
				ID:        docID,
				Timestamp: time.Now(),
				Component: "SmartMergeManager",
				Operation: "HandleConflitFusion",
				Message:   err.Error(),
				Details:   meta, // Ajout champ Details pour conformité ErrorEntry
			}
			_ = sm.ErrorMgr.ProcessError(ctx, err, "SmartMergeManager", "HandleConflitFusion", nil)
			_ = sm.ErrorMgr.CatalogError(entry)
			_ = sm.ErrorMgr.ValidateErrorEntry(entry)
		}
		return err
	}
	return nil
}

// Handler pour fallback-rollback-critique
// Déclenche un rollback documentaire critique.
func (sm *SmartMergeManager) HandleRollbackCritique(ctx context.Context, docID string, meta map[string]interface{}) error {
	// Condition : échec critique ou validation KO
	if meta["critical_failure"] == true {
		// Action : rollback à l’état antérieur validé
		_, err := sm.FallbackMgr.ApplyFallback(ctx, map[string]interface{}{
			"docID":  docID,
			"action": "rollback_to_previous",
		})
		if err != nil && sm.ErrorMgr != nil {
			entry := ErrorEntry{
				ID:        docID,
				Timestamp: time.Now(),
				Component: "SmartMergeManager",
				Operation: "HandleRollbackCritique",
				Message:   err.Error(),
				Details:   meta, // Ajout champ Details pour conformité ErrorEntry
			}
			_ = sm.ErrorMgr.ProcessError(ctx, err, "SmartMergeManager", "HandleRollbackCritique", nil)
			_ = sm.ErrorMgr.CatalogError(entry)
			_ = sm.ErrorMgr.ValidateErrorEntry(entry)
		}
		return err
	}
	return nil
}

// Handler pour fallback-plugin-failure
// Gère l’échec d’un plugin de fallback documentaire.
func (sm *SmartMergeManager) HandlePluginFailure(ctx context.Context, docID string, meta map[string]interface{}) error {
	// Condition : plugin de fallback en erreur
	if meta["plugin_failure"] == true {
		// Action : désactiver le plugin et appliquer une stratégie alternative
		_, err := sm.FallbackMgr.ApplyFallback(ctx, map[string]interface{}{
			"docID":  docID,
			"action": "disable_plugin_and_alternate",
		})
		return err
	}
	return nil
}
