# Recueil des besoins spécifiques à Jan

Ce document liste les exigences, limites et scénarios cibles pour l'intégration de Jan en tant que moteur d'orchestration séquentielle multi-personas.

## Exigences Fonctionnelles
- **Orchestration séquentielle**: Jan doit pouvoir exécuter une série de tâches IA en séquence, simulant différents personas.
- **Gestion du contexte**: Le ContextManager doit centraliser l'historique des dialogues et le contexte de chaque persona, et le rendre accessible à Jan.
- **Flexibilité des prompts**: Possibilité d'injecter des prompts système et contextuels dynamiques pour chaque étape de l'orchestration.
- **Performance**: L'intégration doit minimiser la latence et l'utilisation des ressources, en cohérence avec les limites matérielles.
- **Traçabilité**: Chaque interaction avec Jan et chaque changement de contexte doit être logué pour le débogage et l'audit.

## Exigences Non-Fonctionnelles
- **Robustesse**: Le système doit être résilient aux erreurs de communication avec Jan ou aux réponses inattendues.
- **Sécurité**: Assurer la confidentialité des données échangées avec Jan.
- **Maintenabilité**: Le code d'intégration doit être clair, modulaire et facile à maintenir.
- **Évolutivité**: La solution doit pouvoir s'adapter à de nouveaux personas ou à des scénarios d'orchestration plus complexes.

## Limites Identifiées (basées sur l'analyse d'écart)
- **Mono-agent**: Jan opère comme un mono-agent. L'orchestration multi-agent doit être simulée séquentiellement.
- **Modèle unique**: Jan utilise un modèle LLM unique. La diversité des modèles doit être gérée par la configuration des prompts et du contexte.
- **Gestion centralisée de l'historique**: L'historique des dialogues doit être géré et injecté par le ContextManager, et non par Jan directement.

## Scénarios Cibles
- **Prospection automatisée**: Jan simule un commercial, un analyste, puis un rédacteur pour générer des emails de prospection.
- **Support client**: Jan gère un dialogue avec un utilisateur en alternant entre un persona de compréhension de requête et un persona de génération de réponse.
- **Création de contenu**: Jan orchestre la création d'articles en passant par des personas de recherche, de rédaction et de révision.

## Critères de Validation
- Le fichier `besoins_jan.md` est généré.
- Les exigences fonctionnelles et non-fonctionnelles sont clairement définies.
- Les limites identifiées sont prises en compte.
- Les scénarios cibles sont décrits.
- Le document est validé par revue croisée (simulée ici par la génération).
