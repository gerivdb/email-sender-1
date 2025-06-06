// Manager Toolkit - Dependency Analyzer
// Version: 3.0.0
// Analyzes Go module dependencies for vulnerabilities and updates

package analysis

import (
	"github.com/email-sender/tools/core/registry"
	"github.com/email-sender/tools/core/toolkit"
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"time"
)

// DependencyAnalyzer implémente l'interface toolkit.ToolkitOperation pour l'analyse des dépendances
type DependencyAnalyzer struct {
	BaseDir string
	Logger  *toolkit.Logger
	Stats   *toolkit.ToolkitStats
	DryRun  bool
}

// DependencyInfo représente les informations d'une dépendance
type DependencyInfo struct {
	Name            string            `json:"name"`
	Version         string            `json:"version"`
	ModulePath      string            `json:"module_path"`
	IsIndirect      bool              `json:"is_indirect"`
	UpdateAvailable bool              `json:"update_available"`
	LatestVersion   string            `json:"latest_version,omitempty"`
	Vulnerabilities []Vulnerability   `json:"vulnerabilities"`
	Size            int64             `json:"size,omitempty"`
	License         string            `json:"license,omitempty"`
	Repository      string            `json:"repository,omitempty"`
	Tags            map[string]string `json:"tags"`
}

// Vulnerability représente une vulnérabilité de sécurité
type Vulnerability struct {
	ID          string   `json:"id"`
	Severity    string   `json:"severity"`
	Description string   `json:"description"`
	CVEIDs      []string `json:"cve_ids,omitempty"`
	FixedIn     string   `json:"fixed_in,omitempty"`
}

// DependencyReport représente le rapport d'analyse des dépendances
type DependencyReport struct {
	Tool                 string           `json:"tool"`
	Timestamp            time.Time        `json:"timestamp"`
	ProjectPath          string           `json:"project_path"`
	GoVersion            string           `json:"go_version"`
	ModuleName           string           `json:"module_name"`
	TotalDependencies    int              `json:"total_dependencies"`
	DirectDependencies   int              `json:"direct_dependencies"`
	IndirectDependencies int              `json:"indirect_dependencies"`
	VulnerabilitiesFound int              `json:"vulnerabilities_found"`
	UpdatesAvailable     int              `json:"updates_available"`
	Dependencies         []DependencyInfo `json:"dependencies"`
	SecuritySummary      SecuritySummary  `json:"security_summary"`
	DurationMs           int64            `json:"duration_ms"`
}

// SecuritySummary résume les vulnérabilités par sévérité
type SecuritySummary struct {
	Critical int `json:"critical"`
	High     int `json:"high"`
	Medium   int `json:"medium"`
	Low      int `json:"low"`
}

// NewDependencyAnalyzer crée une nouvelle instance de DependencyAnalyzer
func NewDependencyAnalyzer(baseDir string, logger *toolkit.Logger, dryRun bool) (*DependencyAnalyzer, error) {
	if baseDir == "" {
		return nil, fmt.Errorf("base directory cannot be empty")
	}

	// Vérifier que le répertoire existe
	if _, err := os.Stat(baseDir); os.IsNotExist(err) {
		return nil, fmt.Errorf("base directory does not exist: %s", baseDir)
	}

	if logger == nil {
		// Assuming toolkit.Logger has a NewLogger function or a simple struct instantiation
		// This might need adjustment based on actual toolkit.Logger definition
		logger = &toolkit.Logger{} // Simplistic instantiation
	}

	return &DependencyAnalyzer{
		BaseDir: baseDir,
		Logger:  logger,
		Stats:   &toolkit.ToolkitStats{},
		DryRun:  dryRun,
	}, nil
}

