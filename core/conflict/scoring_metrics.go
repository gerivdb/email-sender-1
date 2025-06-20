package conflict

// ScoringMetrics exposes scoring precision metrics.
type ScoringMetrics struct {
	TruePositives  int
	FalsePositives int
	TrueNegatives  int
	FalseNegatives int
}

func (m *ScoringMetrics) Precision() float64 {
	total := m.TruePositives + m.FalsePositives
	if total == 0 {
		return 0
	}
	return float64(m.TruePositives) / float64(total)
}
