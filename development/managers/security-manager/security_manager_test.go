package security

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/email-sender-manager/interfaces"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestSecurityManager_Implementation(t *testing.T) {
	// Test que SecurityManagerImpl implémente l'interface SecurityManager
	var _ interfaces.SecurityManager = (*SecurityManagerImpl)(nil)
}

func TestNewSecurityManager(t *testing.T) {
	config := &Config{
		EncryptionKey:    "",
		AuditLogEnabled:  true,
		AuditLogPath:     "./test-audit.log",
		RateLimitEnabled: true,
		DefaultRateLimit: 100,
		DefaultRateBurst: 10,
		ScanEnabled:      true,
		ScanInterval:     24 * time.Hour,
		VulnDBPath:       "./test-vuln.db",
		HashCost:         4, // Réduire pour les tests
	}

	sm, err := NewSecurityManager(config)
	require.NoError(t, err)
	require.NotNil(t, sm)
	assert.True(t, sm.isInitialized)

	// Cleanup
	defer func() {
		if _, err := os.Stat(config.AuditLogPath); err == nil {
			os.Remove(config.AuditLogPath)
		}
	}()
}

func TestSecurityManager_ValidateInput(t *testing.T) {
	sm, err := NewSecurityManager(nil)
	require.NoError(t, err)

	tests := []struct {
		name     string
		input    string
		rules    interfaces.ValidationRules
		wantErr  bool
		errMsg   string
	}{
		{
			name:  "Valid input - basic",
			input: "hello world",
			rules: interfaces.ValidationRules{
				MinLength: 5,
				MaxLength: 20,
			},
			wantErr: false,
		},
		{
			name:  "Invalid input - too short",
			input: "hi",
			rules: interfaces.ValidationRules{
				MinLength: 5,
				MaxLength: 20,
			},
			wantErr: true,
			errMsg:  "minimum length",
		},
		{
			name:  "Invalid input - too long",
			input: "this is a very long string that exceeds the maximum length",
			rules: interfaces.ValidationRules{
				MinLength: 5,
				MaxLength: 20,
			},
			wantErr: true,
			errMsg:  "maximum length",
		},
		{
			name:  "Valid input - allowed chars",
			input: "abc123",
			rules: interfaces.ValidationRules{
				AllowedChars: "abcdefghijklmnopqrstuvwxyz0123456789",
			},
			wantErr: false,
		},
		{
			name:  "Invalid input - forbidden chars",
			input: "abc@123",
			rules: interfaces.ValidationRules{
				ForbiddenChars: "@#$%",
			},
			wantErr: true,
			errMsg:  "forbidden characters",
		},
		{
			name:  "Valid input - required pattern",
			input: "test@example.com",
			rules: interfaces.ValidationRules{
				RequiredPatterns: []string{`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`},
			},
			wantErr: false,
		},
		{
			name:  "Invalid input - forbidden pattern",
			input: "DROP TABLE users;",
			rules: interfaces.ValidationRules{
				ForbiddenPatterns: []string{`(?i)(DROP|DELETE|INSERT|UPDATE|SELECT).*(TABLE|FROM|INTO)`},
			},
			wantErr: true,
			errMsg:  "forbidden pattern",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := sm.ValidateInput(tt.input, tt.rules)
			if tt.wantErr {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.errMsg)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestSecurityManager_SanitizeInput(t *testing.T) {
	sm, err := NewSecurityManager(nil)
	require.NoError(t, err)

	tests := []struct {
		name     string
		input    string
		options  interfaces.SanitizationOptions
		expected string
	}{
		{
			name:    "Trim spaces",
			input:   "  hello world  ",
			options: interfaces.SanitizationOptions{TrimSpaces: true},
			expected: "hello world",
		},
		{
			name:    "Remove control chars",
			input:   "hello\x00\x1F\x7Fworld",
			options: interfaces.SanitizationOptions{RemoveControlChars: true},
			expected: "helloworld",
		},
		{
			name:    "Escape HTML",
			input:   "<script>alert('xss')</script>",
			options: interfaces.SanitizationOptions{EscapeHTML: true},
			expected: "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;",
		},
		{
			name:    "Escape SQL",
			input:   "Robert'; DROP TABLE users; --",
			options: interfaces.SanitizationOptions{EscapeSQL: true},
			expected: "Robert''; DROP TABLE users; --",
		},
		{
			name:    "Remove custom chars",
			input:   "hello@#$world",
			options: interfaces.SanitizationOptions{RemoveChars: []string{"@", "#", "$"}},
			expected: "helloworld",
		},
		{
			name:  "Combined sanitization",
			input: "  <script>alert('test')</script>  ",
			options: interfaces.SanitizationOptions{
				TrimSpaces: true,
				EscapeHTML: true,
			},
			expected: "&lt;script&gt;alert(&#39;test&#39;)&lt;/script&gt;",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := sm.SanitizeInput(tt.input, tt.options)
			assert.Equal(t, tt.expected, result)
		})
	}
}

func TestSecurityManager_Encryption(t *testing.T) {
	sm, err := NewSecurityManager(nil)
	require.NoError(t, err)

	originalData := []byte("This is a secret message that needs to be encrypted")

	// Test encryption
	encryptedData, err := sm.EncryptData(originalData)
	require.NoError(t, err)
	assert.NotEqual(t, originalData, encryptedData)
	assert.Greater(t, len(encryptedData), len(originalData))

	// Test decryption
	decryptedData, err := sm.DecryptData(encryptedData)
	require.NoError(t, err)
	assert.Equal(t, originalData, decryptedData)

	// Test invalid encrypted data
	invalidData := []byte("invalid encrypted data")
	_, err = sm.DecryptData(invalidData)
	assert.Error(t, err)
}

func TestSecurityManager_PasswordHashing(t *testing.T) {
	sm, err := NewSecurityManager(&Config{HashCost: 4}) // Réduire pour les tests
	require.NoError(t, err)

	password := "mySecretPassword123!"

	// Test password hashing
	hash, err := sm.HashPassword(password)
	require.NoError(t, err)
	assert.NotEmpty(t, hash)
	assert.NotEqual(t, password, hash)
	assert.True(t, strings.HasPrefix(hash, "$2a$04$")) // bcrypt avec cost 4

	// Test password verification - correct password
	isValid := sm.VerifyPassword(password, hash)
	assert.True(t, isValid)

	// Test password verification - incorrect password
	isValid = sm.VerifyPassword("wrongPassword", hash)
	assert.False(t, isValid)

	// Test password verification - invalid hash
	isValid = sm.VerifyPassword(password, "invalid hash")
	assert.False(t, isValid)
}

func TestSecurityManager_LogEvent(t *testing.T) {
	tmpDir := t.TempDir()
	auditLogPath := filepath.Join(tmpDir, "audit.log")

	config := &Config{
		AuditLogEnabled: true,
		AuditLogPath:    auditLogPath,
	}

	sm, err := NewSecurityManager(config)
	require.NoError(t, err)

	event := interfaces.SecurityEvent{
		ID:           "test-event-1",
		Type:         "authentication",
		UserID:       "user123",
		Action:       "login",
		Resource:     "/api/login",
		IPAddress:    "192.168.1.100",
		UserAgent:    "Mozilla/5.0",
		Success:      true,
		ErrorMessage: "",
		Metadata: map[string]interface{}{
			"method": "POST",
		},
		Timestamp: time.Now(),
	}

	err = sm.LogEvent(event)
	assert.NoError(t, err)

	// Vérifier que le fichier de log existe
	_, err = os.Stat(auditLogPath)
	assert.NoError(t, err)
}

func TestSecurityManager_RateLimit(t *testing.T) {
	config := &Config{
		RateLimitEnabled: true,
		DefaultRateLimit: 2,  // 2 requêtes par seconde
		DefaultRateBurst: 1,  // Burst de 1
	}

	sm, err := NewSecurityManager(config)
	require.NoError(t, err)

	identifier := "test-user"

	// Première requête - doit passer
	allowed := sm.CheckRateLimit(identifier, 2)
	assert.True(t, allowed)

	// Deuxième requête immédiate - doit passer (burst)
	allowed = sm.CheckRateLimit(identifier, 2)
	assert.True(t, allowed)

	// Troisième requête immédiate - doit être bloquée
	allowed = sm.CheckRateLimit(identifier, 2)
	assert.False(t, allowed)

	// Test avec rate limiting désactivé
	sm.config.RateLimitEnabled = false
	allowed = sm.CheckRateLimit(identifier, 2)
	assert.True(t, allowed)
}

func TestSecurityManager_VulnerabilityScanning(t *testing.T) {
	sm, err := NewSecurityManager(nil)
	require.NoError(t, err)

	// Créer un répertoire temporaire pour les tests
	tmpDir := t.TempDir()

	// Créer un fichier package.json avec des vulnérabilités connues
	packageJson := `{
  "name": "test-project",
  "dependencies": {
    "express": "4.16.0",
    "lodash": "4.17.20"
  }
}`
	packageJsonPath := filepath.Join(tmpDir, "package.json")
	err = os.WriteFile(packageJsonPath, []byte(packageJson), 0644)
	require.NoError(t, err)

	// Créer un fichier .env sensible
	envPath := filepath.Join(tmpDir, ".env")
	err = os.WriteFile(envPath, []byte("SECRET_KEY=mysecret"), 0644)
	require.NoError(t, err)

	ctx := context.Background()
	result, err := sm.ScanForVulnerabilities(ctx, tmpDir)
	require.NoError(t, err)
	require.NotNil(t, result)

	assert.NotEmpty(t, result.ScanID)
	assert.Equal(t, tmpDir, result.Target)
	assert.Equal(t, "completed", result.Status)
	assert.True(t, result.EndTime.After(result.StartTime))

	// Vérifier qu'on a trouvé des vulnérabilités
	assert.Greater(t, len(result.Vulnerabilities), 0)

	// Vérifier le résumé
	assert.Equal(t, len(result.Vulnerabilities), result.Summary.TotalIssues)
	assert.Greater(t, result.Summary.RiskScore, 0.0)

	// Test de récupération du résultat
	retrievedResult, err := sm.GetScanResult(result.ScanID)
	require.NoError(t, err)
	assert.Equal(t, result.ScanID, retrievedResult.ScanID)

	// Test de récupération d'un résultat inexistant
	_, err = sm.GetScanResult("non-existent-id")
	assert.Error(t, err)
}

func TestSecurityManager_HelperMethods(t *testing.T) {
	sm, err := NewSecurityManager(nil)
	require.NoError(t, err)

	t.Run("Generate Secure Token", func(t *testing.T) {
		token, err := sm.GenerateSecureToken(32)
		require.NoError(t, err)
		assert.NotEmpty(t, token)
		assert.Greater(t, len(token), 32) // Base64 encoded sera plus long

		// Test avec longueur différente
		shortToken, err := sm.GenerateSecureToken(16)
		require.NoError(t, err)
		assert.NotEqual(t, token, shortToken)
	})

	t.Run("Hash Data", func(t *testing.T) {
		data := []byte("test data to hash")
		hash := sm.HashData(data)
		assert.NotEmpty(t, hash)
		assert.Equal(t, 64, len(hash)) // SHA-256 en hex = 64 caractères

		// Same data should produce same hash
		hash2 := sm.HashData(data)
		assert.Equal(t, hash, hash2)

		// Different data should produce different hash
		differentData := []byte("different test data")
		differentHash := sm.HashData(differentData)
		assert.NotEqual(t, hash, differentHash)
	})

	t.Run("Validate IP Address", func(t *testing.T) {
		tests := []struct {
			ip    string
			valid bool
		}{
			{"192.168.1.1", true},
			{"10.0.0.1", true},
			{"127.0.0.1", true},
			{"::1", true},
			{"2001:db8::1", true},
			{"invalid-ip", false},
			{"256.256.256.256", false},
			{"", false},
		}

		for _, test := range tests {
			result := sm.ValidateIPAddress(test.ip)
			assert.Equal(t, test.valid, result, "IP: %s", test.ip)
		}
	})

	t.Run("Is Private IP", func(t *testing.T) {
		tests := []struct {
			ip      string
			private bool
		}{
			{"192.168.1.1", true},
			{"10.0.0.1", true},
			{"172.16.0.1", true},
			{"127.0.0.1", true},
			{"169.254.1.1", true},
			{"8.8.8.8", false},
			{"1.1.1.1", false},
			{"invalid-ip", false},
		}

		for _, test := range tests {
			result := sm.IsPrivateIP(test.ip)
			assert.Equal(t, test.private, result, "IP: %s", test.ip)
		}
	})
}

func TestSecurityManager_ConfigurationScanning(t *testing.T) {
	sm, err := NewSecurityManager(nil)
	require.NoError(t, err)

	tmpDir := t.TempDir()

	// Créer un fichier nginx.conf avec des problèmes de sécurité
	nginxConf := `
server {
    server_tokens on;
    ssl_protocols TLSv1.0 TLSv1.1 TLSv1.2;
    listen 80;
}
`
	nginxPath := filepath.Join(tmpDir, "nginx.conf")
	err = os.WriteFile(nginxPath, []byte(nginxConf), 0644)
	require.NoError(t, err)

	vulns := sm.scanConfigurations(tmpDir)
	assert.Greater(t, len(vulns), 0)

	// Vérifier qu'on a détecté les problèmes de configuration
	found := false
	for _, vuln := range vulns {
		if strings.Contains(vuln.Description, "nginx.conf") {
			found = true
			break
		}
	}
	assert.True(t, found, "Should detect nginx configuration issues")
}

func TestSecurityManager_DependencyParsing(t *testing.T) {
	sm, err := NewSecurityManager(nil)
	require.NoError(t, err)

	t.Run("Parse package.json dependencies", func(t *testing.T) {
		packageJson := `{
  "dependencies": {
    "express": "^4.16.0",
    "lodash": "~4.17.20",
    "jquery": ">=3.4.1"
  },
  "devDependencies": {
    "jest": "^29.0.0"
  }
}`
		deps := sm.parsePackageJsonDependencies(packageJson)
		assert.Contains(t, deps, "express")
		assert.Contains(t, deps, "lodash")
		assert.Contains(t, deps, "jquery")
		assert.Contains(t, deps, "jest")

		// Vérifier que les préfixes de version sont supprimés
		assert.Equal(t, "4.16.0", deps["express"])
		assert.Equal(t, "4.17.20", deps["lodash"])
		assert.Equal(t, "3.4.1", deps["jquery"])
	})

	t.Run("Parse go.mod dependencies", func(t *testing.T) {
		goMod := `module test-project

go 1.21

require (
	github.com/gorilla/mux v1.8.0
	github.com/lib/pq v1.10.9 // indirect
)

require github.com/stretchr/testify v1.8.4
`
		deps := sm.parseGoModDependencies(goMod)
		assert.Contains(t, deps, "github.com/gorilla/mux")
		assert.Contains(t, deps, "github.com/lib/pq")
		assert.Contains(t, deps, "github.com/stretchr/testify")

		assert.Equal(t, "v1.8.0", deps["github.com/gorilla/mux"])
		assert.Equal(t, "v1.10.9", deps["github.com/lib/pq"])
		assert.Equal(t, "v1.8.4", deps["github.com/stretchr/testify"])
	})
}

// Benchmark tests
func BenchmarkSecurityManager_Encryption(b *testing.B) {
	sm, err := NewSecurityManager(nil)
	if err != nil {
		b.Fatalf("Failed to create security manager: %v", err)
	}

	data := []byte("This is test data for encryption benchmarking that should be reasonably long to get meaningful results")

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		encrypted, err := sm.EncryptData(data)
		if err != nil {
			b.Fatalf("Encryption failed: %v", err)
		}
		_, err = sm.DecryptData(encrypted)
		if err != nil {
			b.Fatalf("Decryption failed: %v", err)
		}
	}
}

func BenchmarkSecurityManager_PasswordHashing(b *testing.B) {
	sm, err := NewSecurityManager(&Config{HashCost: 4})
	if err != nil {
		b.Fatalf("Failed to create security manager: %v", err)
	}

	password := "testPassword123!"

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := sm.HashPassword(password)
		if err != nil {
			b.Fatalf("Password hashing failed: %v", err)
		}
	}
}

func BenchmarkSecurityManager_VulnerabilityScanning(b *testing.B) {
	sm, err := NewSecurityManager(nil)
	if err != nil {
		b.Fatalf("Failed to create security manager: %v", err)
	}

	tmpDir := b.TempDir()
	
	// Créer quelques fichiers de test
	packageJson := `{"dependencies": {"express": "4.16.0", "lodash": "4.17.20"}}`
	os.WriteFile(filepath.Join(tmpDir, "package.json"), []byte(packageJson), 0644)
	os.WriteFile(filepath.Join(tmpDir, ".env"), []byte("SECRET=test"), 0644)

	ctx := context.Background()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := sm.ScanForVulnerabilities(ctx, tmpDir)
		if err != nil {
			b.Fatalf("Vulnerability scanning failed: %v", err)
		}
	}
}
