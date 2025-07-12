package dependency

type Dependency struct {
	Name    string
	Version string
}

type DependencyManager struct {
	deps map[string]Dependency
}

// ... (autres méthodes et constructeurs déjà présents)
