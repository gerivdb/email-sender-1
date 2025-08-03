/*
pipeline_manager.go
Implémentation Roo du PipelineManager pour l’automatisation documentaire
Pattern manager/agent Roo-Code, extensible dynamiquement via PluginInterface Roo.

Phase 3 plan v113 Roo — Intégration complète PluginInterface :
- Registre dynamique de plugins (ajout/suppression/listing)
- Hooks d’extension (avant/après étape, validation, log, etc.)
- Exemples d’utilisation : plugin de log, plugin de validation (voir stubs plus bas)
- Traçabilité documentaire Roo (cf. AGENTS.md, rules-plugins.md, plan-dev-v113-autmatisation-doc-roo.md)
*/

package automatisation_doc

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"

	/*
		PluginInterface Roo : interface d’extension dynamique pour PipelineManager.
		Chaque plugin doit implémenter :
		- Name() string
		- Execute(ctx context.Context, params map[string]interface{}) error
		- (Optionnel) Hooks d’extension : BeforeStep, AfterStep, ValidateStep, LogStep, etc.
		Voir stubs d’exemple plus bas.
	*/

	"gopkg.in/yaml.v3"
)

// PipelineStep représente une étape du pipeline
type PipelineStep struct {
	Name      string                 `yaml:"name"`
	Type      string                 `yaml:"type"`
	Params    map[string]interface{} `yaml:"params,omitempty"`
	DependsOn []string               `yaml:"depends_on,omitempty"`
	Plugin    string                 `yaml:"plugin,omitempty"`
}

// PipelineMetadata pour les métadonnées additionnelles
type PipelineMetadata struct {
	Author    string    `yaml:"author,omitempty"`
	CreatedAt time.Time `yaml:"created_at,omitempty"`
	Tags      []string  `yaml:"tags,omitempty"`
}

// Pipeline définit la structure d’un pipeline Roo
type Pipeline struct {
	PipelineID  string           `yaml:"pipeline_id"`
	Description string           `yaml:"description,omitempty"`
	Steps       []PipelineStep   `yaml:"steps"`
	Metadata    PipelineMetadata `yaml:"metadata,omitempty"`
}

/*
PipelineManager gère l’orchestration, la validation et l’exécution du pipeline Roo.
Points d’extension PluginInterface Roo :
- Registre dynamique de plugins (ajout, suppression, listing)
- Hooks d’extension (BeforeStep, AfterStep, ValidateStep, LogStep)
- Traçabilité Roo (cf. AGENTS.md, rules-plugins.md)
*/
type PipelineManager struct {
	Pipeline     *Pipeline
	Plugins      map[string]PluginInterface
	ErrorLog     []error
	ErrorManager ErrorManagerInterface // Injection Roo pour gestion d’erreur centralisée
	LogDir       string                // Répertoire de logs JSON (pour tests)
	ReportDir    string                // Répertoire de rapports Markdown (pour tests)
	mu           sync.Mutex
}

/*
NewPipelineManager crée un PipelineManager à partir d’un YAML Roo.
Injection possible d’un ErrorManager Roo pour la traçabilité des erreurs.
*/
func NewPipelineManager(yamlData []byte, plugins []PluginInterface, errManager ErrorManagerInterface) (*PipelineManager, error) {
	var pipeline Pipeline
	if err := yaml.Unmarshal(yamlData, &pipeline); err != nil {
		return nil, fmt.Errorf("erreur de parsing YAML: %w", err)
	}
	if err := validatePipeline(&pipeline); err != nil {
		return nil, fmt.Errorf("pipeline invalide: %w", err)
	}
	pluginMap := make(map[string]PluginInterface)
	for _, p := range plugins {
		pluginMap[p.Name()] = p
	}
	return &PipelineManager{
		Pipeline:     &pipeline,
		Plugins:      pluginMap,
		ErrorLog:     []error{},
		ErrorManager: errManager,
		LogDir:       "", // Par défaut, utilise pipeline_logs
		ReportDir:    "", // Par défaut, utilise pipeline_reports
	}, nil
}

