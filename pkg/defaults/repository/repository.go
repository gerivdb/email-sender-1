package repository

import (
	"context"
	"d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\pkg\defaults\models"
)

// Repository defines the interface for default value storage operations
type Repository interface {
	// Create stores a new default value
	Create(ctx context.Context, value *models.DefaultValue) error

	// Get retrieves a default value by key and context
	Get(ctx context.Context, key, context string) (*models.DefaultValue, error)

	// Update modifies an existing default value
	Update(ctx context.Context, value *models.DefaultValue) error

	// Delete removes a default value
	Delete(ctx context.Context, id int64) error

	// List retrieves all default values for a given context
	List(ctx context.Context, context string) ([]*models.DefaultValue, error)

	// GetMostConfident returns the most confident value for a key
	GetMostConfident(ctx context.Context, key string) (*models.DefaultValue, error)

	// IncrementUsage increases the usage count of a default value
	IncrementUsage(ctx context.Context, id int64) error
}