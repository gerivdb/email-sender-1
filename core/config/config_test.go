package config

import (
	"io/ioutil"
	"testing"
)

func TestLoadConfigYAML(t *testing.T) {
	content := []byte("env: test\nsettings:\n  key: value\n")
	tmp := "test_config.yaml"
	_ = ioutil.WriteFile(tmp, content, 0o644)
	defer func() { _ = ioutil.ReadFile(tmp) }()
	cfg, err := LoadConfigYAML(tmp)
	if err != nil || cfg.Env != "test" {
		t.Error("YAML config load failed")
	}
}

func TestHotReloadConfig(t *testing.T) {
	content := []byte("env: reload\nsettings:\n  key: value\n")
	tmp := "test_reload.yaml"
	_ = ioutil.WriteFile(tmp, content, 0o644)
	defer func() { _ = ioutil.ReadFile(tmp) }()
	h := &HotReloadConfig{Path: tmp}
	h.WatchAndReload()
}
