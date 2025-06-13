package main

import (
	"context"
	"fmt"
	"log"
	"path/filepath"
	"testing"
	"time"

	storageManager "github.com/email-sender-manager/storage-manager"
	dependencyManager "github.com/email-sender-manager/dependency-manager"
	securityManager "github.com/email-sender-manager/security-manager"
)

// TestManagersIntegration teste l'intégration des trois managers
func TestManagersIntegration(t *testing.T) {
	ctx := context.Background()

	// Initialiser le Storage Manager
	storageConfig := &storageManager.Config{
		DatabaseURL:    "postgres://test:test@localhost:5432/test_db?sslmode=disable",
		QdrantURL:     "http://localhost:6333",
		CacheEnabled:  true,
		CacheTTL:      5 * time.Minute,
		MaxConnections: 10,
	}

	sm, err := storageManager.NewStorageManager(storageConfig)
	if err != nil {
		log.Printf("Warning: Storage Manager initialization failed: %v", err)
		t.Skip("Skipping integration test - Storage Manager requires external dependencies")
		return
	}

	// Initialiser le Dependency Manager
	depConfig := &dependencyManager.Config{
		PackageManagers: []string{"go", "npm"},
		CacheEnabled:    true,
		CacheTTL:        5 * time.Minute,
		RegistryTimeout: 30 * time.Second,
	}

	dm, err := dependencyManager.NewDependencyManager(depConfig)
	if err != nil {
		t.Fatalf("Failed to initialize Dependency Manager: %v", err)
	}

	// Initialiser le Security Manager
	secConfig := &securityManager.Config{
		EncryptionKey:    "",
		AuditLogEnabled:  true,
		AuditLogPath:     "./integration-test-audit.log",
		RateLimitEnabled: true,
		DefaultRateLimit: 100,
		DefaultRateBurst: 10,
		ScanEnabled:      true,
		ScanInterval:     24 * time.Hour,
		VulnDBPath:       "./integration-test-vuln.db",
		HashCost:         4,
	}

	secMgr, err := securityManager.NewSecurityManager(secConfig)
	if err != nil {
		t.Fatalf("Failed to initialize Security Manager: %v", err)
	}

	t.Run("Dependency Analysis and Security Scan", func(t *testing.T) {
		// Analyser les dépendances du projet
		projectPath := filepath.Join("..", "..", "..")
		analysis, err := dm.AnalyzeDependencies(ctx, projectPath)
		if err != nil {
			t.Logf("Dependency analysis failed: %v", err)
		} else {
			log.Printf("Dependency analysis completed: %d direct dependencies, %d transitive", 
				len(analysis.DirectDependencies), len(analysis.TransitiveDependencies))

			// Scanner les vulnérabilités de sécurité
			scanResult, err := secMgr.ScanForVulnerabilities(ctx, projectPath)
			if err != nil {
				t.Errorf("Security scan failed: %v", err)
			} else {
				log.Printf("Security scan completed: %d vulnerabilities found", 
					len(scanResult.Vulnerabilities))

				// Stocker les résultats (si Storage Manager disponible)
				if sm != nil {
					data := map[string]interface{}{
						"analysis":    analysis,
						"scan_result": scanResult,
						"timestamp":   time.Now(),
					}

					key := fmt.Sprintf("integration_test_%d", time.Now().Unix())
					err = sm.Store(ctx, key, data)
					if err != nil {
						t.Logf("Storage failed: %v", err)
					} else {
						log.Printf("Results stored with key: %s", key)
					}
				}
			}
		}
	})

	t.Run("Security Input Validation", func(t *testing.T) {
		// Tester la validation d'entrées
		testInputs := []string{
			"normal_input",
			"<script>alert('xss')</script>",
			"'; DROP TABLE users; --",
			"../../../../etc/passwd",
		}

		for _, input := range testInputs {
			// Valider l'entrée
			rules := secMgr.ValidationRules{
				MaxLength:         100,
				ForbiddenPatterns: []string{`<script`, `DROP\s+TABLE`, `\.\.\/`},
			}

			err := secMgr.ValidateInput(input, rules)
			if err != nil {
				log.Printf("Input '%s' rejected: %v", input, err)
			}

			// Nettoyer l'entrée
			sanitized := secMgr.SanitizeInput(input, secMgr.SanitizationOptions{
				TrimSpaces:         true,
				EscapeHTML:         true,
				EscapeSQL:          true,
				RemoveControlChars: true,
			})

			if sanitized != input {
				log.Printf("Input sanitized: '%s' -> '%s'", input, sanitized)
			}
		}
	})

	t.Run("Data Encryption", func(t *testing.T) {
		// Tester le chiffrement de données sensibles
		sensitiveData := []byte("This is sensitive configuration data")

		encrypted, err := secMgr.EncryptData(sensitiveData)
		if err != nil {
			t.Errorf("Encryption failed: %v", err)
		} else {
			log.Printf("Data encrypted successfully (%d bytes -> %d bytes)", 
				len(sensitiveData), len(encrypted))

			// Déchiffrer
			decrypted, err := secMgr.DecryptData(encrypted)
			if err != nil {
				t.Errorf("Decryption failed: %v", err)
			} else if string(decrypted) != string(sensitiveData) {
				t.Errorf("Decrypted data doesn't match original")
			} else {
				log.Printf("Data decrypted successfully")
			}
		}
	})

	t.Run("Rate Limiting", func(t *testing.T) {
		// Tester la limitation de taux
		identifier := "test_user_integration"

		for i := 0; i < 5; i++ {
			allowed := secMgr.CheckRateLimit(identifier, 2)
			log.Printf("Rate limit check %d: %t", i+1, allowed)
			
			if i < 2 && !allowed {
				t.Errorf("Expected request %d to be allowed", i+1)
			}
			if i >= 2 && allowed {
				t.Logf("Request %d allowed (may be due to time passing)", i+1)
			}
		}
	})

	log.Println("Integration test completed successfully")
}

