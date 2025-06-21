// SPDX-License-Identifier: MIT
// Package quotas : gestion des quotas multi-tenant (v65)
package quotas

import (
	"time"
)

// QuotaManager gère les quotas multi-tenant
type QuotaManager struct {
	Storage  QuotaStorage
	Monitor  *UsageMonitor
	Alerter  *AlertManager
	Policies map[string]*QuotaPolicy
}

// QuotaPolicy définit la politique de quota
type QuotaPolicy struct {
	ResourceType    string
	Limit           int64
	Period          time.Duration
	ResetTime       time.Time
	AlertThresholds []float64   // [0.8, 0.9, 1.0]
	Action          QuotaAction // throttle, block, alert
}

// QuotaAction type d’action sur dépassement
type QuotaAction string

// Usage suivi d’utilisation
type Usage struct {
	TenantID     string
	UserID       string
	ResourceType string
	Amount       int64
	Timestamp    time.Time
	Metadata     map[string]interface{}
}

// QuotaStorage, UsageMonitor, AlertManager à implémenter selon besoins

// QuotaStorage est une interface pour stocker et récupérer les données de quota.
type QuotaStorage interface {
	// Méthodes à définir, par exemple:
	// GetUsage(tenantID, resourceType string) (int64, error)
	// RecordUsage(usage Usage) error
	// GetPolicy(policyID string) (*QuotaPolicy, error)
}

// UsageMonitor surveille l'utilisation des ressources par rapport aux quotas.
type UsageMonitor struct{}

// AlertManager gère l'envoi d'alertes lorsque les seuils de quota sont atteints.
type AlertManager struct{}
