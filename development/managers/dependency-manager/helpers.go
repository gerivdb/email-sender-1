package dependency

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"strings"

	"d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/development/managers/interfaces"
)

// ConfigFile représente un fichier de configuration de dépendances
type ConfigFile struct {
	Path         string
	Type         string // "go.mod", "package.json", etc.
	PackageManager string // "go", "npm", "yarn"
}

// detectConfigFiles détecte les fichiers de configuration dans un projet
func (dm *DependencyManagerImpl) detectConfigFiles(projectPath string) ([]ConfigFile, error) {
	var configFiles []ConfigFile

	// Rechercher go.mod
	goModPath := filepath.Join(projectPath, "go.mod")
	if _, err := os.Stat(goModPath); err == nil {
		configFiles = append(configFiles, ConfigFile{
			Path:         goModPath,
			Type:         "go.mod",
			PackageManager: "go",
		})
	}

	// Rechercher package.json
	packageJsonPath := filepath.Join(projectPath, "package.json")
	if _, err := os.Stat(packageJsonPath); err == nil {
		configFiles = append(configFiles, ConfigFile{
			Path:         packageJsonPath,
			Type:         "package.json", 
			PackageManager: "npm",
		})
	}

	// Rechercher yarn.lock
	yarnLockPath := filepath.Join(projectPath, "yarn.lock")
	if _, err := os.Stat(yarnLockPath); err == nil {
		// Si yarn.lock existe, mettre à jour le package manager
		for i := range configFiles {
			if configFiles[i].Type == "package.json" {
				configFiles[i].PackageManager = "yarn"
				break
			}
		}
	}

	// Rechercher Cargo.toml (Rust)
	cargoTomlPath := filepath.Join(projectPath, "Cargo.toml")
	if _, err := os.Stat(cargoTomlPath); err == nil {
		configFiles = append(configFiles, ConfigFile{
			Path:         cargoTomlPath,
			Type:         "Cargo.toml",
			PackageManager: "cargo",
		})
	}

	// Rechercher requirements.txt (Python)
	reqTxtPath := filepath.Join(projectPath, "requirements.txt")
	if _, err := os.Stat(reqTxtPath); err == nil {
		configFiles = append(configFiles, ConfigFile{
			Path:         reqTxtPath,
			Type:         "requirements.txt",
			PackageManager: "pip",
		})
	}

	return configFiles, nil
}

// analyzeConfigFile analyse un fichier de configuration spécifique
func (dm *DependencyManagerImpl) analyzeConfigFile(ctx context.Context, config ConfigFile) ([]interfaces.DependencyMetadata, []interfaces.DependencyMetadata, error) {
	switch config.Type {
	case "go.mod":
		return dm.analyzeGoMod(ctx, config.Path)
	case "package.json":
		return dm.analyzePackageJson(ctx, config.Path)
	case "Cargo.toml":
		return dm.analyzeCargoToml(ctx, config.Path)
	case "requirements.txt":
		return dm.analyzeRequirements(ctx, config.Path)
	default:
		return nil, nil, fmt.Errorf("unsupported config file type: %s", config.Type)
	}
}

// analyzeGoMod analyse un fichier go.mod
func (dm *DependencyManagerImpl) analyzeGoMod(ctx context.Context, modPath string) ([]interfaces.DependencyMetadata, []interfaces.DependencyMetadata, error) {
	content, err := os.ReadFile(modPath)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to read go.mod: %w", err)
	}

	var directDeps []interfaces.DependencyMetadata
	var transitiveDeps []interfaces.DependencyMetadata

	lines := strings.Split(string(content), "\n")
	inRequireBlock := false

	for _, line := range lines {
		line = strings.TrimSpace(line)
		
		if strings.HasPrefix(line, "require (") {
			inRequireBlock = true
			continue
		}
		
		if inRequireBlock && line == ")" {
			inRequireBlock = false
			continue
		}

		if strings.HasPrefix(line, "require ") || inRequireBlock {
			if line == "" || strings.HasPrefix(line, "//") {
				continue
			}

			// Parser la ligne de dépendance
			parts := strings.Fields(line)
			if len(parts) >= 2 {
				name := strings.TrimPrefix(parts[0], "require ")
				version := parts[1]
				
				// Supprimer les commentaires
				if idx := strings.Index(version, "//"); idx != -1 {
					version = strings.TrimSpace(version[:idx])
				}

				dep := interfaces.DependencyMetadata{
					Name:           name,
					Version:        version,
					Type:           "go",
					Direct:         true,
					Required:       true,
					Source:         modPath,
					PackageManager: "go",
				}

				directDeps = append(directDeps, dep)

				// Ajouter au graphe des dépendances
				dm.dependencyGraph.AddNode(name, version, true)
			}
		}
	}

	return directDeps, transitiveDeps, nil
}

