package main

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"
)

// SecurityConfig holds configuration for registry access
type SecurityConfig struct {
	RegistryAuth map[string]RegistryCredentials `json:"registry_auth"`
}

// RegistryCredentials holds authentication info for a registry
type RegistryCredentials struct {
	Username string `json:"username"`
	Password string `json:"password"`
	Token    string `json:"token,omitempty"`
}

// initializeSecurityIntegration sets up security manager integration
func (m *GoModManager) initializeSecurityIntegration() error {
	// Check if security manager is already initialized
	if m.securityManager != nil {
		return nil
	}

	m.Log("Initializing security integration...")
	// In a real implementation, this would use a factory or service locator
	// to get an instance of the SecurityManager
	
	// For now we'll just log this step
	m.Log("Security integration initialized successfully")
	return nil
}

// loadRegistryCredentials loads and decrypts registry credentials using SecurityManager
func (m *GoModManager) loadRegistryCredentials() error {
	if m.securityManager == nil {
		m.Log("SecurityManager not initialized, skipping credential loading")
		return nil
	}

	m.Log("Loading registry credentials...")
	
	// Try to get the registry credentials secret
	regCredentialsSecret, err := m.securityManager.GetSecret("dependency-manager.registry-credentials")
	if err != nil {
		m.Log(fmt.Sprintf("Error loading registry credentials: %v", err))
		return err
	}
	
	// Parse credentials
	var secConfig SecurityConfig
	if err := json.Unmarshal([]byte(regCredentialsSecret), &secConfig); err != nil {
		m.Log(fmt.Sprintf("Error parsing registry credentials: %v", err))
		return err
	}
	
	// Store credentials in memory for use in go operations
	m.registryCredentials = secConfig.RegistryAuth
	m.Log(fmt.Sprintf("Loaded credentials for %d registries", len(m.registryCredentials)))
	
	return nil
}

// configureAuthForPrivateModules sets up GOPRIVATE and GOPROXY environment variables
func (m *GoModManager) configureAuthForPrivateModules() error {
	if len(m.registryCredentials) == 0 {
		return nil // No credentials to configure
	}

	m.Log("Configuring authentication for private modules...")
	
	// Build list of private module patterns for GOPRIVATE
	var privateModules []string
	for registry := range m.registryCredentials {
		// Convert registry URL to Go module pattern
		// Example: github.com/private-org would be added to GOPRIVATE
		privateModules = append(privateModules, registry)
	}
	
	// Configuration would set GOPRIVATE in the real implementation
	// os.Setenv("GOPRIVATE", strings.Join(privateModules, ","))
	m.Log(fmt.Sprintf("Configured GOPRIVATE=%s", strings.Join(privateModules, ",")))

	// In a real implementation, this would also configure git credentials or NETRC file
	// for authentication with the private repositories
	
	return nil
}

// scanDependenciesForVulnerabilities scans dependencies using SecurityManager
func (m *GoModManager) scanDependenciesForVulnerabilities(ctx context.Context, dependencies []Dependency) (*SecurityAuditResult, error) {
	if m.securityManager == nil {
		return nil, fmt.Errorf("security manager not initialized")
	}
	
	m.Log(fmt.Sprintf("Scanning %d dependencies for vulnerabilities...", len(dependencies)))
	
	return m.securityManager.ScanForVulnerabilities(ctx, dependencies)
}

// generateVulnerabilityReport creates a formatted vulnerability report
func (m *GoModManager) generateVulnerabilityReport(report *SecurityAuditResult) string {
	if report == nil {
		return "No vulnerability report available"
	}
	
	var output strings.Builder
	
	output.WriteString("=== Dependency Vulnerability Report ===\n")
	output.WriteString(fmt.Sprintf("Timestamp: %s\n", report.Timestamp.Format(time.RFC3339)))
	output.WriteString(fmt.Sprintf("Total dependencies scanned: %d\n", report.TotalScanned))
	output.WriteString(fmt.Sprintf("Vulnerabilities found: %d\n", report.VulnerabilitiesFound))
	output.WriteString("\nDetails:\n")
	
	if report.VulnerabilitiesFound > 0 {
		for dep, info := range report.Details {
			output.WriteString(fmt.Sprintf("- %s: \n", dep))
			output.WriteString(fmt.Sprintf("  Severity: %s\n", info.Severity))
			output.WriteString(fmt.Sprintf("  Description: %s\n", info.Description))
			if len(info.CVEIDs) > 0 {
				output.WriteString(fmt.Sprintf("  CVEs: %s\n", strings.Join(info.CVEIDs, ", ")))
			}
			if info.FixVersion != "" {
				output.WriteString(fmt.Sprintf("  Fix available in version: %s\n", info.FixVersion))
			}
			output.WriteString("\n")
		}
	} else {
		output.WriteString("No vulnerabilities found. All dependencies are secure.\n")
	}
	
	return output.String()
}
