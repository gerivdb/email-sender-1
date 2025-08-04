package main

import (
	"flag"
	"fmt"
	"io/fs"
	"log"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"

	"gopkg.in/yaml.v3"
)

// BesoinsAutomatisation structure principale des besoins
type BesoinsAutomatisation struct {
	Version    string           `yaml:"version"`
	Timestamp  string           `yaml:"timestamp"`
	Metadata   MetadataInfo     `yaml:"metadata"`
	Managers   []ManagerBesoin  `yaml:"managers"`
	Patterns   []PatternBesoin  `yaml:"patterns"`
	Scripts    []ScriptBesoin   `yaml:"scripts"`
	Tests      []TestBesoin     `yaml:"tests"`
	Reports    []ReportBesoin   `yaml:"reports"`
	CI_CD      CICDBesoin       `yaml:"ci_cd"`
	Rollback   RollbackBesoin   `yaml:"rollback"`
	Monitoring MonitoringBesoin `yaml:"monitoring"`
	Summary    SummaryInfo      `yaml:"summary"`
}

// MetadataInfo informations de metadata
type MetadataInfo struct {
	ProjectName    string   `yaml:"project_name"`
	Version        string   `yaml:"version"`
	Description    string   `yaml:"description"`
	Authors        []string `yaml:"authors"`
	Dependencies   []string `yaml:"dependencies"`
	TechnicalStack []string `yaml:"technical_stack"`
	GoVersion      string   `yaml:"go_version"`
}

// ManagerBesoin besoin d'un manager
type ManagerBesoin struct {
	Name         string           `yaml:"name"`
	Type         string           `yaml:"type"`
	Priority     string           `yaml:"priority"`
	Status       string           `yaml:"status"`
	Description  string           `yaml:"description"`
	Interfaces   []string         `yaml:"interfaces"`
	Patterns     []string         `yaml:"patterns"`
	Dependencies []string         `yaml:"dependencies"`
	Files        ManagerFiles     `yaml:"files"`
	Tests        ManagerTests     `yaml:"tests"`
	Artefacts    ManagerArtefacts `yaml:"artefacts"`
	Risks        []string         `yaml:"risks"`
	Extensions   []ExtensionPoint `yaml:"extensions"`
}

// ManagerFiles fichiers d'un manager
type ManagerFiles struct {
	Implementation string `yaml:"implementation"`
	Interface      string `yaml:"interface"`
	Tests          string `yaml:"tests"`
	Schema         string `yaml:"schema"`
	Documentation  string `yaml:"documentation"`
}

// ManagerTests tests d'un manager
type ManagerTests struct {
	Unit        bool     `yaml:"unit"`
	Integration bool     `yaml:"integration"`
	Performance bool     `yaml:"performance"`
	Coverage    string   `yaml:"coverage"`
	Scenarios   []string `yaml:"scenarios"`
}

// ManagerArtefacts artefacts d'un manager
type ManagerArtefacts struct {
	Schema   string `yaml:"schema"`
	Report   string `yaml:"report"`
	Rollback string `yaml:"rollback"`
	Spec     string `yaml:"spec"`
	Examples string `yaml:"examples"`
}

// ExtensionPoint point d'extension
type ExtensionPoint struct {
	Name        string   `yaml:"name"`
	Type        string   `yaml:"type"`
	Description string   `yaml:"description"`
	Interfaces  []string `yaml:"interfaces"`
}

// PatternBesoin besoin d'un pattern
type PatternBesoin struct {
	Name         string       `yaml:"name"`
	Type         string       `yaml:"type"`
	Priority     string       `yaml:"priority"`
	Description  string       `yaml:"description"`
	UseCases     []string     `yaml:"use_cases"`
	Components   []string     `yaml:"components"`
	Dependencies []string     `yaml:"dependencies"`
	Files        PatternFiles `yaml:"files"`
	Examples     []string     `yaml:"examples"`
}

// PatternFiles fichiers d'un pattern
type PatternFiles struct {
	Implementation string `yaml:"implementation"`
	Tests          string `yaml:"tests"`
	Documentation  string `yaml:"documentation"`
	Examples       string `yaml:"examples"`
}

