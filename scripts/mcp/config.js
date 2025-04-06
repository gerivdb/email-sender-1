const JournalProvider = require('./journal_provider');

module.exports = {
  providers: [
    {
      name: 'journal',
      provider: new JournalProvider(),
      methods: {
        listEntries: {
          description: 'Liste les entrées du journal de bord',
          parameters: [
            {
              name: 'options',
              type: 'object',
              description: 'Options de filtrage (tag, date, limit, sortBy, sortOrder)',
              required: false
            }
          ]
        },
        getEntry: {
          description: 'Récupère le contenu d\'une entrée spécifique',
          parameters: [
            {
              name: 'entryPath',
              type: 'string',
              description: 'Chemin de l\'entrée (nom du fichier)',
              required: true
            }
          ]
        },
        searchJournal: {
          description: 'Recherche dans le journal de bord',
          parameters: [
            {
              name: 'query',
              type: 'string',
              description: 'Requête de recherche',
              required: true
            },
            {
              name: 'limit',
              type: 'number',
              description: 'Nombre maximum de résultats',
              required: false
            }
          ]
        },
        queryRag: {
          description: 'Interroge le système RAG du journal',
          parameters: [
            {
              name: 'query',
              type: 'string',
              description: 'Requête pour le RAG',
              required: true
            }
          ]
        },
        createEntry: {
          description: 'Crée une nouvelle entrée dans le journal',
          parameters: [
            {
              name: 'entryData',
              type: 'object',
              description: 'Données de l\'entrée (title, tags, content)',
              required: true
            }
          ]
        },
        annotateEntry: {
          description: 'Ajoute une annotation à une entrée existante',
          parameters: [
            {
              name: 'entryPath',
              type: 'string',
              description: 'Chemin de l\'entrée (nom du fichier)',
              required: true
            },
            {
              name: 'section',
              type: 'string',
              description: 'Section à annoter',
              required: true
            },
            {
              name: 'annotation',
              type: 'string',
              description: 'Annotation à ajouter',
              required: true
            }
          ]
        }
      }
    }
  ]
};
