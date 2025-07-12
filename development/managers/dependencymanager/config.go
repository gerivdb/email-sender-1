package dependency

import "github.com/gerivdb/email-sender-1/development/managers/interfaces"

type Config struct {
	Dependency     interfaces.DependencyConfig
	PackageManager interfaces.PackageManagerConfig
	Registry       interfaces.RegistryConfig
	Auth           interfaces.AuthConfig
	Security       interfaces.SecurityConfig
	Resolution     interfaces.ResolutionConfig
	Cache          interfaces.CacheConfig
}

func NewConfig() *Config {
	return &Config{
		Dependency:     interfaces.DependencyConfig{},
		PackageManager: interfaces.PackageManagerConfig{},
		Registry:       interfaces.RegistryConfig{},
		Auth:           interfaces.AuthConfig{},
		Security:       interfaces.SecurityConfig{},
		Resolution:     interfaces.ResolutionConfig{},
		Cache:          interfaces.CacheConfig{},
	}
}