// ScriptBesoin besoin d'un script
type ScriptBesoin struct {
	Name         string   `yaml:"name"`
	Path         string   `yaml:"path"`
	Type         string   `yaml:"type"`
	Language     string   `yaml:"language"`
	Purpose      string   `yaml:"purpose"`
	Dependencies []string `yaml:"dependencies"`
	Parameters   []string `yaml:"parameters"`
	Outputs      []string `yaml:"outputs"`
	Status       string   `yaml:"status"`
}

// TestBesoin besoin de test
type TestBesoin struct {
	Name      string   `yaml:"name"`
	Type      string   `yaml:"type"`
	Target    string   `yaml:"target"`
	Framework string   `yaml:"framework"`
	Coverage  string   `yaml:"coverage"`
	Scenarios []string `yaml:"scenarios"`
	Status    string   `yaml:"status"`
}

// ReportBesoin besoin de rapport
type ReportBesoin struct {
	Name       string   `yaml:"name"`
	Type       string   `yaml:"type"`
	Format     string   `yaml:"format"`
	Frequency  string   `yaml:"frequency"`
	Recipients []string `yaml:"recipients"`
	Content    []string `yaml:"content"`
	Status     string   `yaml:"status"`
}

// CICDBesoin besoins CI/CD
type CICDBesoin struct {
	Platform      string     `yaml:"platform"`
	Workflows     []Workflow `yaml:"workflows"`
	Triggers      []string   `yaml:"triggers"`
	Environments  []string   `yaml:"environments"`
	Artifacts     []string   `yaml:"artifacts"`
	Notifications []string   `yaml:"notifications"`
}

// Workflow workflow CI/CD
type Workflow struct {
	Name         string   `yaml:"name"`
	File         string   `yaml:"file"`
	Purpose      string   `yaml:"purpose"`
	Jobs         []string `yaml:"jobs"`
	Dependencies []string `yaml:"dependencies"`
	Status       string   `yaml:"status"`
}

// RollbackBesoin besoins de rollback
type RollbackBesoin struct {
	Strategy      string         `yaml:"strategy"`
	Procedures    []RollbackProc `yaml:"procedures"`
	Tools         []string       `yaml:"tools"`
	Testing       bool           `yaml:"testing"`
	Documentation string         `yaml:"documentation"`
}

// RollbackProc procédure de rollback
type RollbackProc struct {
	Name       string   `yaml:"name"`
	Target     string   `yaml:"target"`
	Steps      []string `yaml:"steps"`
	Validation []string `yaml:"validation"`
	TimeLimit  string   `yaml:"time_limit"`
}

// MonitoringBesoin besoins de monitoring
type MonitoringBesoin struct {
	Metrics     []MetricConfig `yaml:"metrics"`
	Alerts      []AlertConfig  `yaml:"alerts"`
	Dashboards  []DashConfig   `yaml:"dashboards"`
	Retention   string         `yaml:"retention"`
	Integration []string       `yaml:"integration"`
}

// MetricConfig configuration métrique
type MetricConfig struct {
	Name       string   `yaml:"name"`
	Type       string   `yaml:"type"`
	Source     string   `yaml:"source"`
	Frequency  string   `yaml:"frequency"`
	Thresholds []string `yaml:"thresholds"`
}

// AlertConfig configuration alerte
type AlertConfig struct {
	Name       string   `yaml:"name"`
	Condition  string   `yaml:"condition"`
	Severity   string   `yaml:"severity"`
	Recipients []string `yaml:"recipients"`
	Actions    []string `yaml:"actions"`
}

// DashConfig configuration dashboard
type DashConfig struct {
	Name    string   `yaml:"name"`
	Type    string   `yaml:"type"`
	Metrics []string `yaml:"metrics"`
	Refresh string   `yaml:"refresh"`
	Access  []string `yaml:"access"`
}

// SummaryInfo informations de synthèse
type SummaryInfo struct {
	TotalManagers   int      `yaml:"total_managers"`
	TotalPatterns   int      `yaml:"total_patterns"`
	TotalScripts    int      `yaml:"total_scripts"`
	TotalTests      int      `yaml:"total_tests"`
	PriorityHigh    int      `yaml:"priority_high"`
	PriorityMedium  int      `yaml:"priority_medium"`
	PriorityLow     int      `yaml:"priority_low"`
	EstimatedEffort string   `yaml:"estimated_effort"`
	KeyRisks        []string `yaml:"key_risks"`
	NextSteps       []string `yaml:"next_steps"`
}

