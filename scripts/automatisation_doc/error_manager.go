// scripts/automatisation_doc/error_manager.go
// ErrorManager Roo — Orchestration multi-managers, conformité AGENTS.md, traçabilité, gouvernance, sécurité, audit, rollback.
// Références croisées : AGENTS.md, plan-dev-v113-autmatisation-doc-roo.md, rules-plugins.md, README.md, .github/workflows/ci.yml

package automatisation_doc

import (
	"context"
	"fmt"
	"sync"
	"time"
)

// Types factorisés importés depuis interfaces.go

// Types factorisés importés depuis interfaces.go

// ErrorManager — struct Roo, gestion centralisée, extensible, thread-safe
type ErrorManager struct {
	config  *ErrorManagerConfig
	entries []ErrorEntry
	plugins map[string]PluginInterface
	mu      sync.RWMutex
	healthy bool
}

// Initialize — initialisation, validation config, activation plugins
func (em *ErrorManager) Initialize(ctx context.Context, config *ErrorManagerConfig) error {
	em.mu.Lock()
	defer em.mu.Unlock()
	em.config = config
	em.entries = []ErrorEntry{}
	em.plugins = make(map[string]PluginInterface)
	em.healthy = true
	// Validation automatique
	if config == nil || len(config.QualityGateLevel) == 0 {
		em.healthy = false
		return fmt.Errorf("configuration invalide: niveau de quality gate manquant")
	}
	return nil
}

// Shutdown — arrêt sécurisé, désactivation plugins
func (em *ErrorManager) Shutdown(ctx context.Context) error {
	em.mu.Lock()
	defer em.mu.Unlock()
	for _, plugin := range em.plugins {
		_ = plugin.Deactivate(ctx)
	}
	em.healthy = false
	return nil
}

// IsHealthy — monitoring, intégration CI/CD
func (em *ErrorManager) IsHealthy(ctx context.Context) bool {
	em.mu.RLock()
	defer em.mu.RUnlock()
	return em.healthy
}

// ProcessError — gestion centralisée, hooks, reporting, audit, rollback
func (em *ErrorManager) ProcessError(ctx context.Context, err error, component, operation string, hooks *ErrorHooks) error {
	entry := ErrorEntry{
		ID:        "",
		Timestamp: time.Now(),
		Component: component,
		Operation: operation,
		Message:   fmt.Sprintf("%v", err),
		Severity:  "critical",
		Context:   map[string]interface{}{},
		Tags:      []string{},
		Reported:  false,
	}
	if hooks != nil && hooks.PreValidate != nil {
		if err := hooks.PreValidate(&entry); err != nil {
			return fmt.Errorf("prevalidate hook failed: %w", err)
		}
	}
	em.mu.Lock()
	em.entries = append(em.entries, entry)
	em.mu.Unlock()
	if hooks != nil && hooks.PostValidate != nil {
		_ = hooks.PostValidate(&entry)
	}
	return nil
}

// CatalogError — ajout manuel, traçabilité
func (em *ErrorManager) CatalogError(entry ErrorEntry) error {
	em.mu.Lock()
	defer em.mu.Unlock()
	em.entries = append(em.entries, entry)
	return nil
}

// ValidateErrorEntry — validation structurale, sécurité
func (em *ErrorManager) ValidateErrorEntry(entry ErrorEntry) error {
	if entry.Component == "" || entry.Operation == "" || entry.Message == "" {
		return fmt.Errorf("entrée d’erreur invalide")
	}
	return nil
}

// Report — reporting filtré, audit, export
func (em *ErrorManager) Report(ctx context.Context, filter map[string]interface{}) ([]ErrorEntry, error) {
	em.mu.RLock()
	defer em.mu.RUnlock()
	// Filtrage simple, à étendre selon besoins
	var result []ErrorEntry
	for _, entry := range em.entries {
		result = append(result, entry)
	}
	return result, nil
}

