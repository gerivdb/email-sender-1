package main

import (
	"fmt"
	"gopkg.in/yaml.v3"
	"os"
)

// GitWorkflowConfig represents the configuration for GitWorkflowManager
type GitWorkflowConfig struct {
	Repository struct {
		Path   string `yaml:"path"`
		Remote string `yaml:"remote"`
		Owner  string `yaml:"owner"`
		Name   string `yaml:"name"`
	} `yaml:"repository"`
	
	Workflow struct {
		Type             string            `yaml:"type"`
		DefaultBranch    string            `yaml:"default_branch"`
		ProtectedBranches []string         `yaml:"protected_branches"`
		BranchNaming     map[string]string `yaml:"branch_naming"`
	} `yaml:"workflow"`
	
	CommitRules struct {
		ConventionalCommits bool     `yaml:"conventional_commits"`
		RequiredFormat      string   `yaml:"required_format"`
		MaxLength           int      `yaml:"max_length"`
		MinLength           int      `yaml:"min_length"`
		AllowedTypes        []string `yaml:"allowed_types"`
	} `yaml:"commit_rules"`
	
	GitHub struct {
		Token        string `yaml:"token"`
		Organization string `yaml:"organization"`
		Repository   string `yaml:"repository"`
		APIEndpoint  string `yaml:"api_endpoint"`
	} `yaml:"github"`
	
	Webhooks struct {
		Enabled bool `yaml:"enabled"`
		Endpoints []struct {
			Name    string            `yaml:"name"`
			URL     string            `yaml:"url"`
			Events  []string          `yaml:"events"`
			Secret  string            `yaml:"secret"`
			Headers map[string]string `yaml:"headers"`
		} `yaml:"endpoints"`
		Timeout int `yaml:"timeout"`
		Retries int `yaml:"retries"`
	} `yaml:"webhooks"`
	
	Automation struct {
		AutoMerge struct {
			Enabled           bool     `yaml:"enabled"`
			RequiredChecks    []string `yaml:"required_checks"`
			RequiredReviews   int      `yaml:"required_reviews"`
			TargetBranches    []string `yaml:"target_branches"`
		} `yaml:"auto_merge"`
		
		BranchCleanup struct {
			Enabled       bool `yaml:"enabled"`
			DaysAfterMerge int `yaml:"days_after_merge"`
			ExcludeBranches []string `yaml:"exclude_branches"`
		} `yaml:"branch_cleanup"`
	} `yaml:"automation"`
	
	Notifications struct {
		Slack struct {
			Enabled    bool   `yaml:"enabled"`
			WebhookURL string `yaml:"webhook_url"`
			Channel    string `yaml:"channel"`
		} `yaml:"slack"`
		
		Email struct {
			Enabled bool     `yaml:"enabled"`
			SMTP    struct {
				Host     string `yaml:"host"`
				Port     int    `yaml:"port"`
				Username string `yaml:"username"`
				Password string `yaml:"password"`
			} `yaml:"smtp"`
			Recipients []string `yaml:"recipients"`
		} `yaml:"email"`
	} `yaml:"notifications"`
	
	Logging struct {
		Level  string `yaml:"level"`
		Format string `yaml:"format"`
		Output string `yaml:"output"`
	} `yaml:"logging"`
}

