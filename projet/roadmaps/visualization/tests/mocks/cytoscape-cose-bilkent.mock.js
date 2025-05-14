/**
 * Mock pour l'extension Cytoscape cose-bilkent
 */

// Fonction d'extension
const coseBilkent = (cytoscape) => {
  // Enregistrer l'extension
  cytoscape('layout', 'cose-bilkent', function(options) {
    return {
      run: function() {
        // Simuler un layout simple
        const nodes = this.options.eles.nodes();
        const spacing = 100;
        
        nodes.forEach((node, i) => {
          const row = Math.floor(i / 5);
          const col = i % 5;
          node.position({
            x: col * spacing,
            y: row * spacing
          });
        });
        
        return this;
      },
      stop: function() {
        return this;
      }
    };
  });
};

// Exporter le module
export default coseBilkent;
