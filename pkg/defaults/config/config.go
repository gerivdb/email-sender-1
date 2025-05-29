package config

import (
	"encoding/json"
	"os"
	"path/filepath"
)

// Config holds the configuration for the defaults package
type Config struct {
	// Database configuration
	SQLite struct {
		Path string `json:"path"`
	} `json:"sqlite"`

	// Redis configuration
	Redis struct {
		Host     string `json:"host"`
		Port     int    `json:"port"`
		Password string `json:"password"`
		DB       int    `json:"db"`
	} `json:"redis"`

	// ML configuration
	ML struct {
		ModelPath    string  `json:"model_path"`
		Threshold    float64 `json:"threshold"`
		UpdatePeriod string  `json:"update_period"`
	} `json:"ml"`
}

// LoadConfig loads configuration from a JSON file
func LoadConfig(path string) (*Config, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	config := &Config{}
	if err := json.NewDecoder(file).Decode(config); err != nil {
		return nil, err
	}

	return config, nil
}

// DefaultConfig returns a default configuration
func DefaultConfig() *Config {
	config := &Config{}
	
	// Set default SQLite path
	config.SQLite.Path = filepath.Join("data", "defaults.db")

	// Set default Redis configuration
	config.Redis.Host = "localhost"
	config.Redis.Port = 6379
	config.Redis.DB = 0

	// Set default ML configuration
	config.ML.ModelPath = filepath.Join("data", "model.pkl")
	config.ML.Threshold = 0.8
	config.ML.UpdatePeriod = "24h"

	return config
}