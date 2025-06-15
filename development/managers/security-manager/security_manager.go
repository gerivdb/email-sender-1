package security

import (
	"context"
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"fmt"
	"io"
	"log"
	"regexp"
	"strings"
	"sync"
	"time"

	"github.com/email-sender-manager/interfaces"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
	"golang.org/x/time/rate"
	"go.uber.org/zap"
)

// SecurityManagerImpl implémente l'interface SecurityManager
type SecurityManagerImpl struct {
	config          *Config
	logger          *zap.Logger
	auditLog        *AuditLogger
	encryptionKey   []byte
	rateLimiters    map[string]*rate.Limiter
	rateLimitersMu  sync.RWMutex
	isInitialized   bool
	scanResults     map[string]*interfaces.SecurityScanResult
	scanResultsMu   sync.RWMutex

	// Phase 4.2.2: Ajout des capacités de vectorisation pour la sécurité
	vectorizer              VectorizationEngine       // Moteur de vectorisation
	qdrant                 QdrantInterface           // Interface Qdrant pour stockage vectoriel
	policyVectorizer       *PolicyVectorizer         // Vectoriseur de politiques de sécurité
	anomalyDetector        *AnomalyDetector          // Détecteur d'anomalies basé sur embeddings
	vulnerabilityClassifier *VulnerabilityClassifier // Classificateur automatique de vulnérabilités
	vectorizationEnabled   bool                      // Flag d'activation de la vectorisation
}

// Config pour le Security Manager
type Config struct {
	EncryptionKey      string        `json:"encryption_key"`
	AuditLogEnabled    bool          `json:"audit_log_enabled"`
	AuditLogPath       string        `json:"audit_log_path"`
	RateLimitEnabled   bool          `json:"rate_limit_enabled"`
	DefaultRateLimit   int           `json:"default_rate_limit"`
	DefaultRateBurst   int           `json:"default_rate_burst"`
	ScanEnabled        bool          `json:"scan_enabled"`
	ScanInterval       time.Duration `json:"scan_interval"`
	VulnDBPath         string        `json:"vuln_db_path"`
	HashCost           int           `json:"hash_cost"`
}

// AuditLogger gère les logs d'audit
type AuditLogger struct {
	enabled bool
	logger  *zap.Logger
	path    string
	mu      sync.Mutex
}

// NewSecurityManager crée une nouvelle instance du Security Manager
func NewSecurityManager(config *Config) (*SecurityManagerImpl, error) {
	if config == nil {
		config = getDefaultConfig()
	}

	// Initialiser le logger
	logger, err := zap.NewProduction()
	if err != nil {
		return nil, fmt.Errorf("failed to create logger: %w", err)
	}

	// Initialiser l'audit logger
	auditLogger, err := NewAuditLogger(config.AuditLogEnabled, config.AuditLogPath)
	if err != nil {
		return nil, fmt.Errorf("failed to create audit logger: %w", err)
	}

	// Générer ou utiliser la clé de chiffrement
	encryptionKey, err := getOrGenerateEncryptionKey(config.EncryptionKey)
	if err != nil {
		return nil, fmt.Errorf("failed to setup encryption key: %w", err)
	}

	sm := &SecurityManagerImpl{
		config:          config,
		logger:          logger,
		auditLog:        auditLogger,
		encryptionKey:   encryptionKey,
		rateLimiters:    make(map[string]*rate.Limiter),
		rateLimitersMu:  sync.RWMutex{},
		isInitialized:   true,
		scanResults:     make(map[string]*interfaces.SecurityScanResult),
		scanResultsMu:   sync.RWMutex{},
	}

	sm.logger.Info("Security Manager initialized successfully")
	sm.auditLog.LogEvent("SYSTEM", "SECURITY_MANAGER_INITIALIZED", "Security Manager started", nil)

	return sm, nil
}

// GetDefaultConfig retourne la configuration par défaut
func getDefaultConfig() *Config {
	return &Config{
		EncryptionKey:    "",
		AuditLogEnabled:  true,
		AuditLogPath:     "./security-audit.log",
		RateLimitEnabled: true,
		DefaultRateLimit: 100,
		DefaultRateBurst: 10,
		ScanEnabled:      true,
		ScanInterval:     24 * time.Hour,
		VulnDBPath:       "./vuln.db",
		HashCost:         bcrypt.DefaultCost,
	}
}

