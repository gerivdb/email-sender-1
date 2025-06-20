// SPDX-License-Identifier: MIT
// Package docmanager - Plugin Registry for Open/Closed Principle
package docmanager

import (
	"context"
	"fmt"
	"sync"
)

// TASK ATOMIQUE 3.1.2.1 - ManagerType Extensible Interface
// MICRO-TASK 3.1.2.1.2 - Plugin registry implementation

// PluginRegistry registre thread-safe pour les plugins
type PluginRegistry struct {
	plugins map[string]PluginInterface
	mu      sync.RWMutex
}

// NewPluginRegistry crée un nouveau registre de plugins
func NewPluginRegistry() *PluginRegistry {
	return &PluginRegistry{
		plugins: make(map[string]PluginInterface),
		mu:      sync.RWMutex{},
	}
}

// Register enregistre un plugin avec détection de conflits de version
func (pr *PluginRegistry) Register(plugin PluginInterface) error {
	if plugin == nil {
		return fmt.Errorf("plugin cannot be nil")
	}

	name := plugin.Name()
	if name == "" {
		return fmt.Errorf("plugin name cannot be empty")
	}

	pr.mu.Lock()
	defer pr.mu.Unlock()

	// Vérifier si un plugin avec ce nom existe déjà
	if existing, exists := pr.plugins[name]; exists {
		existingVersion := existing.Version()
		newVersion := plugin.Version()

		if existingVersion == newVersion {
			return fmt.Errorf("plugin %s version %s already registered", name, newVersion)
		}

		// Permettre la mise à jour de version
		if err := existing.Shutdown(); err != nil {
			return fmt.Errorf("failed to shutdown existing plugin %s: %w", name, err)
		}
	}

	// Initialiser le nouveau plugin
	if err := plugin.Initialize(); err != nil {
		return fmt.Errorf("failed to initialize plugin %s: %w", name, err)
	}

	pr.plugins[name] = plugin
	return nil
}

// Unregister supprime un plugin du registre
func (pr *PluginRegistry) Unregister(name string) error {
	pr.mu.Lock()
	defer pr.mu.Unlock()

	plugin, exists := pr.plugins[name]
	if !exists {
		return fmt.Errorf("plugin %s not found", name)
	}

	if err := plugin.Shutdown(); err != nil {
		return fmt.Errorf("failed to shutdown plugin %s: %w", name, err)
	}

	delete(pr.plugins, name)
	return nil
}

// GetPlugin récupère un plugin par nom
func (pr *PluginRegistry) GetPlugin(name string) (PluginInterface, error) {
	pr.mu.RLock()
	defer pr.mu.RUnlock()

	plugin, exists := pr.plugins[name]
	if !exists {
		return nil, fmt.Errorf("plugin %s not found", name)
	}

	return plugin, nil
}

// ListPlugins retourne la liste des plugins enregistrés
func (pr *PluginRegistry) ListPlugins() []PluginInfo {
	pr.mu.RLock()
	defer pr.mu.RUnlock()

	infos := make([]PluginInfo, 0, len(pr.plugins))
	for _, plugin := range pr.plugins {
		info := PluginInfo{
			Name:        plugin.Name(),
			Version:     plugin.Version(),
			Description: fmt.Sprintf("Plugin %s v%s", plugin.Name(), plugin.Version()),
			Author:      "Unknown",
			Enabled:     true,
		}
		infos = append(infos, info)
	}

	return infos
}

// ExecutePlugin exécute un plugin avec le contexte donné
func (pr *PluginRegistry) ExecutePlugin(name string, ctx context.Context, input interface{}) (interface{}, error) {
	plugin, err := pr.GetPlugin(name)
	if err != nil {
		return nil, err
	}

	return plugin.Execute(ctx, input)
}

// Count retourne le nombre de plugins enregistrés
func (pr *PluginRegistry) Count() int {
	pr.mu.RLock()
	defer pr.mu.RUnlock()
	return len(pr.plugins)
}

// Clear supprime tous les plugins du registre
func (pr *PluginRegistry) Clear() error {
	pr.mu.Lock()
	defer pr.mu.Unlock()

	var errs []error
	for name, plugin := range pr.plugins {
		if err := plugin.Shutdown(); err != nil {
			errs = append(errs, fmt.Errorf("failed to shutdown plugin %s: %w", name, err))
		}
	}

	pr.plugins = make(map[string]PluginInterface)

	if len(errs) > 0 {
		return fmt.Errorf("errors during clear: %v", errs)
	}

	return nil
}
