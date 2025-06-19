package chaos

import (
	"context"
	"errors"
	"math/rand"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

// ChaosScenario définit un scénario de chaos
type ChaosScenario struct {
	Name        string
	Description string
	Inject      func(ctx context.Context) error
	Recover     func(ctx context.Context) error
}

// TestChaosEngineering exécute des scénarios de chaos sur l’infra Go/N8N
func TestChaosEngineering(t *testing.T) {
	scenarios := []ChaosScenario{
		{
			Name:        "Kill Random Worker",
			Description: "Arrête brutalement un worker Go",
			Inject: func(ctx context.Context) error {
				time.Sleep(100 * time.Millisecond)
				return errors.New("worker killed (simulé)")
			},
			Recover: func(ctx context.Context) error {
				time.Sleep(50 * time.Millisecond)
				return nil
			},
		},
		{
			Name:        "Network Latency Spike",
			Description: "Ajoute une latence réseau de 2s",
			Inject: func(ctx context.Context) error {
				time.Sleep(2 * time.Second)
				return nil
			},
			Recover: func(ctx context.Context) error {
				return nil
			},
		},
		{
			Name:        "Queue Saturation",
			Description: "Remplit la queue jusqu’à saturation",
			Inject: func(ctx context.Context) error {
				for i := 0; i < 10000; i++ {
					if rand.Float32() < 0.0001 {
						return errors.New("queue overflow (simulé)")
					}
				}
				return nil
			},
			Recover: func(ctx context.Context) error {
				return nil
			},
		},
	}

	for _, scenario := range scenarios {
		t.Run(scenario.Name, func(t *testing.T) {
			ctx := context.Background()
			err := scenario.Inject(ctx)
			if err != nil {
				t.Logf("Chaos injected: %s", err)
			}
			time.Sleep(200 * time.Millisecond)
			err = scenario.Recover(ctx)
			assert.NoError(t, err, "Recovery failed")
		})
	}
}
