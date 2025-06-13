# Intu00e9gration Hygen pour AMP

## Utilisation des templates existants

Le projet utilise [Hygen](https://www.hygen.io/) pour gu00e9nu00e9rer du code u00e0 partir de templates. Les templates sont situu00e9s dans les dossiers `_templates` du projet.

### Structure des templates Hygen

```plaintext
_templates/
  plan-dev/
    new/
      plan-dev.ejs.t
      prompt.js
  n8n-integration/
    new/
      prompt.js
  ...
```plaintext
### Gu00e9nu00e9ration de code avec Hygen

Pour gu00e9nu00e9rer du code u00e0 partir d'un template Hygen, l'agent AMP doit:

1. Identifier le template appropriu00e9
2. Consulter la structure du template et ses prompt.js
3. Gu00e9nu00e9rer le contenu conforme aux attentes du template
4. Intu00e9grer le contenu gu00e9nu00e9ru00e9 dans le fichier de destination

### Exemple d'utilisation

```javascript
// Gu00e9nu00e9ration d'un nouveau plan de du00e9veloppement
hygen plan-dev new --name "v27-notifications-temps-reel" --description "Mise en place de notifications en temps ru00e9el" --complexity "medium"
```plaintext
## Cru00e9ation de nouveaux templates

Lorsque nu00e9cessaire, l'agent AMP peut proposer de nouveaux templates Hygen pour standardiser la gu00e9nu00e9ration de code ru00e9pu00e9titif.