// see types of prompts:
// https://github.com/enquirer/enquirer/tree/master/examples
//
module.exports = [
  {
    type: 'input',
    name: 'description',
    message: "Description du serveur"
  },
  {
    type: 'input',
    name: 'port',
    message: "Port du serveur",
    initial: "5000"
  },
  {
    type: 'input',
    name: 'host',
    message: "Hôte du serveur",
    initial: "0.0.0.0"
  },
  {
    type: 'confirm',
    name: 'debug',
    message: "Mode debug ?",
    initial: false
  },
  {
    type: 'list',
    name: 'endpoints',
    message: "Endpoints (format: nom:chemin:méthode:description, séparés par des virgules)",
    initial: "get_data:/data:GET:Récupère des données",
    separator: ',',
    result: (value) => {
      if (!value) return [];
      return value.map(item => {
        const parts = item.split(':');
        return {
          name: parts[0],
          path: parts[1] || '/',
          method: parts[2] || 'GET',
          description: parts[3] || '',
          params: []
        };
      });
    }
  },
  {
    type: 'json',
    name: 'config',
    message: "Configuration supplémentaire (format JSON)",
    initial: "{}",
    result: (value) => {
      try {
        return JSON.parse(value);
      } catch (e) {
        return {};
      }
    }
  }
]
