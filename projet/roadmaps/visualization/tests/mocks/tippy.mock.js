/**
 * Mock pour tippy.js
 */

// Fonction tippy
const tippy = (element, options) => {
  return {
    setContent: (content) => {},
    setProps: (props) => {},
    show: () => {},
    hide: () => {},
    destroy: () => {}
  };
};

// Ajouter des méthodes statiques
tippy.setDefaultProps = (props) => {};

// Exporter le module
export default tippy;
