package storage

import (
	"os"
	"path/filepath"
)

// GetDefaultStoragePath returns the standardized storage path for roadmap data
// This ensures both CLI and TUI use the same storage location
func GetDefaultStoragePath() string {
	// Check for environment variable override first
	if envPath := os.Getenv("ROADMAP_STORAGE_PATH"); envPath != "" {
		return envPath
	}

	// Use user's home directory as default
	homeDir, err := os.UserHomeDir()
	if err != nil {
		// Fallback to current directory if home directory not accessible
		return "./roadmap.json"
	}

	// Create .roadmap-cli directory if it doesn't exist
	configDir := filepath.Join(homeDir, ".roadmap-cli")
	os.MkdirAll(configDir, 0755)

	return filepath.Join(configDir, "roadmap.json")
}

// GetStorageDir returns the directory portion of the storage path
func GetStorageDir() string {
	storagePath := GetDefaultStoragePath()
	return filepath.Dir(storagePath)
}
