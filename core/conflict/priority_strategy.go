package conflict

import (
	"errors"
	"time"
)

// PriorityBasedStrategy implements resolution based on priority/weight.
type PriorityBasedStrategy struct{}

func (p *PriorityBasedStrategy) Execute(conflict Conflict) (Resolution, error) {
	return Resolution{
		Status:    "priority_resolved",
		Strategy:  "PriorityBased",
		AppliedAt: time.Now(),
		Rollback:  false,
	}, nil
}

func (p *PriorityBasedStrategy) Validate(res Resolution) error {
	if res.Status != "priority_resolved" {
		return errors.New("not priority resolved")
	}
	return nil
}

func (p *PriorityBasedStrategy) Rollback(res Resolution) error {
	return nil // No-op for demo
}
