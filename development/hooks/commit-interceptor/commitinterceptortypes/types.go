// types.go - Types partagés pour commit-interceptor
package commitinterceptortypes

import (
	"time"
)

// CommitData représente les données extraites d'un commit
type CommitData struct {
	Hash       string    `json:"hash"`
	Message    string    `json:"message"`
	Author     string    `json:"author"`
	Timestamp  time.Time `json:"timestamp"`
	Files      []string  `json:"files"`
	Branch     string    `json:"branch"`
	Repository string    `json:"repository"`
}

// CommitAnalysis - Résultat d’analyse enrichi pour le routage
type CommitAnalysis struct {
	ChangeType      string     // ex: "feature", "fix", etc.
	Impact          string     // "low", "medium", "high"
	Priority        string     // "normal", "critical", etc.
	SuggestedBranch string     // nom de branche suggéré
	Confidence      float64    // score de confiance
	CommitData      CommitData // données du commit associé
}

// Config représente la configuration pour le commit interceptor
type Config struct {
	Server               ServerConfig  `json:"server"`
	Git                  GitConfig     `json:"git"`
	Routing              RoutingConfig `json:"routing"`
	NotificationsEnabled bool          `json:"notifications_enabled"`
	Webhooks             WebhookConfig `json:"webhooks"`
	Logging              LoggingConfig `json:"logging"`
	TestMode             bool          `json:"test_mode"`
}

type ServerConfig struct {
	Port            int    `json:"port"`
	Host            string `json:"host"`
	ReadTimeout     int    `json:"read_timeout"`
	WriteTimeout    int    `json:"write_timeout"`
	ShutdownTimeout int    `json:"shutdown_timeout"`
}

type GitConfig struct {
	DefaultBranch     string   `json:"default_branch"`
	ProtectedBranches []string `json:"protected_branches"`
	RemoteName        string   `json:"remote_name"`
	AutoFetch         bool     `json:"auto_fetch"`
}

type RoutingConfig struct {
	Rules                map[string]RoutingRule `json:"rules"`
	DefaultStrategy      string                 `json:"default_strategy"`
	ConflictStrategy     string                 `json:"conflict_strategy"`
	AutoMergeEnabled     bool                   `json:"auto_merge_enabled"`
	CriticalFilePatterns []string               `json:"critical_file_patterns,omitempty"`
}

type RoutingRule struct {
	Patterns      []string `json:"patterns"`
	TargetBranch  string   `json:"target_branch"`
	CreateBranch  bool     `json:"create_branch"`
	MergeStrategy string   `json:"merge_strategy"`
	Priority      string   `json:"priority"`
}

type WebhookConfig struct {
	Enabled    bool              `json:"enabled"`
	Endpoints  map[string]string `json:"endpoints"`
	AuthTokens map[string]string `json:"auth_tokens"`
	Timeout    int               `json:"timeout"`
}

type LoggingConfig struct {
	Level      string `json:"level"`
	Format     string `json:"format"`
	OutputFile string `json:"output_file"`
}