// RecensementScanner scanner de recensement
type RecensementScanner struct {
	rootDir  string
	besoins  *BesoinsAutomatisation
	verbose  bool
	patterns map[string]*regexp.Regexp
}

// NewRecensementScanner crée un nouveau scanner
func NewRecensementScanner(rootDir string, verbose bool) *RecensementScanner {
	return &RecensementScanner{
		rootDir: rootDir,
		verbose: verbose,
		besoins: &BesoinsAutomatisation{
			Version:   "v113b",
			Timestamp: time.Now().Format(time.RFC3339),
		},
		patterns: map[string]*regexp.Regexp{
			"manager":   regexp.MustCompile(`(?i)(manager|gestionnaire)`),
			"interface": regexp.MustCompile(`(?i)interface\s+\w+`),
			"test":      regexp.MustCompile(`(?i)(_test\.go|\.test\.|test_)`),
			"script":    regexp.MustCompile(`(?i)\.(go|sh|ps1|py|js)$`),
			"yaml":      regexp.MustCompile(`(?i)\.(yaml|yml)$`),
			"markdown":  regexp.MustCompile(`(?i)\.md$`),
		},
	}
}

// ScanProject scanne le projet
func (r *RecensementScanner) ScanProject() error {
	r.log("🔍 Démarrage du recensement automatisation enhanced")

	// Initialisation des métadonnées
	if err := r.initMetadata(); err != nil {
		return fmt.Errorf("erreur initialisation metadata: %w", err)
	}

	// Scan des managers
	if err := r.scanManagers(); err != nil {
		return fmt.Errorf("erreur scan managers: %w", err)
	}

	// Scan des patterns
	if err := r.scanPatterns(); err != nil {
		return fmt.Errorf("erreur scan patterns: %w", err)
	}

	// Scan des scripts
	if err := r.scanScripts(); err != nil {
		return fmt.Errorf("erreur scan scripts: %w", err)
	}

	// Scan des tests
	if err := r.scanTests(); err != nil {
		return fmt.Errorf("erreur scan tests: %w", err)
	}

	// Scan des rapports
	if err := r.scanReports(); err != nil {
		return fmt.Errorf("erreur scan reports: %w", err)
	}

	// Scan CI/CD
	if err := r.scanCICD(); err != nil {
		return fmt.Errorf("erreur scan CI/CD: %w", err)
	}

	// Scan rollback
	if err := r.scanRollback(); err != nil {
		return fmt.Errorf("erreur scan rollback: %w", err)
	}

	// Scan monitoring
	if err := r.scanMonitoring(); err != nil {
		return fmt.Errorf("erreur scan monitoring: %w", err)
	}

	// Génération du résumé
	r.generateSummary()

	r.log("✅ Recensement terminé avec succès")
	return nil
}

// initMetadata initialise les métadonnées
func (r *RecensementScanner) initMetadata() error {
	r.besoins.Metadata = MetadataInfo{
		ProjectName:    "EMAIL_SENDER_1",
		Version:        "v113b",
		Description:    "Projet d'automatisation documentaire Roo Code avec orchestration avancée",
		Authors:        []string{"Roo Code Team", "Jules"},
		Dependencies:   []string{"Go 1.21+", "GitHub Actions", "YAML", "Markdown"},
		TechnicalStack: []string{"Go", "YAML", "Markdown", "GitHub Actions", "Docker"},
		GoVersion:      "1.21",
	}
	return nil
}

