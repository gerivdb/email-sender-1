package conflict

// RollbackManager manages the rollback of conflict resolutions in the system.
//
// Rôle : Gestion des rollbacks et restaurations documentaires.
//
// Interfaces :
//   - Dépend de ConflictHistory (historique des conflits)
//   - Méthode principale : RollbackLast() error
//
// Utilisation :
//   - Permet d’annuler la dernière résolution de conflit enregistrée dans l’historique.
//   - Utilisé pour restaurer un état antérieur en cas d’erreur ou de besoin de révision.
//
// Entrée/Sortie :
//   - Entrée : aucune (opère sur l’historique interne)
//   - Sortie : erreur éventuelle si le rollback échoueventuelle si le rollback échoue
//
// Example:/ Example:
//   mgr := &RollbackManager{History: history}//   mgr := &RollbackManager{History: history}
















}	return nil	record.Resolved = false	// Implementation of the rollback logic goes here.func (mgr *RollbackManager) RollbackLast() error {// RollbackLast undoes the last conflict resolution recorded in the history.}	History ConflictHistorytype RollbackManager struct {// RollbackManager manages the rollback of conflict resolutions in the system.//   if err != nil { /* gestion d’erreur */ }//   err := mgr.RollbackLast()//   err := mgr.RollbackLast()
//   if err != nil { /* gestion d’erreur */ }

// RollbackManager handles rollback of resolutions.
type RollbackManager struct {
	History *ConflictHistory
}

func (r *RollbackManager) RollbackLast() error {
	h := r.History
	if len(h.Conflicts) == 0 {
		return nil
	}
	record := &h.Conflicts[len(h.Conflicts)-1]
	if !record.Resolved {
		return nil
	}
	record.Resolved = false
	return nil
}
