module.exports = {
  templates: `${__dirname}/development/templates/hygen`,
  helpers: {
    capitalize: (str) => {
      if (typeof str !== 'string' || !str) return ''
      return str.charAt(0).toUpperCase() + str.slice(1)
    },
    lowercase: (str) => {
      if (typeof str !== 'string' || !str) return ''
      return str.toLowerCase()
    },
    now: () => new Date().toISOString().slice(0, 10),
    year: () => new Date().getFullYear(),
    uuid: () => {
      return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
      });
    },
    toFunctionName: (name) => {
      // Supprimer les caractères non alphanumériques du début
      const cleanName = name.replace(/^[^a-zA-Z]+/, '');
      // Convertir en PascalCase
      return cleanName
        .split(/[-_]/)
        .map(part => part.charAt(0).toUpperCase() + part.slice(1))
        .join('');
    }
  }
}
