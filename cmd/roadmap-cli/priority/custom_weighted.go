package priority

import (
	"time"

	"email_sender/cmd/roadmap-cli/types"
)

// CustomWeightedCalculator implements a fully customizable weighted priority algorithm
type CustomWeightedCalculator struct {
	name        string
	description string
}

// NewCustomWeightedCalculator creates a new custom weighted calculator
func NewCustomWeightedCalculator() *CustomWeightedCalculator {
	return &CustomWeightedCalculator{
		name:        "custom_weighted",
		description: "Custom weighted calculator for user-defined priority formulas",
	}
}

// GetName returns the calculator name
func (c *CustomWeightedCalculator) GetName() string {
	return c.name
}

// GetDescription returns the calculator description
func (c *CustomWeightedCalculator) GetDescription() string {
	return c.description
}

// Calculate computes priority using fully customizable weights
func (c *CustomWeightedCalculator) Calculate(item types.RoadmapItem, config WeightingConfig) (TaskPriority, error) {
	factors := make(map[PriorityFactor]float64)

	// Calculate all individual factors
	urgency := c.calculateUrgency(item)
	factors[FactorUrgency] = urgency

	impact := c.calculateImpact(item) 
	factors[FactorImpact] = impact

	effort := c.calculateEffort(item)
	factors[FactorEffort] = effort

	dependencies := c.calculateDependencies(item)
	factors[FactorDependencies] = dependencies

	businessValue := c.calculateBusinessValue(item)
	factors[FactorBusinessValue] = businessValue

	risk := c.calculateRisk(item)
	factors[FactorRisk] = risk

	// Apply user-defined weights
	score := (urgency * config.Urgency) +
		(impact * config.Impact) +
		(effort * config.Effort) +
		(dependencies * config.Dependencies) +
		(businessValue * config.BusinessValue) +
		(risk * config.Risk)

	// Normalize the score (weights might not sum to 1.0)
	weightSum := config.Urgency + config.Impact + config.Effort + 
		config.Dependencies + config.BusinessValue + config.Risk
	
	if weightSum > 0 {
		score = score / weightSum
	}

	return TaskPriority{
		TaskID:         item.ID,
		Score:          score,
		Factors:        factors,
		LastCalculated: time.Now(),
		Algorithm:      c.name,
	}, nil
}

// calculateUrgency determines urgency based on target date and priority
func (c *CustomWeightedCalculator) calculateUrgency(item types.RoadmapItem) float64 {
	now := time.Now()
	
	// Base urgency on explicit priority
	var priorityScore float64
	switch item.Priority {
	case types.PriorityCritical:
		priorityScore = 1.0
	case types.PriorityHigh:
		priorityScore = 0.8
	case types.PriorityMedium:
		priorityScore = 0.5
	case types.PriorityLow:
		priorityScore = 0.2
	default:
		priorityScore = 0.3
	}

	// Adjust based on target date if available
	if !item.TargetDate.IsZero() {
		daysUntilTarget := item.TargetDate.Sub(now).Hours() / 24
		
		var timeScore float64
		if daysUntilTarget < 0 {
			timeScore = 1.2 // Overdue gets penalty boost
		} else if daysUntilTarget <= 1 {
			timeScore = 1.0 // Due today
		} else if daysUntilTarget <= 3 {
			timeScore = 0.9 // Due within 3 days
		} else if daysUntilTarget <= 7 {
			timeScore = 0.7 // Due within a week
		} else if daysUntilTarget <= 30 {
			timeScore = 0.5 // Due within a month
		} else {
			timeScore = 0.2 // Due later
		}
		
		// Combine priority and time factors
		combined := (priorityScore * 0.6) + (timeScore * 0.4)
		if combined > 1.0 {
			combined = 1.0
		}
		return combined
	}

	return priorityScore
}

// calculateImpact determines overall impact/importance
func (c *CustomWeightedCalculator) calculateImpact(item types.RoadmapItem) float64 {
	var impact float64

	// Business value is primary impact indicator
	if item.BusinessValue > 0 {
		impact += float64(item.BusinessValue) / 10.0 * 0.4
	}

	// Priority level indicates impact
	switch item.Priority {
	case types.PriorityCritical:
		impact += 0.3
	case types.PriorityHigh:
		impact += 0.25
	case types.PriorityMedium:
		impact += 0.15
	case types.PriorityLow:
		impact += 0.1
	}

	// Complexity can indicate impact (infrastructure/foundation work)
	switch item.Complexity {
	case types.BasicComplexityHigh:
		impact += 0.15
	case types.BasicComplexityMedium:
		impact += 0.1
	case types.BasicComplexityLow:
		impact += 0.05
	}

	// Items that produce outputs have impact
	if len(item.Outputs) > 0 {
		impact += 0.1
	}

	// Items with many tools/frameworks might be foundational
	if len(item.Tools) + len(item.Frameworks) > 2 {
		impact += 0.05
	}

	// Ensure score doesn't exceed 1.0
	if impact > 1.0 {
		impact = 1.0
	}

	return impact
}

