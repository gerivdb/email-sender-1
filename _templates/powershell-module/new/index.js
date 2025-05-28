// development/templates/hygen/powershell-module/new/index.js
module.exports = {
  params: ({ args }) => {
    return {
      name: args.name,
      description: args.description || 'Module PowerShell standard',
      author: args.author || 'Augment Agent',
      category: args.category || 'core',
      type: args.type || 'standard'
    }
  },
  actions: (data) => {
    const { type } = data;
    const actions = [
      {
        type: 'add',
        path: 'development/scripts/{{category}}/modules/{{name}}/{{name}}.psd1',
        templateFile: 'development/templates/hygen/powershell-module/new/manifest.ejs.t'
      },
      {
        type: 'add',
        path: 'development/scripts/{{category}}/modules/{{name}}/Public/README.md',
        templateFile: 'development/templates/hygen/powershell-module/new/public-readme.ejs.t'
      },
      {
        type: 'add',
        path: 'development/scripts/{{category}}/modules/{{name}}/Private/README.md',
        templateFile: 'development/templates/hygen/powershell-module/new/private-readme.ejs.t'
      },
      {
        type: 'add',
        path: 'development/scripts/{{category}}/modules/{{name}}/Tests/{{name}}.Tests.ps1',
        templateFile: 'development/templates/hygen/powershell-module/new/tests.ejs.t'
      },
      {
        type: 'add',
        path: 'development/scripts/{{category}}/modules/{{name}}/README.md',
        templateFile: 'development/templates/hygen/powershell-module/new/readme.ejs.t'
      }
    ];

    // Ajouter le fichier de module approprié en fonction du type
    if (data.type === 'standard') {
      actions.push({
        type: 'add',
        path: 'development/scripts/{{category}}/modules/{{name}}/{{name}}.psm1',
        templateFile: 'development/templates/hygen/powershell-module/new/module.ejs.t'
      });
    } else if (data.type === 'advanced') {
      actions.push({
        type: 'add',
        path: 'development/scripts/{{category}}/modules/{{name}}/{{name}}.psm1',
        templateFile: 'development/templates/hygen/powershell-module/new/module-advanced.ejs.t'
      });
    } else if (data.type === 'extension') {
      actions.push({
        type: 'add',
        path: 'development/scripts/{{category}}/modules/{{name}}/{{name}}.psm1',
        templateFile: 'development/templates/hygen/powershell-module/new/module-extension.ejs.t'
      });
    }

    return actions;
  }
}