// DefaultConfig returns a default configuration
func DefaultConfig() *GitWorkflowConfig {
	return &GitWorkflowConfig{
		Repository: struct {
			Path   string `yaml:"path"`
			Remote string `yaml:"remote"`
			Owner  string `yaml:"owner"`
			Name   string `yaml:"name"`
		}{
			Path:   ".",
			Remote: "origin",
			Owner:  "",
			Name:   "",
		},
		
		Workflow: struct {
			Type             string            `yaml:"type"`
			DefaultBranch    string            `yaml:"default_branch"`
			ProtectedBranches []string         `yaml:"protected_branches"`
			BranchNaming     map[string]string `yaml:"branch_naming"`
		}{
			Type:             "gitflow",
			DefaultBranch:    "main",
			ProtectedBranches: []string{"main", "develop"},
			BranchNaming: map[string]string{
				"feature": "feature/{name}",
				"hotfix":  "hotfix/{name}",
				"release": "release/{version}",
				"bugfix":  "bugfix/{name}",
			},
		},
		
		CommitRules: struct {
			ConventionalCommits bool     `yaml:"conventional_commits"`
			RequiredFormat      string   `yaml:"required_format"`
			MaxLength           int      `yaml:"max_length"`
			MinLength           int      `yaml:"min_length"`
			AllowedTypes        []string `yaml:"allowed_types"`
		}{
			ConventionalCommits: true,
			RequiredFormat:      "^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)(\\(.+\\))?: .{1,50}",
			MaxLength:           72,
			MinLength:           10,
			AllowedTypes:        []string{"feat", "fix", "docs", "style", "refactor", "test", "chore", "perf", "ci", "build", "revert"},
		},
		
		GitHub: struct {
			Token        string `yaml:"token"`
			Organization string `yaml:"organization"`
			Repository   string `yaml:"repository"`
			APIEndpoint  string `yaml:"api_endpoint"`
		}{
			Token:        "",
			Organization: "",
			Repository:   "",
			APIEndpoint:  "https://api.github.com",
		},
		
		Webhooks: struct {
			Enabled bool `yaml:"enabled"`
			Endpoints []struct {
				Name    string            `yaml:"name"`
				URL     string            `yaml:"url"`
				Events  []string          `yaml:"events"`
				Secret  string            `yaml:"secret"`
				Headers map[string]string `yaml:"headers"`
			} `yaml:"endpoints"`
			Timeout int `yaml:"timeout"`
			Retries int `yaml:"retries"`
		}{
			Enabled:   false,
			Endpoints: []struct {
				Name    string            `yaml:"name"`
				URL     string            `yaml:"url"`
				Events  []string          `yaml:"events"`
				Secret  string            `yaml:"secret"`
				Headers map[string]string `yaml:"headers"`
			}{},
			Timeout: 30,
			Retries: 3,
		},
		
		Automation: struct {
			AutoMerge struct {
				Enabled           bool     `yaml:"enabled"`
				RequiredChecks    []string `yaml:"required_checks"`
				RequiredReviews   int      `yaml:"required_reviews"`
				TargetBranches    []string `yaml:"target_branches"`
			} `yaml:"auto_merge"`
			BranchCleanup struct {
				Enabled       bool `yaml:"enabled"`
				DaysAfterMerge int `yaml:"days_after_merge"`
				ExcludeBranches []string `yaml:"exclude_branches"`
			} `yaml:"branch_cleanup"`
		}{
			AutoMerge: struct {
				Enabled           bool     `yaml:"enabled"`
				RequiredChecks    []string `yaml:"required_checks"`
				RequiredReviews   int      `yaml:"required_reviews"`
				TargetBranches    []string `yaml:"target_branches"`
			}{
				Enabled:         false,
				RequiredChecks:  []string{},
				RequiredReviews: 1,
				TargetBranches:  []string{"main", "develop"},
			},
			BranchCleanup: struct {
				Enabled       bool `yaml:"enabled"`
				DaysAfterMerge int `yaml:"days_after_merge"`
				ExcludeBranches []string `yaml:"exclude_branches"`
			}{
				Enabled:         false,
				DaysAfterMerge:  7,
				ExcludeBranches: []string{"main", "develop", "master"},
			},
		},
		
		Notifications: struct {
			Slack struct {
				Enabled    bool   `yaml:"enabled"`
				WebhookURL string `yaml:"webhook_url"`
				Channel    string `yaml:"channel"`
			} `yaml:"slack"`
			Email struct {
				Enabled bool     `yaml:"enabled"`
				SMTP    struct {
					Host     string `yaml:"host"`
					Port     int    `yaml:"port"`
					Username string `yaml:"username"`
					Password string `yaml:"password"`
				} `yaml:"smtp"`
				Recipients []string `yaml:"recipients"`
			} `yaml:"email"`
		}{
			Slack: struct {
				Enabled    bool   `yaml:"enabled"`
				WebhookURL string `yaml:"webhook_url"`
				Channel    string `yaml:"channel"`
			}{
				Enabled:    false,
				WebhookURL: "",
				Channel:    "#git-notifications",
			},
			Email: struct {
				Enabled bool     `yaml:"enabled"`
				SMTP    struct {
					Host     string `yaml:"host"`
					Port     int    `yaml:"port"`
					Username string `yaml:"username"`
					Password string `yaml:"password"`
				} `yaml:"smtp"`
				Recipients []string `yaml:"recipients"`
			}{
				Enabled: false,
				SMTP: struct {
					Host     string `yaml:"host"`
					Port     int    `yaml:"port"`
					Username string `yaml:"username"`
					Password string `yaml:"password"`
				}{
					Host:     "smtp.gmail.com",
					Port:     587,
					Username: "",
					Password: "",
				},
				Recipients: []string{},
			},
		},
		
		Logging: struct {
			Level  string `yaml:"level"`
			Format string `yaml:"format"`
			Output string `yaml:"output"`
		}{
			Level:  "info",
			Format: "json",
			Output: "stdout",
		},
	}
}

// LoadConfig loads configuration from a YAML file
func LoadConfig(filename string) (*GitWorkflowConfig, error) {
	data, err := os.ReadFile(filename)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}
	
	config := DefaultConfig()
	err = yaml.Unmarshal(data, config)
	if err != nil {
		return nil, fmt.Errorf("failed to parse config file: %w", err)
	}
	
	return config, nil
}

// SaveConfig saves configuration to a YAML file
func SaveConfig(config *GitWorkflowConfig, filename string) error {
	data, err := yaml.Marshal(config)
	if err != nil {
		return fmt.Errorf("failed to marshal config: %w", err)
	}
	
	err = os.WriteFile(filename, data, 0644)
	if err != nil {
		return fmt.Errorf("failed to write config file: %w", err)
	}
	
	return nil
}

