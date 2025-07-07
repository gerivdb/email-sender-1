package scripts

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// NeedsSurveyReport represents documentation needs assessment
type NeedsSurveyReport struct {
	GeneratedAt        time.Time               `json:"generated_at"`
	ProjectName        string                  `json:"project_name"`
	UserRoles          []UserRole              `json:"user_roles"`
	DocumentationNeeds []DocumentationNeed     `json:"documentation_needs"`
	PriorityMatrix     map[string]PriorityItem `json:"priority_matrix"`
	Recommendations    []string                `json:"recommendations"`
	Summary            string                  `json:"summary"`
}

// UserRole represents different types of users and their needs
type UserRole struct {
	Name        string   `json:"name"`
	Description string   `json:"description"`
	Needs       []string `json:"needs"`
	Priority    string   `json:"priority"`
	Usage       string   `json:"usage"`
}

// DocumentationNeed represents a specific documentation requirement
type DocumentationNeed struct {
	Category    string   `json:"category"`
	Type        string   `json:"type"`
	Description string   `json:"description"`
	UserRoles   []string `json:"user_roles"`
	Priority    string   `json:"priority"`
	Format      string   `json:"format"`
	Examples    []string `json:"examples"`
}

// PriorityItem represents prioritized documentation items
type PriorityItem struct {
	Description string   `json:"description"`
	Impact      string   `json:"impact"`
	Effort      string   `json:"effort"`
	UserRoles   []string `json:"user_roles"`
}

func main() {
	projectRoot := "."
	if len(os.Args) > 1 {
		projectRoot = os.Args[1]
	}

	report, err := generateNeedsSurvey(projectRoot)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error generating needs survey: %v\n", err)
		os.Exit(1)
	}

	// Output JSON to stdout
	encoder := json.NewEncoder(os.Stdout)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(report); err != nil {
		fmt.Fprintf(os.Stderr, "Error encoding JSON: %v\n", err)
		os.Exit(1)
	}
}

func generateNeedsSurvey(root string) (*NeedsSurveyReport, error) {
	projectName := filepath.Base(root)
	if projectName == "." || projectName == "/" {
		projectName = "project"
	}

	// Analyze project structure to determine user roles and needs
	projectType := analyzeProjectType(root)
	userRoles := defineUserRoles(projectType)
	documentationNeeds := generateDocumentationNeeds(projectType)
	priorityMatrix := createPriorityMatrix(documentationNeeds)

	report := &NeedsSurveyReport{
		GeneratedAt:        time.Now(),
		ProjectName:        projectName,
		UserRoles:          userRoles,
		DocumentationNeeds: documentationNeeds,
		PriorityMatrix:     priorityMatrix,
		Recommendations:    generateRecommendations(userRoles, documentationNeeds),
		Summary:            generateNeedsSummary(userRoles, documentationNeeds),
	}

	return report, nil
}

