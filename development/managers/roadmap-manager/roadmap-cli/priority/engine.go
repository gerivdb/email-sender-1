package priority

import (
	"fmt"
	"time"

	"email_sender/cmd/roadmap-cli/types"
)

// PriorityFactor represents different factors that influence task priority
type PriorityFactor string

const (
	FactorUrgency       PriorityFactor = "urgency"
	FactorImpact        PriorityFactor = "impact"
	FactorEffort        PriorityFactor = "effort"
	FactorDependencies  PriorityFactor = "dependencies"
	FactorBusinessValue PriorityFactor = "business_value"
	FactorRisk          PriorityFactor = "risk"
)

// TaskPriority represents the calculated priority for a task
type TaskPriority struct {
	TaskID         string                     `json:"task_id"`
	Score          float64                    `json:"score"`
	Factors        map[PriorityFactor]float64 `json:"factors"`
	LastCalculated time.Time                  `json:"last_calculated"`
	Algorithm      string                     `json:"algorithm"`
}

// WeightingConfig represents user-customizable weights for priority factors
type WeightingConfig struct {
	Urgency       float64 `json:"urgency"`        // Weight for urgency (0.0-1.0)
	Impact        float64 `json:"impact"`         // Weight for impact (0.0-1.0)
	Effort        float64 `json:"effort"`         // Weight for effort (0.0-1.0)
	Dependencies  float64 `json:"dependencies"`   // Weight for dependencies (0.0-1.0)
	BusinessValue float64 `json:"business_value"` // Weight for business value (0.0-1.0)
	Risk          float64 `json:"risk"`           // Weight for risk (0.0-1.0)
}

// DefaultWeightingConfig returns the default weighting configuration
func DefaultWeightingConfig() WeightingConfig {
	return WeightingConfig{
		Urgency:       0.25,
		Impact:        0.25,
		Effort:        0.20,
		Dependencies:  0.10,
		BusinessValue: 0.15,
		Risk:          0.05,
	}
}

// PriorityCalculator interface defines methods for priority calculation algorithms
type PriorityCalculator interface {
	Calculate(item types.RoadmapItem, config WeightingConfig) (TaskPriority, error)
	GetName() string
	GetDescription() string
}

// PriorityEngine interface defines the main priority engine operations
type PriorityEngine interface {
	Calculate(item types.RoadmapItem) (TaskPriority, error)
	Update(taskID string) error
	Rank(items []types.RoadmapItem) ([]types.RoadmapItem, error)
	SetCalculator(calculator PriorityCalculator)
	SetWeightingConfig(config WeightingConfig)
	GetWeightingConfig() WeightingConfig
}

// Engine implements the PriorityEngine interface
type Engine struct {
	calculator PriorityCalculator
	config     WeightingConfig
	cache      map[string]TaskPriority
}

// NewEngine creates a new priority engine with default configuration
func NewEngine() *Engine {
	return &Engine{
		calculator: NewEisenhowerCalculator(),
		config:     DefaultWeightingConfig(),
		cache:      make(map[string]TaskPriority),
	}
}

// Calculate computes priority for a single item
func (e *Engine) Calculate(item types.RoadmapItem) (TaskPriority, error) {
	if e.calculator == nil {
		return TaskPriority{}, fmt.Errorf("no priority calculator configured")
	}

	priority, err := e.calculator.Calculate(item, e.config)
	if err != nil {
		return TaskPriority{}, fmt.Errorf("failed to calculate priority: %w", err)
	}

	// Cache the result
	e.cache[item.ID] = priority

	return priority, nil
}

// Update recalculates priority for a specific task
func (e *Engine) Update(taskID string) error {
	// In a real implementation, this would fetch the task data
	// For now, we'll just remove from cache to force recalculation
	delete(e.cache, taskID)
	return nil
}

// Rank sorts items by priority score in descending order
func (e *Engine) Rank(items []types.RoadmapItem) ([]types.RoadmapItem, error) {
	type itemWithPriority struct {
		item     types.RoadmapItem
		priority TaskPriority
	}

	var itemsWithPriority []itemWithPriority

	// Calculate priorities for all items
	for _, item := range items {
		priority, err := e.Calculate(item)
		if err != nil {
			return nil, fmt.Errorf("failed to calculate priority for item %s: %w", item.ID, err)
		}
		itemsWithPriority = append(itemsWithPriority, itemWithPriority{
			item:     item,
			priority: priority,
		})
	}

	// Sort by priority score (highest first)
	for i := 0; i < len(itemsWithPriority)-1; i++ {
		for j := i + 1; j < len(itemsWithPriority); j++ {
			if itemsWithPriority[i].priority.Score < itemsWithPriority[j].priority.Score {
				itemsWithPriority[i], itemsWithPriority[j] = itemsWithPriority[j], itemsWithPriority[i]
			}
		}
	}

	// Extract sorted items
	var sortedItems []types.RoadmapItem
	for _, item := range itemsWithPriority {
		sortedItems = append(sortedItems, item.item)
	}

	return sortedItems, nil
}

// SetCalculator sets the priority calculation algorithm
func (e *Engine) SetCalculator(calculator PriorityCalculator) {
	e.calculator = calculator
	// Clear cache when algorithm changes
	e.cache = make(map[string]TaskPriority)
}

// SetWeightingConfig sets the weighting configuration
func (e *Engine) SetWeightingConfig(config WeightingConfig) {
	e.config = config
	// Clear cache when weights change
	e.cache = make(map[string]TaskPriority)
}

// GetWeightingConfig returns the current weighting configuration
func (e *Engine) GetWeightingConfig() WeightingConfig {
	return e.config
}

// GetCachedPriority returns cached priority if available
func (e *Engine) GetCachedPriority(taskID string) (TaskPriority, bool) {
	priority, exists := e.cache[taskID]
	return priority, exists
}

// ClearCache clears the priority calculation cache
func (e *Engine) ClearCache() {
	e.cache = make(map[string]TaskPriority)
}
