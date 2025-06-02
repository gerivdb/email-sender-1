package priority

import (
	"time"

	"email_sender/cmd/roadmap-cli/types"
)

// HybridCalculator combines multiple priority calculation approaches
type HybridCalculator struct {
	name         string
	description  string
	eisenhower   *EisenhowerCalculator
	moscow       *MoSCoWCalculator
	wsjf         *WSJFCalculator
	customWeight *CustomWeightedCalculator
}

// HybridConfig defines weights for combining different algorithms
type HybridConfig struct {
	EisenhowerWeight   float64 `json:"eisenhower_weight"`
	MoSCoWWeight       float64 `json:"moscow_weight"`
	WSJFWeight         float64 `json:"wsjf_weight"`
	CustomWeightWeight float64 `json:"custom_weight_weight"`
}

// DefaultHybridConfig returns default hybrid configuration
func DefaultHybridConfig() HybridConfig {
	return HybridConfig{
		EisenhowerWeight:   0.3,
		MoSCoWWeight:       0.25,
		WSJFWeight:         0.25,
		CustomWeightWeight: 0.2,
	}
}

// NewHybridCalculator creates a new hybrid calculator
func NewHybridCalculator() *HybridCalculator {
	return &HybridCalculator{
		name:         "hybrid",
		description:  "Hybrid calculator combining multiple priority algorithms",
		eisenhower:   NewEisenhowerCalculator(),
		moscow:       NewMoSCoWCalculator(),
		wsjf:         NewWSJFCalculator(),
		customWeight: NewCustomWeightedCalculator(),
	}
}

// GetName returns the calculator name
func (c *HybridCalculator) GetName() string {
	return c.name
}

// GetDescription returns the calculator description
func (c *HybridCalculator) GetDescription() string {
	return c.description
}

// Calculate computes priority using a hybrid approach
func (c *HybridCalculator) Calculate(item types.RoadmapItem, config WeightingConfig) (TaskPriority, error) {
	hybridConfig := DefaultHybridConfig()
	
	// Calculate priority using each algorithm
	eisenhowerResult, err := c.eisenhower.Calculate(item, config)
	if err != nil {
		return TaskPriority{}, err
	}

	moscowResult, err := c.moscow.Calculate(item, config)
	if err != nil {
		return TaskPriority{}, err
	}

	wsjfResult, err := c.wsjf.Calculate(item, config)
	if err != nil {
		return TaskPriority{}, err
	}

	customResult, err := c.customWeight.Calculate(item, config)
	if err != nil {
		return TaskPriority{}, err
	}

	// Combine scores using weighted average
	hybridScore := (eisenhowerResult.Score * hybridConfig.EisenhowerWeight) +
		(moscowResult.Score * hybridConfig.MoSCoWWeight) +
		(wsjfResult.Score * hybridConfig.WSJFWeight) +
		(customResult.Score * hybridConfig.CustomWeightWeight)

	// Combine factors by averaging across algorithms
	factors := make(map[PriorityFactor]float64)
	
	factors[FactorUrgency] = c.averageFactor(
		eisenhowerResult.Factors[FactorUrgency],
		moscowResult.Factors[FactorUrgency],
		wsjfResult.Factors[FactorUrgency],
		customResult.Factors[FactorUrgency],
	)

	factors[FactorImpact] = c.averageFactor(
		eisenhowerResult.Factors[FactorImpact],
		moscowResult.Factors[FactorImpact],
		wsjfResult.Factors[FactorImpact],
		customResult.Factors[FactorImpact],
	)

	factors[FactorEffort] = c.averageFactor(
		eisenhowerResult.Factors[FactorEffort],
		moscowResult.Factors[FactorEffort],
		wsjfResult.Factors[FactorEffort],
		customResult.Factors[FactorEffort],
	)

	factors[FactorDependencies] = c.averageFactor(
		eisenhowerResult.Factors[FactorDependencies],
		moscowResult.Factors[FactorDependencies],
		wsjfResult.Factors[FactorDependencies],
		customResult.Factors[FactorDependencies],
	)

	factors[FactorBusinessValue] = c.averageFactor(
		eisenhowerResult.Factors[FactorBusinessValue],
		moscowResult.Factors[FactorBusinessValue],
		wsjfResult.Factors[FactorBusinessValue],
		customResult.Factors[FactorBusinessValue],
	)

	factors[FactorRisk] = c.averageFactor(
		eisenhowerResult.Factors[FactorRisk],
		moscowResult.Factors[FactorRisk],
		wsjfResult.Factors[FactorRisk],
		customResult.Factors[FactorRisk],
	)

	// Apply consensus adjustments
	hybridScore = c.applyConsensusAdjustments(hybridScore, 
		eisenhowerResult.Score, moscowResult.Score, 
		wsjfResult.Score, customResult.Score)

	return TaskPriority{
		TaskID:         item.ID,
		Score:          hybridScore,
		Factors:        factors,
		LastCalculated: time.Now(),
		Algorithm:      c.name,
	}, nil
}