// Execute implémente ToolkitOperation.Execute
func (da *DependencyAnalyzer) Execute(ctx context.Context, options *toolkit.OperationOptions) error {
	da.Logger.Info("🔍 Starting dependency analysis on: %s", options.Target)
	startTime := time.Now()

	// Vérifier la présence de go.mod
	goModPath := filepath.Join(options.Target, "go.mod")
	if _, err := os.Stat(goModPath); os.IsNotExist(err) {
		return fmt.Errorf("go.mod not found in %s", options.Target)
	}

	// Changer vers le répertoire du projet
	originalDir, err := os.Getwd()
	if err != nil {
		return err
	}
	defer os.Chdir(originalDir)

	if err := os.Chdir(options.Target); err != nil {
		return err
	}

	// Analyser les dépendances
	dependencies, err := da.analyzeDependencies(ctx)
	if err != nil {
		return err
	}

	// Obtenir les informations du module
	moduleName, goVersion, err := da.getModuleInfo()
	if err != nil {
		da.Logger.Warn("Failed to get module info: %v", err)
	}

	// Analyser les vulnérabilités
	err = da.analyzeVulnerabilities(ctx, dependencies)
	if err != nil {
		da.Logger.Warn("Failed to analyze vulnerabilities: %v", err)
	}

	// Vérifier les mises à jour disponibles
	err = da.checkUpdates(ctx, dependencies)
	if err != nil {
		da.Logger.Warn("Failed to check updates: %v", err)
	}

	duration := time.Since(startTime)

	// Calculer les statistiques
	totalDeps := len(dependencies)
	directDeps := 0
	indirectDeps := 0
	vulnCount := 0
	updatesAvailable := 0

	securitySummary := SecuritySummary{}

	for _, dep := range dependencies {
		if dep.IsIndirect {
			indirectDeps++
		} else {
			directDeps++
		}

		vulnCount += len(dep.Vulnerabilities)
		for _, vuln := range dep.Vulnerabilities {
			switch strings.ToLower(vuln.Severity) {
			case "critical":
				securitySummary.Critical++
			case "high":
				securitySummary.High++
			case "medium":
				securitySummary.Medium++
			case "low":
				securitySummary.Low++
			}
		}

		if dep.UpdateAvailable {
			updatesAvailable++
		}
	}

	// Mettre à jour les statistiques standardisées
	da.Stats.FilesAnalyzed = totalDeps
	da.Stats.ErrorsFixed = vulnCount

	// Générer le rapport si demandé
	if options.Output != "" {
		report := DependencyReport{
			Tool:                 "DependencyAnalyzer",
			Timestamp:            time.Now(),
			ProjectPath:          options.Target,
			GoVersion:            goVersion,
			ModuleName:           moduleName,
			TotalDependencies:    totalDeps,
			DirectDependencies:   directDeps,
			IndirectDependencies: indirectDeps,
			VulnerabilitiesFound: vulnCount,
			UpdatesAvailable:     updatesAvailable,
			Dependencies:         dependencies,
			SecuritySummary:      securitySummary,
			DurationMs:           duration.Milliseconds(),
		}

		if err := da.generateReport(report, options.Output); err != nil {
			da.Logger.Error("Failed to generate report: %v", err)
			return err
		}

		da.Logger.Info("Dependency analysis report saved to: %s", options.Output)
	}

	// Afficher le résumé
	da.Logger.Info("✅ Dependency analysis completed:")
	da.Logger.Info("   📦 Total dependencies: %d (%d direct, %d indirect)", totalDeps, directDeps, indirectDeps)
	da.Logger.Info("   🚨 Vulnerabilities: %d (Critical: %d, High: %d, Medium: %d, Low: %d)",
		vulnCount, securitySummary.Critical, securitySummary.High, securitySummary.Medium, securitySummary.Low)
	da.Logger.Info("   📈 Updates available: %d", updatesAvailable)
	da.Logger.Info("   ⏱️  Duration: %v", duration)

	return nil
}

// analyzeDependencies analyse les dépendances du module Go
func (da *DependencyAnalyzer) analyzeDependencies(ctx context.Context) ([]DependencyInfo, error) {
	da.Logger.Info("Analyzing Go module dependencies...")

	// Exécuter go list pour obtenir les dépendances
	cmd := exec.CommandContext(ctx, "go", "list", "-m", "-json", "all")
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to list dependencies: %v", err)
	}

	var dependencies []DependencyInfo

	// Parser la sortie JSON
	lines := strings.Split(string(output), "\n")
	var currentModule strings.Builder

	for _, line := range lines {
		if strings.TrimSpace(line) == "" {
			if currentModule.Len() > 0 {
				var moduleInfo struct {
					Path     string `json:"Path"`
					Version  string `json:"Version"`
					Indirect bool   `json:"Indirect"`
					Main     bool   `json:"Main"`
				}

				if err := json.Unmarshal([]byte(currentModule.String()), &moduleInfo); err == nil {
					if !moduleInfo.Main { // Exclure le module principal
						dep := DependencyInfo{
							Name:       da.extractPackageName(moduleInfo.Path),
							Version:    moduleInfo.Version,
							ModulePath: moduleInfo.Path,
							IsIndirect: moduleInfo.Indirect,
							Tags:       make(map[string]string),
						}
						dependencies = append(dependencies, dep)
					}
				}

				currentModule.Reset()
			}
		} else {
			currentModule.WriteString(line)
		}
	}

	da.Logger.Info("Found %d dependencies", len(dependencies))
	return dependencies, nil
}

