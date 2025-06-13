package security

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"fmt"
	"io"
	"net"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"

	"github.com/email-sender-manager/interfaces"
)

// performVulnerabilityScan effectue un scan de vulnérabilités
func (sm *SecurityManagerImpl) performVulnerabilityScan(ctx context.Context, target string) []interfaces.Vulnerability {
	var vulnerabilities []interfaces.Vulnerability

	// Scanner les ports ouverts
	portVulns := sm.scanOpenPorts(target)
	vulnerabilities = append(vulnerabilities, portVulns...)

	// Scanner les fichiers sensibles
	fileVulns := sm.scanSensitiveFiles(target)
	vulnerabilities = append(vulnerabilities, fileVulns...)

	// Scanner les configurations
	configVulns := sm.scanConfigurations(target)
	vulnerabilities = append(vulnerabilities, configVulns...)

	// Scanner les dépendances
	depVulns := sm.scanDependencies(target)
	vulnerabilities = append(vulnerabilities, depVulns...)

	return vulnerabilities
}

// scanOpenPorts scanne les ports ouverts
func (sm *SecurityManagerImpl) scanOpenPorts(target string) []interfaces.Vulnerability {
	var vulnerabilities []interfaces.Vulnerability

	// Ports dangereux couramment ouverts
	dangerousPorts := map[int]string{
		22:   "SSH - Ensure strong authentication",
		23:   "Telnet - Unencrypted protocol",
		80:   "HTTP - Consider HTTPS",
		135:  "RPC - Potential security risk",
		139:  "NetBIOS - Potential security risk",
		445:  "SMB - Ensure proper configuration",
		1433: "SQL Server - Secure database access",
		3389: "RDP - Ensure strong authentication",
		5432: "PostgreSQL - Secure database access",
		6379: "Redis - Ensure authentication",
	}

	// Simuler un scan de ports (dans un vrai environnement, on utiliserait nmap ou similar)
	for port, description := range dangerousPorts {
		if sm.isPortOpen(target, port) {
			severity := "medium"
			if port == 23 || port == 135 || port == 139 {
				severity = "high"
			}

			vulnerabilities = append(vulnerabilities, interfaces.Vulnerability{
				ID:          fmt.Sprintf("OPEN_PORT_%d", port),
				PackageName: "network",
				Version:     "N/A",
				Severity:    severity,
				Description: fmt.Sprintf("Port %d is open: %s", port, description),
				CVSS:        sm.calculatePortCVSS(port),
				References: []string{
					fmt.Sprintf("https://www.speedguide.net/port.php?port=%d", port),
				},
			})
		}
	}

	return vulnerabilities
}

// scanSensitiveFiles scanne les fichiers sensibles
func (sm *SecurityManagerImpl) scanSensitiveFiles(target string) []interfaces.Vulnerability {
	var vulnerabilities []interfaces.Vulnerability

	sensitiveFiles := []string{
		".env",
		".env.local",
		".env.production",
		"config.json",
		"secrets.json",
		"private.key",
		"id_rsa",
		"id_dsa",
		"id_ecdsa",
		"id_ed25519",
		".htpasswd",
		"web.config",
		"app.config",
		"database.yml",
		"config/database.yml",
		".aws/credentials",
		".ssh/id_rsa",
		"backup.sql",
		"dump.sql",
	}

	for _, file := range sensitiveFiles {
		filePath := filepath.Join(target, file)
		if _, err := os.Stat(filePath); err == nil {
			severity := "high"
			if strings.Contains(file, "backup") || strings.Contains(file, "dump") {
				severity = "critical"
			}

			vulnerabilities = append(vulnerabilities, interfaces.Vulnerability{
				ID:          fmt.Sprintf("SENSITIVE_FILE_%s", strings.ReplaceAll(file, "/", "_")),
				PackageName: "filesystem",
				Version:     "N/A",
				Severity:    severity,
				Description: fmt.Sprintf("Sensitive file found: %s", file),
				CVSS:        sm.calculateFileCVSS(file),
				References: []string{
					"https://owasp.org/www-project-top-ten/2021/A05_2021-Security_Misconfiguration/",
				},
			})
		}
	}

	return vulnerabilities
}

// scanConfigurations scanne les configurations
func (sm *SecurityManagerImpl) scanConfigurations(target string) []interfaces.Vulnerability {
	var vulnerabilities []interfaces.Vulnerability

	// Scanner les fichiers de configuration courants
	configFiles := map[string][]string{
		"nginx.conf": {
			`server_tokens\s+on`,
			`ssl_protocols.*TLSv1\.0`,
			`ssl_protocols.*TLSv1\.1`,
		},
		"apache2.conf": {
			`ServerTokens\s+Full`,
			`ServerSignature\s+On`,
		},
		"docker-compose.yml": {
			`privileged:\s*true`,
			`--privileged`,
		},
	}

	for configFile, patterns := range configFiles {
		filePath := filepath.Join(target, configFile)
		if content, err := os.ReadFile(filePath); err == nil {
			for _, pattern := range patterns {
				if matched, _ := regexp.Match(pattern, content); matched {
					vulnerabilities = append(vulnerabilities, interfaces.Vulnerability{
						ID:          fmt.Sprintf("CONFIG_ISSUE_%s", strings.ReplaceAll(configFile, ".", "_")),
						PackageName: "configuration",
						Version:     "N/A",
						Severity:    "medium",
						Description: fmt.Sprintf("Security misconfiguration in %s: %s", configFile, pattern),
						CVSS:        5.0,
						References: []string{
							"https://owasp.org/www-project-top-ten/2021/A05_2021-Security_Misconfiguration/",
						},
					})
				}
			}
		}
	}

	return vulnerabilities
}

