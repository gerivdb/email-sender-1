package development

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
	"gopkg.in/yaml.v3"

	"github.com/gerivdb/email-sender-1/development/managers/branching-manager/interfaces"
)

// BranchingManagerImpl implements the BranchingManager interface
type BranchingManagerImpl struct {
	interfaces.BaseManager
	config           *BranchingConfig
	storageManager   interfaces.StorageManager
	errorManager     interfaces.ErrorManager
	contextualMemory interfaces.ContextualMemoryManager

	// Internal state
	activeSessions    map[string]*interfaces.Session
	sessionMutex      sync.RWMutex
	eventQueue        chan interfaces.BranchingEvent
	eventProcessors   map[interfaces.EventType]EventProcessor
	temporalSnapshots map[string][]*interfaces.TemporalSnapshot
	quantumBranches   map[string]*interfaces.QuantumBranch

	// AI/ML components for predictive branching
	predictor BranchingPredictor
	analyzer  PatternAnalyzer

	logger   *log.Logger
	stopChan chan struct{}
	wg       sync.WaitGroup
}

// BranchingConfig holds the configuration for the branching manager
type BranchingConfig struct {
	// Level 1: Micro-Sessions
	DefaultSessionDuration time.Duration `yaml:"default_session_duration"`
	MaxSessionDuration     time.Duration `yaml:"max_session_duration"`
	SessionNamingPattern   string        `yaml:"session_naming_pattern"`
	AutoArchiveEnabled     bool          `yaml:"auto_archive_enabled"`

	// Level 2: Event-Driven
	EventQueueSize         int           `yaml:"event_queue_size"`
	GitHooksEnabled        bool          `yaml:"git_hooks_enabled"`
	AutoBranchingEnabled   bool          `yaml:"auto_branching_enabled"`
	EventProcessingTimeout time.Duration `yaml:"event_processing_timeout"`

	// Level 3: Multi-Dimensional
	MaxDimensions          int  `yaml:"max_dimensions"`
	TaggingEnabled         bool `yaml:"tagging_enabled"`
	DimensionWeightEnabled bool `yaml:"dimension_weight_enabled"`

	// Level 4: Contextual Memory
	AutoDocumentationEnabled bool `yaml:"auto_documentation_enabled"`
	MemoryIntegrationEnabled bool `yaml:"memory_integration_enabled"`
	ContextLinkingEnabled    bool `yaml:"context_linking_enabled"`

	// Level 5: Temporal
	SnapshotInterval      time.Duration `yaml:"snapshot_interval"`
	MaxSnapshotsPerBranch int           `yaml:"max_snapshots_per_branch"`
	TimeTravelEnabled     bool          `yaml:"time_travel_enabled"`

	// Level 6: Predictive
	PredictiveEnabled             bool    `yaml:"predictive_enabled"`
	AIModelPath                   string  `yaml:"ai_model_path"`
	PredictionConfidenceThreshold float64 `yaml:"prediction_confidence_threshold"`

	// Level 7: Branching as Code
	CodeExecutionEnabled  bool     `yaml:"code_execution_enabled"`
	SupportedLanguages    []string `yaml:"supported_languages"`
	CodeValidationEnabled bool     `yaml:"code_validation_enabled"`

	// Level 8: Quantum
	QuantumBranchingEnabled bool `yaml:"quantum_branching_enabled"`
	MaxParallelApproaches   int  `yaml:"max_parallel_approaches"`
	ApproachSelectionAI     bool `yaml:"approach_selection_ai"`

	// Database settings
	DatabaseURL       string `yaml:"database_url"`
	VectorDatabaseURL string `yaml:"vector_database_url"`

	// Monitoring
	MetricsEnabled bool   `yaml:"metrics_enabled"`
	LogLevel       string `yaml:"log_level"`
}

// EventProcessor defines the interface for processing different event types
type EventProcessor interface {
	ProcessEvent(ctx context.Context, event interfaces.BranchingEvent) error
	GetEventType() interfaces.EventType
}

// BranchingPredictor interface for AI-powered predictions
type BranchingPredictor interface {
	PredictOptimalBranch(ctx context.Context, intent interfaces.BranchingIntent) (*interfaces.PredictedBranch, error)
	AnalyzePatterns(ctx context.Context, projectID string) (*interfaces.BranchingAnalysis, error)
	OptimizeStrategy(ctx context.Context, strategy interfaces.BranchingStrategy) (*interfaces.OptimizedStrategy, error)
}

