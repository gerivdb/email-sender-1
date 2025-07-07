package dependency

import (
	"context"
	"fmt"
	"time"

	"github.com/email-sender-manager/interfaces"
)

// PackageResolverImpl implémente PackageResolver
type PackageResolverImpl struct {
	config         *DependencyConfig
	versionManager interfaces.VersionManager
	cache          map[string]*interfaces.ResolvedPackage
}

// NewPackageResolver crée un nouveau résolveur de packages
func NewPackageResolver(config *DependencyConfig) interfaces.PackageResolver {
	return &PackageResolverImpl{
		config:         config,
		versionManager: NewVersionManager(),
		cache:          make(map[string]*interfaces.ResolvedPackage),
	}
}

// Resolve résout un package spécifique
func (pr *PackageResolverImpl) Resolve(ctx context.Context, packageName, version string) (*interfaces.ResolvedPackage, error) {
	cacheKey := fmt.Sprintf("%s@%s", packageName, version)

	// Check cache first
	if cached, exists := pr.cache[cacheKey]; exists {
		return cached, nil
	}

	// Timeout context
	ctx, cancel := context.WithTimeout(ctx, pr.config.Resolution.Timeout)
	defer cancel()

	// Resolve based on package manager type
	var resolved *interfaces.ResolvedPackage
	var err error

	switch pr.detectPackageManager(packageName) {
	case "go":
		resolved, err = pr.resolveGoPackage(ctx, packageName, version)
	case "npm":
		resolved, err = pr.resolveNpmPackage(ctx, packageName, version)
	default:
		return nil, fmt.Errorf("unsupported package manager for %s", packageName)
	}

	if err != nil {
		return nil, err
	}

	// Cache the result
	pr.cache[cacheKey] = resolved

	return resolved, nil
}

// GetVersions retourne toutes les versions disponibles d'un package
func (pr *PackageResolverImpl) GetVersions(ctx context.Context, packageName string) ([]string, error) {
	switch pr.detectPackageManager(packageName) {
	case "go":
		return pr.getGoVersions(ctx, packageName)
	case "npm":
		return pr.getNpmVersions(ctx, packageName)
	default:
		return nil, fmt.Errorf("unsupported package manager for %s", packageName)
	}
}

// FindCompatibleVersion trouve une version compatible
func (pr *PackageResolverImpl) FindCompatibleVersion(ctx context.Context, packageName string, constraints []string) (string, error) {
	versions, err := pr.GetVersions(ctx, packageName)
	if err != nil {
		return "", err
	}

	if vm, ok := pr.versionManager.(*VersionManagerImpl); ok {
		return vm.FindBestVersion(versions, constraints)
	}

	// Fallback: return latest if no constraints
	if len(constraints) == 0 && len(versions) > 0 {
		return versions[len(versions)-1], nil
	}

	return "", fmt.Errorf("no compatible version found")
}

// detectPackageManager détecte le gestionnaire de packages
func (pr *PackageResolverImpl) detectPackageManager(packageName string) string {
	// Simple heuristic based on package name patterns
	if packageName == "go" || packageName == "golang" {
		return "go"
	}

	// Check if it looks like a Go module
	if packageName != "" && (packageName[0] != '@' && packageName != "") {
		return "go"
	}

	// Default to npm for @scoped packages
	if len(packageName) > 0 && packageName[0] == '@' {
		return "npm"
	}

	return "go" // default
}

// resolveGoPackage résout un package Go
func (pr *PackageResolverImpl) resolveGoPackage(ctx context.Context, packageName, version string) (*interfaces.ResolvedPackage, error) {
	// Placeholder implementation for Go packages
	// In real implementation, this would query the Go proxy API

	return &interfaces.ResolvedPackage{
		Name:         packageName,
		Version:      version,
		Source:       pr.config.Registry.DefaultRegistry,
		Dependencies: []string{}, // Would be populated from actual resolution
		Metadata: map[string]interface{}{
			"type":        "go",
			"resolved_at": time.Now(),
		},
	}, nil
}

// resolveNpmPackage résout un package npm
func (pr *PackageResolverImpl) resolveNpmPackage(ctx context.Context, packageName, version string) (*interfaces.ResolvedPackage, error) {
	// Placeholder implementation for npm packages

	return &interfaces.ResolvedPackage{
		Name:         packageName,
		Version:      version,
		Source:       "https://registry.npmjs.org",
		Dependencies: []string{},
		Metadata: map[string]interface{}{
			"type":        "npm",
			"resolved_at": time.Now(),
		},
	}, nil
}

// getGoVersions récupère les versions Go disponibles
func (pr *PackageResolverImpl) getGoVersions(ctx context.Context, packageName string) ([]string, error) {
	// Placeholder - would query Go proxy API
	return []string{"v1.0.0", "v1.1.0", "v1.2.0"}, nil
}

// getNpmVersions récupère les versions npm disponibles
func (pr *PackageResolverImpl) getNpmVersions(ctx context.Context, packageName string) ([]string, error) {
	// Placeholder - would query npm registry API
	return []string{"1.0.0", "1.1.0", "1.2.0"}, nil
}
