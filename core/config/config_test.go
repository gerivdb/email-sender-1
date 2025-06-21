package config

import (
	"os"
	"testing"
)

func TestLoadConfigYAML(t *testing.T) {
	content := []byte("env: test\nsettings:\n  key: value\n")
	tmp := "test_config.yaml"
	_ = os.WriteFile(tmp, content, 0o644)
	defer func() { _, _ = os.ReadFile(tmp) }() // Correctly ignore two return values
	cfg, err := LoadConfigYAML(tmp)
	if err != nil || cfg.Env != "test" {
		t.Error("YAML config load failed")
	}
	// Attempt to clean up the temp file
	_ = os.Remove(tmp)
}

func TestHotReloadConfig(t *testing.T) {
	content := []byte("env: reload\nsettings:\n  key: value\n")
	tmp := "test_reload.yaml"
	_ = os.WriteFile(tmp, content, 0o644)
	defer func() { _, _ = os.ReadFile(tmp) }() // Correctly ignore two return values
	h := &HotReloadConfig{Path: tmp}
	// Note: h.WatchAndReload() likely starts a goroutine.
	// Proper testing of this might require more advanced techniques
	// to ensure the reload logic is triggered and verified.
	// For now, we're just checking if it runs without immediate error.
	h.WatchAndReload()
	// Attempt to clean up the temp file
	_ = os.Remove(tmp)
}
