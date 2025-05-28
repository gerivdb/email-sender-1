<!-- 
  Générateur de points de vigilance avec niveaux de gravité
  Utilisation :
  - Inclure ce fichier dans plan-dev.ejs avec la syntaxe EJS :
    <%~ include('warnings.ejs', { warnings: warnings }) %>
  - 'warnings' doit être un tableau d'objets { message: 'Message', severity: 'Gravité' }
-->
<% if (typeof warnings !== 'undefined' && warnings.length > 0) { %>
## Points de vigilance
<% warnings.forEach(function(w) { %>
- ⚠️ (<%= w.severity %>) <%= w.message %>
<% }) %>
<% } %>