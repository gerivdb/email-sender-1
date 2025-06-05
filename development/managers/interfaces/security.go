package interfaces

import "context"

// SecurityManager interface pour la gestion de la sécurité
type SecurityManager interface {
	BaseManager
	ScanDependenciesForVulnerabilities(ctx context.Context, deps []string) (*VulnerabilityReport, error)
	ValidateAPIKeyAccess(ctx context.Context, key string) (bool, error)
	LoadSecrets(ctx context.Context) error
	GetSecret(key string) (string, error)
	GenerateAPIKey(ctx context.Context, scope string) (string, error)
	EncryptData(data []byte) ([]byte, error)
	DecryptData(encryptedData []byte) ([]byte, error)
}