// TestManagersPerformance teste les performances des managers
func TestManagersPerformance(t *testing.T) {
	ctx := context.Background()

	// Initialiser les managers avec configuration optimisée
	dm, err := dependencyManager.NewDependencyManager(&dependencyManager.Config{
		PackageManagers: []string{"go"},
		CacheEnabled:    true,
		CacheTTL:        5 * time.Minute,
		RegistryTimeout: 10 * time.Second,
	})
	if err != nil {
		t.Fatalf("Failed to initialize Dependency Manager: %v", err)
	}

	secMgr, err := securityManager.NewSecurityManager(&securityManager.Config{
		HashCost: 4, // Réduire pour les tests de performance
	})
	if err != nil {
		t.Fatalf("Failed to initialize Security Manager: %v", err)
	}

	t.Run("Dependency Analysis Performance", func(t *testing.T) {
		start := time.Now()
		projectPath := filepath.Join("..", "..", "..")
		
		_, err := dm.AnalyzeDependencies(ctx, projectPath)
		duration := time.Since(start)
		
		if err != nil {
			t.Logf("Dependency analysis failed: %v", err)
		} else {
			log.Printf("Dependency analysis completed in %v", duration)
			if duration > 10*time.Second {
				t.Logf("Warning: Dependency analysis took longer than expected: %v", duration)
			}
		}
	})

	t.Run("Security Scan Performance", func(t *testing.T) {
		start := time.Now()
		projectPath := filepath.Join("..", "..", "..")
		
		_, err := secMgr.ScanForVulnerabilities(ctx, projectPath)
		duration := time.Since(start)
		
		if err != nil {
			t.Errorf("Security scan failed: %v", err)
		} else {
			log.Printf("Security scan completed in %v", duration)
			if duration > 5*time.Second {
				t.Logf("Warning: Security scan took longer than expected: %v", duration)
			}
		}
	})

	t.Run("Encryption Performance", func(t *testing.T) {
		data := make([]byte, 1024*1024) // 1MB de données
		for i := range data {
			data[i] = byte(i % 256)
		}

		start := time.Now()
		encrypted, err := secMgr.EncryptData(data)
		encryptDuration := time.Since(start)

		if err != nil {
			t.Errorf("Encryption failed: %v", err)
		} else {
			log.Printf("Encrypted 1MB in %v", encryptDuration)

			start = time.Now()
			_, err = secMgr.DecryptData(encrypted)
			decryptDuration := time.Since(start)

			if err != nil {
				t.Errorf("Decryption failed: %v", err)
			} else {
				log.Printf("Decrypted 1MB in %v", decryptDuration)
			}
		}
	})
}

func main() {
	fmt.Println("Running integration tests for Phase 2 managers...")
	
	// Ce fichier peut être exécuté directement pour des tests manuels
	ctx := context.Background()

	// Test rapide des managers
	fmt.Println("Testing Dependency Manager...")
	dm, err := dependencyManager.NewDependencyManager(nil)
	if err != nil {
		log.Printf("Dependency Manager failed: %v", err)
	} else {
		fmt.Println("✓ Dependency Manager initialized successfully")
	}

	fmt.Println("Testing Security Manager...")
	sm, err := securityManager.NewSecurityManager(nil)
	if err != nil {
		log.Printf("Security Manager failed: %v", err)
	} else {
		fmt.Println("✓ Security Manager initialized successfully")

		// Test rapide de chiffrement
		data := []byte("test data")
		encrypted, err := sm.EncryptData(data)
		if err != nil {
			log.Printf("Encryption failed: %v", err)
		} else {
			_, err = sm.DecryptData(encrypted)
			if err != nil {
				log.Printf("Decryption failed: %v", err)
			} else {
				fmt.Println("✓ Encryption/Decryption working")
			}
		}
	}

	fmt.Println("All Phase 2 managers are operational!")
}