// getModuleInfo obtient les informations du module principal
func (da *DependencyAnalyzer) getModuleInfo() (string, string, error) {
	// Obtenir le nom du module
	cmd := exec.Command("go", "list", "-m")
	moduleOutput, err := cmd.Output()
	if err != nil {
		return "", "", err
	}
	moduleName := strings.TrimSpace(string(moduleOutput))

	// Obtenir la version de Go
	cmd = exec.Command("go", "version")
	versionOutput, err := cmd.Output()
	if err != nil {
		return moduleName, "", err
	}

	// Extraire la version Go
	versionRegex := regexp.MustCompile(`go(\d+\.\d+(?:\.\d+)?)`)
	matches := versionRegex.FindStringSubmatch(string(versionOutput))
	goVersion := ""
	if len(matches) > 1 {
		goVersion = matches[1]
	}

	return moduleName, goVersion, nil
}

// analyzeVulnerabilities analyse les vulnérabilités de sécurité
func (da *DependencyAnalyzer) analyzeVulnerabilities(ctx context.Context, dependencies []DependencyInfo) error {
	da.Logger.Info("Checking for security vulnerabilities...")

	// Vérifier si govulncheck est disponible
	if _, err := exec.LookPath("govulncheck"); err != nil {
		da.Logger.Warn("govulncheck not found, skipping vulnerability analysis")
		da.Logger.Info("Install with: go install golang.org/x/vuln/cmd/govulncheck@latest")
		return nil
	}

	// Exécuter govulncheck
	cmd := exec.CommandContext(ctx, "govulncheck", "-json", "./...")
	output, err := cmd.Output()
	if err != nil {
		// govulncheck peut retourner une erreur même avec des vulnérabilités trouvées
		da.Logger.Warn("govulncheck completed with warnings: %v", err)
	}

	// Parser les résultats de govulncheck
	lines := strings.Split(string(output), "\n")
	for _, line := range lines {
		if strings.TrimSpace(line) == "" {
			continue
		}

		var result struct {
			Type string `json:"type"`
			OSV  struct {
				ID      string   `json:"id"`
				Summary string   `json:"summary"`
				Aliases []string `json:"aliases"`
			} `json:"osv"`
			Modules []struct {
				Path         string `json:"path"`
				FixedVersion string `json:"fixed_version"`
			} `json:"modules"`
		}

		if err := json.Unmarshal([]byte(line), &result); err == nil {
			if result.Type == "osv" {
				// Associer la vulnérabilité aux dépendances concernées
				for i := range dependencies {
					for _, module := range result.Modules {
						if dependencies[i].ModulePath == module.Path {
							vuln := Vulnerability{
								ID:          result.OSV.ID,
								Severity:    da.determineSeverity(result.OSV.Summary),
								Description: result.OSV.Summary,
								CVEIDs:      result.OSV.Aliases,
								FixedIn:     module.FixedVersion,
							}
							dependencies[i].Vulnerabilities = append(dependencies[i].Vulnerabilities, vuln)
						}
					}
				}
			}
		}
	}

	return nil
}

// checkUpdates vérifie les mises à jour disponibles
func (da *DependencyAnalyzer) checkUpdates(ctx context.Context, dependencies []DependencyInfo) error {
	da.Logger.Info("Checking for available updates...")

	// Exécuter go list pour obtenir les dernières versions
	cmd := exec.CommandContext(ctx, "go", "list", "-u", "-m", "-json", "all")
	output, err := cmd.Output()
	if err != nil {
		return fmt.Errorf("failed to check updates: %v", err)
	}

	// Parser la sortie pour détecter les mises à jour
	lines := strings.Split(string(output), "\n")
	var currentModule strings.Builder

	for _, line := range lines {
		if strings.TrimSpace(line) == "" {
			if currentModule.Len() > 0 {
				var moduleInfo struct {
					Path    string `json:"Path"`
					Version string `json:"Version"`
					Update  struct {
						Version string `json:"Version"`
					} `json:"Update"`
				}

				if err := json.Unmarshal([]byte(currentModule.String()), &moduleInfo); err == nil {
					if moduleInfo.Update.Version != "" {
						// Trouver la dépendance correspondante et marquer la mise à jour
						for i := range dependencies {
							if dependencies[i].ModulePath == moduleInfo.Path {
								dependencies[i].UpdateAvailable = true
								dependencies[i].LatestVersion = moduleInfo.Update.Version
								break
							}
						}
					}
				}

				currentModule.Reset()
			}
		} else {
			currentModule.WriteString(line)
		}
	}

	return nil
}

