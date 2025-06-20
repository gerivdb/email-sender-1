// SPDX-License-Identifier: MIT
// Package docmanager - Conflict Resolver SRP Implementation
package docmanager

import (
	"fmt"
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

// Interface contrat

type ConflictResolverInterface interface {
	Detect() ([]*DocumentConflict, error)
	Resolve(conflict *DocumentConflict) (*Resolution, error)
	Score(conflict *DocumentConflict) float64
}