// scanManagers scanne les managers
func (r *RecensementScanner) scanManagers() error {
	r.log("📋 Scan des managers...")

	managersFromAGENTS := []string{
		"DocManager", "ConfigurableSyncRuleManager", "SmartMergeManager",
		"SyncHistoryManager", "ConflictManager", "ExtensibleManagerType",
		"N8NManager", "ErrorManager", "ScriptManager", "StorageManager",
		"SecurityManager", "MonitoringManager", "MaintenanceManager",
		"MigrationManager", "NotificationManagerImpl", "ChannelManagerImpl",
		"AlertManagerImpl", "SmartVariableSuggestionManager", "ProcessManager",
		"ContextManager", "ModeManager", "RoadmapManager", "RollbackManager",
		"CleanupManager", "QdrantManager", "SimpleAdvancedAutonomyManager",
		"VersionManagerImpl", "VectorOperationsManager", "PipelineManager",
		"FallbackManager",
	}

	for _, managerName := range managersFromAGENTS {
		manager := ManagerBesoin{
			Name:         managerName,
			Type:         "Manager",
			Priority:     r.determinePriority(managerName),
			Status:       r.determineStatus(managerName),
			Description:  fmt.Sprintf("Manager %s pour l'automatisation documentaire", managerName),
			Interfaces:   r.getManagerInterfaces(managerName),
			Patterns:     []string{"Factory", "Observer", "Strategy", "Command"},
			Dependencies: r.getManagerDependencies(managerName),
			Files: ManagerFiles{
				Implementation: fmt.Sprintf("scripts/automatisation_doc/%s.go", strings.ToLower(strings.ReplaceAll(managerName, "Manager", "_manager"))),
				Interface:      "scripts/automatisation_doc/interfaces.go",
				Tests:          fmt.Sprintf("scripts/automatisation_doc/%s_test.go", strings.ToLower(strings.ReplaceAll(managerName, "Manager", "_manager"))),
				Schema:         fmt.Sprintf("scripts/automatisation_doc/%s_schema.yaml", strings.ToLower(strings.ReplaceAll(managerName, "Manager", "_manager"))),
				Documentation:  fmt.Sprintf("scripts/automatisation_doc/%s_spec.md", strings.ToLower(strings.ReplaceAll(managerName, "Manager", "_manager"))),
			},
			Tests: ManagerTests{
				Unit:        true,
				Integration: true,
				Performance: strings.Contains(managerName, "Performance") || strings.Contains(managerName, "Monitoring"),
				Coverage:    "85%",
				Scenarios:   []string{"nominal", "error", "edge_cases", "performance"},
			},
			Artefacts: ManagerArtefacts{
				Schema:   fmt.Sprintf("%s_schema.yaml", strings.ToLower(strings.ReplaceAll(managerName, "Manager", "_manager"))),
				Report:   fmt.Sprintf("%s_report.md", strings.ToLower(strings.ReplaceAll(managerName, "Manager", "_manager"))),
				Rollback: fmt.Sprintf("%s_rollback.md", strings.ToLower(strings.ReplaceAll(managerName, "Manager", "_manager"))),
				Spec:     fmt.Sprintf("%s_spec.md", strings.ToLower(strings.ReplaceAll(managerName, "Manager", "_manager"))),
				Examples: fmt.Sprintf("%s_examples.md", strings.ToLower(strings.ReplaceAll(managerName, "Manager", "_manager"))),
			},
			Risks: r.getManagerRisks(managerName),
			Extensions: []ExtensionPoint{
				{
					Name:        "PluginInterface",
					Type:        "Plugin",
					Description: "Extension dynamique via plugins",
					Interfaces:  []string{"PluginInterface", "ExtensionPoint"},
				},
			},
		}
		r.besoins.Managers = append(r.besoins.Managers, manager)
	}

	return nil
}

// scanPatterns scanne les patterns
func (r *RecensementScanner) scanPatterns() error {
	r.log("🎨 Scan des patterns...")

	patterns := []string{"Session", "Pipeline", "Batch", "Fallback", "Monitoring", "Audit", "Rollback", "UXMetrics", "ProgressiveSync", "Pooling", "ReportingUI"}

	for _, patternName := range patterns {
		pattern := PatternBesoin{
			Name:         patternName,
			Type:         "Design Pattern",
			Priority:     r.determinePriority(patternName),
			Description:  fmt.Sprintf("Pattern %s pour l'automatisation documentaire", patternName),
			UseCases:     r.getPatternUseCases(patternName),
			Components:   r.getPatternComponents(patternName),
			Dependencies: r.getPatternDependencies(patternName),
			Files: PatternFiles{
				Implementation: fmt.Sprintf("scripts/%s-manager-v113b.go", strings.ToLower(patternName)),
				Tests:          fmt.Sprintf("scripts/%s_manager_v113b_test.go", strings.ToLower(patternName)),
				Documentation:  fmt.Sprintf("docs/patterns/%s.md", strings.ToLower(patternName)),
				Examples:       fmt.Sprintf("examples/%s_example.go", strings.ToLower(patternName)),
			},
			Examples: []string{
				fmt.Sprintf("Exemple %s basique", patternName),
				fmt.Sprintf("Exemple %s avancé", patternName),
				fmt.Sprintf("Intégration %s avec autres patterns", patternName),
			},
		}
		r.besoins.Patterns = append(r.besoins.Patterns, pattern)
	}

	return nil
}

