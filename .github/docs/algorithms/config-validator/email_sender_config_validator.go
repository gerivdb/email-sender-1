// File: .github/docs/algorithms/config-validator/email_sender_config_validator.go
// EMAIL_SENDER_1 Algorithm 7 - Configuration Validator
// Validates and optimizes EMAIL_SENDER_1 configuration files across all components

package main

import (
	"encoding/json"
	"fmt"
	"io/fs"
	"log"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"time"
	"unicode"
)

// ConfigValidationResult represents the complete validation result
type ConfigValidationResult struct {
	ProjectPath      string                     `json:"project_path"`
	ValidationTime   time.Time                  `json:"validation_time"`
	TotalConfigs     int                        `json:"total_configs"`
	ValidConfigs     int                        `json:"valid_configs"`
	InvalidConfigs   int                        `json:"invalid_configs"`
	ComponentConfigs map[string]ComponentConfig `json:"component_configs"`
	ValidationIssues []ValidationIssue          `json:"validation_issues"`
	SecurityIssues   []SecurityIssue            `json:"security_issues"`
	OptimizationTips []OptimizationTip          `json:"optimization_tips"`
	OverallHealth    string                     `json:"overall_health"`
	HealthScore      float64                    `json:"health_score"`
	ExecutionTime    time.Duration              `json:"execution_time"`
}

// ComponentConfig represents configuration analysis for a component
type ComponentConfig struct {
	Name            string            `json:"name"`
	ConfigFiles     []string          `json:"config_files"`
	ValidFiles      int               `json:"valid_files"`
	InvalidFiles    int               `json:"invalid_files"`
	MissingRequired []string          `json:"missing_required"`
	DeprecatedKeys  []string          `json:"deprecated_keys"`
	SecurityRisks   []string          `json:"security_risks"`
	Recommendations []string          `json:"recommendations"`
	ConfigType      string            `json:"config_type"`
	LastModified    time.Time         `json:"last_modified"`
	Properties      map[string]string `json:"properties"`
}

// ValidationIssue represents a configuration validation issue
type ValidationIssue struct {
	File       string `json:"file"`
	Component  string `json:"component"`
	Type       string `json:"type"`
	Severity   string `json:"severity"`
	Line       int    `json:"line"`
	Column     int    `json:"column"`
	Message    string `json:"message"`
	Suggestion string `json:"suggestion"`
	RuleName   string `json:"rule_name"`
}

// SecurityIssue represents a security-related configuration issue
type SecurityIssue struct {
	File         string `json:"file"`
	Component    string `json:"component"`
	RiskLevel    string `json:"risk_level"`
	Issue        string `json:"issue"`
	Impact       string `json:"impact"`
	Remediation  string `json:"remediation"`
	CWEReference string `json:"cwe_reference,omitempty"`
}

// OptimizationTip represents a performance optimization suggestion
type OptimizationTip struct {
	File         string  `json:"file"`
	Component    string  `json:"component"`
	Category     string  `json:"category"`
	Suggestion   string  `json:"suggestion"`
	ExpectedGain string  `json:"expected_gain"`
	Complexity   string  `json:"complexity"`
	Confidence   float64 `json:"confidence"`
}

