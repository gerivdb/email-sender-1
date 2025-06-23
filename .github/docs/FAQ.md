# ❓ FAQ – Questions Fréquentes

## 1. Problèmes courants

- **Q : Je n’arrive pas à envoyer d’email via Gmail.**
  - R : Vérifiez la validité du token OAuth et les scopes configurés dans Google Cloud Console.
- **Q : L’intégration Notion ne fonctionne pas.**
  - R : Vérifiez que la clé API est correcte et que l’intégration a accès à la page cible.
- **Q : Le workflow ne se déclenche pas.**
  - R : Vérifiez le déclencheur n8n et les logs d’exécution.

## 2. Erreurs fréquentes

- **Erreur 401** : Authentification/API Key invalide
- **Erreur 429** : Limite de requêtes atteinte
- **Erreur 404** : Ressource introuvable

## 3. Solutions rapides

- Redémarrer n8n et vérifier les logs
- Mettre à jour les clés API dans `.env`
- Consulter les guides d’intégration pour chaque service

## 4. Ressources complémentaires

- [Guides d’intégration](INTEGRATIONS/)
- [Bonnes pratiques](BONNES-PRATIQUES.md)
- [Support n8n](https://community.n8n.io/)