// LoadPipeline charge dynamiquement un pipeline Roo à partir d’un YAML (traçabilité Roo)
// Peut être utilisé pour recharger ou remplacer le pipeline courant.
func (pm *PipelineManager) LoadPipeline(yamlData []byte) error {
	pm.mu.Lock()
	defer pm.mu.Unlock()
	var pipeline Pipeline
	if err := yaml.Unmarshal(yamlData, &pipeline); err != nil {
		pm.LogError(fmt.Errorf("erreur parsing YAML: %w", err))
		return err
	}
	if err := validatePipeline(&pipeline); err != nil {
		pm.LogError(fmt.Errorf("pipeline invalide: %w", err))
		return err
	}
	pm.Pipeline = &pipeline
	return nil
}

// validatePipeline vérifie la structure Roo et les contraintes du pipeline
func validatePipeline(p *Pipeline) error {
	if p.PipelineID == "" {
		return errors.New("pipeline_id requis")
	}
	stepNames := make(map[string]bool)
	for _, step := range p.Steps {
		if step.Name == "" {
			return errors.New("chaque étape doit avoir un nom")
		}
		if stepNames[step.Name] {
			return fmt.Errorf("nom d’étape dupliqué: %s", step.Name)
		}
		stepNames[step.Name] = true
	}
	// Vérification DAG acyclique
	if hasCycle(p.Steps) {
		return errors.New("le pipeline contient un cycle de dépendances")
	}
	return nil
}

// hasCycle détecte les cycles dans le DAG des étapes
func hasCycle(steps []PipelineStep) bool {
	graph := make(map[string][]string)
	for _, step := range steps {
		graph[step.Name] = step.DependsOn
	}
	visited := make(map[string]bool)
	recStack := make(map[string]bool)
	var visit func(string) bool
	visit = func(node string) bool {
		if recStack[node] {
			return true
		}
		if visited[node] {
			return false
		}
		visited[node] = true
		recStack[node] = true
		for _, dep := range graph[node] {
			if visit(dep) {
				return true
			}
		}
		recStack[node] = false
		return false
	}
	for name := range graph {
		if visit(name) {
			return true
		}
	}
	return false
}

/*
RegisterPlugin ajoute dynamiquement un plugin au manager.
Traçabilité Roo : phase 3 plan v113, pattern extensible.
*/
func (pm *PipelineManager) RegisterPlugin(plugin PluginInterface) {
	pm.mu.Lock()
	defer pm.mu.Unlock()
	pm.Plugins[plugin.Name()] = plugin
}

/*
UnregisterPlugin retire dynamiquement un plugin du manager.
*/
func (pm *PipelineManager) UnregisterPlugin(name string) {
	pm.mu.Lock()
	defer pm.mu.Unlock()
	delete(pm.Plugins, name)
}

/*
ListPlugins retourne la liste des plugins enregistrés.
*/
func (pm *PipelineManager) ListPlugins() []string {
	pm.mu.Lock()
	defer pm.mu.Unlock()
	names := make([]string, 0, len(pm.Plugins))
	for name := range pm.Plugins {
		names = append(names, name)
	}
	return names
}

/*
Execute exécute le pipeline complet en respectant les dépendances.
À chaque exécution, un log JSON détaillé et un rapport Markdown synthétique sont générés et archivés (cf. phase 3 plan v113 Roo).
Traçabilité Roo : logs dans pipeline_logs/, rapports dans pipeline_reports/, rotation par timestamp.
*/
func (pm *PipelineManager) Execute(ctx context.Context) error {
	executed := make(map[string]bool)
	var stepLogs []PipelineStepLog
	var pipelineStatus string = "success"
	var pipelineError string = ""
	startTime := time.Now()

	for len(executed) < len(pm.Pipeline.Steps) {
		progress := false
		for _, step := range pm.Pipeline.Steps {
			if executed[step.Name] {
				continue
			}
			ready := true
			for _, dep := range step.DependsOn {
				if !executed[dep] {
					ready = false
					break
				}
			}
			if ready {
				stepStart := time.Now()
				err := pm.executeStep(ctx, &step)
				stepEnd := time.Now()
				stepLog := PipelineStepLog{
					Name:      step.Name,
					Type:      step.Type,
					Plugin:    step.Plugin,
					StartedAt: stepStart.Format(time.RFC3339),
					EndedAt:   stepEnd.Format(time.RFC3339),
					Status:    "success",
					Error:     "",
				}
				if err != nil {
					pm.LogError(fmt.Errorf("erreur étape %s: %w", step.Name, err))
					stepLog.Status = "error"
					stepLog.Error = err.Error()
					pipelineStatus = "error"
					pipelineError = fmt.Sprintf("erreur étape %s: %s", step.Name, err.Error())
					stepLogs = append(stepLogs, stepLog)
					pm.archivePipelineLogsAndReport(startTime, stepLogs, pipelineStatus, pipelineError)
					return err
				}
				executed[step.Name] = true
				progress = true
				stepLogs = append(stepLogs, stepLog)
			}
		}
		if !progress {
			pipelineStatus = "error"
			pipelineError = "impossible de progresser: dépendances non résolues ou cycle détecté"
			pm.archivePipelineLogsAndReport(startTime, stepLogs, pipelineStatus, pipelineError)
			return errors.New(pipelineError)
		}
	}
	pm.archivePipelineLogsAndReport(startTime, stepLogs, pipelineStatus, pipelineError)
	return nil
}

