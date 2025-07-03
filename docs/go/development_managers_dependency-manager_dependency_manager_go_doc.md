# Package dependency

## Types

### ConfigFile

ConfigFile représente un fichier de configuration de dépendances


### PackageResolverImpl

PackageResolverImpl implémente PackageResolver


#### Methods

##### PackageResolverImpl.FindCompatibleVersion

FindCompatibleVersion trouve une version compatible


```go
func (pr *PackageResolverImpl) FindCompatibleVersion(ctx context.Context, packageName string, constraints []string) (string, error)
```

##### PackageResolverImpl.GetVersions

GetVersions retourne toutes les versions disponibles d'un package


```go
func (pr *PackageResolverImpl) GetVersions(ctx context.Context, packageName string) ([]string, error)
```

##### PackageResolverImpl.Resolve

Resolve résout un package spécifique


```go
func (pr *PackageResolverImpl) Resolve(ctx context.Context, packageName, version string) (*interfaces.ResolvedPackage, error)
```

### VersionManagerImpl

VersionManagerImpl implémente VersionManager


#### Methods

##### VersionManagerImpl.CompareVersions

CompareVersions compare deux versions
Retourne: -1 si v1 < v2, 0 si v1 == v2, 1 si v1 > v2


```go
func (vm *VersionManagerImpl) CompareVersions(v1, v2 string) int
```

##### VersionManagerImpl.FindBestVersion

FindBestVersion trouve la meilleure version selon les contraintes


```go
func (vm *VersionManagerImpl) FindBestVersion(versions []string, constraints []string) (string, error)
```

##### VersionManagerImpl.GetLatestStableVersion

GetLatestStableVersion retourne la dernière version stable


```go
func (vm *VersionManagerImpl) GetLatestStableVersion(ctx context.Context, packageName string) (string, error)
```

##### VersionManagerImpl.GetLatestVersion

GetLatestVersion retourne la dernière version d'un package


```go
func (vm *VersionManagerImpl) GetLatestVersion(ctx context.Context, packageName string) (string, error)
```

##### VersionManagerImpl.IsCompatible

IsCompatible vérifie si une version satisfait les contraintes


```go
func (vm *VersionManagerImpl) IsCompatible(version string, constraints []string) bool
```

## Functions

### NewPackageResolver

NewPackageResolver crée un nouveau résolveur de packages


```go
func NewPackageResolver(config *DependencyConfig) interfaces.PackageResolver
```

### NewVersionManager

NewVersionManager crée un nouveau gestionnaire de versions


```go
func NewVersionManager() interfaces.VersionManager
```

# Package main

