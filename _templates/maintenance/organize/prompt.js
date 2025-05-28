// see types of prompts:
// https://github.com/enquirer/enquirer/tree/master/examples
//
module.exports = {
  prompt: ({ inquirer }) => {
    const basePrompts = [
      {
        type: 'input',
        name: 'name',
        message: "Nom du script d'organisation (sans l'extension .ps1) :"
      },
      {
        type: 'input',
        name: 'description',
        message: "Description du script d'organisation :"
      },
      {
        type: 'select',
        name: 'scriptType',
        message: 'Type de script d\'organisation :',
        choices: ['standard', 'mcp']
      }
    ];

    return inquirer.prompt(basePrompts).then(answers => {
      if (answers.scriptType === 'standard') {
        // Prompts pour le script standard
        return inquirer.prompt([
          {
            type: 'input',
            name: 'targetDir',
            message: "Quel est le répertoire cible à organiser ? (chemin relatif ou absolu)"
          },
          {
            type: 'select',
            name: 'type',
            message: 'Type d\'organisation :',
            choices: ['structure', 'files', 'modules', 'scripts', 'docs', 'custom']
          },
          {
            type: 'confirm',
            name: 'createCleanup',
            message: "Créer également un script de nettoyage ?"
          }
        ]).then(standardAnswers => {
          return { ...answers, ...standardAnswers, template: 'standard' };
        });
      } else {
        // Prompts pour le script MCP
        return inquirer.prompt([
          {
            type: 'input',
            name: 'rootPath',
            message: "Chemin racine à organiser:",
            default: "Join-Path -Path $PSScriptRoot -ChildPath \"../..\""
          },
          {
            type: 'input',
            name: 'sourceDescription',
            message: "Description des fichiers source:",
            default: "de la racine du répertoire"
          },
          {
            type: 'input',
            name: 'targetDescription',
            message: "Description des dossiers cibles:",
            default: "des sous-dossiers thématiques selon leur fonction"
          },
          {
            type: 'confirm',
            name: 'useDefaultMappings',
            message: "Utiliser les mappages par défaut?",
            default: false
          }
        ]).then(mcpAnswers => {
          // Définir les mappages par défaut
          const defaultMappings = {
            // Fichiers liés aux managers
            "define-manager-structure.ps1.bak": "modules",
            "find-managers.ps1.bak": "modules",
            "generate-manager-documentation.ps1.bak": "modules",
            "install-integrated-manager.ps1.bak": "modules",
            "manager-configs.csv": "modules",
            "managers.csv": "modules",
            "managers.txt": "modules",
            "rename-manager-folder.ps1.bak": "modules",
            "reorganize-manager-files.ps1.bak": "modules",
            "standardize-manager-names.ps1.bak": "modules",
            "test-install-integrated-manager-doc.ps1.bak": "modules",
            "test-manager-structure.ps1.bak": "modules",
            "uninstall-integrated-manager.ps1.bak": "modules",
            "update-manager-references.ps1.bak": "modules",

            // Fichiers liés à la roadmap
            "Manage-Roadmap.ps1.bak": "roadmap",
            "Navigate-Roadmap.ps1.bak": "roadmap",
            "Simple-Split-Roadmap.ps1.bak": "roadmap",
            "Split-Roadmap.ps1.bak": "roadmap",
            "update-roadmap-checkboxes.ps1.bak": "roadmap",
            "Update-RoadmapStatus.ps1.bak": "roadmap",

            // Fichiers liés à OpenRouter/Qwen3
            "Implement-TaskWithQwen3.ps1.bak": "api",
            "init-openrouter.ps1.bak": "api",
            "qwen3-dev-r.ps1.bak": "api",
            "qwen3-integration.ps1.bak": "api",
            "simple-openrouter-test.ps1.bak": "api",
            "simple-qwen3-test.ps1.bak": "api",
            "Use-Qwen3DevR.ps1.bak": "api",

            // Fichiers liés à l'environnement
            "Initialize-MaintenanceEnvironment.ps1.bak": "environment-compatibility",
            "verify-installation.ps1.bak": "environment-compatibility",

            // Fichiers liés à la maintenance du code
            "Check-FileLengths.ps1.bak": "cleanup",
            "Fix-FileEncoding.ps1.bak": "encoding",
            "fix-variable-names.ps1.bak": "cleanup",

            // Documentation
            "README.md": "docs"
          };

          // Si l'utilisateur veut utiliser les mappages par défaut
          if (mcpAnswers.useDefaultMappings) {
            return { ...answers, ...mcpAnswers, fileMappings: defaultMappings, template: 'mcp' };
          }

          // Sinon, demander les mappages personnalisés
          return inquirer.prompt([
            {
              type: 'editor',
              name: 'customMappings',
              message: "Entrez les mappages personnalisés au format JSON (fichier: dossier):",
              default: JSON.stringify({
                "exemple1.ps1": "dossier1",
                "exemple2.txt": "dossier2",
                "exemple3.md": "dossier3"
              }, null, 2)
            }
          ]).then(customAnswers => {
            try {
              const fileMappings = JSON.parse(customAnswers.customMappings);
              return { ...answers, ...mcpAnswers, fileMappings, template: 'mcp' };
            } catch (error) {
              console.error("Erreur lors de l'analyse du JSON. Utilisation des mappages par défaut.");
              return { ...answers, ...mcpAnswers, fileMappings: defaultMappings, template: 'mcp' };
            }
          });
        });
      }
    });
  }
}
