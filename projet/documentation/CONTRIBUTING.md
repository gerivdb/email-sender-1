# Guide de contribution

Merci de votre intérêt pour contribuer au projet Email Sender pour n8n ! Voici quelques directives pour vous aider à contribuer efficacement.

## Comment contribuer

1. **Fork** le dépôt sur GitHub
2. **Clone** votre fork sur votre machine locale
3. **Créez une branche** pour vos modifications (`git checkout -b feature/amazing-feature`)
4. **Committez** vos changements (`git commit -m 'Add some amazing feature'`)
5. **Poussez** vers la branche (`git push origin feature/amazing-feature`)
6. Ouvrez une **Pull Request**

## Structure du projet

Veuillez respecter la structure de répertoires existante :

```plaintext
├── workflows/            # Workflows n8n finaux

├── credentials/          # Informations d'identification

├── config/               # Fichiers de configuration

├── mcp/                  # Configurations MCP

├── src/                  # Code source principal

│   ├── workflows/        # Workflows n8n (développement)

│   └── mcp/              # Fichiers MCP

├── scripts/              # Scripts utilitaires

├── docs/                 # Documentation

└── ...
```plaintext
## Normes de codage

- Utilisez des noms de variables et de fonctions descriptifs
- Commentez votre code lorsque nécessaire
- Suivez les conventions de nommage existantes
- Pour les workflows n8n, utilisez la convention de nommage : `[Phase]_[Action]_[Resource].json`

## Tests

- Testez vos workflows dans n8n avant de soumettre une pull request
- Documentez les tests effectués dans votre pull request

## Documentation

- Mettez à jour la documentation si vous modifiez des fonctionnalités
- Ajoutez des commentaires dans les workflows pour expliquer leur fonctionnement

## Questions ?

Si vous avez des questions, n'hésitez pas à ouvrir une issue sur GitHub.
