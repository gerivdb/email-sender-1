package tenant

import (
	"errors"
	"sync"
	"time"
)

// Tenant représente un client/isolation logique
type Tenant struct {
	ID        string
	Name      string
	CreatedAt time.Time
	Config    map[string]interface{}
	Queues    map[string]string // logical queue name → physical queue name
}

// TenantManager gère les tenants et leur isolation
type TenantManager struct {
	tenants map[string]*Tenant
	mu      sync.RWMutex
}

// NewTenantManager crée un gestionnaire multi-tenant
func NewTenantManager() *TenantManager {
	return &TenantManager{
		tenants: make(map[string]*Tenant),
	}
}

// CreateTenant ajoute un nouveau tenant
func (tm *TenantManager) CreateTenant(id, name string, config map[string]interface{}) (*Tenant, error) {
	tm.mu.Lock()
	defer tm.mu.Unlock()
	if _, exists := tm.tenants[id]; exists {
		return nil, errors.New("tenant already exists")
	}
	tenant := &Tenant{
		ID:        id,
		Name:      name,
		CreatedAt: time.Now(),
		Config:    config,
		Queues:    make(map[string]string),
	}
	tm.tenants[id] = tenant
	return tenant, nil
}

// GetTenant récupère un tenant par ID
func (tm *TenantManager) GetTenant(id string) (*Tenant, error) {
	tm.mu.RLock()
	defer tm.mu.RUnlock()
	tenant, exists := tm.tenants[id]
	if !exists {
		return nil, errors.New("tenant not found")
	}
	return tenant, nil
}

// ListTenants retourne tous les tenants
func (tm *TenantManager) ListTenants() []*Tenant {
	tm.mu.RLock()
	defer tm.mu.RUnlock()
	result := make([]*Tenant, 0, len(tm.tenants))
	for _, t := range tm.tenants {
		result = append(result, t)
	}
	return result
}

// AssignQueue mappe une queue logique à une queue physique pour un tenant
func (tm *TenantManager) AssignQueue(tenantID, logicalQueue, physicalQueue string) error {
	tm.mu.Lock()
	defer tm.mu.Unlock()
	tenant, exists := tm.tenants[tenantID]
	if !exists {
		return errors.New("tenant not found")
	}
	tenant.Queues[logicalQueue] = physicalQueue
	return nil
}

// GetQueue retourne la queue physique pour un tenant et une queue logique
func (tm *TenantManager) GetQueue(tenantID, logicalQueue string) (string, error) {
	tm.mu.RLock()
	defer tm.mu.RUnlock()
	tenant, exists := tm.tenants[tenantID]
	if !exists {
		return "", errors.New("tenant not found")
	}
	queue, exists := tenant.Queues[logicalQueue]
	if !exists {
		return "", errors.New("queue not assigned")
	}
	return queue, nil
}