// scanDependencies scanne les dépendances pour les vulnérabilités
func (sm *SecurityManagerImpl) scanDependencies(target string) []interfaces.Vulnerability {
	var vulnerabilities []interfaces.Vulnerability

	// Vulnérabilités connues simulées
	knownVulns := map[string]map[string]interfaces.Vulnerability{
		"express": {
			"4.16.0": {
				ID:          "CVE-2022-24999",
				PackageName: "express",
				Version:     "4.16.0",
				Severity:    "medium",
				Description: "Open redirect vulnerability in express",
				CVSS:        5.4,
				References: []string{
					"https://nvd.nist.gov/vuln/detail/CVE-2022-24999",
				},
			},
		},
		"lodash": {
			"4.17.20": {
				ID:          "CVE-2021-23337",
				PackageName: "lodash",
				Version:     "4.17.20",
				Severity:    "high",
				Description: "Command injection vulnerability in lodash",
				CVSS:        7.5,
				References: []string{
					"https://nvd.nist.gov/vuln/detail/CVE-2021-23337",
				},
			},
		},
		"jquery": {
			"3.4.1": {
				ID:          "CVE-2020-11022",
				PackageName: "jquery",
				Version:     "3.4.1",
				Severity:    "medium",
				Description: "Cross-site scripting vulnerability in jQuery",
				CVSS:        6.1,
				References: []string{
					"https://nvd.nist.gov/vuln/detail/CVE-2020-11022",
				},
			},
		},
	}

	// Scanner package.json
	packageJsonPath := filepath.Join(target, "package.json")
	if content, err := os.ReadFile(packageJsonPath); err == nil {
		dependencies := sm.parsePackageJsonDependencies(string(content))
		for name, version := range dependencies {
			if packageVulns, exists := knownVulns[name]; exists {
				if vuln, versionExists := packageVulns[version]; versionExists {
					vulnerabilities = append(vulnerabilities, vuln)
				}
			}
		}
	}

	// Scanner go.mod
	goModPath := filepath.Join(target, "go.mod")
	if content, err := os.ReadFile(goModPath); err == nil {
		dependencies := sm.parseGoModDependencies(string(content))
		for name, version := range dependencies {
			if packageVulns, exists := knownVulns[name]; exists {
				if vuln, versionExists := packageVulns[version]; versionExists {
					vulnerabilities = append(vulnerabilities, vuln)
				}
			}
		}
	}

	return vulnerabilities
}

// generateScanSummary génère un résumé du scan
func (sm *SecurityManagerImpl) generateScanSummary(vulnerabilities []interfaces.Vulnerability) interfaces.ScanSummary {
	summary := interfaces.ScanSummary{
		TotalIssues:     len(vulnerabilities),
		CriticalIssues:  0,
		HighIssues:      0,
		MediumIssues:    0,
		LowIssues:       0,
		InfoIssues:      0,
		RiskScore:       0.0,
	}

	var totalCVSS float64
	for _, vuln := range vulnerabilities {
		switch vuln.Severity {
		case "critical":
			summary.CriticalIssues++
		case "high":
			summary.HighIssues++
		case "medium":
			summary.MediumIssues++
		case "low":
			summary.LowIssues++
		case "info":
			summary.InfoIssues++
		}
		totalCVSS += vuln.CVSS
	}

	if len(vulnerabilities) > 0 {
		summary.RiskScore = totalCVSS / float64(len(vulnerabilities))
	}

	return summary
}

// Méthodes utilitaires

// isPortOpen vérifie si un port est ouvert
func (sm *SecurityManagerImpl) isPortOpen(host string, port int) bool {
	timeout := time.Second * 2
	conn, err := net.DialTimeout("tcp", fmt.Sprintf("%s:%d", host, port), timeout)
	if err != nil {
		return false
	}
	defer conn.Close()
	return true
}

// calculatePortCVSS calcule le score CVSS pour un port ouvert
func (sm *SecurityManagerImpl) calculatePortCVSS(port int) float64 {
	dangerousPortsCVSS := map[int]float64{
		23:   8.8, // Telnet - très dangereux
		135:  7.5, // RPC
		139:  7.0, // NetBIOS
		445:  6.5, // SMB
		1433: 6.0, // SQL Server
		3389: 6.0, // RDP
		5432: 5.5, // PostgreSQL
		6379: 5.5, // Redis
		22:   4.0, // SSH - moins dangereux si bien configuré
		80:   3.0, // HTTP - information disclosure
	}

	if cvss, exists := dangerousPortsCVSS[port]; exists {
		return cvss
	}
	return 2.0 // Score par défaut pour les ports inconnus
}

