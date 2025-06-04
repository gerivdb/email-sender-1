// Moteur de Suggestions de Correction - Phase 9.2.1
// Plan de développement v42 - Gestionnaire d'erreurs avancé
package auto_fix

import (
	"context"
	"fmt"
	"go/ast"
	"go/format"
	"go/parser"
	"go/token"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"sync"
	"time"

	"golang.org/x/tools/go/ast/astutil"
)

// FixSuggestion représente une suggestion de correction
type FixSuggestion struct {
	ID             string                 `json:"id"`
	Type           FixType                `json:"type"`
	Description    string                 `json:"description"`
	File           string                 `json:"file"`
	FilePath       string                 `json:"file_path"`
	StartPos       token.Pos              `json:"start_pos"`
	EndPos         token.Pos              `json:"end_pos"`
	LineNumbers    []int                  `json:"line_numbers"`
	OriginalCode   string                 `json:"original_code"`
	ProposedCode   string                 `json:"proposed_code"`
	Patterns       []string               `json:"patterns"`
	Replacements   []string               `json:"replacements"`
	Confidence     float64                `json:"confidence"`
	SafetyLevel    SafetyLevel            `json:"safety_level"`
	Impact         ImpactLevel            `json:"impact"`
	Category       FixCategory            `json:"category"`
	AutoApplicable bool                   `json:"auto_applicable"`
	RequiresReview bool                   `json:"requires_review"`
	Dependencies   []string               `json:"dependencies"`
	Metadata       map[string]interface{} `json:"metadata"`
	CreatedAt      time.Time              `json:"created_at"`
}

// FixType représente le type de correction
type FixType string

const (
	FixTypeRemoveUnused  FixType = "remove_unused"
	FixTypeAddMissing    FixType = "add_missing"
	FixTypeSimplify      FixType = "simplify"
	FixTypeRefactor      FixType = "refactor"
	FixTypeFormat        FixType = "format"
	FixTypeOptimize      FixType = "optimize"
	FixTypeSecurity      FixType = "security"
	FixTypeNaming        FixType = "naming"
	FixTypeErrorHandling FixType = "error_handling"
	FixTypePerformance   FixType = "performance"
)

// ImpactLevel représente le niveau d'impact d'une correction
type ImpactLevel string

const (
	ImpactLow    ImpactLevel = "low"
	ImpactMedium ImpactLevel = "medium"
	ImpactHigh   ImpactLevel = "high"
)

// FixCategory représente la catégorie de correction
type FixCategory string

const (
	CategoryBugFix      FixCategory = "bug_fix"
	CategoryCodeQuality FixCategory = "code_quality"
	CategoryPerformance FixCategory = "performance"
	CategorySecurity    FixCategory = "security"
	CategoryMaintenance FixCategory = "maintenance"
	CategoryStyle       FixCategory = "style"
)

// FixTemplate représente un template de correction
type FixTemplate struct {
	ID          string              `json:"id"`
	Name        string              `json:"name"`
	Description string              `json:"description"`
	Pattern     *regexp.Regexp      `json:"-"`
	PatternStr  string              `json:"pattern"`
	Replacement string              `json:"replacement"`
	Conditions  []TemplateCondition `json:"conditions"`
	Category    FixCategory         `json:"category"`
	Confidence  float64             `json:"confidence"`
	Impact      ImpactLevel         `json:"impact"`
	AutoApply   bool                `json:"auto_apply"`
}

// TemplateCondition représente une condition pour appliquer un template
type TemplateCondition struct {
	Type     string `json:"type"`
	Value    string `json:"value"`
	Operator string `json:"operator"`
	Target   string `json:"target"`
}

// SuggestionEngine est le moteur principal de suggestions
type SuggestionEngine struct {
	fileSet   *token.FileSet
	templates map[string]*FixTemplate
	fixers    map[string]SpecificFixer
	mutex     sync.RWMutex
	config    EngineConfig
	stats     EngineStats
}