// PatternAnalyzer interface for analyzing branching patterns
type PatternAnalyzer interface {
	AnalyzeBranchingPatterns(ctx context.Context, branches []*interfaces.Branch) ([]interfaces.BranchingPattern, error)
	ExtractInsights(ctx context.Context, patterns []interfaces.BranchingPattern) ([]string, error)
}

// NewBranchingManager creates a new instance of BranchingManager
func NewBranchingManager(configPath string) (*BranchingManagerImpl, error) {
	config, err := loadConfig(configPath)
	if err != nil {
		return nil, fmt.Errorf("failed to load config: %w", err)
	}

	logger := log.New(os.Stdout, "[BranchingManager] ", log.LstdFlags|log.Lshortfile)

	manager := &BranchingManagerImpl{
		config:            config,
		activeSessions:    make(map[string]*interfaces.Session),
		eventQueue:        make(chan interfaces.BranchingEvent, config.EventQueueSize),
		eventProcessors:   make(map[interfaces.EventType]EventProcessor),
		temporalSnapshots: make(map[string][]*interfaces.TemporalSnapshot),
		quantumBranches:   make(map[string]*interfaces.QuantumBranch),
		logger:            logger,
		stopChan:          make(chan struct{}),
	}

	// Initialize event processors
	manager.initializeEventProcessors()

	return manager, nil
}

// NewBranchingManagerImpl creates a new instance of the branching manager
func NewBranchingManagerImpl(config *BranchingConfig) *BranchingManagerImpl {
	bm := &BranchingManagerImpl{
		config:            config,
		activeSessions:    make(map[string]*interfaces.Session),
		eventQueue:        make(chan interfaces.BranchingEvent, config.EventQueueSize),
		eventProcessors:   make(map[interfaces.EventType]EventProcessor),
		temporalSnapshots: make(map[string][]*interfaces.TemporalSnapshot),
		quantumBranches:   make(map[string]*interfaces.QuantumBranch),
		logger:            log.New(os.Stdout, "[BranchingManager] ", log.LstdFlags),
		stopChan:          make(chan struct{}),
	}

	// Initialize event processors
	bm.initializeEventProcessors()

	return bm
}