// ValidateConfig validates the configuration
func ValidateConfig(config *GitWorkflowConfig) error {
	// Validate repository configuration
	if config.Repository.Path == "" {
		return fmt.Errorf("repository path is required")
	}
	
	// Validate workflow type
	validWorkflowTypes := []string{"gitflow", "githubflow", "feature-branch", "custom"}
	isValidWorkflow := false
	for _, validType := range validWorkflowTypes {
		if config.Workflow.Type == validType {
			isValidWorkflow = true
			break
		}
	}
	if !isValidWorkflow {
		return fmt.Errorf("invalid workflow type: %s", config.Workflow.Type)
	}
	
	// Validate commit rules
	if config.CommitRules.MaxLength <= 0 {
		return fmt.Errorf("commit max length must be positive")
	}
	
	if config.CommitRules.MinLength < 0 {
		return fmt.Errorf("commit min length cannot be negative")
	}
	
	if config.CommitRules.MinLength >= config.CommitRules.MaxLength {
		return fmt.Errorf("commit min length must be less than max length")
	}
	
	// Validate webhook configuration
	if config.Webhooks.Enabled {
		if config.Webhooks.Timeout <= 0 {
			return fmt.Errorf("webhook timeout must be positive")
		}
		
		if config.Webhooks.Retries < 0 {
			return fmt.Errorf("webhook retries cannot be negative")
		}
	}
	
	return nil
}

// ToMap converts the configuration to a map[string]interface{}
func (c *GitWorkflowConfig) ToMap() map[string]interface{} {
	result := make(map[string]interface{})
	
	result["repository"] = map[string]interface{}{
		"path":   c.Repository.Path,
		"remote": c.Repository.Remote,
		"owner":  c.Repository.Owner,
		"name":   c.Repository.Name,
	}
	
	result["workflow"] = map[string]interface{}{
		"type":              c.Workflow.Type,
		"default_branch":    c.Workflow.DefaultBranch,
		"protected_branches": c.Workflow.ProtectedBranches,
		"branch_naming":     c.Workflow.BranchNaming,
	}
	
	result["commit_rules"] = map[string]interface{}{
		"conventional_commits": c.CommitRules.ConventionalCommits,
		"required_format":      c.CommitRules.RequiredFormat,
		"max_length":          c.CommitRules.MaxLength,
		"min_length":          c.CommitRules.MinLength,
		"allowed_types":       c.CommitRules.AllowedTypes,
	}
	
	result["github"] = map[string]interface{}{
		"token":        c.GitHub.Token,
		"organization": c.GitHub.Organization,
		"repository":   c.GitHub.Repository,
		"api_endpoint": c.GitHub.APIEndpoint,
	}
	
	// Convert webhook endpoints
	var webhookEndpoints []map[string]interface{}
	for _, endpoint := range c.Webhooks.Endpoints {
		webhookEndpoints = append(webhookEndpoints, map[string]interface{}{
			"name":    endpoint.Name,
			"url":     endpoint.URL,
			"events":  endpoint.Events,
			"secret":  endpoint.Secret,
			"headers": endpoint.Headers,
		})
	}
	
	result["webhooks"] = map[string]interface{}{
		"enabled":   c.Webhooks.Enabled,
		"endpoints": webhookEndpoints,
		"timeout":   c.Webhooks.Timeout,
		"retries":   c.Webhooks.Retries,
	}
	
	result["automation"] = map[string]interface{}{
		"auto_merge": map[string]interface{}{
			"enabled":          c.Automation.AutoMerge.Enabled,
			"required_checks":  c.Automation.AutoMerge.RequiredChecks,
			"required_reviews": c.Automation.AutoMerge.RequiredReviews,
			"target_branches":  c.Automation.AutoMerge.TargetBranches,
		},
		"branch_cleanup": map[string]interface{}{
			"enabled":         c.Automation.BranchCleanup.Enabled,
			"days_after_merge": c.Automation.BranchCleanup.DaysAfterMerge,
			"exclude_branches": c.Automation.BranchCleanup.ExcludeBranches,
		},
	}
	
	result["notifications"] = map[string]interface{}{
		"slack": map[string]interface{}{
			"enabled":     c.Notifications.Slack.Enabled,
			"webhook_url": c.Notifications.Slack.WebhookURL,
			"channel":     c.Notifications.Slack.Channel,
		},
		"email": map[string]interface{}{
			"enabled": c.Notifications.Email.Enabled,
			"smtp": map[string]interface{}{
				"host":     c.Notifications.Email.SMTP.Host,
				"port":     c.Notifications.Email.SMTP.Port,
				"username": c.Notifications.Email.SMTP.Username,
				"password": c.Notifications.Email.SMTP.Password,
			},
			"recipients": c.Notifications.Email.Recipients,
		},
	}
	
	result["logging"] = map[string]interface{}{
		"level":  c.Logging.Level,
		"format": c.Logging.Format,
		"output": c.Logging.Output,
	}
	
	return result
}