// EMAIL_SENDER_1 component configuration patterns
var configPatterns = map[string]ConfigPattern{
	"RAG_Engine": {
		Files:          []string{"**/*rag*.json", "**/*embedding*.yaml", "**/*vector*.yml", "**/*llm*.config"},
		RequiredKeys:   []string{"model", "api_key", "endpoint"},
		OptionalKeys:   []string{"temperature", "max_tokens", "timeout"},
		DeprecatedKeys: []string{"old_api_version", "legacy_endpoint"},
		SecurityKeys:   []string{"api_key", "secret", "token"},
		Type:           "AI/ML Configuration",
	},
	"N8N_Workflows": {
		Files:          []string{"**/*workflow*.json", "**/n8n/**/*.json"},
		RequiredKeys:   []string{"name", "nodes", "connections"},
		OptionalKeys:   []string{"settings", "meta", "tags"},
		DeprecatedKeys: []string{"old_version"},
		SecurityKeys:   []string{"credentials", "auth"},
		Type:           "Workflow Configuration",
	},
	"Notion_API": {
		Files:          []string{"**/*notion*.json", "**/*notion*.env", "**/*database*.config"},
		RequiredKeys:   []string{"notion_token", "database_id"},
		OptionalKeys:   []string{"version", "timeout", "retry_count"},
		DeprecatedKeys: []string{"legacy_token"},
		SecurityKeys:   []string{"notion_token", "integration_token"},
		Type:           "API Configuration",
	},
	"Gmail_Processing": {
		Files:          []string{"**/*gmail*.json", "**/*email*.yaml", "**/*smtp*.config"},
		RequiredKeys:   []string{"smtp_server", "port", "username"},
		OptionalKeys:   []string{"use_tls", "timeout", "max_retries"},
		DeprecatedKeys: []string{"old_auth_method"},
		SecurityKeys:   []string{"password", "oauth_token", "app_password"},
		Type:           "Email Configuration",
	},
	"PowerShell_Scripts": {
		Files:          []string{"**/*.psd1", "**/config.ps1", "**/*settings*.ps1"},
		RequiredKeys:   []string{"ModuleVersion", "GUID"},
		OptionalKeys:   []string{"Author", "Description", "PowerShellVersion"},
		DeprecatedKeys: []string{"CLRVersion"},
		SecurityKeys:   []string{"ExecutionPolicy", "Credential"},
		Type:           "PowerShell Configuration",
	},
	"System_Config": {
		Files:          []string{"**/*.env", "**/config.*", "**/.env*", "**/settings.*"},
		RequiredKeys:   []string{},
		OptionalKeys:   []string{},
		DeprecatedKeys: []string{},
		SecurityKeys:   []string{"PASSWORD", "SECRET", "KEY", "TOKEN"},
		Type:           "System Configuration",
	},
}

type ConfigPattern struct {
	Files          []string
	RequiredKeys   []string
	OptionalKeys   []string
	DeprecatedKeys []string
	SecurityKeys   []string
	Type           string
}

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintf(os.Stderr, "Usage: %s <project_path> [output_file]\n", os.Args[0])
		os.Exit(1)
	}

	projectPath := os.Args[1]
	outputFile := "config_validation_results.json"

	if len(os.Args) > 2 {
		outputFile = os.Args[2]
	}

	startTime := time.Now()
	log.Printf("🔧 Starting EMAIL_SENDER_1 Configuration Validation for: %s", projectPath)

	result, err := validateEmailSenderConfigs(projectPath)
	if err != nil {
		log.Fatalf("❌ Configuration validation failed: %v", err)
	}

	result.ExecutionTime = time.Since(startTime)
	log.Printf("✅ Configuration validation completed in %v", result.ExecutionTime)

	// Output results
	if err := outputResults(result, outputFile); err != nil {
		log.Fatalf("❌ Failed to output results: %v", err)
	}

	log.Printf("📊 Results saved to: %s", outputFile)
	displaySummary(result)
}

// validateEmailSenderConfigs performs comprehensive configuration validation
func validateEmailSenderConfigs(projectPath string) (*ConfigValidationResult, error) {
	result := &ConfigValidationResult{
		ProjectPath:      projectPath,
		ValidationTime:   time.Now(),
		ComponentConfigs: make(map[string]ComponentConfig),
	}

	// Validate each component configuration
	for componentName, pattern := range configPatterns {
		log.Printf("🔍 Validating %s configurations", componentName)

		componentConfig, err := validateComponentConfig(projectPath, componentName, pattern)
		if err != nil {
			log.Printf("⚠️ Warning: Failed to validate %s configs: %v", componentName, err)
			continue
		}

		result.ComponentConfigs[componentName] = *componentConfig
		result.TotalConfigs += len(componentConfig.ConfigFiles)
		result.ValidConfigs += componentConfig.ValidFiles
		result.InvalidConfigs += componentConfig.InvalidFiles
	}

	// Collect all validation issues
	result.ValidationIssues = collectValidationIssues(result)
	result.SecurityIssues = collectSecurityIssues(result)
	result.OptimizationTips = generateOptimizationTips(result)

	// Calculate overall health
	result.HealthScore = calculateHealthScore(result)
	result.OverallHealth = determineOverallHealth(result.HealthScore)

	return result, nil
}

