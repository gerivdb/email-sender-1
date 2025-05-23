// Package generator implements task and phase generation functions
package generator

import (
	"fmt"
	"strings"

	"plan-generator/pkg/models"
	"plan-generator/pkg/utils"
)

// GenerateNestedTasks génère une structure de tâches imbriquée avec une profondeur spécifiée
func GenerateNestedTasks(baseID string, label string, description string, currentLevel int, maxDepth int) []models.Task {
	if currentLevel > maxDepth {
		return []models.Task{}
	}

	// Nombre de sous-tâches à créer par niveau
	subTasksCount := 3

	// Créer les sous-tâches pour ce niveau
	tasks := make([]models.Task, subTasksCount)
	for i := 0; i < subTasksCount; i++ {
		taskID := fmt.Sprintf("%s.%d", baseID, i+1)
		taskLabel := fmt.Sprintf("%s %d", label, i+1)
		taskDesc := fmt.Sprintf("Description de %s", taskLabel)

		// Exemples de sous-tâches textuelles simples
		simpleSubtasks := []string{
			fmt.Sprintf("Étape de préparation pour %s", taskLabel),
			fmt.Sprintf("Étape d'exécution pour %s", taskLabel),
			fmt.Sprintf("Étape de validation pour %s", taskLabel),
		}

		// Création de la tâche
		task := models.Task{
			ID:          taskID,
			Label:       taskLabel,
			Description: taskDesc,
			Done:        false,
			Subtasks:    simpleSubtasks,
			Level:       currentLevel,
			MaxDepth:    maxDepth,
		}

		// Génération récursive des sous-tâches (uniquement si nous ne sommes pas au niveau maximum)
		if currentLevel < maxDepth {
			task.NestedTasks = GenerateNestedTasks(taskID, taskLabel, taskDesc, currentLevel+1, maxDepth)
		}

		tasks[i] = task
	}

	return tasks
}

// CalculateMaxDepth calcule la profondeur maximale d'une tâche en incluant ses sous-tâches
func CalculateMaxDepth(task models.Task) int {
	if len(task.NestedTasks) == 0 {
		return task.Level
	}

	maxDepth := task.Level
	for _, subTask := range task.NestedTasks {
		subDepth := CalculateMaxDepth(subTask)
		if subDepth > maxDepth {
			maxDepth = subDepth
		}
	}

	return maxDepth
}

// GenerateTasksForPhase génère des tâches pour une phase spécifique avec une profondeur donnée
func GenerateTasksForPhase(phaseNum int, maxTaskDepth int) []models.Task {
	// Créer une tâche principale (niveau 1)
	mainTask := models.Task{
		ID:          fmt.Sprintf("%d.1", phaseNum),
		Label:       fmt.Sprintf("Tâche principale 1"),
		Description: utils.PhaseDescription(phaseNum),
		Done:        false,
		Subtasks:    []string{},
		Level:       1,
		MaxDepth:    maxTaskDepth,
	}

	// Utiliser GenerateNestedTasks pour générer des sous-tâches avec la profondeur spécifiée
	if maxTaskDepth > 1 {
		baseID := mainTask.ID
		mainTask.NestedTasks = GenerateNestedTasks(baseID, "Sous-tâche",
			fmt.Sprintf("Détail pour la phase %d", phaseNum), 2, maxTaskDepth)
	}

	return []models.Task{mainTask}
}

// GeneratePhases génère toutes les phases du plan
func GeneratePhases(count int, maxTaskDepth int) []models.Phase {
	phases := make([]models.Phase, count)
	for i := 1; i <= count; i++ {
		phases[i-1] = models.Phase{
			Number:      i,
			Description: utils.PhaseDescription(i),
			Tasks:       GenerateTasksForPhase(i, maxTaskDepth),
			Subtasks: []string{
				"Étape 1 : Définir les objectifs",
				"Étape 2 : Identifier les parties prenantes",
				"Étape 3 : Documenter les résultats",
				"Étape 4 : Valider les étapes avec l'équipe",
				"Étape 5 : Ajouter des schémas ou diagrammes si nécessaire",
				"Étape 6 : Vérifier les dépendances",
				"Étape 7 : Finaliser et archiver",
				"Étape 8 : Effectuer une revue par les pairs",
				"Étape 9 : Planifier les prochaines actions",
			},
		}
	}
	return phases
}

// RenderTasksHierarchy génère le contenu Markdown pour une tâche et ses sous-tâches
func RenderTasksHierarchy(task models.Task, level int) string {
	indent := strings.Repeat("  ", level-1)
	result := fmt.Sprintf("%s- [ ] **%s** %s - %s\n", indent, task.ID, task.Label, task.Description)

	// Ajouter les sous-tâches simples
	for _, subtask := range task.Subtasks {
		result += fmt.Sprintf("%s  - %s\n", indent, subtask)
	}

	// Ajouter les sous-tâches hiérarchiques
	for _, nestedTask := range task.NestedTasks {
		result += RenderTasksHierarchy(nestedTask, level+1)
	}

	return result
}
