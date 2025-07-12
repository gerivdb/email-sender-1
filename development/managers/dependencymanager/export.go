package dependency

type DependencyManager struct{}

func NewGoModManager(modPath string, config interface{}) *DependencyManager {
	return &DependencyManager{}
}

// Méthode factice pour la validation
func (dm *DependencyManager) AnalyzeDependencies(path string) ([]string, error) {
	return []string{"depA", "depB"}, nil
}
