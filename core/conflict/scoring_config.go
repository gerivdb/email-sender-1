package conflict

// ScoringConfig holds dynamic weights for scoring.
type ScoringConfig struct {
	ImpactWeight     float64
	UrgencyWeight    float64
	ComplexityWeight float64
}

func (c *ScoringConfig) Update(impact, urgency, complexity float64) {
	c.ImpactWeight = impact
	c.UrgencyWeight = urgency
	c.ComplexityWeight = complexity
}