// loadConfig loads the configuration from YAML file
func loadConfig(configPath string) (*BranchingConfig, error) {
	data, err := os.ReadFile(configPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	var config BranchingConfig
	if err := yaml.Unmarshal(data, &config); err != nil {
		return nil, fmt.Errorf("failed to unmarshal config: %w", err)
	}

	// Set defaults
	if config.DefaultSessionDuration == 0 {
		config.DefaultSessionDuration = 30 * time.Minute
	}
	if config.EventQueueSize == 0 {
		config.EventQueueSize = 1000
	}

	return &config, nil
}

// initializeEventProcessors sets up the event processing system
func (bm *BranchingManagerImpl) initializeEventProcessors() {
	bm.eventProcessors[interfaces.EventTypeSessionCreated] = &SessionEventProcessor{}
	bm.eventProcessors[interfaces.EventTypeSessionEnded] = &SessionEventProcessor{}
	bm.eventProcessors[interfaces.EventTypeBranchCreated] = &BranchEventProcessor{}
	bm.eventProcessors[interfaces.EventTypeBranchMerged] = &BranchEventProcessor{}
	bm.eventProcessors[interfaces.EventTypeCommit] = &CommitEventProcessor{}
	bm.eventProcessors[interfaces.EventTypePush] = &PushEventProcessor{manager: bm}
	bm.eventProcessors[interfaces.EventTypePullRequest] = &PullRequestEventProcessor{manager: bm}
	bm.eventProcessors[interfaces.EventTypeTimer] = &TimerEventProcessor{manager: bm}
}

// Start starts the branching manager and begins processing events
func (bm *BranchingManagerImpl) Start(ctx context.Context) error {
	bm.logger.Println("Starting BranchingManager...")

	// Start event processing goroutine
	bm.wg.Add(1)
	go bm.processEvents(ctx)

	// Start session monitoring goroutine
	bm.wg.Add(1)
	go bm.monitorSessions(ctx)

	// Start temporal snapshot goroutine if enabled
	if bm.config.SnapshotInterval > 0 {
		bm.wg.Add(1)
		go bm.createPeriodicSnapshots(ctx)
	}

	bm.logger.Println("BranchingManager started successfully")
	return nil
}

// Stop gracefully stops the branching manager
func (bm *BranchingManagerImpl) Stop() error {
	bm.logger.Println("Stopping BranchingManager...")

	close(bm.stopChan)
	bm.wg.Wait()

	bm.logger.Println("BranchingManager stopped")
	return nil
}

// Level 1: Micro-Sessions Temporelles Implementation

// CreateSession creates a new micro-session with the specified configuration
func (bm *BranchingManagerImpl) CreateSession(ctx context.Context, config interfaces.SessionConfig) (*interfaces.Session, error) {
	bm.sessionMutex.Lock()
	defer bm.sessionMutex.Unlock()

	sessionID := uuid.New().String()
	now := time.Now()

	session := &interfaces.Session{
		ID:        sessionID,
		Timestamp: now,
		Scope:     config.Scope,
		Duration:  config.MaxDuration,
		Status:    interfaces.SessionStatusActive,
		Metadata:  config.Metadata,
		CreatedAt: now,
	}

	// Set default duration if not specified
	if session.Duration == 0 {
		session.Duration = bm.config.DefaultSessionDuration
	}

	// Generate branch name based on pattern
	branchName := bm.generateBranchName(config.NamingPattern, session)

	// Create Git branch
	branchID, err := bm.createGitBranch(ctx, branchName, "main")
	if err != nil {
		return nil, fmt.Errorf("failed to create git branch: %w", err)
	}

	session.BranchID = branchID

	// Store session
	bm.activeSessions[sessionID] = session

	// Store in database if storage manager is available
	if bm.storageManager != nil {
		if err := bm.storeSession(ctx, session); err != nil {
			bm.logger.Printf("Warning: failed to store session in database: %v", err)
		}
	}

	bm.logger.Printf("Created session %s with branch %s", sessionID, branchName)
	return session, nil
}

// EndSession ends an active session
func (bm *BranchingManagerImpl) EndSession(ctx context.Context, sessionID string) error {
	bm.sessionMutex.Lock()
	defer bm.sessionMutex.Unlock()

	session, exists := bm.activeSessions[sessionID]
	if !exists {
		return fmt.Errorf("session %s not found", sessionID)
	}

	now := time.Now()
	session.Status = interfaces.SessionStatusEnded
	session.EndedAt = &now

	// Auto-archive if enabled
	if bm.config.AutoArchiveEnabled {
		if err := bm.archiveSession(ctx, session); err != nil {
			bm.logger.Printf("Warning: failed to archive session: %v", err)
		}
	}

	// Update in database
	if bm.storageManager != nil {
		if err := bm.updateSession(ctx, session); err != nil {
			bm.logger.Printf("Warning: failed to update session in database: %v", err)
		}
	}

	delete(bm.activeSessions, sessionID)
	bm.logger.Printf("Ended session %s", sessionID)
	return nil
}

// GetSessionHistory retrieves session history with filters
func (bm *BranchingManagerImpl) GetSessionHistory(ctx context.Context, filters interfaces.SessionFilters) ([]*interfaces.Session, error) {
	if bm.storageManager == nil {
		return nil, fmt.Errorf("storage manager not available")
	}

	return bm.querySessionHistory(ctx, filters)
}

// GetActiveSession returns the currently active session for the user
func (bm *BranchingManagerImpl) GetActiveSession(ctx context.Context) (*interfaces.Session, error) {
	bm.sessionMutex.RLock()
	defer bm.sessionMutex.RUnlock()

	for _, session := range bm.activeSessions {
		if session.Status == interfaces.SessionStatusActive {
			return session, nil
		}
	}

	return nil, fmt.Errorf("no active session found")
}

// Helper methods for Level 1

func (bm *BranchingManagerImpl) generateBranchName(pattern string, session *interfaces.Session) string {
	if pattern == "" {
		pattern = "session-{{.ID}}-{{.Timestamp.Format \"20060102-1504\"}}"
	}

	// Simple template replacement
	branchName := pattern
	branchName = fmt.Sprintf("session-%s-%s",
		session.ID[:8],
		session.Timestamp.Format("20060102-1504"))

	return branchName
}

func (bm *BranchingManagerImpl) createGitBranch(ctx context.Context, branchName, baseBranch string) (string, error) {
	// This would integrate with Git operations
	// For now, return a mock branch ID
	branchID := uuid.New().String()
	bm.logger.Printf("Created Git branch %s from %s", branchName, baseBranch)
	return branchID, nil
}

func (bm *BranchingManagerImpl) storeSession(ctx context.Context, session *interfaces.Session) error {
	data, err := json.Marshal(session)
	if err != nil {
		return err
	}

	return bm.storageManager.Store(ctx, "sessions", session.ID, string(data))
}

func (bm *BranchingManagerImpl) updateSession(ctx context.Context, session *interfaces.Session) error {
	data, err := json.Marshal(session)
	if err != nil {
		return err
	}

	return bm.storageManager.Update(ctx, "sessions", session.ID, string(data))
}

func (bm *BranchingManagerImpl) archiveSession(ctx context.Context, session *interfaces.Session) error {
	session.Status = interfaces.SessionStatusArchived
	return bm.updateSession(ctx, session)
}

func (bm *BranchingManagerImpl) querySessionHistory(ctx context.Context, filters interfaces.SessionFilters) ([]*interfaces.Session, error) {
	// This would query the database with filters
	// For now, return empty slice
	return []*interfaces.Session{}, nil
}

// Level 2: Event-Driven Branching Implementation

// TriggerBranchCreation creates a new branch based on an event trigger
func (bm *BranchingManagerImpl) TriggerBranchCreation(ctx context.Context, event interfaces.BranchingEvent) (*interfaces.Branch, error) {
	now := time.Now()

	// Generate branch name based on event
	branchName := bm.generateEventBranchName(event)

	// Create Git branch
	branchID, err := bm.createGitBranch(ctx, branchName, "main")
	if err != nil {
		return nil, fmt.Errorf("failed to create event-triggered branch: %w", err)
	}

	// Create branch record
	branch := &interfaces.Branch{
		ID:         branchID,
		Name:       branchName,
		BaseBranch: "main",
		CreatedAt:  now,
		UpdatedAt:  now,
		Status:     interfaces.BranchStatusActive,
		Metadata: map[string]string{
			"event_type":   string(event.Type),
			"trigger":      event.Trigger,
			"auto_created": fmt.Sprintf("%t", event.AutoCreated),
			"priority":     fmt.Sprintf("%d", event.Priority),
		},
		EventID: fmt.Sprintf("%s-%d", event.Type, now.Unix()),
		Level:   2, // Level 2: Event-Driven
	}

	// Add event context to metadata
	for key, value := range event.Context {
		if strValue, ok := value.(string); ok {
			branch.Metadata[fmt.Sprintf("ctx_%s", key)] = strValue
		}
	}

	// Store branch in database
	if bm.storageManager != nil {
		if err := bm.storeBranch(ctx, branch); err != nil {
			bm.logger.Printf("Warning: failed to store event-triggered branch: %v", err)
		}
	}

	bm.logger.Printf("Created event-triggered branch %s (ID: %s) for event %s", branchName, branchID, event.Type)
	return branch, nil
}

// ProcessGitHook processes Git hook events for automatic branching
func (bm *BranchingManagerImpl) ProcessGitHook(ctx context.Context, hookType string, payload map[string]interface{}) error {
	if !bm.config.GitHooksEnabled {
		return fmt.Errorf("git hooks are disabled")
	}

	bm.logger.Printf("Processing Git hook: %s", hookType)

	// Create branching event from Git hook
	event := interfaces.BranchingEvent{
		Type:        bm.mapHookTypeToEventType(hookType),
		Trigger:     fmt.Sprintf("git_hook_%s", hookType),
		Context:     payload,
		AutoCreated: true,
		Priority:    bm.getHookPriority(hookType),
		CreatedAt:   time.Now(),
	}

	// Add to event queue for processing
	select {
	case bm.eventQueue <- event:
		bm.logger.Printf("Queued Git hook event %s for processing", hookType)
	default:
		return fmt.Errorf("event queue is full, dropping Git hook event")
	}

	return nil
}

// HandleEventDriven handles general event-driven branching
func (bm *BranchingManagerImpl) HandleEventDriven(ctx context.Context, eventType string, context map[string]interface{}) error {
	if !bm.config.AutoBranchingEnabled {
		return nil, fmt.Errorf("auto-branching is disabled")
	}

	// Create branching event
	event := interfaces.BranchingEvent{
		Type:        interfaces.EventType(eventType),
		Trigger:     "manual_trigger",
		Context:     context,
		AutoCreated: false,
		Priority:    interfaces.EventPriorityMedium,
		CreatedAt:   time.Now(),
	}

	// Add context ID
	event.Context["event_id"] = uuid.New().String()

	// Process event immediately or queue it
	if bm.shouldProcessImmediately(event) {
		return bm.processEventImmediately(ctx, event)
	}

	// Add to event queue
	select {
	case bm.eventQueue <- event:
		bm.logger.Printf("Queued event-driven event %s for processing", eventType)
		return nil
	default:
		return fmt.Errorf("event queue is full, dropping event-driven event")
	}
}

// Helper methods for Level 2

func (bm *BranchingManagerImpl) generateEventBranchName(event interfaces.BranchingEvent) string {
	timestamp := time.Now().Format("20060102-1504")

	// Extract relevant context for naming
	var contextSuffix string
	if issueID, ok := event.Context["issue_id"].(string); ok {
		contextSuffix = fmt.Sprintf("issue-%s", issueID)
	} else if commitHash, ok := event.Context["commit_hash"].(string); ok {
		contextSuffix = fmt.Sprintf("commit-%s", commitHash[:8])
	} else {
		contextSuffix = "auto"
	}

	return fmt.Sprintf("event-%s-%s-%s", event.Type, contextSuffix, timestamp)
}

func (bm *BranchingManagerImpl) mapHookTypeToEventType(hookType string) interfaces.EventType {
	hookMap := map[string]interfaces.EventType{
		"pre-commit":   interfaces.EventTypeCommit,
		"post-commit":  interfaces.EventTypeCommit,
		"pre-push":     interfaces.EventTypePush,
		"post-receive": interfaces.EventTypePush,
		"pre-receive":  interfaces.EventTypePush,
		"update":       interfaces.EventTypePush,
	}

	if eventType, exists := hookMap[hookType]; exists {
		return eventType
	}

	return interfaces.EventTypeSystemTrigger
}

func (bm *BranchingManagerImpl) getHookPriority(hookType string) interfaces.EventPriority {
	priorityMap := map[string]interfaces.EventPriority{
		"pre-commit":   interfaces.EventPriorityMedium,
		"post-commit":  interfaces.EventPriorityLow,
		"pre-push":     interfaces.EventPriorityHigh,
		"post-receive": interfaces.EventPriorityHigh,
		"pre-receive":  interfaces.EventPriorityCritical,
		"update":       interfaces.EventPriorityMedium,
	}

	if priority, exists := priorityMap[hookType]; exists {
		return priority
	}

	return interfaces.EventPriorityLow
}

func (bm *BranchingManagerImpl) shouldProcessImmediately(event interfaces.BranchingEvent) bool {
	return event.Priority >= interfaces.EventPriorityHigh
}

func (bm *BranchingManagerImpl) processEventImmediately(ctx context.Context, event interfaces.BranchingEvent) error {
	processor, exists := bm.eventProcessors[event.Type]
	if !exists {
		return fmt.Errorf("no processor found for event type %s", event.Type)
	}

	return processor.ProcessEvent(ctx, event)
}

func (bm *BranchingManagerImpl) storeBranch(ctx context.Context, branch *interfaces.Branch) error {
	data, err := json.Marshal(branch)
	if err != nil {
		return err
	}

	return bm.storageManager.Store(ctx, "branches", branch.ID, string(data))
}

// Level 3: Multi-Dimensional Branching Implementation

// CreateMultiDimBranch creates a branch with multiple dimensions and classifications
func (bm *BranchingManagerImpl) CreateMultiDimBranch(ctx context.Context, dimensions []interfaces.BranchDimension) (*interfaces.Branch, error) {
	if !bm.config.TaggingEnabled {
		return nil, fmt.Errorf("multi-dimensional branching is disabled")
	}

	if len(dimensions) > bm.config.MaxDimensions {
		return nil, fmt.Errorf("too many dimensions: %d (max: %d)", len(dimensions), bm.config.MaxDimensions)
	}

	// Validate dimensions
	if err := bm.validateDimensions(dimensions); err != nil {
		return nil, fmt.Errorf("invalid dimensions: %w", err)
	}

	// Generate branch name based on dimensions
	branchName := bm.generateMultiDimBranchName(dimensions)

	// Create Git branch
	branchID, err := bm.createGitBranch(ctx, branchName, "main")
	if err != nil {
		return nil, fmt.Errorf("failed to create multi-dimensional branch: %w", err)
	}

	now := time.Now()
	branch := &interfaces.Branch{
		ID:         branchID,
		Name:       branchName,
		BaseBranch: "main",
		CreatedAt:  now,
		UpdatedAt:  now,
		Status:     interfaces.BranchStatusActive,
		Metadata:   make(map[string]string),
		Level:      3, // Level 3: Multi-Dimensional
	}

	// Add dimension metadata
	for i, dim := range dimensions {
		prefix := fmt.Sprintf("dim_%d", i)
		branch.Metadata[fmt.Sprintf("%s_name", prefix)] = dim.Name
		branch.Metadata[fmt.Sprintf("%s_value", prefix)] = dim.Value
		branch.Metadata[fmt.Sprintf("%s_type", prefix)] = string(dim.Type)
		branch.Metadata[fmt.Sprintf("%s_weight", prefix)] = fmt.Sprintf("%.2f", dim.Weight)
	}

	// Store branch and dimensions
	if bm.storageManager != nil {
		if err := bm.storeBranch(ctx, branch); err != nil {
			bm.logger.Printf("Warning: failed to store multi-dimensional branch: %v", err)
		}
		if err := bm.storeDimensions(ctx, branchID, dimensions); err != nil {
			bm.logger.Printf("Warning: failed to store dimensions: %v", err)
		}
	}

	bm.logger.Printf("Created multi-dimensional branch %s with %d dimensions", branchName, len(dimensions))
	return branch, nil
}

// TagBranch adds tags to an existing branch
func (bm *BranchingManagerImpl) TagBranch(ctx context.Context, branchID string, tags []interfaces.BranchTag) error {
	if !bm.config.TaggingEnabled {
		return fmt.Errorf("tagging is disabled")
	}

	// Validate tags
	if err := bm.validateTags(tags); err != nil {
		return fmt.Errorf("invalid tags: %w", err)
	}

	// Store tags in database
	if bm.storageManager != nil {
		for _, tag := range tags {
			tag.CreatedAt = time.Now()
			if err := bm.storeTag(ctx, branchID, tag); err != nil {
				bm.logger.Printf("Warning: failed to store tag %s: %v", tag.Key, err)
			}
		}
	}

	bm.logger.Printf("Added %d tags to branch %s", len(tags), branchID)
	return nil
}

// SearchBranchesByDimensions searches for branches based on dimensional criteria
func (bm *BranchingManagerImpl) SearchBranchesByDimensions(ctx context.Context, query interfaces.DimensionQuery) ([]*interfaces.Branch, error) {
	if bm.storageManager == nil {
		return nil, fmt.Errorf("storage manager not available")
	}

	// Build search criteria
	searchCriteria := bm.buildSearchCriteria(query)

	// Execute search
	branches, err := bm.executeSearchQuery(ctx, searchCriteria, query.Limit)
	if err != nil {
		return nil, fmt.Errorf("search execution failed: %w", err)
	}

	// Apply post-processing filters
	filteredBranches := bm.applyDimensionFilters(branches, query)

	bm.logger.Printf("Found %d branches matching dimensional query", len(filteredBranches))
	return filteredBranches, nil
}

// Level 4: Contextual Memory Integration Implementation

// IntegrateContextualMemory integrates contextual memory with a branch
func (bm *BranchingManagerImpl) IntegrateContextualMemory(ctx context.Context, branchID string, memoryContext interfaces.MemoryContext) error {
	if !bm.config.MemoryIntegrationEnabled {
		return fmt.Errorf("contextual memory integration is disabled")
	}

	if bm.contextualMemory == nil {
		return fmt.Errorf("contextual memory manager not available")
	}

	// Store memory context
	if err := bm.storeMemoryContext(ctx, branchID, memoryContext); err != nil {
		return fmt.Errorf("failed to store memory context: %w", err)
	}

	// Link branch to memory context
	if err := bm.linkBranchToMemory(ctx, branchID, memoryContext.ContextID); err != nil {
		return fmt.Errorf("failed to link branch to memory: %w", err)
	}

	// Update branch metadata
	if err := bm.updateBranchMemoryMetadata(ctx, branchID, memoryContext); err != nil {
		bm.logger.Printf("Warning: failed to update branch memory metadata: %v", err)
	}

	bm.logger.Printf("Integrated contextual memory %s with branch %s", memoryContext.ContextID, branchID)
	return nil
}

// GenerateAutoDocumentation automatically generates documentation for a branch
func (bm *BranchingManagerImpl) GenerateAutoDocumentation(ctx context.Context, branchID string) (*interfaces.Documentation, error) {
	if !bm.config.AutoDocumentationEnabled {
		return nil, fmt.Errorf("auto-documentation is disabled")
	}

	// Retrieve branch information
	branch, err := bm.getBranch(ctx, branchID)
	if err != nil {
		return nil, fmt.Errorf("failed to retrieve branch: %w", err)
	}

	// Analyze branch content
	content, err := bm.analyzeBranchContent(ctx, branch)
	if err != nil {
		return nil, fmt.Errorf("failed to analyze branch content: %w", err)
	}

	// Generate documentation
	docContent := bm.generateDocumentationContent(branch, content)

	documentation := &interfaces.Documentation{
		ID:          uuid.New().String(),
		BranchID:    branchID,
		Content:     docContent,
		Type:        interfaces.DocumentationTypeAutoGenerated,
		GeneratedAt: time.Now(),
		Metadata: map[string]interface{}{
			"generator":      "branching_manager",
			"version":        "1.0",
			"analysis_type":  "automatic",
			"content_length": len(docContent),
		},
	}

	// Store documentation
	if bm.storageManager != nil {
		if err := bm.storeDocumentation(ctx, documentation); err != nil {
			bm.logger.Printf("Warning: failed to store documentation: %v", err)
		}
	}

	bm.logger.Printf("Generated auto-documentation for branch %s (%d chars)", branchID, len(docContent))
	return documentation, nil
}

// LinkBranchToContext creates a link between a branch and a contextual memory context
func (bm *BranchingManagerImpl) LinkBranchToContext(ctx context.Context, branchID string, contextID string) error {
	if !bm.config.ContextLinkingEnabled {
		return fmt.Errorf("context linking is disabled")
	}

	// Create link record
	link := map[string]interface{}{
		"branch_id":  branchID,
		"context_id": contextID,
		"created_at": time.Now(),
		"link_type":  "contextual_memory",
	}

	// Store link
	if bm.storageManager != nil {
		linkData, err := json.Marshal(link)
		if err != nil {
			return fmt.Errorf("failed to marshal link data: %w", err)
		}

		linkID := fmt.Sprintf("%s_%s", branchID, contextID)
		if err := bm.storageManager.Store(ctx, "context_links", linkID, string(linkData)); err != nil {
			return fmt.Errorf("failed to store context link: %w", err)
		}
	}

	bm.logger.Printf("Linked branch %s to context %s", branchID, contextID)
	return nil
}

// Helper methods for Level 3

func (bm *BranchingManagerImpl) validateDimensions(dimensions []interfaces.BranchDimension) error {
	for i, dim := range dimensions {
		if dim.Name == "" {
			return fmt.Errorf("dimension %d: name cannot be empty", i)
		}
		if dim.Value == "" {
			return fmt.Errorf("dimension %d: value cannot be empty", i)
		}
		if dim.Weight < 0 || dim.Weight > 1 {
			return fmt.Errorf("dimension %d: weight must be between 0 and 1", i)
		}
	}
	return nil
}

func (bm *BranchingManagerImpl) generateMultiDimBranchName(dimensions []interfaces.BranchDimension) string {
	timestamp := time.Now().Format("20060102-1504")

	// Extract primary dimension for naming
	var primaryType, primaryValue string
	maxWeight := -1.0

	for _, dim := range dimensions {
		if dim.Weight > maxWeight {
			maxWeight = dim.Weight
			primaryType = string(dim.Type)
			primaryValue = dim.Value
		}
	}

	if primaryType == "" {
		primaryType = "multi"
		primaryValue = "dimensional"
	}

	return fmt.Sprintf("mdim-%s-%s-%s", primaryType, primaryValue, timestamp)
}

func (bm *BranchingManagerImpl) storeDimensions(ctx context.Context, branchID string, dimensions []interfaces.BranchDimension) error {
	for i, dim := range dimensions {
		dimData, err := json.Marshal(dim)
		if err != nil {
			return err
		
[Response interrupted by a tool use result. Only one tool may be used at a time and should be placed at the end of the message.]
