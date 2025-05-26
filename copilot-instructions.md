# Instructions pour Copilot - Exécuteur de Plans de Développement

1. Lis le fichier de plan spécifié par l'utilisateur (par exemple, `projet/roadmaps/plans/consolidated/plan-dev-v34-rag-go.md` ou tout autre plan dans le projet).
2. Identifie et parcours chaque tâche dans l'ordre du plan (listes numérotées ou à cocher).
3. Pour chaque tâche :
   - Exécute-la directement si c'est une commande shell (exemples : `mkdir`, `cd`, `go run`, etc.)
   - Génère ou modifie les fichiers nécessaires quand la tâche l'exige
   - Coche automatiquement la case dans le fichier de plan lorsque la tâche est réalisée (`- [x]`)
4. Si une tâche contient des sous-tâches, exécute-les récursivement dans l'ordre
5. Vérifie les erreurs d'exécution et corrige-les automatiquement si possible
6. Mets à jour l'état d'avancement dans le fichier de plan original

**Notes importantes :**
- Ne te contente pas d'afficher les commandes, exécute-les réellement
- Utilise les chemins absolus pour garantir l'accès aux bons fichiers
- Continue l'exécution même si l'interface ne montre pas les modifications en temps réel
- Vérifie l'existence des dossiers/fichiers avant chaque action et crée-les si nécessaire
- Si une tâche est incomplète ou ambiguë, demande des précisions