// EngineConfig contient la configuration du moteur
type EngineConfig struct {
	EnableAutoFix        bool           `json:"enable_auto_fix"`
	MaxConfidenceForAuto float64        `json:"max_confidence_for_auto"`
	EnabledCategories    []FixCategory  `json:"enabled_categories"`
	DisabledFixTypes     []FixType      `json:"disabled_fix_types"`
	CustomTemplates      []*FixTemplate `json:"custom_templates"`
	SafetyLevel          SafetyLevel    `json:"safety_level"`
	BackupEnabled        bool           `json:"backup_enabled"`
	ValidationEnabled    bool           `json:"validation_enabled"`
}

// SafetyLevel représente le niveau de sécurité d'une correction
type SafetyLevel string

const (
	SafetyLevelHigh   SafetyLevel = "high"
	SafetyLevelMedium SafetyLevel = "medium"
	SafetyLevelLow    SafetyLevel = "low"
	SafetyLevelUnsafe SafetyLevel = "unsafe"
)

// EngineStats contient les statistiques du moteur
type EngineStats struct {
	SuggestionsGenerated int                 `json:"suggestions_generated"`
	SuggestionsApplied   int                 `json:"suggestions_applied"`
	SuccessfulApplies    int                 `json:"successful_applies"`
	FailedApplies        int                 `json:"failed_applies"`
	ByCategory           map[FixCategory]int `json:"by_category"`
	ByType               map[FixType]int     `json:"by_type"`
	AverageConfidence    float64             `json:"average_confidence"`
}

// SpecificFixer interface pour les correcteurs spécifiques
type SpecificFixer interface {
	CanFix(issue StaticIssue) bool
	GenerateFix(issue StaticIssue, fset *token.FileSet, file *ast.File) (*FixSuggestion, error)
	GetCategory() FixCategory
	GetConfidence() float64
}

// StaticIssue interface pour les problèmes statiques (importé depuis le package static)
type StaticIssue struct {
	ID       string                 `json:"id"`
	File     string                 `json:"file"`
	Line     int                    `json:"line"`
	Column   int                    `json:"column"`
	Rule     string                 `json:"rule"`
	Message  string                 `json:"message"`
	Severity string                 `json:"severity"`
	Category string                 `json:"category"`
	Source   string                 `json:"source"`
	StartPos token.Pos              `json:"start_pos"`
	EndPos   token.Pos              `json:"end_pos"`
	Context  string                 `json:"context"`
	Metadata map[string]interface{} `json:"metadata"`
}

// NewSuggestionEngine crée un nouveau moteur de suggestions
func NewSuggestionEngine(config EngineConfig) *SuggestionEngine {
	engine := &SuggestionEngine{
		fileSet:   token.NewFileSet(),
		templates: make(map[string]*FixTemplate),
		fixers:    make(map[string]SpecificFixer),
		config:    config,
		stats: EngineStats{
			ByCategory: make(map[FixCategory]int),
			ByType:     make(map[FixType]int),
		},
	}

	// Initialiser les templates par défaut
	engine.setupDefaultTemplates()

	// Initialiser les fixers spécifiques
	engine.setupDefaultFixers()

	return engine
}

// setupDefaultTemplates configure les templates de correction par défaut
func (se *SuggestionEngine) setupDefaultTemplates() {
	templates := []*FixTemplate{
		{
			ID:          "unused_variable",
			Name:        "Remove unused variable",
			Description: "Remove variable that is declared but never used",
			PatternStr:  `var\s+(\w+)\s+\w+\s*(?:=.*)?`,
			Replacement: "",
			Category:    CategoryCodeQuality,
			Confidence:  0.9,
			Impact:      ImpactLow,
			AutoApply:   true,
		},
		{
			ID:          "simplify_if",
			Name:        "Simplify if statement",
			Description: "Simplify if statement with boolean expression",
			PatternStr:  `if\s+(.+)\s+==\s+true`,
			Replacement: "if $1",
			Category:    CategoryCodeQuality,
			Confidence:  0.95,
			Impact:      ImpactLow,
			AutoApply:   true,
		},
		{
			ID:          "gofmt_formatting",
			Name:        "Apply Go formatting",
			Description: "Fix formatting issues using gofmt",
			PatternStr:  `.*`,
			Replacement: "",
			Category:    CategoryStyle,
			Confidence:  0.99,
			Impact:      ImpactLow,
			AutoApply:   true,
		},
		{
			ID:          "ineffective_assign",
			Name:        "Remove ineffective assignment",
			Description: "Remove assignment to variable that is never used",
			PatternStr:  `(\w+)\s*=\s*.+`,
			Replacement: "",
			Category:    CategoryCodeQuality,
			Confidence:  0.8,
			Impact:      ImpactLow,
			AutoApply:   false,
		},
		{
			ID:          "error_check_missing",
			Name:        "Add error check",
			Description: "Add missing error check after function call",
			PatternStr:  `(\w+)\s*,\s*err\s*:=\s*(.+)\s*\n(?!\s*if\s+err)`,
			Replacement: "$1, err := $2\nif err != nil {\n\treturn err\n}",
			Category:    CategoryBugFix,
			Confidence:  0.7,
			Impact:      ImpactMedium,
			AutoApply:   false,
		},
	}

	for _, template := range templates {
		template.Pattern = regexp.MustCompile(template.PatternStr)
		se.templates[template.ID] = template
	}
}

