package config

// ProfileConfig for environment profiles.
type ProfileConfig struct {
	Name   string
	Config *AppConfig
}

func NewProfileConfig(name string, cfg *AppConfig) *ProfileConfig {
	return &ProfileConfig{Name: name, Config: cfg}
}
