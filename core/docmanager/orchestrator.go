// core/docmanager/orchestrator.go
// Orchestrateur d’objectifs pour l’intégration Code-Graph RAG & DocManager

package docmanager

type Objective struct {
	Name        string
	Description string
}

type Orchestrator interface {
	DefineObjectives(objs []Objective) error
	ValidateObjectives() bool
}

type OrchestratorImpl struct {
	objectives []Objective
}

func (o *OrchestratorImpl) DefineObjectives(objs []Objective) error {
	o.objectives = objs
	// TODO: gestion erreurs, validation, log
	return nil
}

func (o *OrchestratorImpl) ValidateObjectives() bool {
	return len(o.objectives) > 0
}