// validateComponentConfig validates configuration for a specific component
func validateComponentConfig(projectPath, componentName string, pattern ConfigPattern) (*ComponentConfig, error) {
	config := &ComponentConfig{
		Name:            componentName,
		ConfigFiles:     []string{},
		MissingRequired: []string{},
		DeprecatedKeys:  []string{},
		SecurityRisks:   []string{},
		Recommendations: []string{},
		ConfigType:      pattern.Type,
		Properties:      make(map[string]string),
	}

	// Find configuration files
	configFiles, err := findConfigFiles(projectPath, pattern.Files)
	if err != nil {
		return config, err
	}

	config.ConfigFiles = configFiles

	if len(configFiles) == 0 {
		config.Recommendations = append(config.Recommendations, "No configuration files found for "+componentName)
		return config, nil
	}

	// Validate each configuration file
	for _, configFile := range configFiles {
		isValid, issues := validateConfigFile(configFile, pattern)

		if isValid {
			config.ValidFiles++
		} else {
			config.InvalidFiles++
		}

		// Update last modified time
		if fileInfo, err := os.Stat(configFile); err == nil {
			if fileInfo.ModTime().After(config.LastModified) {
				config.LastModified = fileInfo.ModTime()
			}
		}

		// Collect issues specific to this component
		for _, issue := range issues {
			switch issue.Type {
			case "missing_required":
				if !contains(config.MissingRequired, issue.Message) {
					config.MissingRequired = append(config.MissingRequired, issue.Message)
				}
			case "deprecated":
				if !contains(config.DeprecatedKeys, issue.Message) {
					config.DeprecatedKeys = append(config.DeprecatedKeys, issue.Message)
				}
			case "security":
				if !contains(config.SecurityRisks, issue.Message) {
					config.SecurityRisks = append(config.SecurityRisks, issue.Message)
				}
			}
		}
	}

	// Generate component-specific recommendations
	config.Recommendations = append(config.Recommendations, generateComponentRecommendations(config, pattern)...)

	return config, nil
}

// findConfigFiles finds configuration files matching patterns
func findConfigFiles(projectPath string, patterns []string) ([]string, error) {
	var allFiles []string

	for _, pattern := range patterns {
		files, err := findFilesMatchingPattern(projectPath, pattern)
		if err != nil {
			continue // Skip patterns that don't match
		}
		allFiles = append(allFiles, files...)
	}

	// Remove duplicates and sort
	allFiles = removeDuplicates(allFiles)
	sort.Strings(allFiles)

	return allFiles, nil
}

// findFilesMatchingPattern finds files matching a glob pattern
func findFilesMatchingPattern(projectPath, pattern string) ([]string, error) {
	var matches []string

	err := filepath.WalkDir(projectPath, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return nil // Continue walking
		}

		if d.IsDir() {
			return nil
		}

		// Check if file matches pattern
		relPath, err := filepath.Rel(projectPath, path)
		if err != nil {
			return nil
		}

		// Simple pattern matching
		if matchesPattern(relPath, pattern) {
			matches = append(matches, path)
		}

		return nil
	})

	return matches, err
}

// matchesPattern checks if a file path matches a glob-like pattern
func matchesPattern(filePath, pattern string) bool {
	// Remove ** prefix for simplicity
	pattern = strings.TrimPrefix(pattern, "**/")

	// Check file extension or name matches
	if strings.HasSuffix(pattern, "*") {
		prefix := strings.TrimSuffix(pattern, "*")
		return strings.Contains(filePath, prefix)
	}

	if strings.HasPrefix(pattern, "*.") {
		ext := strings.TrimPrefix(pattern, "*")
		return strings.HasSuffix(filePath, ext)
	}

	return strings.Contains(filePath, pattern) || filepath.Base(filePath) == pattern
}

// validateConfigFile validates a single configuration file
func validateConfigFile(filePath string, pattern ConfigPattern) (bool, []ValidationIssue) {
	var issues []ValidationIssue
	isValid := true

	content, err := os.ReadFile(filePath)
	if err != nil {
		issues = append(issues, ValidationIssue{
			File:     filePath,
			Type:     "read_error",
			Severity: "error",
			Message:  fmt.Sprintf("Cannot read file: %v", err),
			RuleName: "file_accessibility",
		})
		return false, issues
	}

	contentStr := string(content)
	fileExt := strings.ToLower(filepath.Ext(filePath))

	// Validate based on file type
	switch fileExt {
	case ".json":
		jsonIssues := validateJSONConfig(filePath, contentStr, pattern)
		issues = append(issues, jsonIssues...)
	case ".yaml", ".yml":
		yamlIssues := validateYAMLConfig(filePath, contentStr, pattern)
		issues = append(issues, yamlIssues...)
	case ".env":
		envIssues := validateEnvConfig(filePath, contentStr, pattern)
		issues = append(issues, envIssues...)
	case ".ps1", ".psd1", ".psm1":
		psIssues := validatePowerShellConfig(filePath, contentStr, pattern)
		issues = append(issues, psIssues...)
	default:
		genericIssues := validateGenericConfig(filePath, contentStr, pattern)
		issues = append(issues, genericIssues...)
	}

	// Check for security issues
	securityIssues := checkSecurityIssues(filePath, contentStr, pattern)
	issues = append(issues, securityIssues...)

	// Check for deprecated keys
	deprecatedIssues := checkDeprecatedKeys(filePath, contentStr, pattern)
	issues = append(issues, deprecatedIssues...)

	// Determine if file is valid (no error-level issues)
	for _, issue := range issues {
		if issue.Severity == "error" {
			isValid = false
			break
		}
	}

	return isValid, issues
}

