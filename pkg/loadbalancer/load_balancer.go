package loadbalancer

import (
	"context"
	"errors"
	"math/rand"
	"sync"
	"time"
)

// BackendInstance représente une instance Go API/CLI ou worker
type BackendInstance struct {
	ID        string
	Address   string
	Healthy   bool
	LastCheck time.Time
	Latency   time.Duration
	Load      int // nombre de jobs en cours
}

// LoadBalancer interface
type LoadBalancer interface {
	Register(instance *BackendInstance) error
	Unregister(instanceID string) error
	PickInstance(ctx context.Context) (*BackendInstance, error)
	UpdateHealth(instanceID string, healthy bool, latency time.Duration)
	GetAllInstances() []*BackendInstance
}

// SimpleLoadBalancer implémentation round-robin + health-check + load-aware
type SimpleLoadBalancer struct {
	instances map[string]*BackendInstance
	order     []string
	mu        sync.RWMutex
	rrIndex   int
}

// NewSimpleLoadBalancer crée un load balancer vide
func NewSimpleLoadBalancer() *SimpleLoadBalancer {
	return &SimpleLoadBalancer{
		instances: make(map[string]*BackendInstance),
		order:     make([]string, 0),
		rrIndex:   0,
	}
}

// Register ajoute une instance
func (lb *SimpleLoadBalancer) Register(instance *BackendInstance) error {
	lb.mu.Lock()
	defer lb.mu.Unlock()
	if _, exists := lb.instances[instance.ID]; exists {
		return errors.New("instance already registered")
	}
	lb.instances[instance.ID] = instance
	lb.order = append(lb.order, instance.ID)
	return nil
}

// Unregister retire une instance
func (lb *SimpleLoadBalancer) Unregister(instanceID string) error {
	lb.mu.Lock()
	defer lb.mu.Unlock()
	if _, exists := lb.instances[instanceID]; !exists {
		return errors.New("instance not found")
	}
	delete(lb.instances, instanceID)
	for i, id := range lb.order {
		if id == instanceID {
			lb.order = append(lb.order[:i], lb.order[i+1:]...)
			break
		}
	}
	return nil
}

// PickInstance choisit une instance saine avec le moins de charge (ou round-robin fallback)
func (lb *SimpleLoadBalancer) PickInstance(ctx context.Context) (*BackendInstance, error) {
	lb.mu.RLock()
	defer lb.mu.RUnlock()
	healthy := make([]*BackendInstance, 0)
	for _, id := range lb.order {
		inst := lb.instances[id]
		if inst.Healthy {
			healthy = append(healthy, inst)
		}
	}
	if len(healthy) == 0 {
		return nil, errors.New("no healthy instances available")
	}
	// Load-aware: choisir l'instance avec le moins de jobs
	minLoad := healthy[0].Load
	candidates := []*BackendInstance{healthy[0]}
	for _, inst := range healthy[1:] {
		if inst.Load < minLoad {
			minLoad = inst.Load
			candidates = []*BackendInstance{inst}
		} else if inst.Load == minLoad {
			candidates = append(candidates, inst)
		}
	}
	// Si plusieurs candidats, choisir au hasard ou round-robin
	if len(candidates) == 1 {
		return candidates[0], nil
	}
	return candidates[rand.Intn(len(candidates))], nil
}

// UpdateHealth met à jour l'état de santé et la latence
func (lb *SimpleLoadBalancer) UpdateHealth(instanceID string, healthy bool, latency time.Duration) {
	lb.mu.Lock()
	defer lb.mu.Unlock()
	if inst, exists := lb.instances[instanceID]; exists {
		inst.Healthy = healthy
		inst.LastCheck = time.Now()
		inst.Latency = latency
	}
}

// GetAllInstances retourne toutes les instances
func (lb *SimpleLoadBalancer) GetAllInstances() []*BackendInstance {
	lb.mu.RLock()
	defer lb.mu.RUnlock()
	result := make([]*BackendInstance, 0, len(lb.instances))
	for _, inst := range lb.instances {
		result = append(result, inst)
	}
	return result
}