// NewAuditLogger crée un nouveau logger d'audit
func NewAuditLogger(enabled bool, path string) (*AuditLogger, error) {
	if !enabled {
		return &AuditLogger{enabled: false}, nil
	}

	config := zap.NewProductionConfig()
	config.OutputPaths = []string{path}
	
	logger, err := config.Build()
	if err != nil {
		return nil, fmt.Errorf("failed to create audit logger: %w", err)
	}

	return &AuditLogger{
		enabled: true,
		logger:  logger,
		path:    path,
	}, nil
}

// getOrGenerateEncryptionKey génère ou utilise une clé de chiffrement
func getOrGenerateEncryptionKey(keyStr string) ([]byte, error) {
	if keyStr != "" {
		// Utiliser la clé fournie
		if len(keyStr) != 64 { // 32 bytes en hex
			return nil, fmt.Errorf("encryption key must be 32 bytes (64 hex characters)")
		}
		return hex.DecodeString(keyStr)
	}

	// Générer une nouvelle clé
	key := make([]byte, 32)
	if _, err := rand.Read(key); err != nil {
		return nil, fmt.Errorf("failed to generate encryption key: %w", err)
	}

	log.Printf("Generated new encryption key: %s", hex.EncodeToString(key))
	return key, nil
}

// Interface compliance methods

// ValidateInput valide une entrée utilisateur
func (sm *SecurityManagerImpl) ValidateInput(input string, rules interfaces.ValidationRules) error {
	if !sm.isInitialized {
		return fmt.Errorf("security manager not initialized")
	}

	sm.auditLog.LogEvent("VALIDATION", "INPUT_VALIDATION", "Validating user input", map[string]interface{}{
		"input_length": len(input),
		"rules":        rules,
	})

	// Vérifier la longueur
	if rules.MaxLength > 0 && len(input) > rules.MaxLength {
		return fmt.Errorf("input exceeds maximum length of %d characters", rules.MaxLength)
	}

	if rules.MinLength > 0 && len(input) < rules.MinLength {
		return fmt.Errorf("input is below minimum length of %d characters", rules.MinLength)
	}

	// Vérifier les caractères autorisés
	if rules.AllowedChars != "" {
		allowedPattern := fmt.Sprintf("^[%s]*$", regexp.QuoteMeta(rules.AllowedChars))
		matched, err := regexp.MatchString(allowedPattern, input)
		if err != nil {
			return fmt.Errorf("failed to validate allowed characters: %w", err)
		}
		if !matched {
			return fmt.Errorf("input contains forbidden characters")
		}
	}

	// Vérifier les caractères interdits
	if rules.ForbiddenChars != "" {
		forbiddenPattern := fmt.Sprintf("[%s]", regexp.QuoteMeta(rules.ForbiddenChars))
		matched, err := regexp.MatchString(forbiddenPattern, input)
		if err != nil {
			return fmt.Errorf("failed to validate forbidden characters: %w", err)
		}
		if matched {
			return fmt.Errorf("input contains forbidden characters")
		}
	}

	// Vérifier les patterns requis
	for _, pattern := range rules.RequiredPatterns {
		matched, err := regexp.MatchString(pattern, input)
		if err != nil {
			return fmt.Errorf("failed to validate required pattern %s: %w", pattern, err)
		}
		if !matched {
			return fmt.Errorf("input does not match required pattern: %s", pattern)
		}
	}

	// Vérifier les patterns interdits
	for _, pattern := range rules.ForbiddenPatterns {
		matched, err := regexp.MatchString(pattern, input)
		if err != nil {
			return fmt.Errorf("failed to validate forbidden pattern %s: %w", pattern, err)
		}
		if matched {
			return fmt.Errorf("input matches forbidden pattern: %s", pattern)
		}
	}

	sm.logger.Debug("Input validation successful", zap.Int("input_length", len(input)))
	return nil
}

