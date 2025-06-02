package priority

import (
	"time"

	"email_sender/cmd/roadmap-cli/types"
)

// WSJFCalculator implements the Weighted Shortest Job First algorithm
type WSJFCalculator struct {
	name        string
	description string
}

// NewWSJFCalculator creates a new WSJF calculator
func NewWSJFCalculator() *WSJFCalculator {
	return &WSJFCalculator{
		name:        "wsjf",
		description: "Weighted Shortest Job First",
	}
}

// GetName returns the calculator name
func (c *WSJFCalculator) GetName() string {
	return c.name
}

// GetDescription returns the calculator description
func (c *WSJFCalculator) GetDescription() string {
	return c.description
}

// Calculate computes priority using WSJF formula
// WSJF = Cost of Delay / Job Size
// Cost of Delay = User-Business Value + Time Criticality + Risk Reduction
func (c *WSJFCalculator) Calculate(item types.RoadmapItem, config WeightingConfig) (TaskPriority, error) {
	factors := make(map[PriorityFactor]float64)

	// Calculate Cost of Delay components
	userBusinessValue := c.calculateUserBusinessValue(item)
	factors[FactorBusinessValue] = userBusinessValue

	timeCriticality := c.calculateTimeCriticality(item)
	factors[FactorUrgency] = timeCriticality

	riskReduction := c.calculateRiskReduction(item)
	factors[FactorRisk] = riskReduction

	// Calculate Job Size (effort estimation)
	jobSize := c.calculateJobSize(item)
	factors[FactorEffort] = jobSize

	// Dependencies impact
	dependencies := c.calculateDependencies(item)
	factors[FactorDependencies] = dependencies

	// WSJF Calculation
	costOfDelay := (userBusinessValue * 0.4) + (timeCriticality * 0.4) + (riskReduction * 0.2)
	
	// Prevent division by zero
	if jobSize == 0 {
		jobSize = 0.1
	}

	// WSJF = Cost of Delay / Job Size
	wsjfScore := costOfDelay / jobSize

	// Apply dependencies factor
	wsjfScore *= dependencies

	// Normalize score to 0-1 range
	normalizedScore := c.normalizeScore(wsjfScore)

	return TaskPriority{
		TaskID:         item.ID,
		Score:          normalizedScore,
		Factors:        factors,
		LastCalculated: time.Now(),
		Algorithm:      c.name,
	}, nil
}

// calculateUserBusinessValue estimates user and business value
func (c *WSJFCalculator) calculateUserBusinessValue(item types.RoadmapItem) float64 {
	// Primary: explicit business value
	if item.BusinessValue > 0 {
		return float64(item.BusinessValue) / 10.0
	}

	// Secondary: infer from priority and other factors
	var baseValue float64
	switch item.Priority {
	case types.PriorityCritical:
		baseValue = 0.9
	case types.PriorityHigh:
		baseValue = 0.7
	case types.PriorityMedium:
		baseValue = 0.5
	case types.PriorityLow:
		baseValue = 0.3
	default:
		baseValue = 0.4
	}

	// Boost value for items with many tools/frameworks (likely infrastructure)
	if len(item.Tools) + len(item.Frameworks) > 3 {
		baseValue += 0.1
	}

	// Boost value for items with outputs (deliverables)
	if len(item.Outputs) > 0 {
		baseValue += 0.1
	}

	if baseValue > 1.0 {
		baseValue = 1.0
	}

	return baseValue
}

// calculateTimeCriticality assesses how time-sensitive the item is
func (c *WSJFCalculator) calculateTimeCriticality(item types.RoadmapItem) float64 {
	now := time.Now()
	
	// Base criticality from priority
	var baseCriticality float64
	switch item.Priority {
	case types.PriorityCritical:
		baseCriticality = 1.0
	case types.PriorityHigh:
		baseCriticality = 0.8
	case types.PriorityMedium:
		baseCriticality = 0.5
	case types.PriorityLow:
		baseCriticality = 0.2
	default:
		baseCriticality = 0.3
	}

	// Adjust based on target date
	if !item.TargetDate.IsZero() {
		daysUntilTarget := item.TargetDate.Sub(now).Hours() / 24
		
		var timeMultiplier float64
		if daysUntilTarget < 0 {
			timeMultiplier = 1.5 // Overdue items get boost
		} else if daysUntilTarget <= 1 {
			timeMultiplier = 1.3
		} else if daysUntilTarget <= 7 {
			timeMultiplier = 1.1
		} else if daysUntilTarget <= 30 {
			timeMultiplier = 1.0
		} else {
			timeMultiplier = 0.8
		}
		
		baseCriticality *= timeMultiplier
	}

	// Items with many prerequisites might be time-critical for blockers
	if len(item.Prerequisites) > 2 {
		baseCriticality += 0.1
	}

	if baseCriticality > 1.0 {
		baseCriticality = 1.0
	}

	return baseCriticality
}

