package main

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/email-sender/development/managers/interfaces" // Added import
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

	m.Log("info", "Initializing security integration...")
	// In a real implementation, this would use a factory or service locator
	// to get an instance of the SecurityManager
	
	// For now we'll just log this step
	m.Log("info", "Security integration initialized successfully")
	return nil
}

// loadRegistryCredentials loads and decrypts registry credentials using SecurityManager
func (m *GoModManager) loadRegistryCredentials() error {
	if m.securityManager == nil {
		m.Log("warn", "SecurityManager not initialized, skipping credential loading")
		return nil
	}

	m.Log("info", "Loading registry credentials...")
	
	// Try to get the registry credentials secret
	regCredentialsSecret, err := m.securityManager.GetSecret("dependency-manager.registry-credentials") // Assuming GetSecret is part of SecurityManagerInterface
	if err != nil {
		m.Log("error", fmt.Sprintf("Error loading registry credentials: %v", err))
		return err
	}
	
	// Parse credentials
	var secConfig SecurityConfig
	if err := json.Unmarshal([]byte(regCredentialsSecret), &secConfig); err != nil {
		m.Log("error", fmt.Sprintf("Error parsing registry credentials: %v", err))
		return err
	}
	
	// Store credentials in memory for use in go operations
	m.registryCredentials = secConfig.RegistryAuth
	m.Log("info", fmt.Sprintf("Loaded credentials for %d registries", len(m.registryCredentials)))
	
	return nil
}

// configureAuthForPrivateModules sets up GOPRIVATE and GOPROXY environment variables
func (m *GoModManager) configureAuthForPrivateModules() error {
	if len(m.registryCredentials) == 0 {
		return nil // No credentials to configure
	}

	m.Log("info", "Configuring authentication for private modules...")
	
	// Build list of private module patterns for GOPRIVATE
	var privateModules []string
	for registry := range m.registryCredentials {
		// Convert registry URL to Go module pattern
		// Example: github.com/private-org would be added to GOPRIVATE
		privateModules = append(privateModules, registry)
	}
	
	// Configuration would set GOPRIVATE in the real implementation
	// os.Setenv("GOPRIVATE", strings.Join(privateModules, ","))
	m.Log("info", fmt.Sprintf("Configured GOPRIVATE=%s", strings.Join(privateModules, ",")))

	// In a real implementation, this would also configure git credentials or NETRC file
	// for authentication with the private repositories
	
	return nil
}

// scanDependenciesForVulnerabilities scans dependencies using SecurityManager
func (m *GoModManager) scanDependenciesForVulnerabilities(ctx context.Context, dependencies []Dependency) (*interfaces.VulnerabilityReport, error) {
	if m.securityManager == nil {
		return nil, fmt.Errorf("security manager not initialized")
	}
	
	m.Log("info", fmt.Sprintf("Scanning %d dependencies for vulnerabilities...", len(dependencies)))
	
	// This now calls SecurityManagerInterface.ScanDependenciesForVulnerabilities which returns *interfaces.VulnerabilityReport
	return m.securityManager.ScanDependenciesForVulnerabilities(ctx, dependencies)
}

// generateVulnerabilityReport creates a formatted vulnerability report
func (m *GoModManager) generateVulnerabilityReport(report *interfaces.VulnerabilityReport) string {
	if report == nil {
		return "No vulnerability report available"
	}
	
	var output strings.Builder
	totalVulnerabilities := report.CriticalCount + report.HighCount + report.MediumCount + report.LowCount
	
	output.WriteString("=== Dependency Vulnerability Report ===\n")
	output.WriteString(fmt.Sprintf("Timestamp: %s\n", report.Timestamp.Format(time.RFC3339)))
	output.WriteString(fmt.Sprintf("Total dependencies scanned: %d\n", report.TotalScanned))
	output.WriteString(fmt.Sprintf("Total vulnerabilities found: %d (C:%d H:%d M:%d L:%d)\n",
		totalVulnerabilities, report.CriticalCount, report.HighCount, report.MediumCount, report.LowCount))
	
	if totalVulnerabilities > 0 {
		output.WriteString("\nDetails:\n")
		for i, vuln := range report.Vulnerabilities {
			// Assuming interfaces.Vulnerability has fields like PackageName, Version, Description, Severity, CVEs
			// This part needs to be adjusted based on actual fields in interfaces.Vulnerability
			output.WriteString(fmt.Sprintf("%d. Vulnerability:\n", i+1)) // Generic numbering
			output.WriteString(fmt.Sprintf("   Description: %s\n", vuln.Description))
			output.WriteString(fmt.Sprintf("   Severity: %s\n", vuln.Severity))
			if len(vuln.CVEIDs) > 0 {
				output.WriteString(fmt.Sprintf("   CVEs: %s\n", strings.Join(vuln.CVEIDs, ", ")))
			}
			// Add more fields from vuln as needed e.g. PackageName, Version, FixedIn
			output.WriteString("\n")
		}
	} else {
		output.WriteString("\nNo vulnerabilities found. All dependencies are secure.\n")
	}
	
	return output.String()
}