// SanitizeInput nettoie une entrée utilisateur
func (sm *SecurityManagerImpl) SanitizeInput(input string, options interfaces.SanitizationOptions) string {
	if !sm.isInitialized {
		sm.logger.Error("Security manager not initialized")
		return input
	}

	sanitized := input

	// Supprimer les espaces en début et fin
	if options.TrimSpaces {
		sanitized = strings.TrimSpace(sanitized)
	}

	// Supprimer les caractères de contrôle
	if options.RemoveControlChars {
		controlCharsPattern := `[\x00-\x1F\x7F]`
		re := regexp.MustCompile(controlCharsPattern)
		sanitized = re.ReplaceAllString(sanitized, "")
	}

	// Échapper les caractères HTML
	if options.EscapeHTML {
		sanitized = strings.ReplaceAll(sanitized, "<", "&lt;")
		sanitized = strings.ReplaceAll(sanitized, ">", "&gt;")
		sanitized = strings.ReplaceAll(sanitized, "&", "&amp;")
		sanitized = strings.ReplaceAll(sanitized, "\"", "&quot;")
		sanitized = strings.ReplaceAll(sanitized, "'", "&#39;")
	}

	// Échapper les caractères SQL
	if options.EscapeSQL {
		sanitized = strings.ReplaceAll(sanitized, "'", "''")
		sanitized = strings.ReplaceAll(sanitized, "\\", "\\\\")
	}

	// Supprimer les caractères personnalisés
	for _, char := range options.RemoveChars {
		sanitized = strings.ReplaceAll(sanitized, char, "")
	}

	sm.auditLog.LogEvent("SANITIZATION", "INPUT_SANITIZED", "Input sanitized", map[string]interface{}{
		"original_length":  len(input),
		"sanitized_length": len(sanitized),
		"options":          options,
	})

	return sanitized
}

// EncryptData chiffre des données
func (sm *SecurityManagerImpl) EncryptData(data []byte) ([]byte, error) {
	if !sm.isInitialized {
		return nil, fmt.Errorf("security manager not initialized")
	}

	block, err := aes.NewCipher(sm.encryptionKey)
	if err != nil {
		return nil, fmt.Errorf("failed to create cipher: %w", err)
	}

	// Créer un GCM
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return nil, fmt.Errorf("failed to create GCM: %w", err)
	}

	// Générer un nonce
	nonce := make([]byte, gcm.NonceSize())
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		return nil, fmt.Errorf("failed to generate nonce: %w", err)
	}

	// Chiffrer les données
	ciphertext := gcm.Seal(nonce, nonce, data, nil)

	sm.auditLog.LogEvent("ENCRYPTION", "DATA_ENCRYPTED", "Data encrypted", map[string]interface{}{
		"data_size": len(data),
	})

	return ciphertext, nil
}

// DecryptData déchiffre des données
func (sm *SecurityManagerImpl) DecryptData(encryptedData []byte) ([]byte, error) {
	if !sm.isInitialized {
		return nil, fmt.Errorf("security manager not initialized")
	}

	block, err := aes.NewCipher(sm.encryptionKey)
	if err != nil {
		return nil, fmt.Errorf("failed to create cipher: %w", err)
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return nil, fmt.Errorf("failed to create GCM: %w", err)
	}

	nonceSize := gcm.NonceSize()
	if len(encryptedData) < nonceSize {
		return nil, fmt.Errorf("encrypted data is too short")
	}

	nonce, ciphertext := encryptedData[:nonceSize], encryptedData[nonceSize:]
	plaintext, err := gcm.Open(nil, nonce, ciphertext, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to decrypt data: %w", err)
	}

	sm.auditLog.LogEvent("DECRYPTION", "DATA_DECRYPTED", "Data decrypted", map[string]interface{}{
		"data_size": len(plaintext),
	})

	return plaintext, nil
}

// HashPassword hash un mot de passe
func (sm *SecurityManagerImpl) HashPassword(password string) (string, error) {
	if !sm.isInitialized {
		return "", fmt.Errorf("security manager not initialized")
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(password), sm.config.HashCost)
	if err != nil {
		return "", fmt.Errorf("failed to hash password: %w", err)
	}

	sm.auditLog.LogEvent("AUTHENTICATION", "PASSWORD_HASHED", "Password hashed", map[string]interface{}{
		"hash_cost": sm.config.HashCost,
	})

	return string(hash), nil
}

// VerifyPassword vérifie un mot de passe
func (sm *SecurityManagerImpl) VerifyPassword(password, hash string) bool {
	if !sm.isInitialized {
		sm.logger.Error("Security manager not initialized")
		return false
	}

	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	
	sm.auditLog.LogEvent("AUTHENTICATION", "PASSWORD_VERIFIED", "Password verification attempt", map[string]interface{}{
		"success": err == nil,
	})

	return err == nil
}

// LogEvent enregistre un événement de sécurité
func (sm *SecurityManagerImpl) LogEvent(event interfaces.SecurityEvent) error {
	if !sm.isInitialized {
		return fmt.Errorf("security manager not initialized")
	}

	return sm.auditLog.LogSecurityEvent(event)
}

