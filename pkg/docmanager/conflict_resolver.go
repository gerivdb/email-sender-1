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
