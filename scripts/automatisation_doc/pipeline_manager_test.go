// pipeline_manager_test.go
// Tests unitaires Roo pour PipelineManager (phase 3, pattern 2 v113)

package automatisation_doc

import (
	"context"
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

// MockPlugin pour tester l’intégration plugin
/* Utilise la struct MockPlugin définie dans monitoring_manager_test.go */

/* Utilise les méthodes de MockPlugin définies dans monitoring_manager_test.go */

func TestNewPipelineManager_ValidYAML(t *testing.T) {
	yamlData := []byte(`
pipeline_id: "test_pipeline"
description: "Test pipeline"
steps:
  - name: "step1"
    type: "extraction"
  - name: "step2"
    type: "validation"
    depends_on: ["step1"]
`)
	pm, err := NewPipelineManager(yamlData, nil, nil)
	if err != nil {
		t.Fatalf("Erreur inattendue: %v", err)
	}
	if pm.Pipeline.PipelineID != "test_pipeline" {
		t.Error("pipeline_id incorrect")
	}
}

func TestNewPipelineManager_InvalidYAML(t *testing.T) {
	yamlData := []byte(`pipeline_id: ""`)
	_, err := NewPipelineManager(yamlData, nil, nil)
	if err == nil {
		t.Error("Erreur attendue sur pipeline_id manquant")
	}
}

func TestValidatePipeline_DuplicateStep(t *testing.T) {
	p := &Pipeline{
		PipelineID: "dup",
		Steps: []PipelineStep{
			{Name: "a", Type: "extraction"},
			{Name: "a", Type: "validation"},
		},
	}
	err := validatePipeline(p)
	if err == nil || err.Error() != "nom d’étape dupliqué: a" {
		t.Error("Doit détecter les doublons de nom d’étape")
	}
}

func TestValidatePipeline_Cycle(t *testing.T) {
	p := &Pipeline{
		PipelineID: "cycle",
		Steps: []PipelineStep{
			{Name: "a", Type: "extraction", DependsOn: []string{"b"}},
			{Name: "b", Type: "validation", DependsOn: []string{"a"}},
		},
	}
	err := validatePipeline(p)
	if err == nil || err.Error() != "le pipeline contient un cycle de dépendances" {
		t.Error("Doit détecter les cycles")
	}
}

func TestExecute_SimplePipeline(t *testing.T) {
	yamlData := []byte(`
pipeline_id: "simple"
steps:
  - name: "s1"
    type: "extraction"
  - name: "s2"
    type: "validation"
    depends_on: ["s1"]
`)
	pm, err := NewPipelineManager(yamlData, nil, nil)
	if err != nil {
		t.Fatalf("Erreur parsing: %v", err)
	}
	ctx := context.Background()
	if err := pm.Execute(ctx); err != nil {
		t.Errorf("Exécution échouée: %v", err)
	}
}

func TestExecute_PluginStep(t *testing.T) {
	yamlData := []byte(`
pipeline_id: "plugin"
steps:
  - name: "p"
    type: "plugin"
    plugin: "mock"
`)
	mock := &MockPlugin{name: "mock"}
	pm, err := NewPipelineManager(yamlData, []PluginInterface{mock}, nil)
	if err != nil {
		t.Fatalf("Erreur parsing: %v", err)
	}
	ctx := context.Background()
	if err := pm.Execute(ctx); err != nil {
		t.Errorf("Exécution plugin échouée: %v", err)
	}
	if !mock.called {
		t.Error("Le plugin doit être appelé")
	}
}

func TestExecute_UnknownPlugin(t *testing.T) {
	yamlData := []byte(`
pipeline_id: "plugin"
steps:
  - name: "p"
    type: "plugin"
    plugin: "notfound"
`)
	pm, err := NewPipelineManager(yamlData, nil, nil)
	if err != nil {
		t.Fatalf("Erreur parsing: %v", err)
	}
	ctx := context.Background()
	err = pm.Execute(ctx)
	if err == nil || err.Error() != "plugin non trouvé: notfound" {
		t.Error("Doit échouer si plugin absent")
	}
}

func TestExecute_UnknownStepType(t *testing.T) {
	yamlData := []byte(`
pipeline_id: "badtype"
steps:
  - name: "bad"
    type: "unknown"
`)
	pm, err := NewPipelineManager(yamlData, nil, nil)
	if err != nil {
		t.Fatalf("Erreur parsing: %v", err)
	}
	ctx := context.Background()
	err = pm.Execute(ctx)
	if err == nil || err.Error() != "type d’étape inconnu: unknown" {
		t.Error("Doit échouer sur type d’étape inconnu")
	}
}

func TestLogErrorAndGetErrorLog(t *testing.T) {
	pm := &PipelineManager{}
	pm.LogError(errors.New("err1"))
	pm.LogError(errors.New("err2"))
	log := pm.GetErrorLog()
	if len(log) != 2 {
		t.Error("Erreur de log")
	}
	if log[0].Error() != "err1" || log[1].Error() != "err2" {
		t.Error("Contenu du log incorrect")
	}
}

// --- Mocks Roo pour tests d’intégration avancés PipelineManager ---

// MockPluginAdvanced simule tous les hooks PluginInterface Roo
type MockPluginAdvanced struct {
	name          string
	execErr       error
	beforeCalled  bool
	afterCalled   bool
	onErrorCalled bool
	onErrorStep   string
	onErrorParams map[string]interface{}
	onErrorErr    error
}

func (m *MockPluginAdvanced) Name() string { return m.name }
func (m *MockPluginAdvanced) Execute(ctx context.Context, params map[string]interface{}) error {
	return m.execErr
}
func (m *MockPluginAdvanced) BeforeStep(ctx context.Context, stepName string, params map[string]interface{}) error {
	m.beforeCalled = true
	return nil
}
func (m *MockPluginAdvanced) AfterStep(ctx context.Context, stepName string, params map[string]interface{}) error {
	m.afterCalled = true
	return nil
}
func (m *MockPluginAdvanced) OnError(ctx context.Context, stepName string, params map[string]interface{}, err error) error {
	m.onErrorCalled = true
	m.onErrorStep = stepName
	m.onErrorParams = params
	m.onErrorErr = err
	return nil
}

// MockN8NManager simule la réception d’événements
type MockN8NManager struct {
	eventReceived bool
}

func (m *MockN8NManager) ExecuteWorkflow(ctx context.Context, req interface{}) (interface{}, error) {
	m.eventReceived = true
	return nil, nil
}

// MockDocManager simule la réception d’événements
type MockDocManager struct {
	eventReceived bool
}

func (m *MockDocManager) Store(doc interface{}) error {
	m.eventReceived = true
	return nil
}

// MockErrorManager simule la centralisation d’erreurs
type MockErrorManager struct {
	errorProcessed bool
}

func (m *MockErrorManager) ProcessError(ctx context.Context, err error, component, operation string, hooks interface{}) error {
	m.errorProcessed = true
	return nil
}

/*
Test d’intégration Roo — PipelineManager : vérifie l’appel des hooks plugins et la robustesse aux erreurs.

Ce test d’intégration couvre :
- L’appel correct des hooks BeforeStep et AfterStep lors d’une exécution nominale d’un plugin.
- L’appel du hook OnError si le plugin échoue.
- L’archivage correct du log d’erreur dans le PipelineManager.
- La conformité aux standards Roo pour l’extension dynamique via PluginInterface.

Critères de validation Roo :
- Tous les hooks sont appelés au bon moment.
- L’erreur du plugin est bien propagée et loggée.
- Aucun effet de bord inattendu sur l’état du plugin ou du manager.

Voir AGENTS.md : section PipelineManager, PluginInterface.
*/
func TestPipelineManager_PluginHooksAndErrorHandling(t *testing.T) {
	yamlData := []byte(`
pipeline_id: "integration"
steps:
  - name: "pluginstep"
    type: "plugin"
    plugin: "adv"
`)
	plugin := &MockPluginAdvanced{name: "adv"}
	pm, err := NewPipelineManager(yamlData, []PluginInterface{plugin}, nil)
	if err != nil {
		t.Fatalf("Erreur parsing: %v", err)
	}
	ctx := context.Background()
	// Cas nominal : pas d’erreur
	plugin.execErr = nil
	err = pm.Execute(ctx)
	if err != nil {
		t.Errorf("Exécution échouée: %v", err)
	}
	if !plugin.beforeCalled {
		t.Error("BeforeStep du plugin non appelé")
	}
	if !plugin.afterCalled {
		t.Error("AfterStep du plugin non appelé")
	}
	if plugin.onErrorCalled {
		t.Error("OnError ne doit pas être appelé si pas d’erreur")
	}

	// Cas erreur : OnError doit être appelé
	plugin.beforeCalled = false
	plugin.afterCalled = false
	plugin.onErrorCalled = false
	plugin.execErr = errors.New("fail plugin")
	err = pm.Execute(ctx)
	if err == nil {
		t.Error("Doit échouer si le plugin retourne une erreur")
	}
	if !plugin.beforeCalled {
		t.Error("BeforeStep doit être rappelé même en cas d’erreur")
	}
	if plugin.afterCalled {
		t.Error("AfterStep ne doit pas être appelé si erreur")
	}
	if !plugin.onErrorCalled {
		t.Error("OnError doit être appelé si erreur plugin")
	}
	if plugin.onErrorStep != "pluginstep" {
		t.Errorf("OnError appelé sur le mauvais step: %s", plugin.onErrorStep)
	}
	if plugin.onErrorErr == nil || plugin.onErrorErr.Error() != "fail plugin" {
		t.Error("OnError doit recevoir l’erreur du plugin")
	}
}

// --- Tests Roo : Synchronisation & Reporting PipelineManager ---
// Phase 3 v113 — Génération et archivage des logs JSON et rapports Markdown

// Helper pour nettoyer les fichiers générés lors des tests
func cleanupGeneratedFiles(t *testing.T, dir, prefix string) {
	files, _ := os.ReadDir(dir)
	for _, f := range files {
		if strings.HasPrefix(f.Name(), prefix) {
			_ = os.Remove(filepath.Join(dir, f.Name()))
		}
	}
}

/*
Test d’intégration Roo — Génération et archivage des logs JSON et rapports Markdown.

Ce test vérifie :
- La création automatique des fichiers de log JSON et de rapport Markdown lors de l’exécution d’un pipeline.
- L’archivage horodaté des fichiers dans le répertoire de sortie spécifié.
- La conformité du nommage et la présence des extensions attendues.

Critères Roo :
- Un fichier log JSON et un rapport Markdown sont générés pour chaque exécution.
- Les fichiers sont horodatés (année courante présente dans le nom).
- Nettoyage automatique des fichiers générés en fin de test.

Voir AGENTS.md : PipelineManager, section reporting/archivage.
*/
func TestPipelineManager_LogAndReportGeneration(t *testing.T) {
	yamlData := []byte(`
pipeline_id: "sync_report"
steps:
  - name: "ok"
    type: "extraction"
`)
	outputDir := "test-output"
	os.MkdirAll(outputDir, 0o755)
	defer cleanupGeneratedFiles(t, outputDir, "sync_report")

	pm, err := NewPipelineManager(yamlData, nil, nil)
	if err != nil {
		t.Fatalf("Erreur parsing: %v", err)
	}
	pm.LogDir = outputDir
	pm.ReportDir = outputDir

	ctx := context.Background()
	if err := pm.Execute(ctx); err != nil {
		t.Errorf("Exécution échouée: %v", err)
	}

	// Vérifie la présence des fichiers log JSON et rapport Markdown
	foundJSON, foundMD := false, false
	files, _ := os.ReadDir(outputDir)
	for _, f := range files {
		if strings.HasPrefix(f.Name(), "sync_report") && strings.HasSuffix(f.Name(), ".json") {
			foundJSON = true
			// Vérifie horodatage dans le nom
			if !strings.Contains(f.Name(), time.Now().Format("2006")) {
				t.Error("Horodatage absent du nom de log JSON")
			}
		}
		if strings.HasPrefix(f.Name(), "sync_report") && strings.HasSuffix(f.Name(), ".md") {
			foundMD = true
		}
	}
	if !foundJSON {
		t.Error("Log JSON non généré")
	}
	if !foundMD {
		t.Error("Rapport Markdown non généré")
	}
}

/*
Test Roo — Vérification des champs clés dans le log JSON généré par PipelineManager.

Ce test vérifie :
- La présence des champs Roo essentiels ("timestamp", "status", "steps", "roo_trace") dans le log JSON produit après exécution du pipeline.
- La conformité du format JSON et l’absence d’erreur de parsing.

Critères Roo :
- Tous les champs clés sont présents dans le log.
- Le fichier JSON est valide et lisible.

Voir AGENTS.md : PipelineManager, reporting/logs.
*/
func TestPipelineManager_LogJSONFields(t *testing.T) {
	yamlData := []byte(`
pipeline_id: "fields"
steps:
  - name: "ok"
    type: "extraction"
`)
	outputDir := "test-output"
	os.MkdirAll(outputDir, 0o755)
	defer cleanupGeneratedFiles(t, outputDir, "fields")

	pm, _ := NewPipelineManager(yamlData, nil, nil)
	pm.LogDir = outputDir
	pm.ReportDir = outputDir

	_ = pm.Execute(context.Background())

	// Recherche le fichier JSON généré
	var jsonFile string
	files, _ := os.ReadDir(outputDir)
	for _, f := range files {
		if strings.HasPrefix(f.Name(), "fields") && strings.HasSuffix(f.Name(), ".json") {
			jsonFile = filepath.Join(outputDir, f.Name())
			break
		}
	}
	if jsonFile == "" {
		t.Fatal("Log JSON non trouvé")
	}
	data, _ := os.ReadFile(jsonFile)
	var log map[string]interface{}
	if err := json.Unmarshal(data, &log); err != nil {
		t.Fatalf("JSON invalide: %v", err)
	}
	// Champs clés Roo
	for _, k := range []string{"timestamp", "status", "steps", "roo_trace"} {
		if _, ok := log[k]; !ok {
			t.Errorf("Champ clé absent du log JSON: %s", k)
		}
	}
}

/*
Test Roo — Robustesse du reporting en cas d’échec pipeline.

Ce test vérifie :
- Que le log JSON généré après un échec pipeline contient bien le champ "errors".
- Que le fichier log est généré même en cas d’erreur critique (ex : type d’étape inconnu).

Critères Roo :
- Le champ "errors" est toujours présent dans le log JSON en cas d’échec.
- Le fichier log est généré et accessible pour audit.

Voir AGENTS.md : PipelineManager, gestion d’erreur et reporting.
*/
func TestPipelineManager_LogOnPipelineError(t *testing.T) {
	yamlData := []byte(`
pipeline_id: "fail"
steps:
  - name: "bad"
    type: "unknown"
`)
	outputDir := "test-output"
	os.MkdirAll(outputDir, 0o755)
	defer cleanupGeneratedFiles(t, outputDir, "fail")

	pm, _ := NewPipelineManager(yamlData, nil, nil)
	pm.LogDir = outputDir
	pm.ReportDir = outputDir

	err := pm.Execute(context.Background())
	if err == nil {
		t.Fatal("Doit échouer sur type d’étape inconnu")
	}

	// Vérifie que le log JSON contient le champ "errors"
	var jsonFile string
	files, _ := os.ReadDir(outputDir)
	for _, f := range files {
		if strings.HasPrefix(f.Name(), "fail") && strings.HasSuffix(f.Name(), ".json") {
			jsonFile = filepath.Join(outputDir, f.Name())
			break
		}
	}
	if jsonFile == "" {
		t.Fatal("Log JSON non trouvé après échec")
	}
	data, _ := os.ReadFile(jsonFile)
	var log map[string]interface{}
	_ = json.Unmarshal(data, &log)
	if _, ok := log["errors"]; !ok {
		t.Error("Champ 'errors' absent du log JSON en cas d’échec")
	}
}
