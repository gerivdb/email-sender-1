// internal/hybrid/selector.go
package hybrid

import (
	"context"
	"fmt"
	"path/filepath"
	"strings"
	"time"

	"github.com/gerivdb/email-sender-1/development/managers/contextual-memory-manager/interfaces"
)

type ModeSelector struct {
	astManager    interfaces.ASTAnalysisManager
	ragRetriever  interfaces.RetrievalManager
	config        *interfaces.HybridConfig
	metrics       *HybridMetrics
	decisionCache *DecisionCache
}

type HybridMetrics struct {
	totalDecisions      int64
	modeDistribution    map[interfaces.AnalysisMode]int64
	averageDecisionTime time.Duration
	cacheHitRate        float64
	mu                  struct{}
}

type DecisionCache struct {
	entries map[string]*interfaces.ModeDecision
	ttl     time.Duration
	maxSize int
}

func NewModeSelector(astManager interfaces.ASTAnalysisManager, ragRetriever interfaces.RetrievalManager, config *interfaces.HybridConfig) *ModeSelector {
	return &ModeSelector{
		astManager:    astManager,
		ragRetriever:  ragRetriever,
		config:        config,
		metrics:       NewHybridMetrics(),
		decisionCache: NewDecisionCache(1000, config.DecisionCacheTTL),
	}
}

func NewHybridMetrics() *HybridMetrics {
	return &HybridMetrics{
		modeDistribution: make(map[interfaces.AnalysisMode]int64),
	}
}

func NewDecisionCache(maxSize int, ttl time.Duration) *DecisionCache {
	return &DecisionCache{
		entries: make(map[string]*interfaces.ModeDecision),
		ttl:     ttl,
		maxSize: maxSize,
	}
}

func (ms *ModeSelector) SelectOptimalMode(ctx context.Context, query interfaces.ContextQuery) (*interfaces.ModeDecision, error) {
	start := time.Now()

	// Créer une clé de cache pour la décision
	cacheKey := ms.buildCacheKey(query)

	// Vérifier le cache si activé
	if ms.config.CacheDecisions {
		if cached, found := ms.decisionCache.Get(cacheKey); found {
			cached.CacheHit = true
			cached.DecisionTime = time.Since(start)
			return cached, nil
		}
	}

	decision := &interfaces.ModeDecision{
		CacheHit:     false,
		DecisionTime: 0,
		Metadata:     make(map[string]interface{}),
	}

	// Analyse du contexte de la requête
	contextAnalysis := ms.analyzeQueryContext(query)
	decision.Metadata["context_analysis"] = contextAnalysis

	// Calculer les scores pour chaque mode
	astScore, astReasoning := ms.calculateASTScore(ctx, query, contextAnalysis)
	ragScore, ragReasoning := ms.calculateRAGScore(ctx, query, contextAnalysis)

	decision.ASTScore = astScore
	decision.RAGScore = ragScore
	decision.Reasoning = append(decision.Reasoning, astReasoning...)
	decision.Reasoning = append(decision.Reasoning, ragReasoning...)

	// Logique de sélection du mode
	if astScore >= ms.config.ASTThreshold && astScore > ragScore {
		decision.SelectedMode = interfaces.ModePureAST
		decision.Confidence = astScore
		decision.Reasoning = append(decision.Reasoning, "AST score exceeds threshold and outperforms RAG")
	} else if ragScore > astScore && ragScore >= ms.config.QualityScoreMin {
		decision.SelectedMode = interfaces.ModePureRAG
		decision.Confidence = ragScore
		decision.Reasoning = append(decision.Reasoning, "RAG score outperforms AST")
	} else if ms.shouldUseHybridMode(astScore, ragScore) {
		if astScore > ragScore {
			decision.SelectedMode = interfaces.ModeHybridASTFirst
			decision.Reasoning = append(decision.Reasoning, "Hybrid mode with AST priority")
		} else {
			decision.SelectedMode = interfaces.ModeHybridRAGFirst
			decision.Reasoning = append(decision.Reasoning, "Hybrid mode with RAG priority")
		}
		decision.HybridRecommended = true
		decision.Confidence = (astScore + ragScore) / 2
	} else {
		// Fallback à RAG si activé
		if ms.config.RAGFallbackEnabled {
			decision.SelectedMode = interfaces.ModePureRAG
			decision.Confidence = ragScore
			decision.Reasoning = append(decision.Reasoning, "Fallback to RAG mode")
		} else {
			decision.SelectedMode = interfaces.ModePureAST
			decision.Confidence = astScore
			decision.Reasoning = append(decision.Reasoning, "Default to AST mode")
		}
	}

	decision.DecisionTime = time.Since(start)

	// Mettre en cache la décision
	if ms.config.CacheDecisions {
		ms.decisionCache.Set(cacheKey, decision)
	}

	// Enregistrer les métriques
	ms.metrics.RecordDecision(decision)

	return decision, nil
}

