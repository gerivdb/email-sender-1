package ai

import (
	"math"
	"strings"

	"github.com/gerivdb/email-sender-1/development/managers/ai-template-manager/interfaces"
)

// SimilarityScorer implements semantic matching algorithms for templates
type SimilarityScorer struct{}

// NewSimilarityScorer creates a new similarity scorer instance
func NewSimilarityScorer() *SimilarityScorer {
	return &SimilarityScorer{}
}

// CalculateSimilarity calculates similarity between two templates
func (ss *SimilarityScorer) CalculateSimilarity(template1, template2 *interfaces.Template) float64 {
	if template1 == nil || template2 == nil {
		return 0.0
	}

	// Calculate content similarity using Levenshtein distance
	contentSimilarity := ss.calculateContentSimilarity(template1.Content, template2.Content)

	// Calculate variable compatibility
	variableCompatibility := ss.calculateVariableCompatibility(template1.Variables, template2.Variables)

	// Calculate metadata similarity
	metadataSimilarity := ss.calculateMetadataSimilarity(template1.Metadata, template2.Metadata)

	// Weighted combination of similarities
	similarity := contentSimilarity*0.5 + variableCompatibility*0.3 + metadataSimilarity*0.2

	return math.Min(math.Max(similarity, 0.0), 1.0)
}

// LevenshteinDistance calculates the Levenshtein distance between two strings
func (ss *SimilarityScorer) LevenshteinDistance(a, b string) int {
	if len(a) == 0 {
		return len(b)
	}
	if len(b) == 0 {
		return len(a)
	}

	matrix := make([][]int, len(a)+1)
	for i := range matrix {
		matrix[i] = make([]int, len(b)+1)
	}

	for i := 0; i <= len(a); i++ {
		matrix[i][0] = i
	}
	for j := 0; j <= len(b); j++ {
		matrix[0][j] = j
	}

	for i := 1; i <= len(a); i++ {
		for j := 1; j <= len(b); j++ {
			cost := 0
			if a[i-1] != b[j-1] {
				cost = 1
			}
			matrix[i][j] = min(
				matrix[i-1][j]+1,      // deletion
				matrix[i][j-1]+1,      // insertion
				matrix[i-1][j-1]+cost, // substitution
			)
		}
	}

	return matrix[len(a)][len(b)]
}

// calculateContentSimilarity calculates similarity based on template content
func (ss *SimilarityScorer) calculateContentSimilarity(content1, content2 string) float64 {
	if content1 == content2 {
		return 1.0
	}

	distance := ss.LevenshteinDistance(content1, content2)
	maxLen := math.Max(float64(len(content1)), float64(len(content2)))

	if maxLen == 0 {
		return 1.0
	}

	similarity := 1.0 - (float64(distance) / maxLen)
	return math.Max(similarity, 0.0)
}

// calculateVariableCompatibility calculates compatibility between variable sets
func (ss *SimilarityScorer) calculateVariableCompatibility(vars1, vars2 map[string]interfaces.VariableInfo) float64 {
	if len(vars1) == 0 && len(vars2) == 0 {
		return 1.0
	}

	if len(vars1) == 0 || len(vars2) == 0 {
		return 0.0
	}

	commonVars := 0
	compatibleTypes := 0
	totalVars := len(vars1) + len(vars2)

	// Count common variables and type compatibility
	for name1, info1 := range vars1 {
		if info2, exists := vars2[name1]; exists {
			commonVars++
			if ss.areTypesCompatible(info1.Type, info2.Type) {
				compatibleTypes++
			}
		}
	}

	if commonVars == 0 {
		return 0.0
	}

	// Calculate compatibility score
	nameCompatibility := float64(commonVars*2) / float64(totalVars)
	typeCompatibility := float64(compatibleTypes) / float64(commonVars)

	return (nameCompatibility + typeCompatibility) / 2.0
}

// calculateMetadataSimilarity calculates similarity based on template metadata
func (ss *SimilarityScorer) calculateMetadataSimilarity(meta1, meta2 interfaces.TemplateMetadata) float64 {
	similarities := []float64{}

	// Category similarity
	if meta1.Category == meta2.Category {
		similarities = append(similarities, 1.0)
	} else {
		similarities = append(similarities, 0.0)
	}
	// Tags similarity (Jaccard similarity)
	tagSimilarity := ss.CalculateJaccardSimilarity(meta1.Tags, meta2.Tags)
	similarities = append(similarities, tagSimilarity)

	// Author similarity
	if meta1.Author == meta2.Author {
		similarities = append(similarities, 1.0)
	} else {
		similarities = append(similarities, 0.0)
	}

	// Version similarity (semantic version comparison could be added)
	if meta1.Version == meta2.Version {
		similarities = append(similarities, 1.0)
	} else {
		similarities = append(similarities, 0.5) // Partial credit for different versions
	}

	// Average all similarities
	sum := 0.0
	for _, sim := range similarities {
		sum += sim
	}
	return sum / float64(len(similarities))
}

