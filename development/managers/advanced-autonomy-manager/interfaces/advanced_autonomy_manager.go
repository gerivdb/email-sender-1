package interfaces

import (
	"context"
	"time"
)

// AdvancedAutonomyManager est l'interface principale pour le 21ème manager du FMOUA
// qui fournit une autonomie complète pour la maintenance et l'organisation
// Ce manager orchestre tous les 20 managers précédents et fournit une intelligence
// décisionnelle avancée pour l'ensemble de l'écosystème.
type AdvancedAutonomyManager interface {
	// BaseManager est l'interface de base que tous les managers doivent implémenter
	BaseManager

	// OrchestrateAutonomousMaintenance coordonne une opération de maintenance
	// entièrement autonome sur l'ensemble de l'écosystème FMOUA.
	// Cette méthode utilise l'intelligence décisionnelle pour orchestrer
	// les 20 managers précédents sans aucune intervention humaine.
	OrchestrateAutonomousMaintenance(ctx context.Context) (*AutonomyResult, error)

	// PredictMaintenanceNeeds prédit les besoins futurs de maintenance
	// sur un horizon temporel spécifié en utilisant le machine learning
	// et l'analyse de patterns de dégradation.
	PredictMaintenanceNeeds(ctx context.Context, timeHorizon time.Duration) (*PredictionResult, error)

	// ExecuteAutonomousDecisions exécute un ensemble de décisions autonomes
	// préalablement générées par le système décisionnel neural.
	// Cette méthode inclut une évaluation des risques et une stratégie de rollback.
	ExecuteAutonomousDecisions(ctx context.Context, decisions []AutonomousDecision) error

	// MonitorEcosystemHealth surveille en temps réel la santé de l'écosystème
	// complet des 21 managers et renvoie un tableau de bord détaillé.
	MonitorEcosystemHealth(ctx context.Context) (*EcosystemHealth, error)

	// SetupSelfHealing configure le système d'auto-réparation basé sur
	// la détection d'anomalies et les procédures de correction automatiques.
	SetupSelfHealing(ctx context.Context, config *SelfHealingConfig) error

	// OptimizeResourceAllocation optimise l'allocation des ressources
	// entre les différents managers pour maximiser les performances globales.
	OptimizeResourceAllocation(ctx context.Context) (*ResourceOptimizationResult, error)

	// EstablishCrossManagerWorkflows établit des workflows qui traversent
	// plusieurs managers pour des opérations complexes coordonnées.
	EstablishCrossManagerWorkflows(ctx context.Context, workflows []*CrossManagerWorkflow) error

	// HandleEmergencySituations gère des situations d'urgence détectées
	// dans l'écosystème en appliquant des protocoles de récupération.
	HandleEmergencySituations(ctx context.Context, severity EmergencySeverity) (*EmergencyResponse, error)
}