func (ms *ModeSelector) buildCacheKey(query interfaces.ContextQuery) string {
	return fmt.Sprintf("%s:%s:%s:%d",
		query.QueryType,
		query.FilePath,
		query.Query[:min(len(query.Query), 50)],
		query.LineNumber)
}

func (ms *ModeSelector) analyzeQueryContext(query interfaces.ContextQuery) map[string]interface{} {
	context := make(map[string]interface{})

	// Analyser l'extension du fichier
	if query.FilePath != "" {
		ext := filepath.Ext(query.FilePath)
		context["file_extension"] = ext
		context["is_code_file"] = ms.isCodeFile(ext)
		context["is_documentation"] = ms.isDocumentationFile(ext)
	}

	// Analyser le type de requête
	context["query_type"] = query.QueryType
	context["query_length"] = len(query.Query)
	context["has_line_number"] = query.LineNumber > 0
	context["scope"] = query.Scope

	// Analyser la complexité de la requête
	complexity := ms.calculateQueryComplexity(query)
	context["complexity"] = complexity

	return context
}

func (ms *ModeSelector) calculateASTScore(ctx context.Context, query interfaces.ContextQuery, contextAnalysis map[string]interface{}) (float64, []string) {
	score := 0.0
	reasoning := make([]string, 0)

	// Score basé sur l'extension du fichier
	if ext, ok := contextAnalysis["file_extension"].(string); ok {
		for _, preferredExt := range ms.config.PreferAST {
			if ext == preferredExt {
				score += ms.config.WeightFactors.FileExtension
				reasoning = append(reasoning, fmt.Sprintf("File extension %s favors AST", ext))
				break
			}
		}
	}

	// Score basé sur le type de requête
	if query.QueryType == "function_search" || query.QueryType == "type_definition" || query.QueryType == "dependency_analysis" {
		score += ms.config.WeightFactors.QueryComplexity
		reasoning = append(reasoning, fmt.Sprintf("Query type %s benefits from AST", query.QueryType))
	}

	// Score basé sur la structure du code
	if isCodeFile, ok := contextAnalysis["is_code_file"].(bool); ok && isCodeFile {
		score += ms.config.WeightFactors.CodeStructure
		reasoning = append(reasoning, "Code file benefits from structural analysis")
	}

	// Score basé sur la ligne spécifique
	if query.LineNumber > 0 {
		score += 0.2
		reasoning = append(reasoning, "Line-specific query benefits from AST precision")
	}

	// Pénalité pour les fichiers de documentation
	if isDoc, ok := contextAnalysis["is_documentation"].(bool); ok && isDoc {
		score -= 0.3
		reasoning = append(reasoning, "Documentation file less suitable for AST")
	}

	// Normaliser le score entre 0 et 1
	score = min(1.0, max(0.0, score))

	return score, reasoning
}

func (ms *ModeSelector) calculateRAGScore(ctx context.Context, query interfaces.ContextQuery, contextAnalysis map[string]interface{}) (float64, []string) {
	score := 0.0
	reasoning := make([]string, 0)

	// Score basé sur l'extension du fichier
	if ext, ok := contextAnalysis["file_extension"].(string); ok {
		for _, preferredExt := range ms.config.PreferRAG {
			if ext == preferredExt {
				score += ms.config.WeightFactors.FileExtension
				reasoning = append(reasoning, fmt.Sprintf("File extension %s favors RAG", ext))
				break
			}
		}
	}

	// Score basé sur la documentation
	if isDoc, ok := contextAnalysis["is_documentation"].(bool); ok && isDoc {
		score += ms.config.WeightFactors.DocumentationRatio
		reasoning = append(reasoning, "Documentation file benefits from RAG")
	}

	// Score basé sur la complexité de la requête
	if complexity, ok := contextAnalysis["complexity"].(float64); ok && complexity > 0.7 {
		score += ms.config.WeightFactors.QueryComplexity
		reasoning = append(reasoning, "Complex query benefits from semantic search")
	}

	// Score basé sur le type de requête
	if query.QueryType == "semantic_search" || query.QueryType == "concept_search" || query.QueryType == "documentation_search" {
		score += 0.4
		reasoning = append(reasoning, fmt.Sprintf("Query type %s benefits from RAG", query.QueryType))
	}

	// Score pour les requêtes de scope large
	if query.Scope == "workspace" || query.Scope == "project" {
		score += 0.2
		reasoning = append(reasoning, "Wide scope benefits from vectorized search")
	}

	// Normaliser le score entre 0 et 1
	score = min(1.0, max(0.0, score))

	return score, reasoning
}

