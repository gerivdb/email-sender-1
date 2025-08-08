// development/managers/interfaces/email_template.go
package interfaces

import (
	"context"
	"time"
)

// EmailTemplateManager définit l'interface pour la gestion des templates email
type EmailTemplateManager interface {
	BaseManager

	// Gestion des templates
	CreateTemplate(ctx context.Context, template EmailTemplate) error
	GetTemplate(ctx context.Context, id string) (*EmailTemplate, error)
	UpdateTemplate(ctx context.Context, id string, template EmailTemplate) error
	DeleteTemplate(ctx context.Context, id string) error
	ListTemplates(ctx context.Context, filter TemplateFilter) ([]EmailTemplate, error)

	// Rendu et validation
	RenderTemplate(ctx context.Context, templateID string, data map[string]interface{}) (string, error)
	ValidateTemplate(ctx context.Context, template EmailTemplate) error
	PreviewTemplate(ctx context.Context, templateID string, data map[string]interface{}) (*TemplatePreview, error)

	// Gestion des versions
	CreateVersion(ctx context.Context, templateID string, version TemplateVersion) error
	GetVersions(ctx context.Context, templateID string) ([]TemplateVersion, error)
	RollbackToVersion(ctx context.Context, templateID string, versionID string) error
}

/*
	Le type EmailTemplate est défini dans types.go pour éviter toute redéclaration.
	Utiliser le type importé pour garantir la cohérence et la traçabilité Roo-Code.
*/

type TemplateType string

const (
	TemplateTypeHTML  TemplateType = "html"
	TemplateTypeText  TemplateType = "text"
	TemplateTypeMixed TemplateType = "mixed"
)

type TemplateVariable struct {
	Name         string `json:"name"`
	Type         string `json:"type"`
	Required     bool   `json:"required"`
	DefaultValue string `json:"default_value,omitempty"`
	Description  string `json:"description,omitempty"`
}

type TemplateFilter struct {
	Name     string       `json:"name,omitempty"`
	Type     TemplateType `json:"type,omitempty"`
	IsActive *bool        `json:"is_active,omitempty"`
	Limit    int          `json:"limit,omitempty"`
	Offset   int          `json:"offset,omitempty"`
}

type TemplatePreview struct {
	Subject     string                 `json:"subject"`
	BodyHTML    string                 `json:"body_html"`
	BodyText    string                 `json:"body_text"`
	Variables   map[string]interface{} `json:"variables"`
	GeneratedAt time.Time              `json:"generated_at"`
}

type TemplateVersion struct {
	ID         string                 `json:"id"`
	TemplateID string                 `json:"template_id"`
	Version    string                 `json:"version"`
	Subject    string                 `json:"subject"`
	Body       string                 `json:"body"`
	Variables  []TemplateVariable     `json:"variables"`
	Metadata   map[string]interface{} `json:"metadata"`
	CreatedAt  time.Time              `json:"created_at"`
	CreatedBy  string                 `json:"created_by"`
	Changelog  string                 `json:"changelog,omitempty"`
}