// calculateFileCVSS calcule le score CVSS pour un fichier sensible
func (sm *SecurityManagerImpl) calculateFileCVSS(filename string) float64 {
	if strings.Contains(filename, "backup") || strings.Contains(filename, "dump") {
		return 9.0 // Très critique
	}
	if strings.Contains(filename, "private") || strings.Contains(filename, "id_rsa") {
		return 8.5 // Clés privées
	}
	if strings.Contains(filename, ".env") || strings.Contains(filename, "secret") {
		return 7.5 // Fichiers de configuration sensibles
	}
	if strings.Contains(filename, "config") {
		return 6.0 // Fichiers de configuration
	}
	return 5.0 // Autres fichiers sensibles
}

// parsePackageJsonDependencies parse les dépendances d'un package.json
func (sm *SecurityManagerImpl) parsePackageJsonDependencies(content string) map[string]string {
	dependencies := make(map[string]string)
	
	// Expression régulière simplifiée pour extraire les dépendances
	depPattern := regexp.MustCompile(`"([^"]+)":\s*"([^"]+)"`)
	matches := depPattern.FindAllStringSubmatch(content, -1)
	
	inDependencies := false
	for _, match := range matches {
		if len(match) == 3 {
			if match[1] == "dependencies" || match[1] == "devDependencies" {
				inDependencies = true
				continue
			}
			if inDependencies && !strings.Contains(match[1], "}") {
				// Nettoyer la version (supprimer ^, ~, etc.)
				version := strings.TrimPrefix(match[2], "^")
				version = strings.TrimPrefix(version, "~")
				version = strings.TrimPrefix(version, ">=")
				dependencies[match[1]] = version
			}
		}
	}
	
	return dependencies
}

// parseGoModDependencies parse les dépendances d'un go.mod
func (sm *SecurityManagerImpl) parseGoModDependencies(content string) map[string]string {
	dependencies := make(map[string]string)
	
	lines := strings.Split(content, "\n")
	inRequireBlock := false
	
	for _, line := range lines {
		line = strings.TrimSpace(line)
		
		if strings.HasPrefix(line, "require (") {
			inRequireBlock = true
			continue
		}
		
		if inRequireBlock && line == ")" {
			inRequireBlock = false
			continue
		}
		
		if strings.HasPrefix(line, "require ") || inRequireBlock {
			if line == "" || strings.HasPrefix(line, "//") {
				continue
			}
			
			parts := strings.Fields(line)
			if len(parts) >= 2 {
				name := strings.TrimPrefix(parts[0], "require ")
				version := parts[1]
				
				// Supprimer les commentaires
				if idx := strings.Index(version, "//"); idx != -1 {
					version = strings.TrimSpace(version[:idx])
				}
				
				dependencies[name] = version
			}
		}
	}
	
	return dependencies
}

// generateSecureToken génère un token sécurisé
func (sm *SecurityManagerImpl) GenerateSecureToken(length int) (string, error) {
	if !sm.isInitialized {
		return "", fmt.Errorf("security manager not initialized")
	}

	if length <= 0 {
		length = 32
	}
	bytes := make([]byte, length)
	if _, err := io.ReadFull(rand.Reader, bytes); err != nil {
		return "", fmt.Errorf("failed to generate secure token: %w", err)
	}

	// Utiliser base64 URL-safe encoding
	token := base64.URLEncoding.EncodeToString(bytes)
	
	sm.auditLog.LogEvent("TOKEN", "SECURE_TOKEN_GENERATED", "Secure token generated", map[string]interface{}{
		"length": length,
	})

	return token, nil
}

// hashData calcule le hash SHA-256 de données
func (sm *SecurityManagerImpl) HashData(data []byte) string {
	hash := sha256.Sum256(data)
	return fmt.Sprintf("%x", hash)
}

// validateIPAddress valide une adresse IP
func (sm *SecurityManagerImpl) ValidateIPAddress(ip string) bool {
	return net.ParseIP(ip) != nil
}

// isPrivateIP vérifie si une adresse IP est privée
func (sm *SecurityManagerImpl) IsPrivateIP(ip string) bool {
	parsedIP := net.ParseIP(ip)
	if parsedIP == nil {
		return false
	}

	// Plages d'adresses privées RFC 1918
	privateRanges := []string{
		"10.0.0.0/8",
		"172.16.0.0/12",
		"192.168.0.0/16",
		"127.0.0.0/8",
		"169.254.0.0/16",
		"::1/128",
		"fc00::/7",
		"fe80::/10",
	}

	for _, rangeStr := range privateRanges {
		_, cidr, err := net.ParseCIDR(rangeStr)
		if err != nil {
			continue
		}
		if cidr.Contains(parsedIP) {
			return true
		}
	}

	return false
}