func (ms *ModeSelector) shouldUseHybridMode(astScore, ragScore float64) bool {
	scoreDiff := abs(astScore - ragScore)
	return scoreDiff < 0.2 && (astScore > 0.5 || ragScore > 0.5)
}

func (ms *ModeSelector) isCodeFile(ext string) bool {
	codeExtensions := []string{".go", ".js", ".ts", ".py", ".java", ".cpp", ".c", ".rs", ".rb", ".php"}
	for _, codeExt := range codeExtensions {
		if ext == codeExt {
			return true
		}
	}
	return false
}

func (ms *ModeSelector) isDocumentationFile(ext string) bool {
	docExtensions := []string{".md", ".txt", ".rst", ".adoc", ".wiki"}
	for _, docExt := range docExtensions {
		if ext == docExt {
			return true
		}
	}
	return false
}

func (ms *ModeSelector) calculateQueryComplexity(query interfaces.ContextQuery) float64 {
	complexity := 0.0

	// Longueur de la requête
	if len(query.Query) > 100 {
		complexity += 0.3
	} else if len(query.Query) > 50 {
		complexity += 0.2
	} else if len(query.Query) > 20 {
		complexity += 0.1
	}

	// Nombre de mots
	words := strings.Fields(query.Query)
	if len(words) > 10 {
		complexity += 0.2
	} else if len(words) > 5 {
		complexity += 0.1
	}

	// Présence de caractères spéciaux ou patterns de code
	if strings.Contains(query.Query, "(") || strings.Contains(query.Query, "{") || strings.Contains(query.Query, ".") {
		complexity += 0.3
	}

	// Filtres complexes
	if len(query.Filters.FileExtensions) > 0 || len(query.Filters.Packages) > 0 {
		complexity += 0.2
	}

	return min(1.0, complexity)
}

// Méthodes du cache de décisions
func (dc *DecisionCache) Get(key string) (*interfaces.ModeDecision, bool) {
	decision, exists := dc.entries[key]
	if !exists {
		return nil, false
	}

	// Vérifier si l'entrée est expirée
	if time.Since(decision.Timestamp) > dc.ttl {
		delete(dc.entries, key)
		return nil, false
	}

	return decision, true
}

func (dc *DecisionCache) Set(key string, decision *interfaces.ModeDecision) {
	// Nettoyer le cache si trop plein
	if len(dc.entries) >= dc.maxSize {
		dc.evictOldest()
	}

	decision.Timestamp = time.Now()
	dc.entries[key] = decision
}

func (dc *DecisionCache) evictOldest() {
	var oldestKey string
	var oldestTime time.Time
	first := true

	for key, decision := range dc.entries {
		if first {
			oldestKey = key
			oldestTime = decision.Timestamp
			first = false
		} else if decision.Timestamp.Before(oldestTime) {
			oldestKey = key
			oldestTime = decision.Timestamp
		}
	}

	if oldestKey != "" {
		delete(dc.entries, oldestKey)
	}
}

// Méthodes des métriques
func (hm *HybridMetrics) RecordDecision(decision *interfaces.ModeDecision) {
	hm.totalDecisions++
	hm.modeDistribution[decision.SelectedMode]++

	// Calculer la moyenne mobile du temps de décision
	if hm.averageDecisionTime == 0 {
		hm.averageDecisionTime = decision.DecisionTime
	} else {
		hm.averageDecisionTime = (hm.averageDecisionTime + decision.DecisionTime) / 2
	}
}

// Fonctions utilitaires
func min(a, b float64) float64 {
	if a < b {
		return a
	}
	return b
}

func max(a, b float64) float64 {
	if a > b {
		return a
	}
	return b
}

func abs(x float64) float64 {
	if x < 0 {
		return -x
	}
	return x
}
