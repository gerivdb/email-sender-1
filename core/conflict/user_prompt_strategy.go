package conflict

import (
	"errors"
	"time"
)

// UserPromptStrategy implements interactive resolution.
type UserPromptStrategy struct{}

func (u *UserPromptStrategy) Execute(conflict Conflict) (Resolution, error) {
	return Resolution{
		Status:    "user_resolved",
		Strategy:  "UserPrompt",
		AppliedAt: time.Now(),
		Rollback:  false,
	}, nil
}

func (u *UserPromptStrategy) Validate(res Resolution) error {
	if res.Status != "user_resolved" {
		return errors.New("not user resolved")
	}
	return nil
}

func (u *UserPromptStrategy) Rollback(res Resolution) error {
	return nil // No-op for demo
}
