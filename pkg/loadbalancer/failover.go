package loadbalancer

import (
	"context"
	"sync"
	"time"
)

// FailoverManager gère le failover automatique des instances
type FailoverManager struct {
	instances  map[string]*BackendInstance
	primaryID  string
	mu         sync.RWMutex
	failoverCB func(primary *BackendInstance, backup *BackendInstance)
	checkIntv  time.Duration
	stopCh     chan struct{}
}

// NewFailoverManager crée un gestionnaire de failover
func NewFailoverManager(checkIntv time.Duration, cb func(primary, backup *BackendInstance)) *FailoverManager {
	return &FailoverManager{
		instances:  make(map[string]*BackendInstance),
		checkIntv:  checkIntv,
		failoverCB: cb,
		stopCh:     make(chan struct{}),
	}
}

// RegisterInstance ajoute une instance (primary ou backup)
func (fm *FailoverManager) RegisterInstance(id string, inst *BackendInstance, isPrimary bool) {
	fm.mu.Lock()
	defer fm.mu.Unlock()
	fm.instances[id] = inst
	if isPrimary {
		fm.primaryID = id
	}
}

// Start lance la surveillance et le failover automatique
func (fm *FailoverManager) Start(ctx context.Context) {
	go func() {
		ticker := time.NewTicker(fm.checkIntv)
		defer ticker.Stop()
		for {
			select {
			case <-fm.stopCh:
				return
			case <-ticker.C:
				fm.checkFailover()
			}
		}
	}()
}

// Stop arrête la surveillance
func (fm *FailoverManager) Stop() {
	close(fm.stopCh)
}

// checkFailover détecte une panne et déclenche le failover
func (fm *FailoverManager) checkFailover() {
	fm.mu.Lock()
	defer fm.mu.Unlock()
	primary, ok := fm.instances[fm.primaryID]
	if !ok || !primary.Healthy {
		for id, inst := range fm.instances {
			if id != fm.primaryID && inst.Healthy {
				if fm.failoverCB != nil {
					fm.failoverCB(primary, inst)
				}
				fm.primaryID = id
				break
			}
		}
	}
}

// Example usage:
/*
func main() {
fm := loadbalancer.NewFailoverManager(10*time.Second, func(primary, backup *loadbalancer.BackendInstance) {
fmt.Printf("Failover: %s → %s\n", primary.ID, backup.ID)
})
fm.RegisterInstance("go1", &loadbalancer.BackendInstance{ID: "go1", Healthy: true}, true)
fm.RegisterInstance("go2", &loadbalancer.BackendInstance{ID: "go2", Healthy: true}, false)
fm.Start(context.Background())
defer fm.Stop()
}
*/