// validateJSONConfig validates JSON configuration files
func validateJSONConfig(filePath, content string, pattern ConfigPattern) []ValidationIssue {
	var issues []ValidationIssue

	// Try to parse JSON
	var jsonData map[string]interface{}
	if err := json.Unmarshal([]byte(content), &jsonData); err != nil {
		issues = append(issues, ValidationIssue{
			File:       filePath,
			Type:       "syntax_error",
			Severity:   "error",
			Message:    fmt.Sprintf("Invalid JSON syntax: %v", err),
			Suggestion: "Fix JSON syntax errors",
			RuleName:   "json_syntax",
		})
		return issues
	}

	// Check required keys
	for _, requiredKey := range pattern.RequiredKeys {
		if _, exists := jsonData[requiredKey]; !exists {
			issues = append(issues, ValidationIssue{
				File:       filePath,
				Type:       "missing_required",
				Severity:   "error",
				Message:    fmt.Sprintf("Missing required key: %s", requiredKey),
				Suggestion: fmt.Sprintf("Add required key '%s' to configuration", requiredKey),
				RuleName:   "required_keys",
			})
		}
	}

	// Check for empty values in important keys
	for key, value := range jsonData {
		if contains(pattern.RequiredKeys, key) {
			if value == nil || value == "" {
				issues = append(issues, ValidationIssue{
					File:       filePath,
					Type:       "empty_value",
					Severity:   "warning",
					Message:    fmt.Sprintf("Required key '%s' has empty value", key),
					Suggestion: fmt.Sprintf("Provide a valid value for '%s'", key),
					RuleName:   "empty_values",
				})
			}
		}
	}

	return issues
}

// validateYAMLConfig validates YAML configuration files
func validateYAMLConfig(filePath, content string, pattern ConfigPattern) []ValidationIssue {
	var issues []ValidationIssue

	// Basic YAML syntax validation (simplified)
	lines := strings.Split(content, "\n")
	for i, line := range lines {
		trimmed := strings.TrimSpace(line)
		if trimmed == "" || strings.HasPrefix(trimmed, "#") {
			continue
		}

		// Check for basic YAML structure
		if !strings.Contains(line, ":") && !strings.HasPrefix(trimmed, "-") {
			if !unicode.IsSpace(rune(line[0])) {
				issues = append(issues, ValidationIssue{
					File:       filePath,
					Type:       "syntax_warning",
					Severity:   "warning",
					Line:       i + 1,
					Message:    "Potentially malformed YAML line",
					Suggestion: "Check YAML syntax",
					RuleName:   "yaml_syntax",
				})
			}
		}
	}

	// Check for required keys (simplified)
	for _, requiredKey := range pattern.RequiredKeys {
		if !strings.Contains(content, requiredKey+":") {
			issues = append(issues, ValidationIssue{
				File:       filePath,
				Type:       "missing_required",
				Severity:   "error",
				Message:    fmt.Sprintf("Missing required key: %s", requiredKey),
				Suggestion: fmt.Sprintf("Add required key '%s:' to YAML configuration", requiredKey),
				RuleName:   "required_keys",
			})
		}
	}

	return issues
}

