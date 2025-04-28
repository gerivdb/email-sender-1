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
      if (lowerName.includes('roadmap')) return 'roadmap';
      if (lowerName.includes('path')) return 'paths';
      if (lowerName.includes('checkbox')) return 'modes';
      if (lowerName.includes('analyze') || lowerName.includes('analysis')) return 'api';
      if (lowerName.includes('test')) return 'test';
      if (lowerName.includes('vscode')) return 'vscode';
      if (lowerName.includes('git')) return 'git';
      if (lowerName.includes('clean') || lowerName.includes('fix')) return 'cleanup';
      if (lowerName.includes('mode')) return 'modes';
      if (lowerName.includes('encoding')) return 'encoding';
      if (lowerName.includes('log')) return 'logs';
      if (lowerName.includes('performance')) return 'performance';
      if (lowerName.includes('backup')) return 'backups';
      
      // Par défaut, retourner 'utils'
      return 'utils';
    }
  }
}