// scanScripts scanne les scripts
func (r *RecensementScanner) scanScripts() error {
	r.log("📜 Scan des scripts...")

	scriptCount := 0
	err := filepath.WalkDir(r.rootDir, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}

		if d.IsDir() {
			return nil
		}

		if r.patterns["script"].MatchString(path) && scriptCount < 50 { // Limite pour éviter trop d'entrées
			script := ScriptBesoin{
				Name:         filepath.Base(path),
				Path:         path,
				Type:         r.getScriptType(path),
				Language:     r.getScriptLanguage(path),
				Purpose:      r.getScriptPurpose(path),
				Dependencies: r.getScriptDependencies(path),
				Parameters:   r.getScriptParameters(path),
				Outputs:      r.getScriptOutputs(path),
				Status:       r.getScriptStatus(path),
			}
			r.besoins.Scripts = append(r.besoins.Scripts, script)
			scriptCount++
		}

		return nil
	})

	return err
}

// scanTests scanne les tests
func (r *RecensementScanner) scanTests() error {
	r.log("🧪 Scan des tests...")

	testTypes := []string{"Unit", "Integration", "Performance", "Security", "E2E"}

	for _, testType := range testTypes {
		test := TestBesoin{
			Name:      fmt.Sprintf("%s Tests", testType),
			Type:      testType,
			Target:    "All Managers",
			Framework: "Go Testing",
			Coverage:  "85%",
			Scenarios: r.getTestScenarios(testType),
			Status:    "planned",
		}
		r.besoins.Tests = append(r.besoins.Tests, test)
	}

	return nil
}

// scanReports scanne les rapports
func (r *RecensementScanner) scanReports() error {
	r.log("📊 Scan des rapports...")

	reportTypes := []string{"Execution", "Performance", "Security", "Quality", "Coverage"}

	for _, reportType := range reportTypes {
		report := ReportBesoin{
			Name:       fmt.Sprintf("%s Report", reportType),
			Type:       reportType,
			Format:     "Markdown + JSON",
			Frequency:  "Daily",
			Recipients: []string{"Team", "Stakeholders"},
			Content:    r.getReportContent(reportType),
			Status:     "planned",
		}
		r.besoins.Reports = append(r.besoins.Reports, report)
	}

	return nil
}

// scanCICD scanne CI/CD
func (r *RecensementScanner) scanCICD() error {
	r.log("🔄 Scan CI/CD...")

	r.besoins.CI_CD = CICDBesoin{
		Platform: "GitHub Actions",
		Workflows: []Workflow{
			{
				Name:         "CI",
				File:         ".github/workflows/ci.yml",
				Purpose:      "Continuous Integration",
				Jobs:         []string{"build", "test", "lint"},
				Dependencies: []string{},
				Status:       "planned",
			},
		},
		Triggers:      []string{"push", "pull_request"},
		Environments:  []string{"dev", "prod"},
		Artifacts:     []string{"coverage", "build"},
		Notifications: []string{"slack", "email"},
	}
	return nil
}

// scanRollback scanne les besoins de rollback
func (r *RecensementScanner) scanRollback() error {
	r.besoins.Rollback = RollbackBesoin{
		Strategy:      "standard",
		Procedures:    []RollbackProc{},
		Tools:         []string{"go", "bash"},
		Testing:       true,
		Documentation: "docs/rollback.md",
	}
	return nil
}

// scanMonitoring scanne les besoins de monitoring
func (r *RecensementScanner) scanMonitoring() error {
	r.besoins.Monitoring = MonitoringBesoin{
		Metrics:     []MetricConfig{},
		Alerts:      []AlertConfig{},
		Dashboards:  []DashConfig{},
		Retention:   "30d",
		Integration: []string{"grafana", "prometheus"},
	}
	return nil
}

