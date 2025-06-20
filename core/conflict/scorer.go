package conflict

// ConflictScorer interface for scoring and comparing conflicts.
type ConflictScorer interface {
	Calculate(conflict Conflict) float64
	Compare(a, b Conflict) int
}
