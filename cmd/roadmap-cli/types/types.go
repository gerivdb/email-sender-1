package types

import "time"

// BasicComplexity represents the basic complexity level of a task
type BasicComplexity string

const (
	BasicComplexityLow    BasicComplexity = "low"
	BasicComplexityMedium BasicComplexity = "medium"
	BasicComplexityHigh   BasicComplexity = "high"
)

// RiskLevel represents the risk level of a task
type RiskLevel string

const (
	RiskLow    RiskLevel = "low"
	RiskMedium RiskLevel = "medium"
	RiskHigh   RiskLevel = "high"
)

// Status represents roadmap item status
type Status string

const (
	StatusPlanned    Status = "planned"
	StatusInProgress Status = "in_progress"
	StatusInReview   Status = "in_review"
	StatusCompleted  Status = "completed"
	StatusBlocked    Status = "blocked"
)

// Priority represents roadmap item priority
type Priority string

const (
	PriorityLow      Priority = "low"
	PriorityMedium   Priority = "medium"
	PriorityHigh     Priority = "high"
	PriorityCritical Priority = "critical"
)

// TaskInput represents an input required for a task
type TaskInput struct {
	Name        string `json:"name"`
	Type        string `json:"type"`
	Source      string `json:"source"`
	Description string `json:"description"`
}

// TaskOutput represents an output produced by a task
type TaskOutput struct {
	Name        string `json:"name"`
	Type        string `json:"type"`
	Format      string `json:"format"`
	Description string `json:"description"`
}

// TaskScript represents a script or executable associated with a task
type TaskScript struct {
	Name        string `json:"name"`
	Path        string `json:"path"`
	Language    string `json:"language"`
	Description string `json:"description"`
}

// RoadmapItem represents a roadmap item with enriched data
type RoadmapItem struct {
	// Basic fields
	ID          string    `json:"id"`
	Title       string    `json:"title"`
	Description string    `json:"description"`
	Status      Status    `json:"status"`
	Progress    int       `json:"progress"`
	Priority    Priority  `json:"priority"`
	TargetDate  time.Time `json:"target_date"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`

	// Enriched fields
	Inputs        []TaskInput  `json:"inputs,omitempty"`
	Outputs       []TaskOutput `json:"outputs,omitempty"`
	Scripts       []TaskScript `json:"scripts,omitempty"`
	Prerequisites []string     `json:"prerequisites,omitempty"`
	Methods       []string     `json:"methods,omitempty"`
	URIs          []string     `json:"uris,omitempty"`
	Tools         []string     `json:"tools,omitempty"`
	Frameworks    []string     `json:"frameworks,omitempty"`

	// Metadata fields
	Complexity    BasicComplexity `json:"complexity,omitempty"`
	Effort        int             `json:"effort,omitempty"`         // in hours
	BusinessValue int             `json:"business_value,omitempty"` // 1-10 scale
	TechnicalDebt int             `json:"technical_debt,omitempty"` // 1-10 scale
	RiskLevel     RiskLevel       `json:"risk_level,omitempty"`
	Tags          []string        `json:"tags,omitempty"`
}

// Milestone represents a roadmap milestone
type Milestone struct {
	ID          string    `json:"id"`
	Title       string    `json:"title"`
	Description string    `json:"description"`
	TargetDate  time.Time `json:"target_date"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// EnrichedItemOptions contains options for creating enriched roadmap items
type EnrichedItemOptions struct {
	Title         string
	Description   string
	Priority      Priority
	Status        Status
	TargetDate    time.Time
	Inputs        []TaskInput
	Outputs       []TaskOutput
	Scripts       []TaskScript
	Prerequisites []string
	Methods       []string
	URIs          []string
	Tools         []string
	Frameworks    []string
	Complexity    BasicComplexity
	Effort        int
	BusinessValue int
	TechnicalDebt int
	RiskLevel     RiskLevel
	Tags          []string
}

// Roadmap represents a complete roadmap with metadata
type Roadmap struct {
	ID          string        `json:"id"`
	Title       string        `json:"title"`
	Description string        `json:"description"`
	Version     string        `json:"version"`
	CreatedAt   time.Time     `json:"created_at"`
	UpdatedAt   time.Time     `json:"updated_at"`
	Items       []RoadmapItem `json:"items"`
	Metadata    map[string]interface{} `json:"metadata,omitempty"`
}
