package conflict

// RollbackManager handles rollback of resolutions.
type RollbackManager struct {
	History *ConflictHistory
}

func (r *RollbackManager) RollbackLast() error {
	h := r.History
	if len(h.Conflicts) == 0 {
		return nil
	}
	record := &h.Conflicts[len(h.Conflicts)-1]
	if !record.Resolved {
		return nil
	}
	record.Resolved = false
	return nil
}