// setupDefaultFixers configure les correcteurs spécifiques par défaut
func (se *SuggestionEngine) setupDefaultFixers() {
	se.fixers["unused_import"] = &UnusedImportFixer{}
	se.fixers["unused_variable"] = &UnusedVariableFixer{}
	se.fixers["simplify_code"] = &SimplifyCodeFixer{}
	se.fixers["format_code"] = &FormatCodeFixer{}
	se.fixers["error_handling"] = &ErrorHandlingFixer{}
	se.fixers["naming_convention"] = &NamingConventionFixer{}
}

// GenerateSuggestions génère des suggestions de correction pour une liste d'issues
func (se *SuggestionEngine) GenerateSuggestions(ctx context.Context, issues []StaticIssue) ([]*FixSuggestion, error) {
	se.mutex.Lock()
	defer se.mutex.Unlock()

	suggestions := make([]*FixSuggestion, 0)

	// Grouper les issues par fichier pour optimiser
	fileIssues := make(map[string][]StaticIssue)
	for _, issue := range issues {
		fileIssues[issue.File] = append(fileIssues[issue.File], issue)
	}

	// Traiter chaque fichier
	for filePath, fileIssuesSlice := range fileIssues {
		fileSuggestions, err := se.generateSuggestionsForFile(ctx, filePath, fileIssuesSlice)
		if err != nil {
			// Log l'erreur mais continue avec les autres fichiers
			continue
		}
		suggestions = append(suggestions, fileSuggestions...)
	}

	// Trier les suggestions par confiance et impact
	sort.Slice(suggestions, func(i, j int) bool {
		if suggestions[i].Confidence != suggestions[j].Confidence {
			return suggestions[i].Confidence > suggestions[j].Confidence
		}
		return suggestions[i].Impact == ImpactHigh
	})

	// Mettre à jour les statistiques
	se.updateStats(suggestions)

	return suggestions, nil
}

// generateSuggestionsForFile génère des suggestions pour un fichier spécifique
func (se *SuggestionEngine) generateSuggestionsForFile(ctx context.Context, filePath string, issues []StaticIssue) ([]*FixSuggestion, error) {
	// Parser le fichier
	src, err := parser.ParseFile(se.fileSet, filePath, nil, parser.ParseComments)
	if err != nil {
		return nil, fmt.Errorf("failed to parse file %s: %w", filePath, err)
	}

	suggestions := make([]*FixSuggestion, 0)

	// Appliquer les fixers spécifiques
	for _, issue := range issues {
		for fixerName, fixer := range se.fixers {
			if !fixer.CanFix(issue) {
				continue
			}

			suggestion, err := fixer.GenerateFix(issue, se.fileSet, src)
			if err != nil {
				// Log l'erreur mais continue
				continue
			}

			if suggestion != nil {
				suggestion.ID = fmt.Sprintf("%s_%s_%d", fixerName, filepath.Base(issue.File), issue.Line)
				suggestions = append(suggestions, suggestion)
			}
		}

		// Appliquer les templates
		templateSuggestions := se.applyTemplatesToIssue(issue, src)
		suggestions = append(suggestions, templateSuggestions...)
	}

	return suggestions, nil
}

