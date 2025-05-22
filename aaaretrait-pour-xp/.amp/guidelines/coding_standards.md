# Standards de codage pour AMP

## Pratiques générales

- Suivre les standards de codage du projet (SOLID, DRY, KISS, YAGNI)
- Utiliser la méthodologie de tests progressive (P1-P4)
- Respecter les limites de taille (5KB par unité fonctionnelle, 500 lignes par fichier)
- Privilégier le français dans les commentaires et variables quand c'est cohérent avec l'existant

## Traitement des templates Hygen

- Générer du code conforme aux templates Hygen disponibles
- Utiliser les templates appropriés pour la création de:
  - Nouveaux workflows n8n
  - Serveurs MCP
  - Scripts PowerShell
  - Tests automatisés

## Encodage et caractères spéciaux

- Utiliser UTF-8 avec BOM pour les fichiers PowerShell
- Utiliser UTF-8 sans BOM pour les autres fichiers
- Vérifier la préservation des caractères accentués dans tous les fichiers

## Modes d'interaction

- Mode GRAN: Décomposition granulaire privilégiée
- Mode DEV-R: Implémentation des tâches roadmap
- Mode TEST: Tests prioritaires
- Mode DEBUG: Résolution de problèmes