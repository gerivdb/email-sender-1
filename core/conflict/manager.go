package conflict

// ConflictManager orchestrates the detection and resolution of multiple conflicts.
type ConflictManager struct {
	Conflicts []Conflict
}

func NewConflictManager() *ConflictManager {
	return &ConflictManager{
		Conflicts: make([]Conflict, 0),
	}
}

func (cm *ConflictManager) AddConflict(c Conflict) {
	cm.Conflicts = append(cm.Conflicts, c)
}

func (cm *ConflictManager) ListConflicts() []Conflict {
	return cm.Conflicts
}
