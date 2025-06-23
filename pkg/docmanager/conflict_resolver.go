// SPDX-License-Identifier: MIT
// Package docmanager - Conflict Resolver SRP Implementation
package docmanager

import (
	"fmt"
	"regexp"
	"sort"
	"time"
)

// ConflictType types de conflits documentaires
type ConflictType string

const (
	ContentConflict  ConflictType = "content"
	MetadataConflict ConflictType = "metadata"
	VersionConflict  ConflictType = "version"
	PathConflict     ConflictType = "path"
)

// 3.6.1.3 Type ConflictType enum (Path, Content, Version, Permission)
type ConflictTypeEnum int

const (
	ConflictTypePath ConflictTypeEnum = iota
	ConflictTypeContent
	ConflictTypeVersion
	ConflictTypePermission
)

// ResolutionStrategy stratégie de résolution de conflit
type ResolutionStrategy interface {
	Resolve(conflict *DocumentConflict) (*Resolution, error)
	CanHandle(conflictType ConflictType) bool
	Priority() int
}

// DocumentConflict représente un conflit entre documents
type DocumentConflict struct {
	ID           string
	Type         ConflictType
	LocalDoc     *Document
	RemoteDoc    *Document
	ConflictedAt time.Time
	Context      map[string]interface{}
}

// Document structure de document (simplifiée)
type Document struct {
	ID       string
	Path     string
	Content  []byte
	Metadata map[string]interface{}
	Version  int
}

// Resolution résultat de résolution de conflit
type Resolution struct {
	ResolvedDoc *Document
	Strategy    string
	Confidence  float64
	Metadata    map[string]interface{}
}

// ConflictResolver - SRP: Résolution de conflits uniquement
// Adapte strategies pour supporter plusieurs stratégies par type
// et ajoute la gestion des priorités

type ConflictResolver struct {
	strategies      map[ConflictType][]ResolutionStrategy
	defaultStrategy ResolutionStrategy
}

// NewConflictResolver constructeur respectant SRP
func NewConflictResolver() *ConflictResolver {
	resolver := &ConflictResolver{
		strategies: make(map[ConflictType][]ResolutionStrategy),
	}
	// Ajoute les stratégies par défaut avec priorités
	resolver.strategies[ContentConflict] = []ResolutionStrategy{
		&ContentMergeStrategy{},
		&QualityBasedStrategy{MinScore: 100},
	}
	resolver.strategies[MetadataConflict] = []ResolutionStrategy{&MetadataPreferenceStrategy{}}
	resolver.strategies[VersionConflict] = []ResolutionStrategy{&VersionBasedStrategy{}}
	resolver.strategies[PathConflict] = []ResolutionStrategy{
		&PathRenameStrategy{},
		&UserPromptStrategy{Prompter: nil},
	}
	resolver.defaultStrategy = &ManualResolutionStrategy{}
	return resolver
}

// Ajoute une stratégie pour un type de conflit
func (cr *ConflictResolver) AddStrategy(conflictType ConflictType, strategy ResolutionStrategy) {
	cr.strategies[conflictType] = append(cr.strategies[conflictType], strategy)
}

// Résout un conflit en choisissant la stratégie de plus haute priorité pouvant le gérer
func (cr *ConflictResolver) ResolveConflict(conflict *DocumentConflict) (*Resolution, error) {
	if conflict == nil {
		return nil, fmt.Errorf("conflict cannot be nil")
	}
	strategies := cr.strategies[conflict.Type]
	if len(strategies) == 0 {
		return cr.defaultStrategy.Resolve(conflict)
	}
	// Trie par priorité décroissante
	highest := strategies[0]
	for _, s := range strategies {
		if s.CanHandle(conflict.Type) && s.Priority() > highest.Priority() {
			highest = s
		}
	}
	return highest.Resolve(conflict)
}

// SetStrategy configure une stratégie pour un type de conflit
func (cr *ConflictResolver) SetStrategy(conflictType ConflictType, strategy ResolutionStrategy) {
	cr.strategies[conflictType] = []ResolutionStrategy{strategy}
}

// Sélectionne la meilleure stratégie pour un type de conflit donné
func (cr *ConflictResolver) selectOptimalStrategy(conflictType ConflictType) ResolutionStrategy {
	strategies := cr.strategies[conflictType]
	if len(strategies) == 0 {
		return cr.defaultStrategy
	}
	sort.Slice(strategies, func(i, j int) bool {
		return strategies[i].Priority() > strategies[j].Priority()
	})
	return strategies[0]
}

// Stratégies concrètes implémentant ResolutionStrategy

// ContentMergeStrategy fusionne le contenu
type ContentMergeStrategy struct{}