// calculateEffort returns effort factor (higher effort = lower priority factor)
func (c *CustomWeightedCalculator) calculateEffort(item types.RoadmapItem) float64 {
	if item.Effort <= 0 {
		// Default based on complexity
		switch item.Complexity {
		case types.BasicComplexityHigh:
			return 0.2 // High effort, lower score
		case types.BasicComplexityMedium:
			return 0.5
		case types.BasicComplexityLow:
			return 0.8 // Low effort, higher score
		default:
			return 0.5
		}
	}

	// Convert effort hours to score (inversely proportional)
	// Using a logarithmic scale for better distribution
	effortHours := float64(item.Effort)
	
	if effortHours <= 1 {
		return 1.0
	} else if effortHours <= 8 {
		return 0.9 // 1 day
	} else if effortHours <= 24 {
		return 0.8 // 3 days
	} else if effortHours <= 40 {
		return 0.6 // 1 week
	} else if effortHours <= 80 {
		return 0.4 // 2 weeks
	} else if effortHours <= 160 {
		return 0.2 // 1 month
	} else {
		return 0.1 // More than 1 month
	}
}

// calculateDependencies calculates score based on dependencies
func (c *CustomWeightedCalculator) calculateDependencies(item types.RoadmapItem) float64 {
	numDeps := len(item.Prerequisites)
	
	if numDeps == 0 {
		return 1.0 // No dependencies = higher score
	}

	// More dependencies = lower score (using logarithmic scale)
	var depScore float64
	if numDeps == 1 {
		depScore = 0.9
	} else if numDeps <= 3 {
		depScore = 0.7
	} else if numDeps <= 5 {
		depScore = 0.5
	} else if numDeps <= 10 {
		depScore = 0.3
	} else {
		depScore = 0.1
	}

	return depScore
}

// calculateBusinessValue calculates business value factor
func (c *CustomWeightedCalculator) calculateBusinessValue(item types.RoadmapItem) float64 {
	if item.BusinessValue <= 0 {
		// Infer business value from other attributes
		var inferredValue float64
		
		switch item.Priority {
		case types.PriorityCritical:
			inferredValue = 0.8
		case types.PriorityHigh:
			inferredValue = 0.6
		case types.PriorityMedium:
			inferredValue = 0.4
		case types.PriorityLow:
			inferredValue = 0.2
		default:
			inferredValue = 0.3
		}

		// Boost for items with many outputs (deliverables)
		if len(item.Outputs) > 0 {
			inferredValue += 0.1
		}

		// Boost for infrastructure work
		for _, tag := range item.Tags {
			if tag == "infrastructure" || tag == "foundation" {
				inferredValue += 0.1
				break
			}
		}

		if inferredValue > 1.0 {
			inferredValue = 1.0
		}

		return inferredValue
	}

	return float64(item.BusinessValue) / 10.0
}

// calculateRisk calculates risk factor (higher risk = lower score)
func (c *CustomWeightedCalculator) calculateRisk(item types.RoadmapItem) float64 {
	var riskScore float64

	// Base risk assessment
	switch item.RiskLevel {
	case types.RiskHigh:
		riskScore = 0.2
	case types.RiskMedium:
		riskScore = 0.6
	case types.RiskLow:
		riskScore = 1.0
	default:
		riskScore = 0.5
	}

	// Adjust for complexity (more complex = higher risk)
	switch item.Complexity {
	case types.BasicComplexityHigh:
		riskScore *= 0.8
	case types.BasicComplexityMedium:
		riskScore *= 0.9
	case types.BasicComplexityLow:
		riskScore *= 1.0
	}

	// Adjust for technical debt (higher debt = higher risk)
	if item.TechnicalDebt > 5 {
		riskScore *= 0.9
	}

	// Adjust for dependencies (more deps = higher risk)
	if len(item.Prerequisites) > 3 {
		riskScore *= 0.9
	}

	return riskScore
}
