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
type MockPlugin struct {
	name    string
	execErr error
	called  bool
}

func (m *MockPlugin) Name() string { return m.name }
func (m *MockPlugin) Execute(ctx context.Context, params map[string]interface{}) error {
	m.called = true
	return m.execErr
}

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

// Teste la création automatique et l’archivage horodaté des logs JSON et rapports Markdown
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

// Vérifie la présence des champs clés dans le log JSON
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

// Vérifie la robustesse du reporting en cas d’échec pipeline
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
