// index.js - Générateur de PRD
module.exports = {
  prompt: ({ inquirer }) => {
    const questions = [
      {
        type: 'input',
        name: 'name',
        message: 'Nom du PRD (sans espaces, utilisez des tirets):',
        validate: (input) => input.length > 0 ? true : 'Le nom est requis'
      },
      {
        type: 'input',
        name: 'title',
        message: 'Titre complet du PRD:',
        validate: (input) => input.length > 0 ? true : 'Le titre est requis'
      },
      {
        type: 'input',
        name: 'description',
        message: 'Description courte du PRD:',
        validate: (input) => input.length > 0 ? true : 'La description est requise'
      },
      {
        type: 'input',
        name: 'author',
        message: 'Auteur:',
        default: 'EMAIL_SENDER_1 Team'
      },
      {
        type: 'list',
        name: 'category',
        message: 'Catégorie:',
        choices: ['module', 'workflow', 'integration', 'system', 'other']
      },
      {
        type: 'checkbox',
        name: 'sections',
        message: 'Sections à inclure:',
        choices: [
          { name: 'Introduction', value: 'introduction', checked: true },
          { name: 'User Stories', value: 'user_stories', checked: true },
          { name: 'Spécifications fonctionnelles', value: 'functional_specs', checked: true },
          { name: 'Spécifications techniques', value: 'technical_specs', checked: true },
          { name: 'Critères d\'acceptation', value: 'acceptance_criteria', checked: true },
          { name: 'Dépendances', value: 'dependencies', checked: true },
          { name: 'Calendrier', value: 'timeline', checked: true },
          { name: 'Approbation', value: 'approval', checked: true }
        ]
      },
      {
        type: 'confirm',
        name: 'index_in_qdrant',
        message: 'Indexer dans Qdrant après génération?',
        default: true
      }
    ];

    return inquirer.prompt(questions).then(answers => {
      const { name, category } = answers;
      const date = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
      const version = '1.0';
      
      // Générer le chemin du fichier
      const path = `projet/guides/prd/${category}/${name}.md`;
      
      // Préparer les données pour le template
      return { 
        ...answers,
        date,
        version,
        path,
        // Convertir le tableau de sections en booléens individuels pour faciliter les conditions dans le template
        has_introduction: answers.sections.includes('introduction'),
        has_user_stories: answers.sections.includes('user_stories'),
        has_functional_specs: answers.sections.includes('functional_specs'),
        has_technical_specs: answers.sections.includes('technical_specs'),
        has_acceptance_criteria: answers.sections.includes('acceptance_criteria'),
        has_dependencies: answers.sections.includes('dependencies'),
        has_timeline: answers.sections.includes('timeline'),
        has_approval: answers.sections.includes('approval')
      };
    });
  }
};
