package models

import (
	"time"
)

// DefaultValue represents a default value entry in the system
type DefaultValue struct {
	ID          int64     `json:"id" db:"id"`
	Key         string    `json:"key" db:"key"`
	Value       string    `json:"value" db:"value"`
	Context     string    `json:"context" db:"context"`
	Confidence  float64   `json:"confidence" db:"confidence"`
	UsageCount  int64     `json:"usage_count" db:"usage_count"`
	LastUsed    time.Time `json:"last_used" db:"last_used"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time `json:"updated_at" db:"updated_at"`
}

// TableName returns the table name for the DefaultValue model
func (d *DefaultValue) TableName() string {
	return "default_values"
}