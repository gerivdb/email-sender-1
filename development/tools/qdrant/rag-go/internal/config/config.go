package config

import (
	"errors"
	"os"
	"strconv"
	"time"
)

// Provider représente les différents fournisseurs d'embeddings supportés
type Provider string

const (
	// ProviderSimulation pour des tests sans API externe
	ProviderSimulation Provider = "simulation"
	// ProviderOpenAI pour utiliser l'API OpenAI
	ProviderOpenAI Provider = "openai"
	// ProviderHuggingFace pour utiliser l'API HuggingFace
	ProviderHuggingFace Provider = "huggingface"
)

// LogLevel définit les niveaux de log disponibles
type LogLevel string

const (
	// LogLevelDebug pour les logs détaillés (développement)
	LogLevelDebug LogLevel = "DEBUG"
	// LogLevelInfo pour les informations générales (par défaut)
	LogLevelInfo LogLevel = "INFO"
	// LogLevelWarn pour les avertissements
	LogLevelWarn LogLevel = "WARN"
	// LogLevelError pour les erreurs
	LogLevelError LogLevel = "ERROR"
)

// Config contient toutes les configurations pour l'application RAG
type Config struct {
	// Configuration QDrant
	QdrantHost string
	QdrantPort int
	Timeout    time.Duration

	// Configuration des embeddings
	EmbeddingProvider Provider
	EmbeddingModel    string
	VectorDimensions  int

	// Configuration OpenAI
	OpenAIAPIKey string
	OpenAIModel  string

	// Configuration HuggingFace
	HuggingFaceAPIKey string
	HuggingFaceModel  string

	// Configuration des logs
	LogLevel  LogLevel
	LogFile   string
	LogRotate bool
}

// NewConfig crée une nouvelle configuration avec les valeurs par défaut
// et les surcharge avec les variables d'environnement si disponibles
func NewConfig() *Config {
	config := &Config{
		// Valeurs par défaut QDrant
		QdrantHost: "localhost",
		QdrantPort: 6333,
		Timeout:    30 * time.Second,

		// Valeurs par défaut embeddings
		EmbeddingProvider: ProviderSimulation,
		EmbeddingModel:    "all-MiniLM-L6-v2",
		VectorDimensions:  384,

		// Valeurs par défaut logs
		LogLevel:  LogLevelInfo,
		LogFile:   "",
		LogRotate: true,
	}

	// Surcharge avec les variables d'environnement
	if host := os.Getenv("QDRANT_HOST"); host != "" {
		config.QdrantHost = host
	}

	if portStr := os.Getenv("QDRANT_PORT"); portStr != "" {
		if port, err := strconv.Atoi(portStr); err == nil && port > 0 && port <= 65535 {
			config.QdrantPort = port
		}
	}

	if timeoutStr := os.Getenv("QDRANT_TIMEOUT"); timeoutStr != "" {
		if timeout, err := time.ParseDuration(timeoutStr); err == nil {
			config.Timeout = timeout
		}
	}

	if provider := os.Getenv("EMBEDDING_PROVIDER"); provider != "" {
		config.EmbeddingProvider = Provider(provider)
	}

	if model := os.Getenv("EMBEDDING_MODEL"); model != "" {
		config.EmbeddingModel = model
	}

	if dimStr := os.Getenv("VECTOR_DIMENSIONS"); dimStr != "" {
		if dim, err := strconv.Atoi(dimStr); err == nil && dim >= 50 && dim <= 4096 {
			config.VectorDimensions = dim
		}
	}

	if logLevel := os.Getenv("LOG_LEVEL"); logLevel != "" {
		config.LogLevel = LogLevel(logLevel)
	}

	if logFile := os.Getenv("LOG_FILE"); logFile != "" {
		config.LogFile = logFile
	}

	// API keys
	config.OpenAIAPIKey = os.Getenv("OPENAI_API_KEY")
	config.HuggingFaceAPIKey = os.Getenv("HUGGINGFACE_API_KEY")

	return config
}

// Validate vérifie que la configuration est valide
func (c *Config) Validate() error {
	// Validation du port
	if c.QdrantPort <= 0 || c.QdrantPort > 65535 {
		return errors.New("le port QDrant doit être entre 1 et 65535")
	}

	// Validation du provider
	switch c.EmbeddingProvider {
	case ProviderSimulation, ProviderOpenAI, ProviderHuggingFace:
		// Provider valide
	default:
		return errors.New("provider d'embedding non supporté: " + string(c.EmbeddingProvider))
	}

	// Validation des dimensions du vecteur
	if c.VectorDimensions < 50 || c.VectorDimensions > 4096 {
		return errors.New("les dimensions du vecteur doivent être entre 50 et 4096")
	}

	// Validation des API keys selon le provider
	if c.EmbeddingProvider == ProviderOpenAI && c.OpenAIAPIKey == "" {
		return errors.New("clé API OpenAI requise avec le provider OpenAI")
	}

	if c.EmbeddingProvider == ProviderHuggingFace && c.HuggingFaceAPIKey == "" {
		return errors.New("clé API HuggingFace requise avec le provider HuggingFace")
	}

	return nil
}

// SetLogLevel change le niveau de log
func (c *Config) SetLogLevel(level LogLevel) {
	c.LogLevel = level
}
