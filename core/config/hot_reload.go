package config

import (
	"os"
	"sync"
	"time"

	"gopkg.in/yaml.v3"
)

// HotReloadConfig supports hot-reload without restart.
type HotReloadConfig struct {
	Path   string
	Config *AppConfig
	mu     sync.RWMutex
}

func (h *HotReloadConfig) WatchAndReload() {
	go func() {
		for {
			time.Sleep(1 * time.Second)
			data, err := os.ReadFile(h.Path) // Changed to os.ReadFile
			if err == nil {
				var cfg AppConfig
				if err := yaml.Unmarshal(data, &cfg); err == nil {
					h.mu.Lock()
					h.Config = &cfg
					h.mu.Unlock()
				}
				// It might be useful to log errors from yaml.Unmarshal here
			}
			// And also log errors from os.ReadFile
		}
	}() // Added () to invoke the goroutine
}

func (h *HotReloadConfig) Get() *AppConfig {
	h.mu.RLock()
	defer h.mu.RUnlock()
	return h.Config
}
