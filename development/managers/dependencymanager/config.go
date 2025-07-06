package dependency

import (
	"os"
	"strconv"
	"time"
)

// loadDependencyConfig charge la configuration
func loadDependencyConfig() *DependencyConfig {
	return &DependencyConfig{
		ProjectPath: getEnv("PROJECT_PATH", "."),
		PackageManagers: []PackageManagerConfig{
			{
				Type:       "go",
				ConfigFile: "go.mod",
				LockFile:   "go.sum",
				Enabled:    true,
			},
			{
				Type:       "npm",
				ConfigFile: "package.json",
				LockFile:   "package-lock.json",
				Enabled:    false,
			},
		},
		Registry: RegistryConfig{
			DefaultRegistry: getEnv("DEFAULT_REGISTRY", "https://proxy.golang.org"),
			Mirrors:         make(map[string]string),
			Authentication: AuthConfig{
				Token: getEnv("REGISTRY_TOKEN", ""),
			},
		},
		Security: SecurityConfig{
			VulnerabilityCheck: getEnvBool("VULNERABILITY_CHECK", true),
			AllowedLicenses:    []string{"MIT", "Apache-2.0", "BSD-3-Clause"},
			BlockedPackages:    []string{},
			MinSecurityLevel:   getEnv("MIN_SECURITY_LEVEL", "medium"),
		},
		Resolution: ResolutionConfig{
			Strategy:        getEnv("RESOLUTION_STRATEGY", "latest"),
			Timeout:         getDuration("RESOLUTION_TIMEOUT", "30s"),
			MaxRetries:      getEnvInt("MAX_RETRIES", 3),
			PreferStable:    getEnvBool("PREFER_STABLE", true),
			AllowPrerelease: getEnvBool("ALLOW_PRERELEASE", false),
		},
		Cache: CacheConfig{
			Enabled:   getEnvBool("CACHE_ENABLED", true),
			TTL:       getDuration("CACHE_TTL", "24h"),
			MaxSize:   getEnvInt("CACHE_MAX_SIZE", 1000),
			Directory: getEnv("CACHE_DIRECTORY", "./.dependency-cache"),
		},
	}
}

// Helper functions
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}

func getEnvBool(key string, defaultValue bool) bool {
	if value := os.Getenv(key); value != "" {
		if boolValue, err := strconv.ParseBool(value); err == nil {
			return boolValue
		}
	}
	return defaultValue
}

func getDuration(key string, defaultValue string) time.Duration {
	value := getEnv(key, defaultValue)
	if duration, err := time.ParseDuration(value); err == nil {
		return duration
	}
	// Fallback to default
	if duration, err := time.ParseDuration(defaultValue); err == nil {
		return duration
	}
	return time.Hour // ultimate fallback
}
