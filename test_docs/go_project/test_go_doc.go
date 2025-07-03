package goproject

// Sum adds two integers and returns the result.
//
// Parameters:
//
//	a: The first integer.
//	b: The second integer.
//
// Returns:
//
//	The sum of a and b.
func Sum(a, b int) int {
	return a + b
}

// Config represents a configuration structure.
type Config struct {
	// Name is the name of the configuration.
	Name string
	// Version is the version number.
	Version string
}

// NewConfig creates a new Config instance.
func NewConfig(name, version string) *Config {
	return &Config{
		Name:    name,
		Version: version,
	}
}
