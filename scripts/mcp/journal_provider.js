const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const yaml = require('js-yaml');

/**
 * Provider MCP pour le journal de bord
 * Permet aux modèles d'accéder au journal de bord et d'interagir avec lui
 */
class JournalProvider {
  constructor() {
    this.journalDir = path.join(process.cwd(), 'docs', 'journal_de_bord');
    this.entriesDir = path.join(this.journalDir, 'entries');
    this.ragDir = path.join(this.journalDir, 'rag');
    this.pythonScriptsDir = path.join(process.cwd(), 'scripts', 'python', 'journal');
  }

  /**
   * Liste toutes les entrées du journal
   * @param {Object} options Options de filtrage
   * @returns {Array} Liste des entrées
   */
  async listEntries(options = {}) {
    try {
      const { tag, date, limit = 10, sortBy = 'date', sortOrder = 'desc' } = options;
      
      // Lire tous les fichiers d'entrées
      const files = fs.readdirSync(this.entriesDir)
        .filter(file => file.endsWith('.md'));
      
      // Extraire les métadonnées de chaque fichier
      const entries = [];
      for (const file of files) {
        const filePath = path.join(this.entriesDir, file);
        const content = fs.readFileSync(filePath, 'utf8');
        
        // Extraire les métadonnées YAML
        const yamlMatch = content.match(/^---\n([\s\S]*?)\n---/);
        if (!yamlMatch) continue;
        
        try {
          const metadata = yaml.load(yamlMatch[1]);
          
          // Filtrer par tag si spécifié
          if (tag && (!metadata.tags || !metadata.tags.includes(tag))) {
            continue;
          }
          
          // Filtrer par date si spécifiée
          if (date && metadata.date !== date) {
            continue;
          }
          
          entries.push({
            file,
            path: filePath,
            ...metadata,
            // Extraire le titre du contenu Markdown
            title: metadata.title || content.split('\n').find(line => line.startsWith('# '))?.substring(2) || file
          });
        } catch (e) {
          console.error(`Erreur lors de l'analyse de ${file}:`, e);
        }
      }
      
      // Trier les entrées
      entries.sort((a, b) => {
        let aValue = a[sortBy];
        let bValue = b[sortBy];
        
        // Gestion spéciale pour les dates
        if (sortBy === 'date') {
          if (a.heure && b.heure) {
            aValue = `${a.date} ${a.heure}`;
            bValue = `${b.date} ${b.heure}`;
          }
        }
        
        if (sortOrder === 'desc') {
          return bValue.localeCompare(aValue);
        } else {
          return aValue.localeCompare(bValue);
        }
      });
      
      // Limiter le nombre d'entrées
      return entries.slice(0, limit);
    } catch (error) {
      console.error('Erreur lors de la liste des entrées:', error);
      return { error: error.message };
    }
  }

  /**
   * Récupère le contenu d'une entrée spécifique
   * @param {string} entryPath Chemin de l'entrée
   * @returns {Object} Contenu de l'entrée
   */
  async getEntry(entryPath) {
    try {
      const filePath = path.join(this.entriesDir, entryPath);
      
      if (!fs.existsSync(filePath)) {
        return { error: `Entrée non trouvée: ${entryPath}` };
      }
      
      const content = fs.readFileSync(filePath, 'utf8');
      
      // Extraire les métadonnées YAML
      const yamlMatch = content.match(/^---\n([\s\S]*?)\n---/);
      if (!yamlMatch) {
        return { content };
      }
      
      const metadata = yaml.load(yamlMatch[1]);
      const markdownContent = content.substring(yamlMatch[0].length).trim();
      
      return {
        metadata,
        content: markdownContent,
        fullContent: content
      };
    } catch (error) {
      console.error('Erreur lors de la récupération de l\'entrée:', error);
      return { error: error.message };
    }
  }

  /**
   * Recherche dans le journal
   * @param {string} query Requête de recherche
   * @param {number} limit Nombre maximum de résultats
   * @returns {Array} Résultats de la recherche
   */
  async searchJournal(query, limit = 5) {
    try {
      // Exécuter le script de recherche Python
      const command = `python "${path.join(this.pythonScriptsDir, 'journal_search_simple.py')}" --query "${query}" --n ${limit}`;
      
      const output = execSync(command, { encoding: 'utf8' });
      
      // Parser la sortie pour extraire les résultats
      const results = [];
      const resultBlocks = output.split(/\n\d+\./g).slice(1);
      
      for (const block of resultBlocks) {
        const titleMatch = block.match(/(.+?) \((.+?)\) - Section: (.+)/);
        if (!titleMatch) continue;
        
        const [, title, date, section] = titleMatch;
        
        const fileMatch = block.match(/Fichier: (.+)/);
        const tagsMatch = block.match(/Tags: (.+)/);
        const excerptMatch = block.match(/Extrait: ([\s\S]+?)\.{3}/);
        
        results.push({
          title: title.trim(),
          date: date.trim(),
          section: section.trim(),
          file: fileMatch ? fileMatch[1].trim() : null,
          tags: tagsMatch ? tagsMatch[1].split(',').map(t => t.trim()) : [],
          excerpt: excerptMatch ? excerptMatch[1].trim() : null
        });
      }
      
      return results;
    } catch (error) {
      console.error('Erreur lors de la recherche:', error);
      return { error: error.message };
    }
  }

