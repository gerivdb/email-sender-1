package conflict

import (
	"errors"
	"time"
)

// BackupAndReplaceStrategy implements backup then replace resolution.
type BackupAndReplaceStrategy struct{}

func (b *BackupAndReplaceStrategy) Execute(conflict Conflict) (Resolution, error) {
	return Resolution{
		Status:    "backup_replaced",
		Strategy:  "BackupAndReplace",
		AppliedAt: time.Now(),
		Rollback:  false,
	}, nil
}

func (b *BackupAndReplaceStrategy) Validate(res Resolution) error {
	if res.Status != "backup_replaced" {
		return errors.New("not backup replaced")
	}
	return nil
}

func (b *BackupAndReplaceStrategy) Rollback(res Resolution) error {
	return nil // No-op for demo
}
