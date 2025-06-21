// SPDX-License-Identifier: MIT
// Package dashboard : gestion du dashboard utilisateur (v65)
package dashboard

import (
	"time"
)

// LayoutStorage placeholder type
type LayoutStorage struct{}

// WidgetRegistry placeholder type
type WidgetRegistry struct{}

// WebSocketManager placeholder type
type WebSocketManager struct{}

// PermissionManager placeholder type
type PermissionManager struct{}

// DashboardSettings placeholder type
type DashboardSettings struct{}

// DashboardManager gère les dashboards utilisateurs
type DashboardManager struct {
	LayoutStore LayoutStorage
	WidgetReg   *WidgetRegistry
	WSManager   *WebSocketManager
	Permissions *PermissionManager
}

// Dashboard structure principale
type Dashboard struct {
	ID         string
	UserID     string
	Name       string
	Layout     []WidgetLayout
	Settings   DashboardSettings
	SharedWith []string
	CreatedAt  time.Time
	UpdatedAt  time.Time
}

// WidgetLayout configuration d’un widget
type WidgetLayout struct {
	ID     string
	Type   string
	X      int
	Y      int
	Width  int
	Height int
	Config map[string]interface{}
}

// LayoutStorage, WidgetRegistry, WebSocketManager, PermissionManager à implémenter selon besoins
// Defined above as empty structs for now.
