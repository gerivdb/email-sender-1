// development/templates/hygen/script/new/index.js
module.exports = {
  params: ({ args }) => {
    return {
      name: args.name,
      category: args.category || 'maintenance',
      description: args.description || 'Script PowerShell',
      author: args.author || 'Augment Agent'
    }
  },
  actions: [
    {
      type: 'add',
      path: 'development/scripts/{{category}}/{{name}}.ps1',
      templateFile: './script/new/script.ejs'
    }
  ]
}
