package conflict

import "time"

// Resolution represents the result of a conflict resolution attempt.
type Resolution struct {
	Status    string
	Strategy  string
	AppliedAt time.Time
	Rollback  bool
}
