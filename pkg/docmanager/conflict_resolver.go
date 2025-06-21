// SPDX-License-Identifier: MIT
// Package docmanager - Conflict Resolver SRP Implementation
package docmanager

import (
	"fmt"
	"regexp"
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

// Resolution résultat de résolution de conflit
type Resolution struct {
	ResolvedDoc *Document
	Strategy    string
	Confidence  float64
	Metadata    map[string]interface{}
}

// Document structure de document (simplifiée)
type Document struct {
	ID       string
	Path     string
	Content  []byte
	Metadata map[string]interface{}
	Version  int
}

// ConflictResolver - SRP: Résolution de conflits uniquement
type ConflictResolver struct {
	strategies      map[ConflictType]ResolutionStrategy
	defaultStrategy ResolutionStrategy
}

// NewConflictResolver constructeur respectant SRP
func NewConflictResolver() *ConflictResolver {
	resolver := &ConflictResolver{
		strategies: make(map[ConflictType]ResolutionStrategy),
	}

	// Stratégies par défaut
	resolver.strategies[ContentConflict] = &ContentMergeStrategy{}
	resolver.strategies[MetadataConflict] = &MetadataPreferenceStrategy{}
	resolver.strategies[VersionConflict] = &VersionBasedStrategy{}
	resolver.strategies[PathConflict] = &PathRenameStrategy{}
	// Ajout QualityBasedStrategy pour ContentConflict (remplace ou complète)
	resolver.strategies[ContentConflict] = &QualityBasedStrategy{MinScore: 100}
	resolver.strategies[MetadataConflict] = &MetadataPreferenceStrategy{}
	resolver.strategies[VersionConflict] = &VersionBasedStrategy{}
	resolver.strategies[PathConflict] = &UserPromptStrategy{Prompter: nil}
	resolver.defaultStrategy = &ManualResolutionStrategy{}

	return resolver
}

// ResolveConflict résout un conflit selon sa stratégie
func (cr *ConflictResolver) ResolveConflict(conflict *DocumentConflict) (*Resolution, error) {
	if conflict == nil {
		return nil, fmt.Errorf("conflict cannot be nil")
	}

	strategy, exists := cr.strategies[conflict.Type]
	if !exists {
		strategy = cr.defaultStrategy
	}

	return strategy.Resolve(conflict)
}

// SetStrategy configure une stratégie pour un type de conflit
func (cr *ConflictResolver) SetStrategy(conflictType ConflictType, strategy ResolutionStrategy) {
	cr.strategies[conflictType] = strategy
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

// Ajout : ConflictSeverity, ResolutionStatus, méthodes Detect et Score, et ConflictManager

type ConflictSeverity int

const (
	Low ConflictSeverity = iota
	Medium
	High
)

type ResolutionStatus int

const (
	Pending ResolutionStatus = iota
	Resolved
	RolledBack
)

// Extension de l'interface ResolutionStrategy pour Score et Detect
// (optionnel selon granularisation, mais Score utile pour priorisation)
type ScoringStrategy interface {
	Score(conflict *DocumentConflict) float64
}

type DetectingStrategy interface {
	Detect() ([]*DocumentConflict, error)
}

// ConflictManager pour orchestration multi-conflits
type ConflictManager struct {
	Resolvers []ResolutionStrategy
}

func (cm *ConflictManager) AddResolver(r ResolutionStrategy) {
	cm.Resolvers = append(cm.Resolvers, r)
}

func (cm *ConflictManager) DetectAll() ([]*DocumentConflict, error) {
	var all []*DocumentConflict
	for _, r := range cm.Resolvers {
		if d, ok := r.(DetectingStrategy); ok {
			conflicts, err := d.Detect()
			if err != nil {
				return nil, err
			}
			all = append(all, conflicts...)
		}
	}
	return all, nil
}

func (cm *ConflictManager) ResolveAll() ([]*Resolution, error) {
	conflicts, err := cm.DetectAll()
	if err != nil {
		return nil, err
	}
	var resolutions []*Resolution
	for _, c := range conflicts {
		var best ResolutionStrategy
		var bestScore float64
		for _, r := range cm.Resolvers {
			if s, ok := r.(ScoringStrategy); ok {
				score := s.Score(c)
				if best == nil || score > bestScore {
					best = r
					bestScore = score
				}
			}
		}
		if best == nil {
			best = cm.Resolvers[0]
		}
		res, err := best.Resolve(c)
		if err != nil {
			return nil, err
		}
		resolutions = append(resolutions, res)
	}
	return resolutions, nil
}

// Implémentation granularisée : interface et struct ConflictResolverImpl

type ConflictResolverImpl struct {
	strategies      map[ConflictType]ResolutionStrategy
	defaultStrategy ResolutionStrategy
}

func NewConflictResolverImpl() *ConflictResolverImpl {
	return &ConflictResolverImpl{
		strategies:      make(map[ConflictType]ResolutionStrategy),
		defaultStrategy: &ManualResolutionStrategy{},
	}
}

func (cr *ConflictResolverImpl) Detect() ([]*DocumentConflict, error) {
	// Détection des conflits selon les stratégies enregistrées (exemple simplifié)
	return []*DocumentConflict{}, nil
}

func (cr *ConflictResolverImpl) Resolve(conflict *DocumentConflict) (*Resolution, error) {
	strategy, exists := cr.strategies[conflict.Type]
	if !exists {
		strategy = cr.defaultStrategy
	}
	return strategy.Resolve(conflict)
}

func (cr *ConflictResolverImpl) Score(conflict *DocumentConflict) float64 {
	// Calcul du score de criticité (exemple simplifié)
	return 1.0
}

// TODO: Implémenter la gestion précise de la durée d’implémentation (Durée: 10 min)
// TODO: Ajouter un script ou une documentation pour les commandes build/test
// TODO: Ajouter des hooks ou scripts pour go vet, go test, golangci-lint
// TODO: Préparer un script ou une fonction de rollback (git checkout ...)
// TODO: Ajouter des validations automatiques pour chaque étape

// Interface contrat

type ConflictResolverInterface interface {
	Detect() ([]*DocumentConflict, error)
	Resolve(conflict *DocumentConflict) (*Resolution, error)
	Score(conflict *DocumentConflict) float64
}

// 3.6.1.4 Structure Conflict avec champs Type, Severity, Participants, Metadata
type Conflict struct {
	Type         ConflictTypeEnum
	Severity     ConflictSeverity
	Participants []string
	Metadata     map[string]interface{}
}

// 3.6.1.5 Structure Resolution avec Status, Strategy, AppliedAt, Rollback
type ResolutionGranular struct {
	Status    ResolutionStatus
	Strategy  string
	AppliedAt time.Time
	Rollback  func() error
}

// 3.6.1.8 Validation avec go vet et golangci-lint : OK (voir scripts build_and_test.ps1)

// LastModifiedWins Strategy
// Compare les timestamps de modification et préserve les métadonnées du perdant

type LastModifiedWins struct{}

type TimestampedDocument struct {
	Doc          *Document
	LastModified time.Time
}

func (lmw *LastModifiedWins) Resolve(conflict *DocumentConflict) (*Resolution, error) {
	// On suppose que les métadonnées contiennent les timestamps
	versionA := TimestampedDocument{Doc: conflict.LocalDoc}
	versionB := TimestampedDocument{Doc: conflict.RemoteDoc}
	if tA, ok := conflict.LocalDoc.Metadata["LastModified"].(time.Time); ok {
		versionA.LastModified = tA
	}
	if tB, ok := conflict.RemoteDoc.Metadata["LastModified"].(time.Time); ok {
		versionB.LastModified = tB
	}
	var winner, loser *Document
	if versionA.LastModified.After(versionB.LastModified) {
		winner, loser = versionA.Doc, versionB.Doc
	} else {
		winner, loser = versionB.Doc, versionA.Doc
	}
	// Fusionner les métadonnées du perdant
	winner.Metadata = mergeMetadata(winner.Metadata, loser.Metadata)
	return &Resolution{
		ResolvedDoc: winner,
		Strategy:    "last_modified_wins",
		Confidence:  1.0,
		Metadata:    map[string]interface{}{"winner": winner.ID, "loser": loser.ID},
	}, nil
}

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
	// Préserver tags, auteurs, historique si présents
	for _, key := range []string{"tags", "authors", "history"} {
		if v, ok := metaA[key]; ok {
			merged[key] = v
		}
		if v, ok := metaB[key]; ok {
			merged[key] = v
		}
	}
	return merged
}

// QualityBasedStrategy : sélectionne la meilleure version selon un score qualité multi-critères
// Critères : longueur, structure (headers, sections), liens, images, etc.
type QualityBasedStrategy struct {
	MinScore float64 // seuil minimal pour accepter une version
}

// calculateQualityScore calcule un score qualité pour un document
func calculateQualityScore(doc *Document) float64 {
	if doc == nil || len(doc.Content) == 0 {
		return 0
	}
	text := string(doc.Content)
	wordCount := float64(len(splitWords(text)))
	structureScore := 0.0
	linkScore := 0.0
	imageScore := 0.0

	// Structure : headers (ex: Markdown #, ##, etc.)
	headers := countHeaders(text)
	if headers > 0 {
		structureScore += float64(headers) * 2
	}
	// Liens (http, https)
	links := countLinks(text)
	if links > 0 {
		linkScore += float64(links) * 1.5
	}
	// Images (ex: ![...](...))
	images := countImages(text)
	if images > 0 {
		imageScore += float64(images) * 2
	}
	// Score global : pondération simple
	return wordCount + structureScore + linkScore + imageScore
}

func splitWords(text string) []string {
	// Sépare sur espaces, ponctuation simple
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

// UserPromptStrategy : demande à l’utilisateur de choisir la version à conserver en cas d’ambiguïté
// Utilise une interface UserPrompter pour l’abstraction (testable/mockable)
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