// validateEnvConfig validates environment configuration files
func validateEnvConfig(filePath, content string, pattern ConfigPattern) []ValidationIssue {
	var issues []ValidationIssue

	lines := strings.Split(content, "\n")
	for i, line := range lines {
		trimmed := strings.TrimSpace(line)
		if trimmed == "" || strings.HasPrefix(trimmed, "#") {
			continue
		}

		// Check for proper KEY=VALUE format
		if !strings.Contains(trimmed, "=") {
			issues = append(issues, ValidationIssue{
				File:       filePath,
				Type:       "syntax_error",
				Severity:   "error",
				Line:       i + 1,
				Message:    "Invalid environment variable format (should be KEY=VALUE)",
				Suggestion: "Use KEY=VALUE format",
				RuleName:   "env_syntax",
			})
		} else {
			parts := strings.SplitN(trimmed, "=", 2)
			if len(parts) == 2 {
				key := parts[0]
				value := parts[1]

				// Check for empty values in important keys
				if contains(pattern.SecurityKeys, key) && value == "" {
					issues = append(issues, ValidationIssue{
						File:       filePath,
						Type:       "empty_security_value",
						Severity:   "warning",
						Line:       i + 1,
						Message:    fmt.Sprintf("Security-related key '%s' has empty value", key),
						Suggestion: "Provide a valid value for security keys",
						RuleName:   "security_values",
					})
				}
			}
		}
	}

	return issues
}

// validatePowerShellConfig validates PowerShell configuration files
func validatePowerShellConfig(filePath, content string, pattern ConfigPattern) []ValidationIssue {
	var issues []ValidationIssue

	// Check for PowerShell manifest structure (for .psd1 files)
	if strings.HasSuffix(strings.ToLower(filePath), ".psd1") {
		if !strings.Contains(content, "@{") {
			issues = append(issues, ValidationIssue{
				File:       filePath,
				Type:       "syntax_error",
				Severity:   "error",
				Message:    "PowerShell manifest should start with @{",
				Suggestion: "Use proper PowerShell hashtable syntax",
				RuleName:   "powershell_manifest",
			})
		}

		// Check for required keys in manifest
		for _, requiredKey := range pattern.RequiredKeys {
			keyPattern := fmt.Sprintf(`%s\s*=`, requiredKey)
			matched, _ := regexp.MatchString(keyPattern, content)
			if !matched {
				issues = append(issues, ValidationIssue{
					File:       filePath,
					Type:       "missing_required",
					Severity:   "error",
					Message:    fmt.Sprintf("Missing required key: %s", requiredKey),
					Suggestion: fmt.Sprintf("Add '%s = value' to manifest", requiredKey),
					RuleName:   "required_keys",
				})
			}
		}
	}

	// Check for potentially dangerous PowerShell constructs
	dangerousPatterns := []string{
		`Invoke-Expression`,
		`IEX`,
		`Invoke-Command.*-ComputerName`,
		`New-Object.*System\.Net\.WebClient`,
	}

	lines := strings.Split(content, "\n")
	for i, line := range lines {
		for _, pattern := range dangerousPatterns {
			matched, _ := regexp.MatchString(pattern, line)
			if matched {
				issues = append(issues, ValidationIssue{
					File:       filePath,
					Type:       "security_warning",
					Severity:   "warning",
					Line:       i + 1,
					Message:    "Potentially dangerous PowerShell construct detected",
					Suggestion: "Review for security implications",
					RuleName:   "powershell_security",
				})
			}
		}
	}

	return issues
}

// validateGenericConfig validates generic configuration files
func validateGenericConfig(filePath, content string, pattern ConfigPattern) []ValidationIssue {
	var issues []ValidationIssue

	// Check for obviously corrupted files
	if len(content) == 0 {
		issues = append(issues, ValidationIssue{
			File:       filePath,
			Type:       "empty_file",
			Severity:   "warning",
			Message:    "Configuration file is empty",
			Suggestion: "Add configuration content or remove unused file",
			RuleName:   "empty_file",
		})
	}

	// Check for binary content in text config files
	if strings.Contains(content, "\x00") {
		issues = append(issues, ValidationIssue{
			File:       filePath,
			Type:       "binary_content",
			Severity:   "error",
			Message:    "File appears to contain binary content",
			Suggestion: "Ensure configuration file is text-based",
			RuleName:   "text_content",
		})
	}

	return issues
}

