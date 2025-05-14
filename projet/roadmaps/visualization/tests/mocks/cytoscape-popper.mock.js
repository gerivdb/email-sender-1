/**
 * Mock pour l'extension Cytoscape popper
 */

// Fonction d'extension
const popper = (cytoscape) => {
  // Enregistrer l'extension
  cytoscape('core', 'popper', function(options) {
    return {
      destroy: () => {}
    };
  });
  
  cytoscape('collection', 'popper', function(options) {
    return {
      destroy: () => {}
    };
  });
};

// Exporter le module
export default popper;