func analyzeProjectType(root string) map[string]bool {
	features := make(map[string]bool)

	// Check for different project characteristics
	err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if info.IsDir() {
			return nil
		}

		// Get relative path for consistent processing
		relPath, err := filepath.Rel(root, path)
		if err != nil {
			relPath = path // fallback to absolute path
		}

		// Skip certain directories
		if shouldSkipPath(relPath) {
			return nil
		}

		filename := strings.ToLower(info.Name())
		pathLower := strings.ToLower(relPath)

		// Check for API project
		if strings.Contains(filename, "api") || strings.Contains(pathLower, "/api/") ||
			strings.HasPrefix(pathLower, "api/") {
			features["api"] = true
		}

		// Check for web application
		if strings.Contains(filename, "server") || strings.Contains(filename, "handler") ||
			strings.Contains(pathLower, "/web/") || strings.HasPrefix(pathLower, "web/") {
			features["web"] = true
		}

		// Check for CLI application
		if strings.Contains(pathLower, "/cmd/") || strings.HasPrefix(pathLower, "cmd/") ||
			strings.Contains(filename, "cli") || filename == "main.go" {
			features["cli"] = true
		}

		// Check for microservices
		if strings.Contains(pathLower, "/service") || strings.Contains(pathLower, "/microservice") ||
			strings.HasPrefix(pathLower, "service") {
			features["microservices"] = true
		}

		// Check for database integration
		if strings.Contains(filename, "database") || strings.Contains(filename, "db") ||
			strings.Contains(filename, "migration") {
			features["database"] = true
		}

		// Check for testing infrastructure
		if strings.Contains(filename, "test") || strings.Contains(pathLower, "/test") ||
			strings.HasPrefix(pathLower, "test") {
			features["testing"] = true
		}

		// Check for CI/CD
		if strings.Contains(pathLower, ".github/workflows") || strings.Contains(pathLower, "/.github/workflows") ||
			strings.Contains(filename, "pipeline") || strings.Contains(filename, "deploy") ||
			strings.HasSuffix(filename, ".yml") || strings.HasSuffix(filename, ".yaml") {
			features["cicd"] = true
		}

		// Check for Docker
		if filename == "dockerfile" || strings.Contains(filename, "docker") {
			features["docker"] = true
		}

		// Check for configuration management
		if strings.Contains(filename, "config") || strings.HasSuffix(filename, ".yaml") ||
			strings.HasSuffix(filename, ".yml") || strings.HasSuffix(filename, ".json") {
			features["config"] = true
		}

		return nil
	})

	if err != nil {
		// Continue with what we have
	}

	return features
}

func defineUserRoles(projectType map[string]bool) []UserRole {
	var roles []UserRole

	// Always include basic roles
	roles = append(roles, UserRole{
		Name:        "developer",
		Description: "Software developers working on the project",
		Needs: []string{
			"API documentation", "code examples", "setup instructions",
			"development guidelines", "testing guides", "architecture overview",
		},
		Priority: "high",
		Usage:    "Daily development work, onboarding, debugging",
	})

	roles = append(roles, UserRole{
		Name:        "user",
		Description: "End users of the software/service",
		Needs: []string{
			"user guides", "tutorials", "FAQ", "troubleshooting",
			"installation instructions", "feature documentation",
		},
		Priority: "high",
		Usage:    "Learning to use the software, solving problems",
	})

	roles = append(roles, UserRole{
		Name:        "contributor",
		Description: "External contributors and open source community",
		Needs: []string{
			"contribution guidelines", "code of conduct", "development setup",
			"coding standards", "PR process", "community guidelines",
		},
		Priority: "medium",
		Usage:    "Contributing code, reporting issues, community participation",
	})

	// Add role-specific needs based on project type
	if projectType["api"] {
		roles = append(roles, UserRole{
			Name:        "api_consumer",
			Description: "Developers consuming the API",
			Needs: []string{
				"API reference", "authentication docs", "rate limiting",
				"error handling", "SDK documentation", "code examples",
			},
			Priority: "high",
			Usage:    "Integrating with the API, troubleshooting API issues",
		})
	}

	if projectType["cicd"] || projectType["docker"] {
		roles = append(roles, UserRole{
			Name:        "devops",
			Description: "DevOps engineers and system administrators",
			Needs: []string{
				"deployment guides", "infrastructure docs", "monitoring setup",
				"backup procedures", "security guidelines", "scaling documentation",
			},
			Priority: "medium",
			Usage:    "Deploying and maintaining the system",
		})
	}

	if projectType["testing"] {
		roles = append(roles, UserRole{
			Name:        "qa_tester",
			Description: "Quality assurance and testing professionals",
			Needs: []string{
				"test procedures", "test data setup", "bug reporting guidelines",
				"testing environments", "automation guides", "performance testing",
			},
			Priority: "medium",
			Usage:    "Testing the software, validating functionality",
		})
	}

	// Add management role for larger projects
	roles = append(roles, UserRole{
		Name:        "project_manager",
		Description: "Project managers and technical leads",
		Needs: []string{
			"project overview", "roadmap", "progress tracking",
			"team onboarding", "decision records", "status reports",
		},
		Priority: "low",
		Usage:    "Project planning, team coordination, progress tracking",
	})

	return roles
}

