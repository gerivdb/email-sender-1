package email

import (
	"context"
	"fmt"
	"html/template"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/email-sender-manager/interfaces"
	"go.uber.org/zap"
)

// TemplateManagerImpl implémente l'interface TemplateManager
type TemplateManagerImpl struct {
	// Base manager fields
	id            string
	name          string
	version       string
	status        interfaces.ManagerStatus
	logger        *zap.Logger
	mu            sync.RWMutex
	isInitialized bool

	// Template manager specific fields
	templates     map[string]*interfaces.EmailTemplate
	compiledTemplates map[string]*template.Template
}

// NewTemplateManager crée une nouvelle instance de TemplateManager
func NewTemplateManager(logger *zap.Logger) interfaces.TemplateManager {
	return &TemplateManagerImpl{
		id:                uuid.New().String(),
		name:              "TemplateManager",
		version:           "1.0.0",
		status:            interfaces.ManagerStatusStopped,
		logger:            logger,
		templates:         make(map[string]*interfaces.EmailTemplate),
		compiledTemplates: make(map[string]*template.Template),
	}
}

// Initialize implémente BaseManager.Initialize
func (tm *TemplateManagerImpl) Initialize(ctx context.Context) error {
	tm.mu.Lock()
	defer tm.mu.Unlock()

	if tm.isInitialized {
		return fmt.Errorf("template manager already initialized")
	}

	tm.status = interfaces.ManagerStatusStarting
	tm.logger.Info("Initializing template manager", zap.String("id", tm.id))

	// Initialize with default templates
	tm.loadDefaultTemplates()

	tm.status = interfaces.ManagerStatusRunning
	tm.isInitialized = true

	tm.logger.Info("Template manager initialized successfully")
	return nil
}

// Shutdown implémente BaseManager.Shutdown
func (tm *TemplateManagerImpl) Shutdown(ctx context.Context) error {
	tm.mu.Lock()
	defer tm.mu.Unlock()

	if !tm.isInitialized {
		return fmt.Errorf("template manager not initialized")
	}

	tm.status = interfaces.ManagerStatusStopping
	tm.logger.Info("Shutting down template manager")

	// Clear templates
	tm.templates = make(map[string]*interfaces.EmailTemplate)
	tm.compiledTemplates = make(map[string]*template.Template)

	tm.status = interfaces.ManagerStatusStopped
	tm.isInitialized = false

	tm.logger.Info("Template manager shut down successfully")
	return nil
}

// GetID implémente BaseManager.GetID
func (tm *TemplateManagerImpl) GetID() string {
	tm.mu.RLock()
	defer tm.mu.RUnlock()
	return tm.id
}

// GetName implémente BaseManager.GetName
func (tm *TemplateManagerImpl) GetName() string {
	tm.mu.RLock()
	defer tm.mu.RUnlock()
	return tm.name
}

// GetVersion implémente BaseManager.GetVersion
func (tm *TemplateManagerImpl) GetVersion() string {
	tm.mu.RLock()
	defer tm.mu.RUnlock()
	return tm.version
}

// GetStatus implémente BaseManager.GetStatus
func (tm *TemplateManagerImpl) GetStatus() interfaces.ManagerStatus {
	tm.mu.RLock()
	defer tm.mu.RUnlock()
	return tm.status
}

// IsHealthy implémente BaseManager.IsHealthy
func (tm *TemplateManagerImpl) IsHealthy(ctx context.Context) bool {
	tm.mu.RLock()
	defer tm.mu.RUnlock()
	return tm.status == interfaces.ManagerStatusRunning && tm.isInitialized
}

// GetMetrics implémente BaseManager.GetMetrics
func (tm *TemplateManagerImpl) GetMetrics() map[string]interface{} {
	tm.mu.RLock()
	defer tm.mu.RUnlock()

	return map[string]interface{}{
		"total_templates":    len(tm.templates),
		"compiled_templates": len(tm.compiledTemplates),
		"status":            tm.status.String(),
		"uptime":            time.Since(time.Now()).String(),
	}
}

// CreateTemplate implémente TemplateManager.CreateTemplate
func (tm *TemplateManagerImpl) CreateTemplate(ctx context.Context, emailTemplate *interfaces.EmailTemplate) error {
	tm.mu.Lock()
	defer tm.mu.Unlock()

	if !tm.isInitialized {
		return fmt.Errorf("template manager not initialized")
	}

	if emailTemplate.ID == "" {
		emailTemplate.ID = uuid.New().String()
	}

	// Validate template content
	if err := tm.validateTemplateContent(emailTemplate.Content); err != nil {
		return fmt.Errorf("invalid template content: %w", err)
	}

	// Compile template
	tmpl, err := template.New(emailTemplate.ID).Parse(emailTemplate.Content)
	if err != nil {
		return fmt.Errorf("failed to compile template: %w", err)
	}

	emailTemplate.CreatedAt = time.Now()
	emailTemplate.UpdatedAt = time.Now()

	tm.templates[emailTemplate.ID] = emailTemplate
	tm.compiledTemplates[emailTemplate.ID] = tmpl

	tm.logger.Info("Template created", 
		zap.String("template_id", emailTemplate.ID),
		zap.String("name", emailTemplate.Name))

	return nil
}

