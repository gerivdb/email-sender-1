package priority

import (
	"strings"
	"time"

	"email_sender/cmd/roadmap-cli/types"
)

// MoSCoWCalculator implements the MoSCoW (Must/Should/Could/Won't) priority algorithm
type MoSCoWCalculator struct {
	name        string
	description string
}

// MoSCoWCategory represents MoSCoW priority categories
type MoSCoWCategory string

const (
	MustHave   MoSCoWCategory = "must"
	ShouldHave MoSCoWCategory = "should"
	CouldHave  MoSCoWCategory = "could"
	WontHave   MoSCoWCategory = "wont"
)

// NewMoSCoWCalculator creates a new MoSCoW calculator
func NewMoSCoWCalculator() *MoSCoWCalculator {
	return &MoSCoWCalculator{
		name:        "moscow",
		description: "MoSCoW (Must/Should/Could/Won't priorities)",
	}
}

// GetName returns the calculator name
func (c *MoSCoWCalculator) GetName() string {
	return c.name
}

// GetDescription returns the calculator description
func (c *MoSCoWCalculator) GetDescription() string {
	return c.description
}

// Calculate computes priority using MoSCoW methodology
func (c *MoSCoWCalculator) Calculate(item types.RoadmapItem, config WeightingConfig) (TaskPriority, error) {
	factors := make(map[PriorityFactor]float64)

	// Determine MoSCoW category from item data
	moscowCategory := c.determineMoSCoWCategory(item)

	// Base score from MoSCoW category
	baseScore := c.getMoSCoWScore(moscowCategory)
	factors[FactorImpact] = baseScore

	// Calculate other factors
	urgency := c.calculateUrgency(item)
	factors[FactorUrgency] = urgency

	effort := c.calculateEffort(item)
	factors[FactorEffort] = effort

	dependencies := c.calculateDependencies(item)
	factors[FactorDependencies] = dependencies

	businessValue := c.calculateBusinessValue(item)
	factors[FactorBusinessValue] = businessValue

	risk := c.calculateRisk(item)
	factors[FactorRisk] = risk

	// Weighted final score with MoSCoW as primary factor
	score := (baseScore * 0.5) + // MoSCoW category gets 50% weight
		(urgency * config.Urgency * 0.2) +
		(effort * config.Effort * 0.15) +
		(dependencies * config.Dependencies * 0.05) +
		(businessValue * config.BusinessValue * 0.08) +
		(risk * config.Risk * 0.02)

	return TaskPriority{
		TaskID:         item.ID,
		Score:          score,
		Factors:        factors,
		LastCalculated: time.Now(),
		Algorithm:      c.name,
	}, nil
}

// determineMoSCoWCategory analyzes item to determine MoSCoW category
func (c *MoSCoWCalculator) determineMoSCoWCategory(item types.RoadmapItem) MoSCoWCategory {
	// Check if explicitly tagged with MoSCoW category
	for _, tag := range item.Tags {
		tag = strings.ToLower(strings.TrimSpace(tag))
		switch tag {
		case "must", "must-have", "m":
			return MustHave
		case "should", "should-have", "s":
			return ShouldHave
		case "could", "could-have", "c":
			return CouldHave
		case "wont", "won't", "wont-have", "w":
			return WontHave
		}
	}

	// Fallback: determine category based on other attributes
	return c.inferMoSCoWFromAttributes(item)
}

// inferMoSCoWFromAttributes infers MoSCoW category from item attributes
func (c *MoSCoWCalculator) inferMoSCoWFromAttributes(item types.RoadmapItem) MoSCoWCategory {
	// Critical priority items are usually "Must Have"
	if item.Priority == types.PriorityCritical {
		return MustHave
	}

	// High business value + high priority = Must Have
	if item.BusinessValue >= 8 && item.Priority == types.PriorityHigh {
		return MustHave
	}

	// Medium-high business value + medium-high priority = Should Have
	if item.BusinessValue >= 6 && (item.Priority == types.PriorityHigh || item.Priority == types.PriorityMedium) {
		return ShouldHave
	}

	// High effort with low-medium business value = Could Have
	if item.Effort > 40 && item.BusinessValue <= 5 {
		return CouldHave
	}

	// High risk + low business value = Could Have or Won't Have
	if item.RiskLevel == types.RiskHigh && item.BusinessValue <= 4 {
		return CouldHave
	}

	// Default based on priority
	switch item.Priority {
	case types.PriorityHigh:
		return ShouldHave
	case types.PriorityMedium:
		return CouldHave
	case types.PriorityLow:
		return CouldHave
	default:
		return CouldHave
	}
}

// getMoSCoWScore returns the base score for a MoSCoW category
func (c *MoSCoWCalculator) getMoSCoWScore(category MoSCoWCategory) float64 {
	switch category {
	case MustHave:
		return 1.0 // Highest priority
	case ShouldHave:
		return 0.75
	case CouldHave:
		return 0.5
	case WontHave:
		return 0.1 // Lowest priority
	default:
		return 0.5
	}
}

// Helper methods (reused from Eisenhower calculator)
func (c *MoSCoWCalculator) calculateUrgency(item types.RoadmapItem) float64 {
	now := time.Now()

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

	if !item.TargetDate.IsZero() {
		daysUntilTarget := item.TargetDate.Sub(now).Hours() / 24

		var timeScore float64
		if daysUntilTarget < 1 {
			timeScore = 1.0
		} else if daysUntilTarget <= 3 {
			timeScore = 0.9
		} else if daysUntilTarget <= 7 {
			timeScore = 0.7
		} else if daysUntilTarget <= 30 {
			timeScore = 0.5
		} else {
			timeScore = 0.2
		}

		return (priorityScore * 0.6) + (timeScore * 0.4)
	}

	return priorityScore
}

func (c *MoSCoWCalculator) calculateEffort(item types.RoadmapItem) float64 {
	if item.Effort <= 0 {
		switch item.Complexity {
		case types.BasicComplexityHigh:
			return 0.3
		case types.BasicComplexityMedium:
			return 0.6
		case types.BasicComplexityLow:
			return 0.9
		default:
			return 0.5
		}
	}

	effortScore := 1.0 - (float64(item.Effort) / 100.0)
	if effortScore < 0.1 {
		effortScore = 0.1
	}

	return effortScore
}

func (c *MoSCoWCalculator) calculateDependencies(item types.RoadmapItem) float64 {
	numDeps := len(item.Prerequisites)

	if numDeps == 0 {
		return 1.0
	}

	depScore := 1.0 - (float64(numDeps) * 0.1)
	if depScore < 0.2 {
		depScore = 0.2
	}

	return depScore
}

func (c *MoSCoWCalculator) calculateBusinessValue(item types.RoadmapItem) float64 {
	if item.BusinessValue <= 0 {
		return 0.5
	}

	return float64(item.BusinessValue) / 10.0
}

func (c *MoSCoWCalculator) calculateRisk(item types.RoadmapItem) float64 {
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