// CheckRateLimit vérifie la limite de taux
func (sm *SecurityManagerImpl) CheckRateLimit(identifier string, limit int) bool {
	if !sm.isInitialized || !sm.config.RateLimitEnabled {
		return true
	}

	sm.rateLimitersMu.Lock()
	defer sm.rateLimitersMu.Unlock()

	limiter, exists := sm.rateLimiters[identifier]
	if !exists {
		burst := sm.config.DefaultRateBurst
		if limit < burst {
			burst = limit
		}
		limiter = rate.NewLimiter(rate.Limit(limit), burst)
		sm.rateLimiters[identifier] = limiter
	}

	allowed := limiter.Allow()
	
	sm.auditLog.LogEvent("RATE_LIMIT", "RATE_LIMIT_CHECK", "Rate limit check", map[string]interface{}{
		"identifier": identifier,
		"limit":      limit,
		"allowed":    allowed,
	})

	return allowed
}

// ScanForVulnerabilities scanne les vulnérabilités
func (sm *SecurityManagerImpl) ScanForVulnerabilities(ctx context.Context, target string) (*interfaces.SecurityScanResult, error) {
	if !sm.isInitialized {
		return nil, fmt.Errorf("security manager not initialized")
	}

	sm.logger.Info("Starting vulnerability scan", zap.String("target", target))
	
	startTime := time.Now()
	scanID := uuid.New().String()

	result := &interfaces.SecurityScanResult{
		ScanID:         scanID,
		Target:         target,
		StartTime:      startTime,
		EndTime:        time.Time{},
		Status:         "running",
		Vulnerabilities: []interfaces.Vulnerability{},
		Summary:        interfaces.ScanSummary{},
	}

	// Stocker le résultat en cours
	sm.scanResultsMu.Lock()
	sm.scanResults[scanID] = result
	sm.scanResultsMu.Unlock()

	// Simuler un scan (dans un vrai environnement, ceci ferait appel à des outils de scan)
	vulnerabilities := sm.performVulnerabilityScan(ctx, target)
	
	// Mettre à jour le résultat
	result.EndTime = time.Now()
	result.Status = "completed"
	result.Vulnerabilities = vulnerabilities
	result.Summary = sm.generateScanSummary(vulnerabilities)

	sm.auditLog.LogEvent("SECURITY_SCAN", "VULNERABILITY_SCAN_COMPLETED", "Vulnerability scan completed", map[string]interface{}{
		"scan_id":              scanID,
		"target":               target,
		"vulnerabilities_found": len(vulnerabilities),
		"duration":             result.EndTime.Sub(result.StartTime).String(),
	})

	sm.logger.Info("Vulnerability scan completed", 
		zap.String("scan_id", scanID),
		zap.String("target", target),
		zap.Int("vulnerabilities", len(vulnerabilities)),
		zap.Duration("duration", result.EndTime.Sub(result.StartTime)))

	return result, nil
}

// GetScanResult récupère le résultat d'un scan
func (sm *SecurityManagerImpl) GetScanResult(scanID string) (*interfaces.SecurityScanResult, error) {
	if !sm.isInitialized {
		return nil, fmt.Errorf("security manager not initialized")
	}

	sm.scanResultsMu.RLock()
	defer sm.scanResultsMu.RUnlock()

	result, exists := sm.scanResults[scanID]
	if !exists {
		return nil, fmt.Errorf("scan result not found for ID: %s", scanID)
	}

	return result, nil
}

// LogEvent sur l'AuditLogger
func (al *AuditLogger) LogEvent(category, action, description string, metadata map[string]interface{}) error {
	if !al.enabled {
		return nil
	}

	al.mu.Lock()
	defer al.mu.Unlock()

	al.logger.Info("AUDIT",
		zap.String("category", category),
		zap.String("action", action),
		zap.String("description", description),
		zap.Any("metadata", metadata),
		zap.Time("timestamp", time.Now()),
	)

	return nil
}

// LogSecurityEvent enregistre un événement de sécurité
func (al *AuditLogger) LogSecurityEvent(event interfaces.SecurityEvent) error {
	if !al.enabled {
		return nil
	}

	al.mu.Lock()
	defer al.mu.Unlock()

	al.logger.Info("SECURITY_EVENT",
		zap.String("event_id", event.ID),
		zap.String("event_type", event.Type),
		zap.String("user_id", event.UserID),
		zap.String("action", event.Action),
		zap.String("resource", event.Resource),
		zap.String("ip_address", event.IPAddress),
		zap.String("user_agent", event.UserAgent),
		zap.Bool("success", event.Success),
		zap.String("error_message", event.ErrorMessage),
		zap.Any("metadata", event.Metadata),
		zap.Time("timestamp", event.Timestamp),
	)

	return nil
}