func generateDocumentationNeeds(projectType map[string]bool) []DocumentationNeed {
	var needs []DocumentationNeed

	// Core documentation needs
	needs = append(needs, DocumentationNeed{
		Category:    "getting_started",
		Type:        "installation",
		Description: "Step-by-step installation and setup guide",
		UserRoles:   []string{"developer", "user", "contributor"},
		Priority:    "critical",
		Format:      "markdown",
		Examples:    []string{"README.md", "INSTALLATION.md", "docs/setup.md"},
	})

	needs = append(needs, DocumentationNeed{
		Category:    "getting_started",
		Type:        "quick_start",
		Description: "Quick start guide for immediate productivity",
		UserRoles:   []string{"developer", "user"},
		Priority:    "high",
		Format:      "markdown",
		Examples:    []string{"QUICKSTART.md", "docs/quickstart.md"},
	})

	needs = append(needs, DocumentationNeed{
		Category:    "development",
		Type:        "guidelines",
		Description: "Development guidelines and coding standards",
		UserRoles:   []string{"developer", "contributor"},
		Priority:    "high",
		Format:      "markdown",
		Examples:    []string{"CONTRIBUTING.md", "docs/development.md"},
	})

	// API-specific documentation
	if projectType["api"] {
		needs = append(needs, DocumentationNeed{
			Category:    "api",
			Type:        "reference",
			Description: "Complete API reference with endpoints and examples",
			UserRoles:   []string{"developer", "api_consumer"},
			Priority:    "critical",
			Format:      "openapi",
			Examples:    []string{"docs/api.md", "swagger.yaml", "openapi.json"},
		})

		needs = append(needs, DocumentationNeed{
			Category:    "api",
			Type:        "authentication",
			Description: "Authentication and authorization documentation",
			UserRoles:   []string{"api_consumer", "developer"},
			Priority:    "high",
			Format:      "markdown",
			Examples:    []string{"docs/auth.md", "docs/security.md"},
		})
	}

	// Testing documentation
	if projectType["testing"] {
		needs = append(needs, DocumentationNeed{
			Category:    "testing",
			Type:        "guidelines",
			Description: "Testing guidelines and best practices",
			UserRoles:   []string{"developer", "qa_tester"},
			Priority:    "medium",
			Format:      "markdown",
			Examples:    []string{"docs/testing.md", "TEST_GUIDE.md"},
		})
	}

	// Deployment documentation
	if projectType["cicd"] || projectType["docker"] {
		needs = append(needs, DocumentationNeed{
			Category:    "deployment",
			Type:        "guide",
			Description: "Deployment and infrastructure documentation",
			UserRoles:   []string{"devops", "developer"},
			Priority:    "high",
			Format:      "markdown",
			Examples:    []string{"docs/deployment.md", "DEPLOY.md"},
		})
	}

	// Architecture documentation
	needs = append(needs, DocumentationNeed{
		Category:    "architecture",
		Type:        "overview",
		Description: "System architecture and design decisions",
		UserRoles:   []string{"developer", "project_manager"},
		Priority:    "medium",
		Format:      "markdown",
		Examples:    []string{"docs/architecture.md", "ARCHITECTURE.md"},
	})

	// User documentation
	needs = append(needs, DocumentationNeed{
		Category:    "user",
		Type:        "guides",
		Description: "User guides and tutorials",
		UserRoles:   []string{"user"},
		Priority:    "high",
		Format:      "markdown",
		Examples:    []string{"docs/user-guide.md", "docs/tutorials/"},
	})

	// Troubleshooting
	needs = append(needs, DocumentationNeed{
		Category:    "support",
		Type:        "troubleshooting",
		Description: "Common issues and troubleshooting guide",
		UserRoles:   []string{"user", "developer", "devops"},
		Priority:    "medium",
		Format:      "markdown",
		Examples:    []string{"docs/troubleshooting.md", "FAQ.md"},
	})

	return needs
}

