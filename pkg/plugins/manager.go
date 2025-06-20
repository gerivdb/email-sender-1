// SPDX-License-Identifier: MIT
// Package plugins : gestion des extensions dynamiques (v65)
package plugins

import (
	"context"
	"time"
)

// PluginManager gère les plugins dynamiques
type PluginManager struct {
	Registry    *PluginRegistry
	Loader      *PluginLoader
	Sandbox     *SecuritySandbox
	HookManager *HookManager
	Validator   *PluginValidator
}

// Plugin structure principale
type Plugin struct {
	Metadata    PluginMetadata
	Binary      []byte
	Signature   string
	Config      map[string]interface{}
	Permissions []Permission
	Status      PluginStatus
	LoadedAt    *time.Time
}

// PluginInterface interface standardisée
type PluginInterface interface {
	Initialize(ctx context.Context, config map[string]interface{}) error
	Process(ctx context.Context, input interface{}) (interface{}, error)
	Cleanup() error
	GetMetadata() PluginMetadata
}

// PluginMetadata, PluginRegistry, PluginLoader, SecuritySandbox, HookManager, PluginValidator, Permission, PluginStatus à implémenter selon besoins