// executeStep exécute une étape individuelle (supporte plugins)
func (pm *PipelineManager) executeStep(ctx context.Context, step *PipelineStep) error {
	if step.Type == "plugin" {
		plugin, ok := pm.Plugins[step.Plugin]
		if !ok {
			return fmt.Errorf("plugin non trouvé: %s", step.Plugin)
		}
		return plugin.Execute(ctx, step.Params)
	}
	// Implémentations natives Roo (extraction, transformation, validation, export)
	switch step.Type {
	case "extraction":
		// TODO: Implémenter extraction Roo
		return nil
	case "transformation":
		// TODO: Implémenter transformation Roo
		return nil
	case "validation":
		// TODO: Implémenter validation Roo
		return nil
	case "export":
		// TODO: Implémenter export Roo
		return nil
	default:
		return fmt.Errorf("type d’étape inconnu: %s", step.Type)
	}
}

// LogError centralise la gestion des erreurs Roo : log local + délégation ErrorManager si présent
func (pm *PipelineManager) LogError(err error) {
	pm.mu.Lock()
	defer pm.mu.Unlock()
	pm.ErrorLog = append(pm.ErrorLog, err)
	if pm.ErrorManager != nil {
		_ = pm.ErrorManager.ProcessError(context.Background(), err, "PipelineManager", "pipeline", nil)
	}
}

/*
Rollback annule l’exécution ou l’état du pipeline à un point antérieur.
Traçabilité Roo : stub, à compléter selon la logique de rollback documentaire.
*/
func (pm *PipelineManager) Rollback(ctx context.Context, id string) error {
	// TODO Roo: implémenter rollback documentaire (cf. pipeline_manager_rollback.md)
	pm.LogError(fmt.Errorf("rollback non implémenté (id=%s)", id))
	return errors.New("rollback non implémenté")
}

/*
Report génère un rapport d’exécution ou d’état du pipeline.
Traçabilité Roo : stub, à compléter selon la logique de reporting documentaire.
*/
func (pm *PipelineManager) Report(ctx context.Context, id string) (*PipelineReport, error) {
	// TODO Roo: implémenter reporting documentaire (cf. pipeline_manager_report.md)
	pm.LogError(fmt.Errorf("report non implémenté (id=%s)", id))
	return nil, errors.New("report non implémenté")
}

// GetErrorLog retourne l’historique des erreurs
func (pm *PipelineManager) GetErrorLog() []error {
	pm.mu.Lock()
	defer pm.mu.Unlock()
	return append([]error{}, pm.ErrorLog...)
}

/*
PipelineStepLog structure pour journaliser chaque étape du pipeline (cf. phase 3 plan v113 Roo).
*/
type PipelineStepLog struct {
	Name      string `json:"name"`
	Type      string `json:"type"`
	Plugin    string `json:"plugin,omitempty"`
	StartedAt string `json:"started_at"`
	EndedAt   string `json:"ended_at"`
	Status    string `json:"status"` // success | error
	Error     string `json:"error,omitempty"`
}

