package conflict

import (
	"testing"
)

func TestMultiCriteriaScorer_Calculate(t *testing.T) {
	scorer := &MultiCriteriaScorer{ImpactWeight: 1, UrgencyWeight: 2, ComplexityWeight: 3}
	conf := Conflict{Metadata: map[string]interface{}{"impact": 2.0, "urgency": 1.0, "complexity": 0.5}}
	score := scorer.Calculate(conf)
	if score != 1*2.0+2*1.0+3*0.5 {
		t.Errorf("unexpected score: %v", score)
	}
}

func TestPriorityQueue(t *testing.T) {
	pq := &PriorityQueue{}
	conf1 := &ConflictWithScore{Score: 5}
	conf2 := &ConflictWithScore{Score: 10}
	pq.Push(conf1)
	pq.Push(conf2)
	if pq.Peek().Score != 5 {
		t.Error("PriorityQueue Peek failed")
	}
}

func TestScoringConfig_Update(t *testing.T) {
	cfg := &ScoringConfig{}
	cfg.Update(1, 2, 3)
	if cfg.ImpactWeight != 1 || cfg.UrgencyWeight != 2 || cfg.ComplexityWeight != 3 {
		t.Error("ScoringConfig update failed")
	}
}

func TestScoreHistory(t *testing.T) {
	h := &ScoreHistory{}
	h.Add(1.5)
	h.Add(2.5)
	if h.Last() != 2.5 {
		t.Error("ScoreHistory last failed")
	}
}

func TestScoringMetrics_Precision(t *testing.T) {
	m := &ScoringMetrics{TruePositives: 8, FalsePositives: 2}
	if m.Precision() != 0.8 {
		t.Error("ScoringMetrics precision failed")
	}
}
