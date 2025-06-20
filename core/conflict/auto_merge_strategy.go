package conflict

import (
	"errors"
	"time"
)

// AutoMergeStrategy implements automatic safe merging.
type AutoMergeStrategy struct{}

func (a *AutoMergeStrategy) Execute(conflict Conflict) (Resolution, error) {
	return Resolution{
		Status:    "merged",
		Strategy:  "AutoMerge",
		AppliedAt: time.Now(),
		Rollback:  false,
	}, nil
}

func (a *AutoMergeStrategy) Validate(res Resolution) error {
	if res.Status != "merged" {
		return errors.New("not merged")
	}
	return nil
}

func (a *AutoMergeStrategy) Rollback(res Resolution) error {
	return nil // No-op for demo
}
