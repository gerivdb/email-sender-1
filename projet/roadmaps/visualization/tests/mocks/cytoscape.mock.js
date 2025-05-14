/**
 * Mock pour le module Cytoscape
 */

// Classe pour les éléments Cytoscape
class CyElement {
  constructor(data = {}, isNode = true) {
    this._data = data;
    this._isNode = isNode;
    this._isEdge = !isNode;
    this._visible = true;
    this._style = {};
    this._position = { x: 0, y: 0 };
    this._renderedPosition = { x: 0, y: 0 };
    this._renderedBoundingBox = { x: 0, y: 0, w: 50, h: 50 };
    this._classes = new Set();
  }
  
  data(key, value) {
    if (value !== undefined) {
      this._data[key] = value;
      return this;
    }
    return key ? this._data[key] : this._data;
  }
  
  id() {
    return this._data.id || 'mock-id';
  }
  
  isNode() {
    return this._isNode;
  }
  
  isEdge() {
    return this._isEdge;
  }
  
  style(key, value) {
    if (value !== undefined) {
      this._style[key] = value;
      return this;
    }
    return key ? this._style[key] : this._style;
  }
  
  position(pos) {
    if (pos !== undefined) {
      this._position = pos;
      return this;
    }
    return this._position;
  }
  
  renderedPosition() {
    return this._renderedPosition;
  }
  
  renderedBoundingBox() {
    return this._renderedBoundingBox;
  }
  
  visible() {
    return this._visible;
  }
  
  addClass(className) {
    this._classes.add(className);
    return this;
  }
  
  removeClass(className) {
    this._classes.delete(className);
    return this;
  }
  
  hasClass(className) {
    return this._classes.has(className);
  }
  
  connectedEdges() {
    return new CyCollection([]);
  }
  
  connectedNodes() {
    return new CyCollection([]);
  }
  
  animation(params) {
    return {
      play: () => this,
      promise: () => Promise.resolve()
    };
  }
}

// Classe pour les collections Cytoscape
class CyCollection {
  constructor(elements = []) {
    this.elements = elements;
  }
  
  filter(callback) {
    const filtered = this.elements.filter(callback);
    return new CyCollection(filtered);
  }
  
  nodes() {
    const nodes = this.elements.filter(el => el.isNode());
    return new CyCollection(nodes);
  }
  
  edges() {
    const edges = this.elements.filter(el => el.isEdge());
    return new CyCollection(edges);
  }
  
  edgesWith() {
    return this;
  }
  
  union(collection) {
    return new CyCollection([...this.elements, ...collection.elements]);
  }
  
  contains(element) {
    return this.elements.includes(element);
  }
  
  forEach(callback) {
    this.elements.forEach(callback);
  }
  
  map(callback) {
    return this.elements.map(callback);
  }
  
  get length() {
    return this.elements.length;
  }
  
  toArray() {
    return this.elements;
  }
  
  getElementById(id) {
    return this.elements.find(el => el.id() === id) || null;
  }
}

// Classe principale Cytoscape
class Cytoscape {
  constructor(options = {}) {
    this._container = options.container || document.createElement('div');
    this._elements = [];
    this._style = {};
    this._zoom = 1;
    this._pan = { x: 0, y: 0 };
    this._eventHandlers = {};
    
    // Ajouter les éléments initiaux
    if (options.elements) {
      this.add(options.elements);
    }
  }
  
  elements() {
    return new CyCollection(this._elements);
  }
  
  nodes() {
    return this.elements().nodes();
  }
  
  edges() {
    return this.elements().edges();
  }
  
  add(elements) {
    if (Array.isArray(elements)) {
      elements.forEach(el => {
        const isNode = el.group !== 'edges';
        const cyElement = new CyElement(el.data, isNode);
        this._elements.push(cyElement);
      });
    }
    return this;
  }
  
  remove(elements) {
    if (elements) {
      const ids = elements.map(el => el.id());
      this._elements = this._elements.filter(el => !ids.includes(el.id()));
    }
    return this;
  }
  
  style(key, value) {
    if (value !== undefined) {
      this._style[key] = value;
      return this;
    }
    return this;
  }
  
  selector() {
    return this;
  }
  
  update() {
    // Ne rien faire
    return this;
  }
  
  on(event, selector, callback) {
    if (!this._eventHandlers[event]) {
      this._eventHandlers[event] = [];
    }
    this._eventHandlers[event].push({ selector, callback });
    return this;
  }
  
  off(event, selector, callback) {
    if (this._eventHandlers[event]) {
      this._eventHandlers[event] = this._eventHandlers[event].filter(handler => {
        return handler.selector !== selector || handler.callback !== callback;
      });
    }
    return this;
  }
  
  container() {
    return this._container;
  }
  
  zoom(value) {
    if (value !== undefined) {
      this._zoom = value;
      return this;
    }
    return this._zoom;
  }
  
  pan(value) {
    if (value !== undefined) {
      this._pan = value;
      return this;
    }
    return this._pan;
  }
  
  fit() {
    // Ne rien faire
    return this;
  }
  
  center() {
    // Ne rien faire
    return this;
  }
  
  getElementById(id) {
    return this._elements.find(el => el.id() === id) || null;
  }
  
  png() {
    return Promise.resolve(new Blob());
  }
  
  jpg() {
    return Promise.resolve(new Blob());
  }
  
  svg() {
    return Promise.resolve(new Blob());
  }
}

// Fonction factory pour créer une instance Cytoscape
const cytoscape = (options) => {
  return new Cytoscape(options);
};

// Ajouter des méthodes statiques
cytoscape.use = (extension) => {
  // Ne rien faire
};

// Exporter le module
export default cytoscape;