// applyTemplatesToIssue applique les templates à une issue
func (se *SuggestionEngine) applyTemplatesToIssue(issue StaticIssue, file *ast.File) []*FixSuggestion {
	suggestions := make([]*FixSuggestion, 0)

	for _, template := range se.templates {
		if !se.isTemplateApplicable(template, issue) {
			continue
		}

		suggestion := se.applyTemplate(template, issue, file)
		if suggestion != nil {
			suggestions = append(suggestions, suggestion)
		}
	}

	return suggestions
}

// isTemplateApplicable vérifie si un template est applicable à une issue
func (se *SuggestionEngine) isTemplateApplicable(template *FixTemplate, issue StaticIssue) bool {
	// Vérifier les catégories activées
	enabled := false
	for _, enabledCat := range se.config.EnabledCategories {
		if enabledCat == template.Category {
			enabled = true
			break
		}
	}
	if !enabled && len(se.config.EnabledCategories) > 0 {
		return false
	}

	// Vérifier les conditions du template
	for _, condition := range template.Conditions {
		if !se.evaluateCondition(condition, issue) {
			return false
		}
	}

	return true
}

// evaluateCondition évalue une condition de template
func (se *SuggestionEngine) evaluateCondition(condition TemplateCondition, issue StaticIssue) bool {
	var targetValue string

	switch condition.Target {
	case "rule":
		targetValue = issue.Rule
	case "message":
		targetValue = issue.Message
	case "category":
		targetValue = issue.Category
	case "severity":
		targetValue = issue.Severity
	default:
		return false
	}

	switch condition.Operator {
	case "equals":
		return targetValue == condition.Value
	case "contains":
		return strings.Contains(targetValue, condition.Value)
	case "matches":
		if regex, err := regexp.Compile(condition.Value); err == nil {
			return regex.MatchString(targetValue)
		}
		return false
	default:
		return false
	}
}

// applyTemplate applique un template à une issue
func (se *SuggestionEngine) applyTemplate(template *FixTemplate, issue StaticIssue, file *ast.File) *FixSuggestion {
	// Obtenir le code original
	originalCode := issue.Context
	if originalCode == "" {
		// Fallback: lire le code depuis le fichier
		// TODO: Implémenter la lecture du code à partir des positions
		originalCode = "<code not available>"
	}

	// Appliquer la transformation
	proposedCode := template.Pattern.ReplaceAllString(originalCode, template.Replacement)

	// Si aucun changement, pas de suggestion
	if proposedCode == originalCode {
		return nil
	}

	return &FixSuggestion{
		ID:             fmt.Sprintf("template_%s_%d", template.ID, issue.Line),
		Type:           FixType(template.ID),
		Description:    template.Description,
		File:           issue.File,
		StartPos:       issue.StartPos,
		EndPos:         issue.EndPos,
		OriginalCode:   originalCode,
		ProposedCode:   proposedCode,
		Confidence:     template.Confidence,
		Impact:         template.Impact,
		Category:       template.Category,
		AutoApplicable: template.AutoApply && se.config.EnableAutoFix,
		RequiresReview: !template.AutoApply || template.Impact == ImpactHigh,
		Dependencies:   []string{},
		Metadata: map[string]interface{}{
			"template_id": template.ID,
			"issue_id":    issue.ID,
		},
		CreatedAt: time.Now(),
	}
}

// updateStats met à jour les statistiques du moteur
func (se *SuggestionEngine) updateStats(suggestions []*FixSuggestion) {
	se.stats.SuggestionsGenerated += len(suggestions)

	confidenceSum := 0.0
	for _, suggestion := range suggestions {
		se.stats.ByCategory[suggestion.Category]++
		se.stats.ByType[suggestion.Type]++
		confidenceSum += suggestion.Confidence
	}

	if len(suggestions) > 0 {
		se.stats.AverageConfidence = confidenceSum / float64(len(suggestions))
	}
}

// === FIXERS SPÉCIFIQUES ===

// UnusedImportFixer corrige les imports non utilisés
type UnusedImportFixer struct{}

func (f *UnusedImportFixer) CanFix(issue StaticIssue) bool {
	return strings.Contains(issue.Rule, "unused") && strings.Contains(issue.Message, "import")
}

