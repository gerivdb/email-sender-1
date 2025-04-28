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
    }
  }
}
