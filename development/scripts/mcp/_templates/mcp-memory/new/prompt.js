// see types of prompts:
// https://github.com/enquirer/enquirer/tree/master/examples
//
module.exports = [
  {
    type: 'input',
    name: 'description',
    message: "Description de la mémoire"
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
    initial: "storage_path:str:Chemin de stockage des mémoires:'./memories'",
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
    message: "Méthodes supplémentaires (format: nom:type_retour:description, séparées par des virgules)",
    initial: "search:List[Dict[str, Any]]:Recherche des mémoires",
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
