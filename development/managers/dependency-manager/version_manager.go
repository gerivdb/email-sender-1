package dependency

import (
	"context"
	"fmt"
	"strings"

	"github.com/Masterminds/semver/v3"
	"github.com/email-sender-manager/interfaces"
)

// VersionManagerImpl implémente VersionManager
type VersionManagerImpl struct{}

// NewVersionManager crée un nouveau gestionnaire de versions
func NewVersionManager() interfaces.VersionManager {
	return &VersionManagerImpl{}
}

// CompareVersions compare deux versions
// Retourne: -1 si v1 < v2, 0 si v1 == v2, 1 si v1 > v2
func (vm *VersionManagerImpl) CompareVersions(v1, v2 string) int {
	version1, err1 := semver.NewVersion(vm.normalizeVersion(v1))
	version2, err2 := semver.NewVersion(vm.normalizeVersion(v2))

	if err1 != nil || err2 != nil {
		// Fallback to string comparison if semver parsing fails
		if v1 < v2 {
			return -1
		} else if v1 > v2 {
			return 1
		}
		return 0
	}

	return version1.Compare(version2)
}

// IsCompatible vérifie si une version satisfait les contraintes
func (vm *VersionManagerImpl) IsCompatible(version string, constraints []string) bool {
	v, err := semver.NewVersion(vm.normalizeVersion(version))
	if err != nil {
		return false
	}

	for _, constraint := range constraints {
		c, err := semver.NewConstraint(constraint)
		if err != nil {
			continue // Skip invalid constraints
		}

		if !c.Check(v) {
			return false
		}
	}

	return true
}

// GetLatestVersion retourne la dernière version d'un package
func (vm *VersionManagerImpl) GetLatestVersion(ctx context.Context, packageName string) (string, error) {
	// Cette implémentation serait spécifique au gestionnaire de packages
	// Pour Go, on utiliserait la Go proxy API
	// Pour npm, on utiliserait l'API npm registry
	
	// Placeholder implementation
	return "latest", fmt.Errorf("not implemented: GetLatestVersion for %s", packageName)
}

// GetLatestStableVersion retourne la dernière version stable
func (vm *VersionManagerImpl) GetLatestStableVersion(ctx context.Context, packageName string) (string, error) {
	// Cette implémentation filtrerait les versions préliminaires
	
	// Placeholder implementation
	return "stable", fmt.Errorf("not implemented: GetLatestStableVersion for %s", packageName)
}

// normalizeVersion normalise une version pour semver
func (vm *VersionManagerImpl) normalizeVersion(version string) string {
	// Supprimer les préfixes comme 'v'
	version = strings.TrimPrefix(version, "v")
	
	// Ajouter .0 si nécessaire pour faire une version semver valide
	parts := strings.Split(version, ".")
	for len(parts) < 3 {
		parts = append(parts, "0")
	}
	
	return strings.Join(parts, ".")
}

// FindBestVersion trouve la meilleure version selon les contraintes
func (vm *VersionManagerImpl) FindBestVersion(versions []string, constraints []string) (string, error) {
	var validVersions []*semver.Version
	var validVersionStrings []string

	// Filter valid versions
	for _, v := range versions {
		if vm.IsCompatible(v, constraints) {
			if parsed, err := semver.NewVersion(vm.normalizeVersion(v)); err == nil {
				validVersions = append(validVersions, parsed)
				validVersionStrings = append(validVersionStrings, v)
			}
		}
	}

	if len(validVersions) == 0 {
		return "", fmt.Errorf("no compatible version found")
	}

	// Find the highest version
	bestIndex := 0
	for i, v := range validVersions {
		if v.GreaterThan(validVersions[bestIndex]) {
			bestIndex = i
		}
	}

	return validVersionStrings[bestIndex], nil
}