/*
archivePipelineLogsAndReport génère et archive les logs JSON et le rapport Markdown à chaque exécution du pipeline.
- pipeline_logs/pipeline_logs-YYYYMMDD-HHMMSS.json
- pipeline_reports/pipeline_report-YYYYMMDD-HHMMSS.md
Traçabilité Roo : cf. plan-dev-v113-autmatisation-doc-roo.md, AGENTS.md.
*/
func (pm *PipelineManager) archivePipelineLogsAndReport(startTime time.Time, steps []PipelineStepLog, status, pipelineError string) {
	timestamp := startTime.Format("20060102-150405")
	logDir := pm.LogDir
	if logDir == "" {
		logDir = "pipeline_logs"
	}
	reportDir := pm.ReportDir
	if reportDir == "" {
		reportDir = "pipeline_reports"
	}
	_ = os.MkdirAll(logDir, 0o755)
	_ = os.MkdirAll(reportDir, 0o755)

	// Génération du log JSON détaillé (naming Roo: <pipeline_id>-<timestamp>.json)
	logFile := filepath.Join(logDir, fmt.Sprintf("%s-%s.json", pm.Pipeline.PipelineID, timestamp))
	logData := map[string]interface{}{
		"pipeline_id": pm.Pipeline.PipelineID,
		"description": pm.Pipeline.Description,
		"started_at":  startTime.Format(time.RFC3339),
		"ended_at":    time.Now().Format(time.RFC3339),
		"status":      status,
		"error":       pipelineError,
		"steps":       steps,
		"timestamp":   time.Now().Format(time.RFC3339),
		"roo_trace":   "", // stub Roo
	}
	// Ajout du champ "errors" si status=error
	if status == "error" && len(pm.ErrorLog) > 0 {
		var errs []string
		for _, e := range pm.ErrorLog {
			errs = append(errs, e.Error())
		}
		logData["errors"] = errs
	}
	b, _ := json.MarshalIndent(logData, "", "  ")
	_ = os.WriteFile(logFile, b, 0o644)

	// Génération du rapport Markdown synthétique (naming Roo: <pipeline_id>-<timestamp>.md)
	reportFile := filepath.Join(reportDir, fmt.Sprintf("%s-%s.md", pm.Pipeline.PipelineID, timestamp))
	md := pm.generateMarkdownReport(startTime, steps, status, pipelineError)
	_ = os.WriteFile(reportFile, []byte(md), 0o644)
}

/*
generateMarkdownReport produit un rapport Markdown synthétique d’exécution du pipeline.
Traçabilité Roo : cf. pipeline_manager_report.md.
*/
func (pm *PipelineManager) generateMarkdownReport(startTime time.Time, steps []PipelineStepLog, status, pipelineError string) string {
	md := fmt.Sprintf("# Rapport d’exécution du pipeline `%s`\n\n", pm.Pipeline.PipelineID)
	md += fmt.Sprintf("- **Description** : %s\n", pm.Pipeline.Description)
	md += fmt.Sprintf("- **Début** : %s\n", startTime.Format(time.RFC3339))
	md += fmt.Sprintf("- **Fin** : %s\n", time.Now().Format(time.RFC3339))
	md += fmt.Sprintf("- **Statut global** : %s\n", status)
	if pipelineError != "" {
		md += fmt.Sprintf("- **Erreur** : `%s`\n", pipelineError)
	}
	md += "\n## Détail des étapes\n\n"
	md += "| Étape | Type | Début | Fin | Statut | Erreur |\n"
	md += "|-------|------|-------|-----|--------|--------|\n"
	for _, s := range steps {
		md += fmt.Sprintf("| %s | %s | %s | %s | %s | %s |\n",
			s.Name, s.Type, s.StartedAt, s.EndedAt, s.Status, s.Error)
	}
	return md
}

// --- Interfaces Roo pour ErrorManager et PipelineReport (stubs pour intégration Roo) ---

// ErrorManagerInterface Roo : interface minimale pour injection (cf. AGENTS.md)
type ErrorManagerInterface interface {
	ProcessError(ctx context.Context, err error, component, operation string, hooks interface{}) error
}

// PipelineReport Roo : stub pour reporting documentaire
type PipelineReport struct {
	// TODO Roo: structurer le rapport selon pipeline_manager_report.md
}
