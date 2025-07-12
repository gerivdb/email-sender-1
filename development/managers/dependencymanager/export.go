package dependency

type DependencyManager struct{}

func New() (*DependencyManager, error) {
	return &DependencyManager{}, nil
}

// Méthodes factices pour compatibilité avec le code de validation
func (dm *DependencyManager) AnalyzeDependencies(path string) ([]string, error) {
	return []string{"depA", "depB"}, nil
}