// CalculateJaccardSimilarity calculates Jaccard similarity between two string slices
func (ss *SimilarityScorer) CalculateJaccardSimilarity(set1, set2 []string) float64 {
	if len(set1) == 0 && len(set2) == 0 {
		return 1.0
	}

	// Convert to maps for faster lookup
	map1 := make(map[string]bool)
	map2 := make(map[string]bool)

	for _, item := range set1 {
		map1[strings.ToLower(item)] = true
	}
	for _, item := range set2 {
		map2[strings.ToLower(item)] = true
	}

	// Calculate intersection and union
	intersection := 0
	union := make(map[string]bool)

	for item := range map1 {
		union[item] = true
		if map2[item] {
			intersection++
		}
	}

	for item := range map2 {
		union[item] = true
	}

	if len(union) == 0 {
		return 1.0
	}

	return float64(intersection) / float64(len(union))
}

// areTypesCompatible checks if two variable types are compatible
func (ss *SimilarityScorer) areTypesCompatible(type1, type2 string) bool {
	// Normalize types
	type1 = strings.ToLower(strings.TrimSpace(type1))
	type2 = strings.ToLower(strings.TrimSpace(type2))

	if type1 == type2 {
		return true
	}

	// Define type compatibility groups
	numericTypes := map[string]bool{
		"int": true, "int32": true, "int64": true,
		"float": true, "float32": true, "float64": true,
		"number": true, "numeric": true,
	}

	stringTypes := map[string]bool{
		"string": true, "text": true, "str": true,
	}

	boolTypes := map[string]bool{
		"bool": true, "boolean": true,
	}

	// Check compatibility within groups
	if numericTypes[type1] && numericTypes[type2] {
		return true
	}
	if stringTypes[type1] && stringTypes[type2] {
		return true
	}
	if boolTypes[type1] && boolTypes[type2] {
		return true
	}

	// Interface{} is compatible with everything
	if type1 == "interface{}" || type2 == "interface{}" {
		return true
	}

	return false
}

// CalculateSemanticWeight calculates semantic weight between templates with enhanced analysis
func (ss *SimilarityScorer) CalculateSemanticWeight(template1, template2 *interfaces.Template) float64 {
	if template1 == nil || template2 == nil {
		return 0.0
	}

	// Basic similarity
	basicSimilarity := ss.CalculateSimilarity(template1, template2)

	// Enhanced semantic analysis
	structuralSimilarity := ss.calculateStructuralSimilarity(template1.Content, template2.Content)
	functionalSimilarity := ss.calculateFunctionalSimilarity(template1, template2)

	// Weighted combination with semantic enhancements
	semanticWeight := basicSimilarity*0.4 + structuralSimilarity*0.3 + functionalSimilarity*0.3

	return math.Min(math.Max(semanticWeight, 0.0), 1.0)
}

// calculateStructuralSimilarity analyzes structural patterns in content
func (ss *SimilarityScorer) calculateStructuralSimilarity(content1, content2 string) float64 { // Extract structural patterns (simplified)
	patterns1 := ss.extractStructuralPatterns(content1)
	patterns2 := ss.extractStructuralPatterns(content2)

	return ss.CalculateJaccardSimilarity(patterns1, patterns2)
}

// calculateFunctionalSimilarity analyzes functional similarity
func (ss *SimilarityScorer) calculateFunctionalSimilarity(template1, template2 *interfaces.Template) float64 {
	// Compare usage patterns, performance characteristics, etc.
	usageSimilarity := float64(template1.Metadata.UsageCount) / math.Max(float64(template1.Metadata.UsageCount+template2.Metadata.UsageCount), 1.0)

	// Performance similarity
	perf1 := template1.Metadata.PerformanceInfo
	perf2 := template2.Metadata.PerformanceInfo
	perfSimilarity := 1.0 - math.Abs(perf1.OptimizationScore-perf2.OptimizationScore)

	return (usageSimilarity + perfSimilarity) / 2.0
}

// extractStructuralPatterns extracts structural patterns from content
func (ss *SimilarityScorer) extractStructuralPatterns(content string) []string {
	patterns := []string{}

	// Simple pattern extraction (could be enhanced with AST analysis)
	if strings.Contains(content, "func ") {
		patterns = append(patterns, "function")
	}
	if strings.Contains(content, "type ") {
		patterns = append(patterns, "type_definition")
	}
	if strings.Contains(content, "interface") {
		patterns = append(patterns, "interface")
	}
	if strings.Contains(content, "struct") {
		patterns = append(patterns, "struct")
	}
	if strings.Contains(content, "for ") || strings.Contains(content, "range ") {
		patterns = append(patterns, "loop")
	}
	if strings.Contains(content, "if ") {
		patterns = append(patterns, "conditional")
	}

	return patterns
}

// min returns the minimum of three integers
func min(a, b, c int) int {
	if a < b {
		if a < c {
			return a
		}
		return c
	}
	if b < c {
		return b
	}
	return c
}