  /**
   * Interroge le système RAG du journal
   * @param {string} query Requête pour le RAG
   * @returns {string} Réponse du système RAG
   */
  async queryRag(query) {
    try {
      // Exécuter le script RAG Python
      const command = `python "${path.join(this.pythonScriptsDir, 'journal_rag_simple.py')}" --query "${query}"`;
      
      const output = execSync(command, { encoding: 'utf8' });
      
      return output;
    } catch (error) {
      console.error('Erreur lors de l\'interrogation du RAG:', error);
      return { error: error.message };
    }
  }

  /**
   * Crée une nouvelle entrée dans le journal
   * @param {Object} entryData Données de l'entrée
   * @returns {Object} Résultat de la création
   */
  async createEntry(entryData) {
    try {
      const { title, tags = [], content = {} } = entryData;
      
      if (!title) {
        return { error: 'Le titre est requis' };
      }
      
      // Préparer les arguments pour le script Python
      let tagsArg = '';
      if (tags.length > 0) {
        tagsArg = `--tags ${tags.join(' ')}`;
      }
      
      // Créer l'entrée de base
      const command = `python "${path.join(this.pythonScriptsDir, 'journal_entry.py')}" "${title}" ${tagsArg}`;
      
      const output = execSync(command, { encoding: 'utf8' });
      
      // Extraire le chemin du fichier créé
      const filePathMatch = output.match(/Entrée créée: (.+)/);
      if (!filePathMatch) {
        return { error: 'Impossible de déterminer le chemin du fichier créé' };
      }
      
      const filePath = filePathMatch[1].trim();
      
      // Si du contenu supplémentaire est fourni, mettre à jour l'entrée
      if (Object.keys(content).length > 0) {
        // Lire le contenu actuel
        const currentContent = fs.readFileSync(filePath, 'utf8');
        
        // Mettre à jour chaque section spécifiée
        let updatedContent = currentContent;
        
        for (const [section, sectionContent] of Object.entries(content)) {
          const sectionRegex = new RegExp(`## ${section}\\n-\\s*\\n`, 'g');
          updatedContent = updatedContent.replace(sectionRegex, `## ${section}\n${sectionContent}\n\n`);
        }
        
        // Écrire le contenu mis à jour
        fs.writeFileSync(filePath, updatedContent, 'utf8');
      }
      
      return { 
        success: true, 
        message: `Entrée créée: ${filePath}`,
        path: filePath
      };
    } catch (error) {
      console.error('Erreur lors de la création de l\'entrée:', error);
      return { error: error.message };
    }
  }

  /**
   * Ajoute une annotation à une entrée existante
   * @param {string} entryPath Chemin de l'entrée
   * @param {string} section Section à annoter
   * @param {string} annotation Annotation à ajouter
   * @returns {Object} Résultat de l'annotation
   */
  async annotateEntry(entryPath, section, annotation) {
    try {
      const filePath = path.join(this.entriesDir, entryPath);
      
      if (!fs.existsSync(filePath)) {
        return { error: `Entrée non trouvée: ${entryPath}` };
      }
      
      // Lire le contenu actuel
      const content = fs.readFileSync(filePath, 'utf8');
      
      // Vérifier si la section existe
      const sectionRegex = new RegExp(`## ${section}\\n`);
      if (!sectionRegex.test(content)) {
        return { error: `Section non trouvée: ${section}` };
      }
      
      // Ajouter l'annotation à la fin de la section
      const sectionEndRegex = new RegExp(`## ${section}\\n([\\s\\S]*?)\\n##`);
      const sectionMatch = content.match(sectionEndRegex);
      
      let updatedContent;
      
      if (sectionMatch) {
        // La section se termine par une autre section
        const sectionContent = sectionMatch[1];
        const annotatedContent = `${sectionContent}\n- [Annotation MCP] ${annotation}`;
        updatedContent = content.replace(sectionEndRegex, `## ${section}\n${annotatedContent}\n\n##`);
      } else {
        // La section est la dernière du document
        const sectionStartRegex = new RegExp(`## ${section}\\n([\\s\\S]*)$`);
        const sectionStartMatch = content.match(sectionStartRegex);
        
        if (sectionStartMatch) {
          const sectionContent = sectionStartMatch[1];
          const annotatedContent = `${sectionContent}\n- [Annotation MCP] ${annotation}`;
          updatedContent = content.replace(sectionStartRegex, `## ${section}\n${annotatedContent}`);
        } else {
          return { error: `Impossible de trouver la fin de la section: ${section}` };
        }
      }
      
      // Écrire le contenu mis à jour
      fs.writeFileSync(filePath, updatedContent, 'utf8');
      
      return { 
        success: true, 
        message: `Annotation ajoutée à ${entryPath}, section ${section}`
      };
    } catch (error) {
      console.error('Erreur lors de l\'annotation de l\'entrée:', error);
      return { error: error.message };
    }
  }
}

module.exports = JournalProvider;