func (f *UnusedImportFixer) GenerateFix(issue StaticIssue, fset *token.FileSet, file *ast.File) (*FixSuggestion, error) {
	// Identifier l'import à supprimer
	var importToRemove *ast.ImportSpec
	for _, imp := range file.Imports {
		pos := fset.Position(imp.Pos())
		if pos.Line == issue.Line {
			importToRemove = imp
			break
		}
	}

	if importToRemove == nil {
		return nil, fmt.Errorf("import not found at line %d", issue.Line)
	}
	// Générer le code sans l'import
	newFile := astutil.Apply(file, nil, func(c *astutil.Cursor) bool {
		if imp, ok := c.Node().(*ast.ImportSpec); ok && imp == importToRemove {
			c.Delete()
		}
		return true
	}).(*ast.File)

	// Formatter le nouveau code
	var buf strings.Builder
	if err := format.Node(&buf, fset, newFile); err != nil {
		return nil, fmt.Errorf("failed to format code: %w", err)
	}

	return &FixSuggestion{
		Type:           FixTypeRemoveUnused,
		Description:    fmt.Sprintf("Remove unused import %s", importToRemove.Path.Value),
		File:           issue.File,
		StartPos:       importToRemove.Pos(),
		EndPos:         importToRemove.End(),
		OriginalCode:   issue.Context,
		ProposedCode:   buf.String(),
		Confidence:     0.95,
		Impact:         ImpactLow,
		Category:       CategoryCodeQuality,
		AutoApplicable: true,
		RequiresReview: false,
		CreatedAt:      time.Now(),
	}, nil
}

func (f *UnusedImportFixer) GetCategory() FixCategory {
	return CategoryCodeQuality
}

func (f *UnusedImportFixer) GetConfidence() float64 {
	return 0.95
}

// UnusedVariableFixer corrige les variables non utilisées
type UnusedVariableFixer struct{}

func (f *UnusedVariableFixer) CanFix(issue StaticIssue) bool {
	return strings.Contains(issue.Rule, "unused") && strings.Contains(issue.Message, "variable")
}

func (f *UnusedVariableFixer) GenerateFix(issue StaticIssue, fset *token.FileSet, file *ast.File) (*FixSuggestion, error) {
	// Localiser la déclaration de variable
	var varToFix ast.Node
	ast.Inspect(file, func(n ast.Node) bool {
		switch node := n.(type) {
		case *ast.GenDecl:
			if node.Tok == token.VAR {
				pos := fset.Position(node.Pos())
				if pos.Line == issue.Line {
					varToFix = node
					return false
				}
			}
		case *ast.AssignStmt:
			pos := fset.Position(node.Pos())
			if pos.Line == issue.Line {
				varToFix = node
				return false
			}
		}
		return true
	})

	if varToFix == nil {
		return nil, fmt.Errorf("variable declaration not found at line %d", issue.Line)
	}

	return &FixSuggestion{
		Type:           FixTypeRemoveUnused,
		Description:    "Remove unused variable declaration",
		File:           issue.File,
		StartPos:       varToFix.Pos(),
		EndPos:         varToFix.End(),
		OriginalCode:   issue.Context,
		ProposedCode:   "", // Suppression complète
		Confidence:     0.8,
		Impact:         ImpactLow,
		Category:       CategoryCodeQuality,
		AutoApplicable: false, // Nécessite une révision
		RequiresReview: true,
		CreatedAt:      time.Now(),
	}, nil
}

func (f *UnusedVariableFixer) GetCategory() FixCategory {
	return CategoryCodeQuality
}

func (f *UnusedVariableFixer) GetConfidence() float64 {
	return 0.8
}

// SimplifyCodeFixer simplifie le code complexe
type SimplifyCodeFixer struct{}

func (f *SimplifyCodeFixer) CanFix(issue StaticIssue) bool {
	keywords := []string{"simplify", "complex", "redundant"}
	message := strings.ToLower(issue.Message)
	for _, keyword := range keywords {
		if strings.Contains(message, keyword) {
			return true
		}
	}
	return false
}