// checkSecurityIssues checks for security-related configuration issues
func checkSecurityIssues(filePath, content string, pattern ConfigPattern) []ValidationIssue {
	var issues []ValidationIssue

	// Check for hardcoded credentials
	credentialPatterns := []struct {
		pattern string
		message string
	}{
		{`(?i)password\s*[:=]\s*["\']?[^"\'\s\n]{8,}`, "Hardcoded password detected"},
		{`(?i)api_key\s*[:=]\s*["\']?[a-zA-Z0-9]{20,}`, "Hardcoded API key detected"},
		{`(?i)secret\s*[:=]\s*["\']?[a-zA-Z0-9]{16,}`, "Hardcoded secret detected"},
		{`(?i)token\s*[:=]\s*["\']?[a-zA-Z0-9]{20,}`, "Hardcoded token detected"},
	}

	lines := strings.Split(content, "\n")
	for i, line := range lines {
		for _, cp := range credentialPatterns {
			matched, _ := regexp.MatchString(cp.pattern, line)
			if matched {
				issues = append(issues, ValidationIssue{
					File:       filePath,
					Type:       "security",
					Severity:   "error",
					Line:       i + 1,
					Message:    cp.message,
					Suggestion: "Use environment variables or secure credential storage",
					RuleName:   "hardcoded_credentials",
				})
			}
		}
	}

	// Check for insecure protocols
	insecurePatterns := []string{
		`(?i)http://(?!localhost|127\.0\.0\.1)`,
		`(?i)ftp://`,
		`(?i)telnet://`,
	}

	for i, line := range lines {
		for _, pattern := range insecurePatterns {
			matched, _ := regexp.MatchString(pattern, line)
			if matched {
				issues = append(issues, ValidationIssue{
					File:       filePath,
					Type:       "security",
					Severity:   "warning",
					Line:       i + 1,
					Message:    "Insecure protocol detected",
					Suggestion: "Use secure protocols (HTTPS, SFTP, SSH)",
					RuleName:   "insecure_protocols",
				})
			}
		}
	}

	return issues
}

// checkDeprecatedKeys checks for deprecated configuration keys
func checkDeprecatedKeys(filePath, content string, pattern ConfigPattern) []ValidationIssue {
	var issues []ValidationIssue

	for _, deprecatedKey := range pattern.DeprecatedKeys {
		if strings.Contains(content, deprecatedKey) {
			issues = append(issues, ValidationIssue{
				File:       filePath,
				Type:       "deprecated",
				Severity:   "warning",
				Message:    fmt.Sprintf("Deprecated key found: %s", deprecatedKey),
				Suggestion: "Update to use current configuration keys",
				RuleName:   "deprecated_keys",
			})
		}
	}

	return issues
}

// collectValidationIssues collects all validation issues from components
func collectValidationIssues(result *ConfigValidationResult) []ValidationIssue {
	var allIssues []ValidationIssue

	for componentName, config := range result.ComponentConfigs {
		for _, configFile := range config.ConfigFiles {
			_, issues := validateConfigFile(configFile, configPatterns[componentName])
			for _, issue := range issues {
				issue.Component = componentName
				allIssues = append(allIssues, issue)
			}
		}
	}

	return allIssues
}

// collectSecurityIssues collects security issues from validation results
func collectSecurityIssues(result *ConfigValidationResult) []SecurityIssue {
	var securityIssues []SecurityIssue

	for _, issue := range result.ValidationIssues {
		if issue.Type == "security" || issue.Type == "security_warning" {
			securityIssue := SecurityIssue{
				File:        issue.File,
				Component:   issue.Component,
				RiskLevel:   mapSeverityToRisk(issue.Severity),
				Issue:       issue.Message,
				Impact:      "Potential security vulnerability",
				Remediation: issue.Suggestion,
			}

			// Add CWE reference for known patterns
			if strings.Contains(issue.Message, "credential") {
				securityIssue.CWEReference = "CWE-798"
			} else if strings.Contains(issue.Message, "protocol") {
				securityIssue.CWEReference = "CWE-319"
			}

			securityIssues = append(securityIssues, securityIssue)
		}
	}

	return securityIssues
}

