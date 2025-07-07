package dependency

import (
	"context"
	"fmt"
	"time"

	"github.com/email-sender-manager/interfaces"
)

// Core dependency operations

// AnalyzeDependencies analyse les dépendances d'un projet
func (dm *DependencyManagerImpl) AnalyzeDependencies(ctx context.Context, projectPath string) (*interfaces.DependencyAnalysis, error) {
	if !dm.isInitialized {
		return nil, fmt.Errorf("dependency manager not initialized")
	}

	dm.logger.Printf("Analyzing dependencies for project: %s", projectPath)
	dm.projectPath = projectPath

	startTime := time.Now()

	// Détecter les fichiers de configuration
	configFiles, err := dm.detectConfigFiles(projectPath)
	if err != nil {
		return nil, fmt.Errorf("failed to detect config files: %w", err)
	}

	var directDeps []interfaces.DependencyMetadata
	var transitiveDeps []interfaces.DependencyMetadata
	var conflicts []interfaces.DependencyConflict

	// Analyser chaque gestionnaire de packages
	for _, config := range configFiles {
		deps, transDeps, err := dm.analyzeConfigFile(ctx, config)
		if err != nil {
			dm.logger.Printf("Warning: Failed to analyze %s: %v", config.Path, err)
			continue
		}

		directDeps = append(directDeps, deps...)
		transitiveDeps = append(transitiveDeps, transDeps...)
	}

	// Détecter les conflits
	conflicts = dm.detectDependencyConflicts(directDeps, transitiveDeps)

	// Analyser les vulnérabilités
	vulnerabilities := dm.analyzeVulnerabilities(ctx, directDeps, transitiveDeps)

	analysis := &interfaces.DependencyAnalysis{
		ProjectPath:            projectPath,
		TotalDependencies:      len(directDeps) + len(transitiveDeps),
		DirectDependencies:     directDeps,
		TransitiveDependencies: transitiveDeps,
		Conflicts:              conflicts,
		Vulnerabilities:        vulnerabilities,
		AnalyzedAt:             time.Now(),
	}

	dm.logger.Printf("Analysis completed in %v - Found %d direct, %d transitive dependencies",
		time.Since(startTime), len(directDeps), len(transitiveDeps))

	return analysis, nil
}

// ResolveDependencies résout une liste de dépendances
func (dm *DependencyManagerImpl) ResolveDependencies(ctx context.Context, dependencies []string) (*interfaces.ResolutionResult, error) {
	if !dm.isInitialized {
		return nil, fmt.Errorf("dependency manager not initialized")
	}

	startTime := time.Now()
	dm.logger.Printf("Resolving %d dependencies", len(dependencies))

	result := &interfaces.ResolutionResult{
		Success:          true,
		ResolvedPackages: []interfaces.ResolvedPackage{},
		Conflicts:        []interfaces.DependencyConflict{},
		Errors:           []string{},
		ResolutionTime:   0,
	}

	// Résoudre chaque dépendance
	for _, dep := range dependencies {
		resolved, err := dm.packageResolver.Resolve(ctx, dep, "latest")
		if err != nil {
			result.Success = false
			result.Errors = append(result.Errors, fmt.Sprintf("Failed to resolve %s: %v", dep, err))
			continue
		}

		result.ResolvedPackages = append(result.ResolvedPackages, *resolved)
	}

	// Détecter les conflits dans la résolution
	result.Conflicts = dm.detectResolutionConflicts(result.ResolvedPackages)
	if len(result.Conflicts) > 0 {
		result.Success = false
	}

	result.ResolutionTime = time.Since(startTime)
	dm.logger.Printf("Resolution completed in %v - %d packages resolved, %d conflicts",
		result.ResolutionTime, len(result.ResolvedPackages), len(result.Conflicts))

	return result, nil
}

// UpdateDependency met à jour une dépendance spécifique
func (dm *DependencyManagerImpl) UpdateDependency(ctx context.Context, name, version string) error {
	if !dm.isInitialized {
		return fmt.Errorf("dependency manager not initialized")
	}

	dm.logger.Printf("Updating dependency %s to version %s", name, version)

	// Vérifier que la version existe
	versions, err := dm.packageResolver.GetVersions(ctx, name)
	if err != nil {
		return fmt.Errorf("failed to get versions for %s: %w", name, err)
	}

	versionExists := false
	for _, v := range versions {
		if v == version {
			versionExists = true
			break
		}
	}

	if !versionExists {
		return fmt.Errorf("version %s not found for package %s", version, name)
	}

	// Mettre à jour dans le graphe des dépendances
	dm.dependencyGraph.mu.Lock()
	if node, exists := dm.dependencyGraph.Nodes[name]; exists {
		node.Version = version
		dm.logger.Printf("Updated %s to version %s", name, version)
	} else {
		dm.logger.Printf("Package %s not found in dependency graph", name)
	}
	dm.dependencyGraph.mu.Unlock()

	return nil
}

// CheckForUpdates vérifie les mises à jour disponibles
func (dm *DependencyManagerImpl) CheckForUpdates(ctx context.Context) ([]interfaces.DependencyUpdate, error) {
	if !dm.isInitialized {
		return nil, fmt.Errorf("dependency manager not initialized")
	}

	dm.logger.Println("Checking for dependency updates...")

	var updates []interfaces.DependencyUpdate

	dm.dependencyGraph.mu.RLock()
	for name, node := range dm.dependencyGraph.Nodes {
		if !node.Direct {
			continue // Only check direct dependencies
		}

		latest, err := dm.versionManager.GetLatestVersion(ctx, name)
		if err != nil {
			dm.logger.Printf("Warning: Failed to get latest version for %s: %v", name, err)
			continue
		}

		if dm.versionManager.CompareVersions(latest, node.Version) > 0 {
			updateType := dm.determineUpdateType(node.Version, latest)
			updates = append(updates, interfaces.DependencyUpdate{
				Name:           name,
				CurrentVersion: node.Version,
				LatestVersion:  latest,
				UpdateType:     updateType,
				BreakingChange: updateType == "major",
			})
		}
	}
	dm.dependencyGraph.mu.RUnlock()

	dm.logger.Printf("Found %d available updates", len(updates))
	return updates, nil
}