// averageFactor calculates the average of factor values across algorithms
func (c *HybridCalculator) averageFactor(values ...float64) float64 {
	if len(values) == 0 {
		return 0
	}

	var sum float64
	var count int

	for _, value := range values {
		if value > 0 { // Only count non-zero values
			sum += value
			count++
		}
	}

	if count == 0 {
		return 0
	}

	return sum / float64(count)
}

// applyConsensusAdjustments adjusts score based on algorithm consensus
func (c *HybridCalculator) applyConsensusAdjustments(hybridScore float64, scores ...float64) float64 {
	if len(scores) < 2 {
		return hybridScore
	}

	// Calculate consensus metrics
	variance := c.calculateVariance(scores)
	consensus := 1.0 - variance // High variance = low consensus

	// If algorithms agree (low variance), boost confidence in the score
	if consensus > 0.8 {
		// High consensus: slight boost to extreme scores
		if hybridScore > 0.8 {
			hybridScore = hybridScore * 1.05
		} else if hybridScore < 0.2 {
			hybridScore = hybridScore * 0.95
		}
	} else if consensus < 0.4 {
		// Low consensus: moderate the score toward middle
		hybridScore = (hybridScore * 0.8) + (0.5 * 0.2)
	}

	// Ensure score stays in valid range
	if hybridScore > 1.0 {
		hybridScore = 1.0
	}
	if hybridScore < 0.0 {
		hybridScore = 0.0
	}

	return hybridScore
}

// calculateVariance calculates the variance of scores
func (c *HybridCalculator) calculateVariance(scores []float64) float64 {
	if len(scores) <= 1 {
		return 0
	}

	// Calculate mean
	var sum float64
	for _, score := range scores {
		sum += score
	}
	mean := sum / float64(len(scores))

	// Calculate variance
	var varianceSum float64
	for _, score := range scores {
		diff := score - mean
		varianceSum += diff * diff
	}

	variance := varianceSum / float64(len(scores))
	
	// Normalize variance to 0-1 range (assuming max variance is 0.25 for scores in 0-1 range)
	normalizedVariance := variance / 0.25
	if normalizedVariance > 1.0 {
		normalizedVariance = 1.0
	}

	return normalizedVariance
}

// GetAlgorithmScores returns individual algorithm scores for analysis
func (c *HybridCalculator) GetAlgorithmScores(item types.RoadmapItem, config WeightingConfig) (map[string]float64, error) {
	scores := make(map[string]float64)

	eisenhowerResult, err := c.eisenhower.Calculate(item, config)
	if err != nil {
		return nil, err
	}
	scores["eisenhower"] = eisenhowerResult.Score

	moscowResult, err := c.moscow.Calculate(item, config)
	if err != nil {
		return nil, err
	}
	scores["moscow"] = moscowResult.Score

	wsjfResult, err := c.wsjf.Calculate(item, config)
	if err != nil {
		return nil, err
	}
	scores["wsjf"] = wsjfResult.Score

	customResult, err := c.customWeight.Calculate(item, config)
	if err != nil {
		return nil, err
	}
	scores["custom_weighted"] = customResult.Score

	return scores, nil
}

// SetHybridConfig allows customization of algorithm weights
func (c *HybridCalculator) SetHybridConfig(config HybridConfig) {
	// Store config for future use (in a real implementation, this would be persisted)
	// For now, we'll just validate that weights sum to approximately 1.0
	total := config.EisenhowerWeight + config.MoSCoWWeight + 
		config.WSJFWeight + config.CustomWeightWeight
	
	if total < 0.9 || total > 1.1 {
		// Auto-normalize if weights don't sum to 1
		config.EisenhowerWeight /= total
		config.MoSCoWWeight /= total
		config.WSJFWeight /= total
		config.CustomWeightWeight /= total
	}
}