// analyzePackageJson analyse un fichier package.json
func (dm *DependencyManagerImpl) analyzePackageJson(ctx context.Context, packagePath string) ([]interfaces.DependencyMetadata, []interfaces.DependencyMetadata, error) {
	content, err := os.ReadFile(packagePath)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to read package.json: %w", err)
	}

	var pkg struct {
		Dependencies    map[string]string `json:"dependencies"`
		DevDependencies map[string]string `json:"devDependencies"`
	}

	if err := json.Unmarshal(content, &pkg); err != nil {
		return nil, nil, fmt.Errorf("failed to parse package.json: %w", err)
	}

	var directDeps []interfaces.DependencyMetadata

	// Analyser les dépendances de production
	for name, version := range pkg.Dependencies {
		dep := interfaces.DependencyMetadata{
			Name:           name,
			Version:        version,
			Type:           "npm",
			Direct:         true,
			Required:       true,
			Source:         packagePath,
			PackageManager: "npm",
		}
		directDeps = append(directDeps, dep)
		dm.dependencyGraph.AddNode(name, version, true)
	}

	// Analyser les dépendances de développement
	for name, version := range pkg.DevDependencies {
		dep := interfaces.DependencyMetadata{
			Name:           name,
			Version:        version,
			Type:           "npm",
			Direct:         true,
			Required:       false,
			Source:         packagePath,
			PackageManager: "npm",
		}
		directDeps = append(directDeps, dep)
		dm.dependencyGraph.AddNode(name, version, true)
	}

	return directDeps, []interfaces.DependencyMetadata{}, nil
}

// analyzeCargoToml analyse un fichier Cargo.toml
func (dm *DependencyManagerImpl) analyzeCargoToml(ctx context.Context, cargoPath string) ([]interfaces.DependencyMetadata, []interfaces.DependencyMetadata, error) {
	// Implémentation basique pour Cargo.toml
	// Dans un vrai projet, on utiliserait une bibliothèque TOML
	return []interfaces.DependencyMetadata{}, []interfaces.DependencyMetadata{}, nil
}

// analyzeRequirements analyse un fichier requirements.txt
func (dm *DependencyManagerImpl) analyzeRequirements(ctx context.Context, reqPath string) ([]interfaces.DependencyMetadata, []interfaces.DependencyMetadata, error) {
	content, err := os.ReadFile(reqPath)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to read requirements.txt: %w", err)
	}

	var directDeps []interfaces.DependencyMetadata
	lines := strings.Split(string(content), "\n")

	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}

		// Parser la ligne (ex: "package==1.0.0" ou "package>=1.0.0")
		var name, version string
		if strings.Contains(line, "==") {
			parts := strings.Split(line, "==")
			if len(parts) == 2 {
				name, version = parts[0], parts[1]
			}
		} else if strings.Contains(line, ">=") {
			parts := strings.Split(line, ">=")
			if len(parts) == 2 {
				name, version = parts[0], parts[1]
			}
		} else {
			name = line
			version = "latest"
		}

		if name != "" {
			dep := interfaces.DependencyMetadata{
				Name:           name,
				Version:        version,
				Type:           "python",
				Direct:         true,
				Required:       true,
				Source:         reqPath,
				PackageManager: "pip",
			}
			directDeps = append(directDeps, dep)
			dm.dependencyGraph.AddNode(name, version, true)
		}
	}

	return directDeps, []interfaces.DependencyMetadata{}, nil
}

