package conflict

// MultiCriteriaScorer implements ConflictScorer with impact, urgency, complexity.
type MultiCriteriaScorer struct {
	ImpactWeight     float64
	UrgencyWeight    float64
	ComplexityWeight float64
}

func (m *MultiCriteriaScorer) Calculate(conflict Conflict) float64 {
	impact := 1.0
	urgency := 1.0
	complexity := 1.0
	if v, ok := conflict.Metadata["impact"].(float64); ok {
		impact = v
	}
	if v, ok := conflict.Metadata["urgency"].(float64); ok {
		urgency = v
	}
	if v, ok := conflict.Metadata["complexity"].(float64); ok {
		complexity = v
	}
	return m.ImpactWeight*impact + m.UrgencyWeight*urgency + m.ComplexityWeight*complexity
}

func (m *MultiCriteriaScorer) Compare(a, b Conflict) int {
	scoreA := m.Calculate(a)
	scoreB := m.Calculate(b)
	if scoreA > scoreB {
		return 1
	} else if scoreA < scoreB {
		return -1
	}
	return 0
}