// generateOptimizationTips generates optimization suggestions
func generateOptimizationTips(result *ConfigValidationResult) []OptimizationTip {
	var tips []OptimizationTip

	for componentName, config := range result.ComponentConfigs {
		// Performance tips based on component type
		switch componentName {
		case "RAG_Engine":
			if len(config.ConfigFiles) > 0 {
				tips = append(tips, OptimizationTip{
					Component:    componentName,
					Category:     "Performance",
					Suggestion:   "Consider caching embeddings to improve response time",
					ExpectedGain: "30-50% faster responses",
					Complexity:   "Medium",
					Confidence:   0.8,
				})
			}
		case "N8N_Workflows":
			if config.ValidFiles > 5 {
				tips = append(tips, OptimizationTip{
					Component:    componentName,
					Category:     "Optimization",
					Suggestion:   "Consider consolidating similar workflows to reduce maintenance overhead",
					ExpectedGain: "Reduced complexity",
					Complexity:   "Low",
					Confidence:   0.7,
				})
			}
		case "PowerShell_Scripts":
			tips = append(tips, OptimizationTip{
				Component:    componentName,
				Category:     "Performance",
				Suggestion:   "Enable PowerShell module auto-loading for better performance",
				ExpectedGain: "Faster script execution",
				Complexity:   "Low",
				Confidence:   0.9,
			})
		}

		// General tips based on configuration health
		if len(config.SecurityRisks) > 0 {
			tips = append(tips, OptimizationTip{
				Component:    componentName,
				Category:     "Security",
				Suggestion:   "Implement secure credential management",
				ExpectedGain: "Improved security posture",
				Complexity:   "Medium",
				Confidence:   0.95,
			})
		}
	}

	return tips
}

// Helper functions

func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}

func removeDuplicates(slice []string) []string {
	keys := make(map[string]bool)
	var result []string

	for _, item := range slice {
		if !keys[item] {
			keys[item] = true
			result = append(result, item)
		}
	}

	return result
}

func mapSeverityToRisk(severity string) string {
	switch severity {
	case "error":
		return "High"
	case "warning":
		return "Medium"
	default:
		return "Low"
	}
}

func generateComponentRecommendations(config *ComponentConfig, pattern ConfigPattern) []string {
	var recommendations []string

	if len(config.MissingRequired) > 0 {
		recommendations = append(recommendations, "Add missing required configuration keys")
	}

	if len(config.DeprecatedKeys) > 0 {
		recommendations = append(recommendations, "Update deprecated configuration keys")
	}

	if len(config.SecurityRisks) > 0 {
		recommendations = append(recommendations, "Address security risks in configuration")
	}

	if config.InvalidFiles > 0 {
		recommendations = append(recommendations, "Fix configuration syntax errors")
	}

	if len(config.ConfigFiles) == 0 {
		recommendations = append(recommendations, "Consider adding configuration files for better customization")
	}

	return recommendations
}

func calculateHealthScore(result *ConfigValidationResult) float64 {
	if result.TotalConfigs == 0 {
		return 50.0 // Neutral score for no configs
	}

	// Base score from valid configurations
	validRatio := float64(result.ValidConfigs) / float64(result.TotalConfigs)
	baseScore := validRatio * 100

	// Penalty for security issues
	securityPenalty := float64(len(result.SecurityIssues)) * 10

	// Penalty for validation errors
	errorCount := 0
	for _, issue := range result.ValidationIssues {
		if issue.Severity == "error" {
			errorCount++
		}
	}
	errorPenalty := float64(errorCount) * 5

	// Calculate final score
	finalScore := baseScore - securityPenalty - errorPenalty

	// Ensure score is between 0 and 100
	if finalScore < 0 {
		finalScore = 0
	}
	if finalScore > 100 {
		finalScore = 100
	}

	return finalScore
}

func determineOverallHealth(healthScore float64) string {
	if healthScore >= 90 {
		return "Excellent"
	} else if healthScore >= 75 {
		return "Good"
	} else if healthScore >= 60 {
		return "Fair"
	} else if healthScore >= 40 {
		return "Poor"
	} else {
		return "Critical"
	}
}

// outputResults outputs the validation results
func outputResults(result *ConfigValidationResult, outputFile string) error {
	// JSON output for programmatic use
	if strings.HasSuffix(strings.ToLower(outputFile), ".json") {
		jsonData, err := json.MarshalIndent(result, "", "  ")
		if err != nil {
			return fmt.Errorf("failed to marshal JSON: %w", err)
		}

		return os.WriteFile(outputFile, jsonData, 0644)
	}

	// Text output for human reading
	return outputTextResults(result, outputFile)
}

