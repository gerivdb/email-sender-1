package conflict

// ScoreHistory keeps a record of scores for learning.
type ScoreHistory struct {
	Entries []float64
}

func (h *ScoreHistory) Add(score float64) {
	h.Entries = append(h.Entries, score)
}

func (h *ScoreHistory) Last() float64 {
	if len(h.Entries) == 0 {
		return 0
	}
	return h.Entries[len(h.Entries)-1]
}