// calculateRiskReduction assesses how much risk the item reduces
func (c *WSJFCalculator) calculateRiskReduction(item types.RoadmapItem) float64 {
	var riskReduction float64

	// Items that reduce technical debt provide risk reduction
	if item.TechnicalDebt > 0 {
		// Higher technical debt items provide more risk reduction when completed
		riskReduction += float64(item.TechnicalDebt) / 10.0 * 0.5
	}

	// Infrastructure and foundational work reduces risk
	for _, tag := range item.Tags {
		if tag == "infrastructure" || tag == "foundation" || tag == "security" {
			riskReduction += 0.3
			break
		}
	}

	// Items with many dependencies might reduce blocking risk
	if len(item.Prerequisites) == 0 && len(item.Outputs) > 0 {
		riskReduction += 0.2 // Items that unblock others
	}

	// Risk level of the item itself (inverse relationship)
	switch item.RiskLevel {
	case types.RiskLow:
		riskReduction += 0.3 // Low risk items are safer to implement
	case types.RiskMedium:
		riskReduction += 0.2
	case types.RiskHigh:
		riskReduction += 0.1 // High risk items provide less risk reduction value
	}

	if riskReduction > 1.0 {
		riskReduction = 1.0
	}

	return riskReduction
}

// calculateJobSize estimates the relative size/effort of the job
func (c *WSJFCalculator) calculateJobSize(item types.RoadmapItem) float64 {
	var jobSize float64

	// Primary: explicit effort estimation
	if item.Effort > 0 {
		// Normalize effort (assuming max 160 hours = 1 month)
		jobSize = float64(item.Effort) / 160.0
		if jobSize > 1.0 {
			jobSize = 1.0
		}
		return jobSize
	}

	// Secondary: infer from complexity
	switch item.Complexity {
	case types.BasicComplexityLow:
		jobSize = 0.2
	case types.BasicComplexityMedium:
		jobSize = 0.5
	case types.BasicComplexityHigh:
		jobSize = 0.8
	default:
		jobSize = 0.4
	}

	// Adjust based on number of tools/frameworks (complexity indicator)
	toolComplexity := float64(len(item.Tools)+len(item.Frameworks)) * 0.05
	jobSize += toolComplexity

	// Adjust based on number of prerequisites (integration complexity)
	depComplexity := float64(len(item.Prerequisites)) * 0.03
	jobSize += depComplexity

	// Adjust based on number of outputs (scope indicator)
	outputComplexity := float64(len(item.Outputs)) * 0.02
	jobSize += outputComplexity

	if jobSize > 1.0 {
		jobSize = 1.0
	}
	if jobSize < 0.1 {
		jobSize = 0.1 // Minimum size
	}

	return jobSize
}

// calculateDependencies assesses dependency impact on priority
func (c *WSJFCalculator) calculateDependencies(item types.RoadmapItem) float64 {
	numDeps := len(item.Prerequisites)
	
	if numDeps == 0 {
		return 1.0 // No dependencies = no penalty
	}

	// More dependencies = lower multiplier
	depMultiplier := 1.0 - (float64(numDeps) * 0.1)
	if depMultiplier < 0.3 {
		depMultiplier = 0.3 // Minimum multiplier
	}

	return depMultiplier
}

// normalizeScore normalizes WSJF score to 0-1 range
func (c *WSJFCalculator) normalizeScore(wsjfScore float64) float64 {
	// WSJF scores typically range from 0 to 10+
	// We'll use a sigmoid-like function to normalize
	
	if wsjfScore <= 0 {
		return 0
	}

	// Simple normalization: score / (score + 1)
	// This gives us a nice curve that approaches 1 as score increases
	normalized := wsjfScore / (wsjfScore + 1)
	
	return normalized
}
