package config

import (
	"time"
)

// ConfigFormat type de format supporté
type ConfigFormat string

// MergeStrategy stratégie de fusion
type MergeStrategy string

// ConfigVersion version de configuration
type ConfigVersion struct {
	Timestamp time.Time
	Format    ConfigFormat
	Data      []byte
}

// ExportOptions options d’export
type ExportOptions struct {
	Format         ConfigFormat // yaml, json, toml
	IncludeSecrets bool
	Encrypt        bool
	Compression    bool
}

// ImportOptions options d’import
type ImportOptions struct {
	MergeStrategy MergeStrategy // replace, merge, merge-no-override
	DryRun        bool
	BackupBefore  bool
	ValidateOnly  bool
}

// ExportConfig exporte la configuration selon les options
func (cm *ConfigManager) ExportConfig(opts ExportOptions) ([]byte, error) {
	// TODO: sérialisation, validation, chiffrement, compression
	return nil, nil
}

// ImportConfig importe la configuration selon les options
func (cm *ConfigManager) ImportConfig(data []byte, opts ImportOptions) error {
	// TODO: validation, backup, merge, rollback, déchiffrement
	return nil
}