func (f *SimplifyCodeFixer) GenerateFix(issue StaticIssue, fset *token.FileSet, file *ast.File) (*FixSuggestion, error) {
	// Implémentation basique pour les simplifications communes
	originalCode := issue.Context
	proposedCode := originalCode

	// Simplifications communes
	simplifications := map[string]string{
		`if (.+) == true`:  "if $1",
		`if (.+) == false`: "if !$1",
		`if (.+) != false`: "if $1",
		`if (.+) != true`:  "if !$1",
		`len\((.+)\) == 0`: "$1 == \"\"",
		`len\((.+)\) > 0`:  "$1 != \"\"",
	}

	for pattern, replacement := range simplifications {
		if regex, err := regexp.Compile(pattern); err == nil {
			if regex.MatchString(originalCode) {
				proposedCode = regex.ReplaceAllString(originalCode, replacement)
				break
			}
		}
	}

	if proposedCode == originalCode {
		return nil, nil // Aucune simplification applicable
	}

	return &FixSuggestion{
		Type:           FixTypeSimplify,
		Description:    "Simplify code expression",
		File:           issue.File,
		StartPos:       issue.StartPos,
		EndPos:         issue.EndPos,
		OriginalCode:   originalCode,
		ProposedCode:   proposedCode,
		Confidence:     0.7,
		Impact:         ImpactLow,
		Category:       CategoryCodeQuality,
		AutoApplicable: false,
		RequiresReview: true,
		CreatedAt:      time.Now(),
	}, nil
}

func (f *SimplifyCodeFixer) GetCategory() FixCategory {
	return CategoryCodeQuality
}

func (f *SimplifyCodeFixer) GetConfidence() float64 {
	return 0.7
}

// FormatCodeFixer corrige les problèmes de formatage
type FormatCodeFixer struct{}

func (f *FormatCodeFixer) CanFix(issue StaticIssue) bool {
	formatKeywords := []string{"format", "spacing", "indent", "gofmt"}
	message := strings.ToLower(issue.Message)
	for _, keyword := range formatKeywords {
		if strings.Contains(message, keyword) {
			return true
		}
	}
	return false
}

func (f *FormatCodeFixer) GenerateFix(issue StaticIssue, fset *token.FileSet, file *ast.File) (*FixSuggestion, error) {
	// Appliquer gofmt au fichier entier
	var buf strings.Builder
	if err := format.Node(&buf, fset, file); err != nil {
		return nil, fmt.Errorf("failed to format code: %w", err)
	}

	return &FixSuggestion{
		Type:           FixTypeFormat,
		Description:    "Apply Go formatting (gofmt)",
		File:           issue.File,
		StartPos:       file.Pos(),
		EndPos:         file.End(),
		OriginalCode:   "<whole file>",
		ProposedCode:   buf.String(),
		Confidence:     0.99,
		Impact:         ImpactLow,
		Category:       CategoryStyle,
		AutoApplicable: true,
		RequiresReview: false,
		CreatedAt:      time.Now(),
	}, nil
}

func (f *FormatCodeFixer) GetCategory() FixCategory {
	return CategoryStyle
}

func (f *FormatCodeFixer) GetConfidence() float64 {
	return 0.99
}

// ErrorHandlingFixer améliore la gestion d'erreurs
type ErrorHandlingFixer struct{}

func (f *ErrorHandlingFixer) CanFix(issue StaticIssue) bool {
	errorKeywords := []string{"error", "err", "unchecked"}
	message := strings.ToLower(issue.Message)
	for _, keyword := range errorKeywords {
		if strings.Contains(message, keyword) {
			return true
		}
	}
	return false
}

func (f *ErrorHandlingFixer) GenerateFix(issue StaticIssue, fset *token.FileSet, file *ast.File) (*FixSuggestion, error) {
	// Localiser l'appel de fonction qui retourne une erreur non vérifiée
	var callExpr *ast.CallExpr
	ast.Inspect(file, func(n ast.Node) bool {
		if call, ok := n.(*ast.CallExpr); ok {
			pos := fset.Position(call.Pos())
			if pos.Line == issue.Line {
				callExpr = call
				return false
			}
		}
		return true
	})

	if callExpr == nil {
		return nil, fmt.Errorf("function call not found at line %d", issue.Line)
	}

	// Générer le code avec vérification d'erreur
	originalCode := issue.Context
	proposedCode := fmt.Sprintf(`%s
if err != nil {
	return err
}`, originalCode)

	return &FixSuggestion{
		Type:           FixTypeErrorHandling,
		Description:    "Add error check after function call",
		File:           issue.File,
		StartPos:       callExpr.Pos(),
		EndPos:         callExpr.End(),
		OriginalCode:   originalCode,
		ProposedCode:   proposedCode,
		Confidence:     0.6,
		Impact:         ImpactMedium,
		Category:       CategoryBugFix,
		AutoApplicable: false,
		RequiresReview: true,
		CreatedAt:      time.Now(),
	}, nil
}