func outputTextResults(result *ConfigValidationResult, outputFile string) error {
	file, err := os.Create(outputFile)
	if err != nil {
		return err
	}
	defer file.Close()

	fmt.Fprintf(file, "EMAIL_SENDER_1 CONFIGURATION VALIDATION RESULTS\n")
	fmt.Fprintf(file, "==============================================\n\n")
	fmt.Fprintf(file, "Project: %s\n", result.ProjectPath)
	fmt.Fprintf(file, "Validation Time: %s\n", result.ValidationTime.Format(time.RFC3339))
	fmt.Fprintf(file, "Execution Time: %s\n", result.ExecutionTime)
	fmt.Fprintf(file, "Overall Health: %s (%.1f/100)\n\n", result.OverallHealth, result.HealthScore)

	fmt.Fprintf(file, "CONFIGURATION SUMMARY\n")
	fmt.Fprintf(file, "--------------------\n")
	fmt.Fprintf(file, "Total Configurations: %d\n", result.TotalConfigs)
	fmt.Fprintf(file, "Valid Configurations: %d\n", result.ValidConfigs)
	fmt.Fprintf(file, "Invalid Configurations: %d\n", result.InvalidConfigs)
	fmt.Fprintf(file, "Security Issues: %d\n", len(result.SecurityIssues))
	fmt.Fprintf(file, "Optimization Tips: %d\n\n", len(result.OptimizationTips))

	// Component details
	fmt.Fprintf(file, "COMPONENT ANALYSIS\n")
	fmt.Fprintf(file, "------------------\n")
	for name, config := range result.ComponentConfigs {
		fmt.Fprintf(file, "\n%s (%s):\n", name, config.ConfigType)
		fmt.Fprintf(file, "  Config Files: %d\n", len(config.ConfigFiles))
		fmt.Fprintf(file, "  Valid: %d, Invalid: %d\n", config.ValidFiles, config.InvalidFiles)

		if len(config.MissingRequired) > 0 {
			fmt.Fprintf(file, "  Missing Required: %s\n", strings.Join(config.MissingRequired, ", "))
		}

		if len(config.SecurityRisks) > 0 {
			fmt.Fprintf(file, "  Security Risks: %d\n", len(config.SecurityRisks))
		}
	}

	// Critical issues
	errorIssues := []ValidationIssue{}
	for _, issue := range result.ValidationIssues {
		if issue.Severity == "error" {
			errorIssues = append(errorIssues, issue)
		}
	}

	if len(errorIssues) > 0 {
		fmt.Fprintf(file, "\nCRITICAL ISSUES\n")
		fmt.Fprintf(file, "---------------\n")
		for _, issue := range errorIssues {
			fmt.Fprintf(file, "• %s (Line %d): %s\n", issue.File, issue.Line, issue.Message)
		}
	}

	// Security issues
	if len(result.SecurityIssues) > 0 {
		fmt.Fprintf(file, "\nSECURITY ISSUES\n")
		fmt.Fprintf(file, "---------------\n")
		for _, issue := range result.SecurityIssues {
			fmt.Fprintf(file, "• %s [%s]: %s\n", issue.File, issue.RiskLevel, issue.Issue)
		}
	}

	// Optimization tips
	if len(result.OptimizationTips) > 0 {
		fmt.Fprintf(file, "\nOPTIMIZATION TIPS\n")
		fmt.Fprintf(file, "-----------------\n")
		for _, tip := range result.OptimizationTips {
			fmt.Fprintf(file, "• %s [%s]: %s\n", tip.Component, tip.Category, tip.Suggestion)
			fmt.Fprintf(file, "  Expected Gain: %s (Complexity: %s)\n", tip.ExpectedGain, tip.Complexity)
		}
	}

	return nil
}

func displaySummary(result *ConfigValidationResult) {
	fmt.Printf("\n" + "="*60 + "\n")
	fmt.Printf("📋 EMAIL_SENDER_1 CONFIGURATION VALIDATION SUMMARY\n")
	fmt.Printf("="*60 + "\n")

	fmt.Printf("🎯 Overall Health: %s (%.1f/100)\n", result.OverallHealth, result.HealthScore)
	fmt.Printf("📊 Valid Configs: %d/%d (%.1f%%)\n",
		result.ValidConfigs, result.TotalConfigs,
		float64(result.ValidConfigs)/float64(max(result.TotalConfigs, 1))*100)

	if len(result.SecurityIssues) > 0 {
		fmt.Printf("🔒 Security Issues: %d\n", len(result.SecurityIssues))
	} else {
		fmt.Printf("✅ No Security Issues Found\n")
	}

	if len(result.OptimizationTips) > 0 {
		fmt.Printf("💡 Optimization Tips: %d\n", len(result.OptimizationTips))
	}

	fmt.Printf("⏱️ Validation Time: %v\n", result.ExecutionTime)
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}