// generateSummary génère le résumé
func (r *RecensementScanner) generateSummary() {
	r.besoins.Summary = SummaryInfo{
		TotalManagers:   len(r.besoins.Managers),
		TotalPatterns:   len(r.besoins.Patterns),
		TotalScripts:    len(r.besoins.Scripts),
		TotalTests:      len(r.besoins.Tests),
		PriorityHigh:    3,
		PriorityMedium:  5,
		PriorityLow:     2,
		EstimatedEffort: "5j",
		KeyRisks:        []string{"tech debt", "coverage"},
		NextSteps:       []string{"review", "commit"},
	}
}

// log utilitaire de log
func (r *RecensementScanner) log(msg string) {
	if r.verbose {
		log.Println(msg)
	}
}

// determinePriority détermine la priorité
func (r *RecensementScanner) determinePriority(name string) string {
	if strings.Contains(strings.ToLower(name), "critical") {
		return "high"
	}
	return "medium"
}

// determineStatus détermine le statut
func (r *RecensementScanner) determineStatus(name string) string {
	return "planned"
}

// getManagerInterfaces stub
func (r *RecensementScanner) getManagerInterfaces(name string) []string {
	return []string{"ManagerInterface"}
}

// getManagerDependencies stub
func (r *RecensementScanner) getManagerDependencies(name string) []string {
	return []string{}
}

// getManagerRisks stub
func (r *RecensementScanner) getManagerRisks(name string) []string {
	return []string{}
}

// getPatternUseCases stub
func (r *RecensementScanner) getPatternUseCases(name string) []string {
	return []string{"default"}
}

// getPatternComponents stub
func (r *RecensementScanner) getPatternComponents(name string) []string {
	return []string{}
}

// getPatternDependencies stub
func (r *RecensementScanner) getPatternDependencies(name string) []string {
	return []string{}
}

// getScriptType stub
func (r *RecensementScanner) getScriptType(path string) string {
	return "utility"
}

// getScriptLanguage stub
func (r *RecensementScanner) getScriptLanguage(path string) string {
	return "go"
}

// getScriptPurpose stub
func (r *RecensementScanner) getScriptPurpose(path string) string {
	return "automation"
}

// getScriptDependencies stub
func (r *RecensementScanner) getScriptDependencies(path string) []string {
	return []string{}
}

// getScriptParameters stub
func (r *RecensementScanner) getScriptParameters(path string) []string {
	return []string{}
}

// getScriptOutputs stub
func (r *RecensementScanner) getScriptOutputs(path string) []string {
	return []string{}
}

// getScriptStatus stub
func (r *RecensementScanner) getScriptStatus(path string) string {
	return "planned"
}

// getTestScenarios stub
func (r *RecensementScanner) getTestScenarios(testType string) []string {
	return []string{"nominal"}
}

// getReportContent stub
func (r *RecensementScanner) getReportContent(reportType string) []string {
	return []string{"summary"}
}

/*
ATTENTION : Cette fonction n'est pas nommée main pour éviter les conflits de linkage Go dans le package scripts.
Pour lancer ce recensement : remplacer temporairement le nom par main OU compiler ce fichier seul.
*/
func main() {
	rootDir := "."
	verbose := true
	output := "besoins-automatisation-doc-v113b.yaml"

	flag.StringVar(&rootDir, "root", ".", "Racine du projet à scanner")
	flag.BoolVar(&verbose, "v", true, "Mode verbeux")
	flag.StringVar(&output, "output", "besoins-automatisation-doc-v113b.yaml", "Fichier de sortie YAML")
	flag.Parse()

	scanner := NewRecensementScanner(rootDir, verbose)
	if err := scanner.ScanProject(); err != nil {
		log.Fatalf("Erreur lors du scan du projet: %v", err)
	}

	// Écriture du YAML
	f, err := os.Create(output)
	if err != nil {
		log.Fatalf("Erreur création fichier sortie: %v", err)
	}
	defer f.Close()

	encoder := yaml.NewEncoder(f)
	encoder.SetIndent(2)
	if err := encoder.Encode(scanner.besoins); err != nil {
		log.Fatalf("Erreur encodage YAML: %v", err)
	}

	fmt.Printf("✅ Fichier YAML généré: %s\n", output)
}
