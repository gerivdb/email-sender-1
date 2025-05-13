// see types of prompts:
// https://github.com/enquirer/enquirer/tree/master/examples
//
module.exports = [
  {
    type: 'input',
    name: 'description',
    message: "Description de l'outil"
  },
  {
    type: 'list',
    name: 'dependencies',
    message: "Dépendances (séparées par des virgules)",
    initial: "",
    separator: ','
  },
  {
    type: 'confirm',
    name: 'includeTest',
    message: "Inclure une fonction de test ?",
    initial: true
  },
  {
    type: 'list',
    name: 'options',
    message: "Options du constructeur (format: nom:type:description:valeur_defaut, séparées par des virgules)",
    initial: "config:Dict[str, Any]:Configuration de l'outil:{}",
    separator: ',',
    result: (value) => {
      if (!value) return [];
      return value.map(item => {
        const parts = item.split(':');
        return {
          name: parts[0],
          type: parts[1] || 'Any',
          description: parts[2] || '',
          default: parts[3] || ''
        };
      });
    }
  },
  {
    type: 'list',
    name: 'methods',
    message: "Méthodes (format: nom:type_retour:description, séparées par des virgules)",
    initial: "execute:Dict[str, Any]:Exécute l'outil",
    separator: ',',
    result: (value) => {
      if (!value) return [];
      return value.map(item => {
        const parts = item.split(':');
        return {
          name: parts[0],
          returnType: parts[1] || 'None',
          description: parts[2] || '',
          params: []
        };
      });
    }
  }
]
