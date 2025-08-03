// FallbackManager Roo — Gestion centralisée des stratégies de fallback documentaire
package automatisation_doc

import (
	"context"
	"errors"
	"fmt"
	"sync"

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

// FallbackManager centralise la gestion des fallback documentaire
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
			err := plugin.Execute(ctx, input)
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
