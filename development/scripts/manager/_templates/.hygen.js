module.exports = {
  templates: `${__dirname}`,
  helpers: {
    // Helpers personnalisés pour les templates
    now: () => new Date().toISOString().slice(0, 10),
    year: () => new Date().getFullYear(),
    
    // Fonction pour convertir un nom de fichier en nom de fonction
    toFunctionName: (name) => {
      // Supprimer les caractères non alphanumériques du début
      const cleanName = name.replace(/^[^a-zA-Z]+/, '');
      // Convertir en PascalCase
      return cleanName
        .split(/[-_]/)
        .map(part => part.charAt(0).toUpperCase() + part.slice(1))
        .join('');
    },
    
    // Fonction pour déterminer le sous-dossier approprié en fonction du nom du script
    getScriptCategory: (name) => {
      const lowerName = name.toLowerCase();
      
      // Catégorisation basée sur des mots-clés dans le nom du fichier
      if (lowerName.includes('analyze') || lowerName.includes('analysis')) return 'analysis';
      if (lowerName.includes('organize') || lowerName.includes('organization')) return 'organization';
      if (lowerName.includes('inventory') || lowerName.includes('catalog')) return 'inventory';
      if (lowerName.includes('document') || lowerName.includes('doc')) return 'documentation';
      if (lowerName.includes('monitor') || lowerName.includes('watch')) return 'monitoring';
      if (lowerName.includes('optimize') || lowerName.includes('improve')) return 'optimization';
      if (lowerName.includes('test') || lowerName.includes('validate')) return 'testing';
      if (lowerName.includes('config') || lowerName.includes('setting')) return 'configuration';
      if (lowerName.includes('generate') || lowerName.includes('create')) return 'generation';
      if (lowerName.includes('integrate') || lowerName.includes('connect')) return 'integration';
      if (lowerName.includes('ui') || lowerName.includes('interface')) return 'ui';
      
      // Par défaut, retourner 'core'
      return 'core';
    }
  }
}
