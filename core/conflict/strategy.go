package conflict

// ResolutionStrategy defines the interface for all resolution strategies.
type ResolutionStrategy interface {
	Execute(conflict Conflict) (Resolution, error)
	Validate(res Resolution) error
	Rollback(res Resolution) error
}