// detectDependencyConflicts détecte les conflits entre dépendances
func (dm *DependencyManagerImpl) detectDependencyConflicts(direct, transitive []interfaces.DependencyMetadata) []interfaces.DependencyConflict {
	var conflicts []interfaces.DependencyConflict
	dependencies := make(map[string][]interfaces.DependencyMetadata)

	// Grouper les dépendances par nom
	for _, dep := range append(direct, transitive...) {
		dependencies[dep.Name] = append(dependencies[dep.Name], dep)
	}

	// Détecter les conflits de version
	for name, deps := range dependencies {
		if len(deps) > 1 {
			versions := make(map[string]bool)
			for _, dep := range deps {
				versions[dep.Version] = true
			}

			if len(versions) > 1 {
				var conflictVersions []string
				for version := range versions {
					conflictVersions = append(conflictVersions, version)
				}

				conflict := interfaces.DependencyConflict{
					PackageName:       name,
					ConflictType:      "version",
					ConflictingVersions: conflictVersions,
					Description:       fmt.Sprintf("Multiple versions of %s found: %s", name, strings.Join(conflictVersions, ", ")),
					Severity:          "high",
				}
				conflicts = append(conflicts, conflict)
			}
		}
	}

	return conflicts
}

// detectResolutionConflicts détecte les conflits dans la résolution
func (dm *DependencyManagerImpl) detectResolutionConflicts(packages []interfaces.ResolvedPackage) []interfaces.DependencyConflict {
	var conflicts []interfaces.DependencyConflict
	packageVersions := make(map[string][]string)

	// Grouper les packages par nom
	for _, pkg := range packages {
		packageVersions[pkg.Name] = append(packageVersions[pkg.Name], pkg.Version)
	}

	// Détecter les conflits
	for name, versions := range packageVersions {
		if len(versions) > 1 {
			uniqueVersions := make(map[string]bool)
			for _, v := range versions {
				uniqueVersions[v] = true
			}

			if len(uniqueVersions) > 1 {
				var conflictVersions []string
				for version := range uniqueVersions {
					conflictVersions = append(conflictVersions, version)
				}

				conflict := interfaces.DependencyConflict{
					PackageName:         name,
					ConflictType:        "resolution",
					ConflictingVersions: conflictVersions,
					Description:         fmt.Sprintf("Package %s resolved to multiple versions: %s", name, strings.Join(conflictVersions, ", ")),
					Severity:            "medium",
				}
				conflicts = append(conflicts, conflict)
			}
		}
	}

	return conflicts
}

// analyzeVulnerabilities analyse les vulnérabilités dans les dépendances
func (dm *DependencyManagerImpl) analyzeVulnerabilities(ctx context.Context, direct, transitive []interfaces.DependencyMetadata) []interfaces.Vulnerability {
	var vulnerabilities []interfaces.Vulnerability

	// Pour cette implémentation basique, on simule quelques vulnérabilités connues
	knownVulns := map[string]map[string]interfaces.Vulnerability{
		"lodash": {
			"4.17.20": {
				ID:          "CVE-2021-23337",
				PackageName: "lodash",
				Version:     "4.17.20",
				Severity:    "high",
				Description: "Command injection vulnerability in lodash",
				CVSS:        7.5,
				References:  []string{"https://nvd.nist.gov/vuln/detail/CVE-2021-23337"},
			},
		},
		"express": {
			"4.16.0": {
				ID:          "CVE-2022-24999",
				PackageName: "express",
				Version:     "4.16.0",
				Severity:    "medium",
				Description: "Open redirect vulnerability in express",
				CVSS:        5.4,
				References:  []string{"https://nvd.nist.gov/vuln/detail/CVE-2022-24999"},
			},
		},
	}

	// Vérifier toutes les dépendances
	allDeps := append(direct, transitive...)
	for _, dep := range allDeps {
		if packageVulns, exists := knownVulns[dep.Name]; exists {
			if vuln, versionExists := packageVulns[dep.Version]; versionExists {
				vulnerabilities = append(vulnerabilities, vuln)
			}
		}
	}

	return vulnerabilities
}

// determineUpdateType détermine le type de mise à jour (major, minor, patch)
func (dm *DependencyManagerImpl) determineUpdateType(current, latest string) string {
	// Utiliser le version manager pour comparer
	if dm.versionManager.IsMajorUpdate(current, latest) {
		return "major"
	}
	if dm.versionManager.IsMinorUpdate(current, latest) {
		return "minor"
	}
	return "patch"
}