func (cms *ContentMergeStrategy) Resolve(conflict *DocumentConflict) (*Resolution, error) {
	// TODO: Implémenter fusion intelligente du contenu
	return &Resolution{
		ResolvedDoc: conflict.LocalDoc,
		Strategy:    "content_merge",
		Confidence:  0.8,
		Metadata:    map[string]interface{}{"merged": true},
	}, nil
}
func (cms *ContentMergeStrategy) CanHandle(conflictType ConflictType) bool {
	return conflictType == ContentConflict
}
func (cms *ContentMergeStrategy) Priority() int {
	return 10
}

// MetadataPreferenceStrategy privilégie certaines métadonnées
type MetadataPreferenceStrategy struct{}

func (mps *MetadataPreferenceStrategy) Resolve(conflict *DocumentConflict) (*Resolution, error) {
	// TODO: Implémenter logique de préférence métadonnées
	return &Resolution{
		ResolvedDoc: conflict.RemoteDoc,
		Strategy:    "metadata_preference",
		Confidence:  0.9,
		Metadata:    map[string]interface{}{"preferred": "remote"},
	}, nil
}
func (mps *MetadataPreferenceStrategy) CanHandle(conflictType ConflictType) bool {
	return conflictType == MetadataConflict
}
func (mps *MetadataPreferenceStrategy) Priority() int {
	return 8
}

// VersionBasedStrategy résout selon les versions
type VersionBasedStrategy struct{}

func (vbs *VersionBasedStrategy) Resolve(conflict *DocumentConflict) (*Resolution, error) {
	var resolvedDoc *Document
	if conflict.LocalDoc.Version > conflict.RemoteDoc.Version {
		resolvedDoc = conflict.LocalDoc
	} else {
		resolvedDoc = conflict.RemoteDoc
	}

	return &Resolution{
		ResolvedDoc: resolvedDoc,
		Strategy:    "version_based",
		Confidence:  0.95,
		Metadata:    map[string]interface{}{"version_winner": resolvedDoc.Version},
	}, nil
}
func (vbs *VersionBasedStrategy) CanHandle(conflictType ConflictType) bool {
	return conflictType == VersionConflict
}
func (vbs *VersionBasedStrategy) Priority() int {
	return 7
}

// PathRenameStrategy renomme en cas de conflit de chemin
type PathRenameStrategy struct{}

func (prs *PathRenameStrategy) Resolve(conflict *DocumentConflict) (*Resolution, error) {
	// TODO: Implémenter logique de renommage intelligent
	return &Resolution{
		ResolvedDoc: conflict.LocalDoc,
		Strategy:    "path_rename",
		Confidence:  0.7,
		Metadata:    map[string]interface{}{"renamed": true},
	}, nil
}
func (prs *PathRenameStrategy) CanHandle(conflictType ConflictType) bool {
	return conflictType == PathConflict
}
func (prs *PathRenameStrategy) Priority() int {
	return 5
}

// ManualResolutionStrategy nécessite intervention manuelle
type ManualResolutionStrategy struct{}

func (mrs *ManualResolutionStrategy) Resolve(conflict *DocumentConflict) (*Resolution, error) {
	return &Resolution{
		ResolvedDoc: nil,
		Strategy:    "manual",
		Confidence:  0.0,
		Metadata:    map[string]interface{}{"requires_manual": true},
	}, nil
}
func (mrs *ManualResolutionStrategy) CanHandle(conflictType ConflictType) bool {
	return true // fallback
}
func (mrs *ManualResolutionStrategy) Priority() int {
	return 0
}

// QualityBasedStrategy sélectionne selon un score qualité
type QualityBasedStrategy struct {
	MinScore float64
}

func (qbs *QualityBasedStrategy) Resolve(conflict *DocumentConflict) (*Resolution, error) {
	scoreA := calculateQualityScore(conflict.LocalDoc)
	scoreB := calculateQualityScore(conflict.RemoteDoc)
	var winner, loser *Document
	var winnerScore, loserScore float64
	if scoreA >= scoreB {
		winner, loser = conflict.LocalDoc, conflict.RemoteDoc
		winnerScore, loserScore = scoreA, scoreB
	} else {
		winner, loser = conflict.RemoteDoc, conflict.LocalDoc
		winnerScore, loserScore = scoreB, scoreA
	}
	if winnerScore < qbs.MinScore {
		// Fallback : score trop faible, résolution manuelle
		return (&ManualResolutionStrategy{}).Resolve(conflict)
	}
	// Fusion métadonnées du perdant
	winner.Metadata = mergeMetadata(winner.Metadata, loser.Metadata)
	return &Resolution{
		ResolvedDoc: winner,
		Strategy:    "quality_based",
		Confidence:  winnerScore / (winnerScore + loserScore + 1e-6),
		Metadata:    map[string]interface{}{ "winner": winner.ID, "loser": loser.ID, "scoreA": scoreA, "scoreB": scoreB },
	}, nil
}
func (qbs *QualityBasedStrategy) CanHandle(conflictType ConflictType) bool {
	return conflictType == ContentConflict
}
func (qbs *QualityBasedStrategy) Priority() int {
	return 9
}