// UpdateTemplate implémente TemplateManager.UpdateTemplate
func (tm *TemplateManagerImpl) UpdateTemplate(ctx context.Context, templateID string, emailTemplate *interfaces.EmailTemplate) error {
	tm.mu.Lock()
	defer tm.mu.Unlock()

	if !tm.isInitialized {
		return fmt.Errorf("template manager not initialized")
	}

	existing, exists := tm.templates[templateID]
	if !exists {
		return fmt.Errorf("template not found: %s", templateID)
	}

	// Validate new template content
	if err := tm.validateTemplateContent(emailTemplate.Content); err != nil {
		return fmt.Errorf("invalid template content: %w", err)
	}

	// Compile new template
	tmpl, err := template.New(templateID).Parse(emailTemplate.Content)
	if err != nil {
		return fmt.Errorf("failed to compile template: %w", err)
	}

	// Update template
	emailTemplate.ID = templateID
	emailTemplate.CreatedAt = existing.CreatedAt
	emailTemplate.UpdatedAt = time.Now()

	tm.templates[templateID] = emailTemplate
	tm.compiledTemplates[templateID] = tmpl

	tm.logger.Info("Template updated", 
		zap.String("template_id", templateID),
		zap.String("name", emailTemplate.Name))

	return nil
}

// DeleteTemplate implémente TemplateManager.DeleteTemplate
func (tm *TemplateManagerImpl) DeleteTemplate(ctx context.Context, templateID string) error {
	tm.mu.Lock()
	defer tm.mu.Unlock()

	if !tm.isInitialized {
		return fmt.Errorf("template manager not initialized")
	}

	if _, exists := tm.templates[templateID]; !exists {
		return fmt.Errorf("template not found: %s", templateID)
	}

	delete(tm.templates, templateID)
	delete(tm.compiledTemplates, templateID)

	tm.logger.Info("Template deleted", zap.String("template_id", templateID))
	return nil
}

// GetTemplate implémente TemplateManager.GetTemplate
func (tm *TemplateManagerImpl) GetTemplate(ctx context.Context, templateID string) (*interfaces.EmailTemplate, error) {
	tm.mu.RLock()
	defer tm.mu.RUnlock()

	if !tm.isInitialized {
		return nil, fmt.Errorf("template manager not initialized")
	}

	template, exists := tm.templates[templateID]
	if !exists {
		return nil, fmt.Errorf("template not found: %s", templateID)
	}

	return template, nil
}

// ListTemplates implémente TemplateManager.ListTemplates
func (tm *TemplateManagerImpl) ListTemplates(ctx context.Context) ([]*interfaces.EmailTemplate, error) {
	tm.mu.RLock()
	defer tm.mu.RUnlock()

	if !tm.isInitialized {
		return nil, fmt.Errorf("template manager not initialized")
	}

	templates := make([]*interfaces.EmailTemplate, 0, len(tm.templates))
	for _, template := range tm.templates {
		templates = append(templates, template)
	}

	return templates, nil
}

// RenderTemplate implémente TemplateManager.RenderTemplate
func (tm *TemplateManagerImpl) RenderTemplate(ctx context.Context, templateID string, data map[string]interface{}) (string, error) {
	tm.mu.RLock()
	defer tm.mu.RUnlock()

	if !tm.isInitialized {
		return "", fmt.Errorf("template manager not initialized")
	}

	tmpl, exists := tm.compiledTemplates[templateID]
	if !exists {
		return "", fmt.Errorf("template not found: %s", templateID)
	}

	var result strings.Builder
	if err := tmpl.Execute(&result, data); err != nil {
		return "", fmt.Errorf("failed to render template: %w", err)
	}

	return result.String(), nil
}

// ValidateTemplate implémente TemplateManager.ValidateTemplate
func (tm *TemplateManagerImpl) ValidateTemplate(ctx context.Context, templateContent string) error {
	return tm.validateTemplateContent(templateContent)
}

// PreviewTemplate implémente TemplateManager.PreviewTemplate
func (tm *TemplateManagerImpl) PreviewTemplate(ctx context.Context, templateID string, data map[string]interface{}) (string, error) {
	return tm.RenderTemplate(ctx, templateID, data)
}

// validateTemplateContent valide le contenu d'un template
func (tm *TemplateManagerImpl) validateTemplateContent(content string) error {
	if content == "" {
		return fmt.Errorf("template content cannot be empty")
	}

	// Try to parse the template
	_, err := template.New("test").Parse(content)
	if err != nil {
		return fmt.Errorf("invalid template syntax: %w", err)
	}

	return nil
}

// loadDefaultTemplates charge les templates par défaut
func (tm *TemplateManagerImpl) loadDefaultTemplates() {
	// Template de bienvenue
	welcomeTemplate := &interfaces.EmailTemplate{
		ID:          "welcome",
		Name:        "Welcome Email",
		Subject:     "Welcome to {{.AppName}}",
		Content:     `Hello {{.Name}},\n\nWelcome to {{.AppName}}! We're excited to have you on board.\n\nBest regards,\nThe {{.AppName}} Team`,
		Type:        interfaces.EmailTemplateTypeHTML,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	// Template de notification
	notificationTemplate := &interfaces.EmailTemplate{
		ID:          "notification",
		Name:        "System Notification",
		Subject:     "System Notification: {{.Title}}",
		Content:     `Dear {{.Name}},\n\n{{.Message}}\n\nTime: {{.Timestamp}}\n\nBest regards,\nSystem`,
		Type:        interfaces.EmailTemplateTypeText,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	tm.templates["welcome"] = welcomeTemplate
	tm.templates["notification"] = notificationTemplate

	// Compile templates
	for id, tmpl := range tm.templates {
		compiledTmpl, _ := template.New(id).Parse(tmpl.Content)
		tm.compiledTemplates[id] = compiledTmpl
	}
}
