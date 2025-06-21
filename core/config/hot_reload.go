package config

import (
	"io/ioutil"
	"sync"
	"time"
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
			data, err := ioutil.ReadFile(h.Path)
			if err == nil {
				var cfg AppConfig
				if err := yaml.Unmarshal(data, &cfg); err == nil {
					h.mu.Lock()
					h.Config = &cfg
					h.mu.Unlock()
				}
			}
		}
	}
}

func (h *HotReloadConfig) Get() *AppConfig {
	h.mu.RLock()
	defer h.mu.RUnlock()
	return h.Config
}