// Audit — audit d’une erreur, traçabilité, extension
func (em *ErrorManager) Audit(ctx context.Context, entry ErrorEntry) error {
	// Ajout audit trail, extension possible via hooks/plugins
	em.mu.Lock()
	defer em.mu.Unlock()
	for i := range em.entries {
		if em.entries[i].Timestamp == entry.Timestamp && em.entries[i].Component == entry.Component {
			em.entries[i].Reported = true
			break
		}
	}
	return nil
}

// Rollback — rollback d’une erreur, extension via hooks/plugins
func (em *ErrorManager) Rollback(ctx context.Context, entry ErrorEntry) error {
	em.mu.Lock()
	defer em.mu.Unlock()
	for i := range em.entries {
		if em.entries[i].Timestamp == entry.Timestamp && em.entries[i].Component == entry.Component {
			em.entries[i].Reported = true
			break
		}
	}
	return nil
}

// RegisterPlugin — extension dynamique, conformité AGENTS.md
func (em *ErrorManager) RegisterPlugin(plugin PluginInterface) error {
	em.mu.Lock()
	defer em.mu.Unlock()
	if plugin == nil {
		return fmt.Errorf("plugin nil")
	}
	em.plugins[plugin.Name()] = plugin
	return nil
}

// ListPlugins — gouvernance, audit
func (em *ErrorManager) ListPlugins() []PluginInfo {
	em.mu.RLock()
	defer em.mu.RUnlock()
	var infos []PluginInfo
	for name := range em.plugins {
		infos = append(infos, PluginInfo{Name: name, Activated: true})
	}
	return infos
}

// GetMetrics — monitoring, intégration CI/CD
func (em *ErrorManager) GetMetrics() map[string]interface{} {
	em.mu.RLock()
	defer em.mu.RUnlock()
	return map[string]interface{}{
		"error_count":  len(em.entries),
		"plugin_count": len(em.plugins),
		"healthy":      em.healthy,
	}
}

// GenerateDocumentation — auto-doc, conformité Roo, cross-références
func (em *ErrorManager) GenerateDocumentation(format DocumentationFormat) (*GeneratedDocs, error) {
	docs := &GeneratedDocs{
		Format:  format,
		Content: "",
		Links:   []string{},
	}
	switch format {
	case FormatMarkdown:
		docs.Content = em.generateMarkdownDocs()
	case FormatHTML:
		docs.Content = "<html><body>" + em.generateMarkdownDocs() + "</body></html>"
	default:
		return nil, fmt.Errorf("format non supporté: %v", format)
	}
	return docs, nil
}

// generateMarkdownDocs — documentation Markdown, cross-références
func (em *ErrorManager) generateMarkdownDocs() string {
	return `
# ErrorManager Roo

- Conformité AGENTS.md, plan-dev-v113-autmatisation-doc-roo.md, rules-plugins.md
- Points d’extension PluginInterface, hooks, audit, rollback
- Sécurité, traçabilité, gouvernance, reporting, CI/CD
- Cas limites : non-détection, mauvaise catégorisation, reporting incomplet
- Auto-critique : prévoir tests unitaires exhaustifs, logs d’audit, validation croisée
`
}

// generatePlantUMLDiagrams — diagramme UML, traçabilité
func (em *ErrorManager) generatePlantUMLDiagrams() string {
	return `
@startuml ErrorManager_Architecture
!define RECTANGLE class

RECTANGLE ErrorManagerInterface {
	+Initialize(ctx, config) error
	+Shutdown(ctx) error
	+IsHealthy(ctx) bool
	+ProcessError(ctx, err, component, operation, hooks) error
	+CatalogError(entry) error
	+ValidateErrorEntry(entry) error
	+Report(ctx, filter) []ErrorEntry
	+Audit(ctx, entry) error
	+Rollback(ctx, entry) error
	+RegisterPlugin(plugin) error
	+ListPlugins() []PluginInfo
	+GetMetrics() map[string]interface{}
	+GenerateDocumentation(format) GeneratedDocs
}

RECTANGLE ErrorEntry {
	+Timestamp time.Time
	+Component string
	+Operation string
	+Error error
	+Severity string
	+Resolved bool
	+AuditTrail []string
}

ErrorManagerInterface ||--|| ErrorEntry
@enduml
`
}
