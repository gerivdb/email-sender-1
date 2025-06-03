package priority

import (
	"time"

	"email_sender/cmd/roadmap-cli/types"
)

// EisenhowerCalculator implements the Eisenhower Matrix (Urgent/Important) priority algorithm
type EisenhowerCalculator struct {
	name        string
	description string
}

// NewEisenhowerCalculator creates a new Eisenhower matrix calculator
func NewEisenhowerCalculator() *EisenhowerCalculator {
	return &EisenhowerCalculator{
		name:        "eisenhower",
		description: "Eisenhower Matrix (Urgent/Important quadrants)",
	}
}

// GetName returns the calculator name
func (c *EisenhowerCalculator) GetName() string {
	return c.name
}

// GetDescription returns the calculator description
func (c *EisenhowerCalculator) GetDescription() string {
	return c.description
}

// Calculate computes priority using the Eisenhower Matrix
func (c *EisenhowerCalculator) Calculate(item types.RoadmapItem, config WeightingConfig) (TaskPriority, error) {
	factors := make(map[PriorityFactor]float64)

	// Calculate urgency factor (based on target date and current priority)
	urgency := c.calculateUrgency(item)
	factors[FactorUrgency] = urgency

	// Calculate importance factor (based on business value and priority)
	importance := c.calculateImportance(item)
	factors[FactorImpact] = importance

	// Calculate effort factor (inversely related to priority)
	effort := c.calculateEffort(item)
	factors[FactorEffort] = effort

	// Calculate dependencies factor
	dependencies := c.calculateDependencies(item)
	factors[FactorDependencies] = dependencies

	// Calculate business value factor
	businessValue := c.calculateBusinessValue(item)
	factors[FactorBusinessValue] = businessValue

	// Calculate risk factor
	risk := c.calculateRisk(item)
	factors[FactorRisk] = risk

	// Eisenhower Matrix scoring:
	// Quadrant 1 (Urgent + Important): High priority
	// Quadrant 2 (Not Urgent + Important): Medium-high priority
	// Quadrant 3 (Urgent + Not Important): Medium priority
	// Quadrant 4 (Not Urgent + Not Important): Low priority

	eisenhowerScore := c.calculateEisenhowerScore(urgency, importance)

	// Weighted final score
	score := (eisenhowerScore * 0.6) + // Eisenhower matrix gets 60% weight
		(factors[FactorEffort] * config.Effort * 0.15) +
		(factors[FactorDependencies] * config.Dependencies * 0.1) +
		(factors[FactorBusinessValue] * config.BusinessValue * 0.1) +
		(factors[FactorRisk] * config.Risk * 0.05)

	return TaskPriority{
		TaskID:         item.ID,
		Score:          score,
		Factors:        factors,
		LastCalculated: time.Now(),
		Algorithm:      c.name,
	}, nil
}

// calculateUrgency determines urgency based on target date and priority
func (c *EisenhowerCalculator) calculateUrgency(item types.RoadmapItem) float64 {
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
		if daysUntilTarget < 1 {
			timeScore = 1.0 // Overdue or due today
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
		return (priorityScore * 0.6) + (timeScore * 0.4)
	}

	return priorityScore
}

// calculateImportance determines importance based on business value and impact
func (c *EisenhowerCalculator) calculateImportance(item types.RoadmapItem) float64 {
	var importance float64

	// Business value factor (1-10 scale)
	if item.BusinessValue > 0 {
		importance += float64(item.BusinessValue) / 10.0 * 0.6
	} else {
		// Fallback to priority if no business value
		switch item.Priority {
		case types.PriorityCritical:
			importance += 0.6
		case types.PriorityHigh:
			importance += 0.45
		case types.PriorityMedium:
			importance += 0.3
		case types.PriorityLow:
			importance += 0.15
		}
	}

	// Complexity can indicate importance (more complex = potentially more important)
	switch item.Complexity {
	case types.BasicComplexityHigh:
		importance += 0.2
	case types.BasicComplexityMedium:
		importance += 0.1
	case types.BasicComplexityLow:
		importance += 0.05
	}

	// Prerequisites can indicate importance
	if len(item.Prerequisites) > 0 {
		importance += 0.1
	}

	// Ensure score doesn't exceed 1.0
	if importance > 1.0 {
		importance = 1.0
	}

	return importance
}

// calculateEffort returns effort factor (higher effort = lower priority score)
func (c *EisenhowerCalculator) calculateEffort(item types.RoadmapItem) float64 {
	if item.Effort <= 0 {
		// Default based on complexity
		switch item.Complexity {
		case types.BasicComplexityHigh:
			return 0.3 // High effort, lower score
		case types.BasicComplexityMedium:
			return 0.6
		case types.BasicComplexityLow:
			return 0.9 // Low effort, higher score
		default:
			return 0.5
		}
	}

	// Convert effort hours to score (inversely proportional)
	// Assuming max reasonable effort is 100 hours
	effortScore := 1.0 - (float64(item.Effort) / 100.0)
	if effortScore < 0.1 {
		effortScore = 0.1 // Minimum score
	}

	return effortScore
}

// calculateDependencies calculates score based on dependencies
func (c *EisenhowerCalculator) calculateDependencies(item types.RoadmapItem) float64 {
	numDeps := len(item.Prerequisites)

	if numDeps == 0 {
		return 1.0 // No dependencies = higher score
	}

	// More dependencies = lower score
	depScore := 1.0 - (float64(numDeps) * 0.1)
	if depScore < 0.2 {
		depScore = 0.2 // Minimum score
	}

	return depScore
}

// calculateBusinessValue calculates business value factor
func (c *EisenhowerCalculator) calculateBusinessValue(item types.RoadmapItem) float64 {
	if item.BusinessValue <= 0 {
		return 0.5 // Default neutral value
	}

	return float64(item.BusinessValue) / 10.0
}

// calculateRisk calculates risk factor (higher risk = lower score)
func (c *EisenhowerCalculator) calculateRisk(item types.RoadmapItem) float64 {
	switch item.RiskLevel {
	case types.RiskHigh:
		return 0.3
	case types.RiskMedium:
		return 0.6
	case types.RiskLow:
		return 0.9
	default:
		return 0.5
	}
}

// calculateEisenhowerScore applies the Eisenhower Matrix logic
func (c *EisenhowerCalculator) calculateEisenhowerScore(urgency, importance float64) float64 {
	// Define thresholds for urgent/important
	urgentThreshold := 0.6
	importantThreshold := 0.6

	isUrgent := urgency >= urgentThreshold
	isImportant := importance >= importantThreshold

	// Eisenhower quadrants
	if isUrgent && isImportant {
		// Quadrant 1: Do First (Urgent + Important)
		return 1.0
	} else if !isUrgent && isImportant {
		// Quadrant 2: Schedule (Not Urgent + Important)
		return 0.8
	} else if isUrgent && !isImportant {
		// Quadrant 3: Delegate (Urgent + Not Important)
		return 0.5
	} else {
		// Quadrant 4: Eliminate (Not Urgent + Not Important)
		return 0.2
	}
}