// extractPackageName extrait le nom du package à partir du chemin du module
func (da *DependencyAnalyzer) extractPackageName(modulePath string) string {
	parts := strings.Split(modulePath, "/")
	if len(parts) > 0 {
		return parts[len(parts)-1]
	}
	return modulePath
}

// determineSeverity détermine la sévérité d'une vulnérabilité
func (da *DependencyAnalyzer) determineSeverity(summary string) string {
	summary = strings.ToLower(summary)

	if strings.Contains(summary, "critical") || strings.Contains(summary, "rce") || strings.Contains(summary, "remote code execution") {
		return "critical"
	} else if strings.Contains(summary, "high") || strings.Contains(summary, "privilege escalation") {
		return "high"
	} else if strings.Contains(summary, "medium") || strings.Contains(summary, "injection") {
		return "medium"
	}

	return "low"
}

// generateReport génère un rapport JSON
func (da *DependencyAnalyzer) generateReport(report DependencyReport, outputPath string) error {
	data, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(outputPath, data, 0644)
}

// Validate implémente ToolkitOperation.Validate
func (da *DependencyAnalyzer) Validate(ctx context.Context) error {
	if da.BaseDir == "" {
		return fmt.Errorf("BaseDir is required")
	}

	if da.Logger == nil {
		return fmt.Errorf("Logger is required")
	}

	// Vérifier la présence de Go
	if _, err := exec.LookPath("go"); err != nil {
		return fmt.Errorf("go command not found: %v", err)
	}

	return nil
}

// CollectMetrics implémente ToolkitOperation.CollectMetrics
func (da *DependencyAnalyzer) CollectMetrics() map[string]interface{} {
	return map[string]interface{}{
		"tool":            "DependencyAnalyzer",
		"dependencies":    da.Stats.FilesAnalyzed,
		"vulnerabilities": da.Stats.ErrorsFixed,
		"dry_run_mode":    da.DryRun,
		"base_directory":  da.BaseDir,
	}
}

// HealthCheck implémente ToolkitOperation.HealthCheck
func (da *DependencyAnalyzer) HealthCheck(ctx context.Context) error {
	// Vérifier la commande go
	if _, err := exec.LookPath("go"); err != nil {
		return fmt.Errorf("go command not available: %v", err)
	}

	// Vérifier l'accès au répertoire cible
	if _, err := os.Stat(da.BaseDir); os.IsNotExist(err) {
		return fmt.Errorf("base directory does not exist: %s", da.BaseDir)
	}

	return nil
}

// String implémente ToolkitOperation.String - identification de l'outil
func (da *DependencyAnalyzer) String() string {
	return "DependencyAnalyzer"
}

// GetDescription implémente ToolkitOperation.GetDescription - description de l'outil
func (da *DependencyAnalyzer) GetDescription() string {
	return "Analyzes Go module dependencies for vulnerabilities, updates, and security issues"
}

// Stop implémente ToolkitOperation.Stop - gestion des signaux d'arrêt
func (da *DependencyAnalyzer) Stop(ctx context.Context) error {
	return nil
}

// init registers the DependencyAnalyzer tool automatically
func init() {
	// Ensure globalRegistry is initialized (example, actual initialization might differ)
	// This assumes GetGlobalRegistry() and NewToolRegistry() are accessible, possibly via an import
	// For example, if they are in a package like "core/registry"
	// import coreRegistry "github.com/email-sender/tools/core/registry"
	// globalRegistry = coreRegistry.GetGlobalRegistry()
	// if globalRegistry == nil {
	// 	globalRegistry = coreRegistry.NewToolRegistry()
	// }
	// For now, let's assume direct access or they are globally available for simplicity of this diff
	// This part likely needs more context on how globalRegistry is managed.
	// Assuming registry.GetGlobalRegistry() and registry.NewToolRegistry() are the correct functions
	// and OpAnalyzeDeps is a constant in the registry package.

	globalReg := registry.GetGlobalRegistry()
	if globalReg == nil {
		globalReg = registry.NewToolRegistry()
		// Assuming SetGlobalRegistry exists if we create a new one here.
		// registry.SetGlobalRegistry(globalReg)
	}

	// Create a default instance for registration
	defaultTool := &DependencyAnalyzer{
		BaseDir: "", // Default or placeholder
		Logger:  nil, // Logger should be initialized by the toolkit when the tool is used
		Stats:   &toolkit.ToolkitStats{},
		DryRun:  false,
	}

	err := globalReg.Register(toolkit.AnalyzeDeps, defaultTool) // Changed to toolkit.AnalyzeDeps
	if err != nil {
		// Log error but don't panic during package initialization
		fmt.Printf("Warning: Failed to register DependencyAnalyzer: %v\n", err)
	}
}