func (f *ErrorHandlingFixer) GetCategory() FixCategory {
	return CategoryBugFix
}

func (f *ErrorHandlingFixer) GetConfidence() float64 {
	return 0.6
}

// NamingConventionFixer corrige les conventions de nommage
type NamingConventionFixer struct{}

func (f *NamingConventionFixer) CanFix(issue StaticIssue) bool {
	namingKeywords := []string{"naming", "convention", "exported", "should"}
	message := strings.ToLower(issue.Message)
	for _, keyword := range namingKeywords {
		if strings.Contains(message, keyword) {
			return true
		}
	}
	return false
}

func (f *NamingConventionFixer) GenerateFix(issue StaticIssue, fset *token.FileSet, file *ast.File) (*FixSuggestion, error) {
	// Implémentation basique pour les conventions de nommage
	return &FixSuggestion{
		Type:           FixTypeNaming,
		Description:    "Fix naming convention",
		File:           issue.File,
		StartPos:       issue.StartPos,
		EndPos:         issue.EndPos,
		OriginalCode:   issue.Context,
		ProposedCode:   issue.Context, // Nécessite une analyse plus poussée
		Confidence:     0.5,
		Impact:         ImpactLow,
		Category:       CategoryStyle,
		AutoApplicable: false,
		RequiresReview: true,
		CreatedAt:      time.Now(),
	}, nil
}

func (f *NamingConventionFixer) GetCategory() FixCategory {
	return CategoryStyle
}

func (f *NamingConventionFixer) GetConfidence() float64 {
	return 0.5
}

// AnalyzeCode analyses le code pour identifier les problèmes
func (se *SuggestionEngine) AnalyzeCode(ctx context.Context, filePath string) ([]*FixSuggestion, error) {
	// Parse the file
	fset := token.NewFileSet()
	file, err := parser.ParseFile(fset, filePath, nil, parser.ParseComments)
	if err != nil {
		return nil, fmt.Errorf("failed to parse file %s: %w", filePath, err)
	}

	var suggestions []*FixSuggestion

	// Basic static analysis - find unused variables
	ast.Inspect(file, func(n ast.Node) bool {
		switch node := n.(type) {
		case *ast.GenDecl:
			if node.Tok == token.VAR {
				for _, spec := range node.Specs {
					if valueSpec, ok := spec.(*ast.ValueSpec); ok {
						for _, name := range valueSpec.Names {
							if name.Name != "_" && !isUsed(file, name.Name) {
								suggestions = append(suggestions, &FixSuggestion{
									ID:             fmt.Sprintf("unused_var_%s_%d", name.Name, fset.Position(name.Pos()).Line),
									Type:           FixTypeRemoveUnused,
									Description:    fmt.Sprintf("Remove unused variable '%s'", name.Name),
									File:           filePath,
									FilePath:       filePath,
									StartPos:       name.Pos(),
									EndPos:         name.End(),
									LineNumbers:    []int{fset.Position(name.Pos()).Line},
									OriginalCode:   name.Name,
									ProposedCode:   "",
									Patterns:       []string{fmt.Sprintf("var %s", name.Name)},
									Replacements:   []string{""},
									Confidence:     0.9,
									SafetyLevel:    SafetyLevelHigh,
									Impact:         ImpactLow,
									Category:       CategoryCodeQuality,
									AutoApplicable: true,
									RequiresReview: false,
									Dependencies:   []string{},
									Metadata:       map[string]interface{}{"rule": "unused_variable"},
									CreatedAt:      time.Now(),
								})
							}
						}
					}
				}
			}
		}
		return true
	})

	return suggestions, nil
}

// isUsed checks if a variable is used in the AST (simplified implementation)
func isUsed(file *ast.File, varName string) bool {
	used := false
	ast.Inspect(file, func(n ast.Node) bool {
		if ident, ok := n.(*ast.Ident); ok && ident.Name == varName {
			used = true
			return false // Stop inspection
		}
		return true
	})
	return used
}
