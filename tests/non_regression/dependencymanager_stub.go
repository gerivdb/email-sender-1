// tests/non_regression/dependencymanager_stub.go
package non_regression

type Dependency struct {
	Name    string
	Version string
}

type DependencyManager struct {
	deps map[string]Dependency
}

func New() *DependencyManager {
	return &DependencyManager{deps: make(map[string]Dependency)}
}

func (dm *DependencyManager) AddDependency(name, version string) error {
	dm.deps[name] = Dependency{Name: name, Version: version}
	return nil
}

func (dm *DependencyManager) RemoveDependency(name string) error {
	delete(dm.deps, name)
	return nil
}

func (dm *DependencyManager) HasDependency(name string) bool {
	_, ok := dm.deps[name]
	return ok
}

func (dm *DependencyManager) ListDependencies() []Dependency {
	result := []Dependency{}
	for _, dep := range dm.deps {
		result = append(result, dep)
	}
	return result
}