// UserPromptStrategy demande à l'utilisateur
type UserPrompter interface {
	PromptUser(conflict *DocumentConflict) (choice string, err error)
}

type UserPromptStrategy struct {
	Prompter UserPrompter
}

func (ups *UserPromptStrategy) Resolve(conflict *DocumentConflict) (*Resolution, error) {
	if ups.Prompter == nil {
		return (&ManualResolutionStrategy{}).Resolve(conflict)
	}
	choice, err := ups.Prompter.PromptUser(conflict)
	if err != nil {
		return (&ManualResolutionStrategy{}).Resolve(conflict)
	}
	var winner, loser *Document
	if choice == "local" {
		winner, loser = conflict.LocalDoc, conflict.RemoteDoc
	} else if choice == "remote" {
		winner, loser = conflict.RemoteDoc, conflict.LocalDoc
	} else {
		return (&ManualResolutionStrategy{}).Resolve(conflict)
	}
	winner.Metadata = mergeMetadata(winner.Metadata, loser.Metadata)
	return &Resolution{
		ResolvedDoc: winner,
		Strategy:    "user_prompt",
		Confidence:  1.0,
		Metadata:    map[string]interface{}{ "winner": winner.ID, "loser": loser.ID, "choice": choice },
	}, nil
}
func (ups *UserPromptStrategy) CanHandle(conflictType ConflictType) bool {
	return conflictType == PathConflict
}
func (ups *UserPromptStrategy) Priority() int {
	return 4
}

// mergeMetadata fusionne les métadonnées de deux documents en préservant les clés de A et complétant avec celles de B
func mergeMetadata(metaA, metaB map[string]interface{}) map[string]interface{} {
	merged := make(map[string]interface{})
	for k, v := range metaA {
		merged[k] = v
	}
	for k, v := range metaB {
		if _, exists := merged[k]; !exists {
			merged[k] = v
		}
	}
	return merged
}

// calculateQualityScore calcule un score qualité
func calculateQualityScore(doc *Document) float64 {
	if doc == nil || len(doc.Content) == 0 {
		return 0
	}
	text := string(doc.Content)
	wordCount := float64(len(splitWords(text)))
	structureScore := float64(countHeaders(text)) * 2
	linkScore := float64(countLinks(text)) * 1.5
	imageScore := float64(countImages(text)) * 2
	return wordCount + structureScore + linkScore + imageScore
}

func splitWords(text string) []string {
	return regexp.MustCompile(`\w+`).FindAllString(text, -1)
}

func countHeaders(text string) int {
	return len(regexp.MustCompile(`(?m)^#{1,6} `).FindAllString(text, -1))
}

func countLinks(text string) int {
	return len(regexp.MustCompile(`https?://\S+`).FindAllString(text, -1))
}

func countImages(text string) int {
	return len(regexp.MustCompile(`!\[.*?\]\(.*?\)`).FindAllString(text, -1))
}

// AutoMergeStrategy tente une fusion automatique
type AutoMergeStrategy struct{}

func (ams *AutoMergeStrategy) Resolve(conflict *DocumentConflict) (*Resolution, error) {
	merged, ok := tryAutoMerge(conflict.LocalDoc, conflict.RemoteDoc)
	if ok {
		return &Resolution{
			ResolvedDoc: merged,
			Strategy:    "auto_merge",
			Confidence:  1.0,
			Metadata:    map[string]interface{}{ "merged": true },
		}, nil
	}
	return (&ManualResolutionStrategy{}).Resolve(conflict)
}
func (ams *AutoMergeStrategy) CanHandle(conflictType ConflictType) bool {
	return conflictType == ContentConflict
}
func (ams *AutoMergeStrategy) Priority() int {
	return 11
}

func tryAutoMerge(docA, docB *Document) (*Document, bool) {
	if string(docA.Content) == string(docB.Content) {
		return docA, true
	}
	linesA := splitLines(string(docA.Content))
	linesB := splitLines(string(docB.Content))
	lineSet := make(map[string]struct{})
	for _, l := range linesA {
		lineSet[l] = struct{}{}
	}
	for _, l := range linesB {
		if _, exists := lineSet[l]; exists {
			return nil, false
		}
	}
	merged := &Document{
		ID:       docA.ID + "+" + docB.ID,
		Content:  []byte(string(docA.Content) + "\n" + string(docB.Content)),
		Metadata: mergeMetadata(docA.Metadata, docB.Metadata),
		Version:  max(docA.Version, docB.Version),
	}
	return merged, true
}

func splitLines(text string) []string {
	return regexp.MustCompile(`\r?\n`).Split(text, -1)
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}