func createPriorityMatrix(needs []DocumentationNeed) map[string]PriorityItem {
	matrix := make(map[string]PriorityItem)

	for _, need := range needs {
		key := fmt.Sprintf("%s_%s", need.Category, need.Type)

		impact := "medium"
		effort := "medium"

		// Determine impact based on user roles and priority
		if len(need.UserRoles) >= 3 || need.Priority == "critical" {
			impact = "high"
		} else if need.Priority == "high" {
			impact = "medium"
		} else {
			impact = "low"
		}

		// Determine effort based on complexity
		if need.Type == "reference" || need.Category == "api" {
			effort = "high"
		} else if need.Type == "guidelines" || need.Category == "architecture" {
			effort = "medium"
		} else {
			effort = "low"
		}

		matrix[key] = PriorityItem{
			Description: need.Description,
			Impact:      impact,
			Effort:      effort,
			UserRoles:   need.UserRoles,
		}
	}

	return matrix
}

func generateRecommendations(userRoles []UserRole, needs []DocumentationNeed) []string {
	var recommendations []string

	// Analyze priorities
	criticalNeeds := 0
	highNeeds := 0

	for _, need := range needs {
		if need.Priority == "critical" {
			criticalNeeds++
		} else if need.Priority == "high" {
			highNeeds++
		}
	}

	// Generate strategic recommendations
	if criticalNeeds > 0 {
		recommendations = append(recommendations,
			fmt.Sprintf("Focus immediately on %d critical documentation needs", criticalNeeds))
	}

	if highNeeds > 3 {
		recommendations = append(recommendations,
			"Consider establishing a documentation team or assigning dedicated resources")
	}

	// Role-specific recommendations
	hasAPIRole := false
	hasDevOpsRole := false

	for _, role := range userRoles {
		if role.Name == "api_consumer" {
			hasAPIRole = true
		}
		if role.Name == "devops" {
			hasDevOpsRole = true
		}
	}

	if hasAPIRole {
		recommendations = append(recommendations,
			"Prioritize API documentation as it impacts multiple external consumers")
	}

	if hasDevOpsRole {
		recommendations = append(recommendations,
			"Include deployment and operational documentation for system reliability")
	}

	// General recommendations
	recommendations = append(recommendations,
		"Implement documentation-driven development practices",
		"Set up automated documentation generation where possible",
		"Establish regular documentation review and update processes",
		"Create templates for consistent documentation structure",
	)

	return recommendations
}

func generateNeedsSummary(userRoles []UserRole, needs []DocumentationNeed) string {
	summary := fmt.Sprintf("Documentation needs assessment for %d user roles and %d documentation types.\n\n",
		len(userRoles), len(needs))

	// Count priorities
	priorityCounts := make(map[string]int)
	for _, need := range needs {
		priorityCounts[need.Priority]++
	}

	summary += "Priority breakdown:\n"
	for priority, count := range priorityCounts {
		summary += fmt.Sprintf("- %s: %d items\n", strings.Title(priority), count)
	}

	summary += "\nKey user roles:\n"
	for _, role := range userRoles {
		if role.Priority == "high" {
			summary += fmt.Sprintf("- %s: %s\n", strings.Title(role.Name), role.Description)
		}
	}

	summary += "\nRecommendation: Start with critical and high-priority items, focusing on roles with daily usage patterns."

	return summary
}

func shouldSkipPath(path string) bool {
	skipPaths := []string{
		"node_modules", ".git", "vendor", "build", "dist",
		"coverage", "backup", ".avg-exclude", "bin", "tmp",
	}

	pathLower := strings.ToLower(path)
	for _, skip := range skipPaths {
		if strings.HasPrefix(pathLower, skip+"/") ||
			strings.Contains(pathLower, "/"+skip+"/") ||
			strings.HasSuffix(pathLower, "/"+skip) ||
			pathLower == skip {
			return true
		}
	}
	return false
}
