/**
 * Cosmos Visualization for Cognitive Architecture
 *
 * This module provides a D3.js-based visualization of the cognitive architecture
 * as a cosmic system, with different levels represented as celestial objects.
 */

// In a browser environment, d3 is expected to be available globally
// const d3 = require('d3');

// Configuration
const config = {
  // Canvas dimensions
  width: 1200,
  height: 800,

  // Visual properties for each level
  levelStyles: {
    cosmos: {
      radius: 50,
      color: '#1a237e', // Deep blue
      orbitRadius: 0,
      orbitColor: 'transparent',
      icon: 'universe'
    },
    galaxy: {
      radius: 30,
      color: '#7b1fa2', // Purple
      orbitRadius: 150,
      orbitColor: 'rgba(123, 31, 162, 0.2)',
      icon: 'galaxy'
    },
    stellar_system: {
      radius: 20,
      color: '#d32f2f', // Red
      orbitRadius: 250,
      orbitColor: 'rgba(211, 47, 47, 0.2)',
      icon: 'solar-system'
    },
    planet: {
      radius: 15,
      color: '#ff9800', // Orange
      orbitRadius: 350,
      orbitColor: 'rgba(255, 152, 0, 0.2)',
      icon: 'planet'
    },
    continent: {
      radius: 10,
      color: '#ffc107', // Amber
      orbitRadius: 420,
      orbitColor: 'rgba(255, 193, 7, 0.2)',
      icon: 'continent'
    },
    region: {
      radius: 8,
      color: '#4caf50', // Green
      orbitRadius: 480,
      orbitColor: 'rgba(76, 175, 80, 0.2)',
      icon: 'region'
    },
    locality: {
      radius: 6,
      color: '#00bcd4', // Cyan
      orbitRadius: 530,
      orbitColor: 'rgba(0, 188, 212, 0.2)',
      icon: 'city'
    },
    district: {
      radius: 4,
      color: '#2196f3', // Blue
      orbitRadius: 570,
      orbitColor: 'rgba(33, 150, 243, 0.2)',
      icon: 'district'
    },
    building: {
      radius: 3,
      color: '#3f51b5', // Indigo
      orbitRadius: 600,
      orbitColor: 'rgba(63, 81, 181, 0.2)',
      icon: 'building'
    },
    foundation: {
      radius: 2,
      color: '#212121', // Almost black
      orbitRadius: 625,
      orbitColor: 'rgba(33, 33, 33, 0.2)',
      icon: 'foundation'
    }
  },

  // Dimension visualization properties
  dimensionStyles: {
    temporal: {
      property: 'brightness',
      scale: [0.7, 1.3],
      colorModifier: (baseColor, value) => d3.color(baseColor).brighter(value)
    },
    cognitive: {
      property: 'texture',
      scale: [0, 3],
      patternGenerator: (value) => `pattern-${Math.floor(value * 4)}`
    },
    organizational: {
      property: 'border',
      scale: [0, 5],
      borderGenerator: (value) => value * 5
    },
    strategic: {
      property: 'size',
      scale: [0.7, 1.5],
      sizeModifier: (baseSize, value) => baseSize * (0.7 + value * 0.8)
    }
  },

  // Animation settings
  animation: {
    orbitSpeed: 0.001,
    zoomDuration: 750,
    nodeClickDuration: 500
  },

  // Interaction settings
  interaction: {
    zoomExtent: [0.1, 10],
    tooltipDelay: 300,
    contextMenuItems: [
      { label: 'View Details', action: 'details' },
      { label: 'Edit', action: 'edit' },
      { label: 'Add Child', action: 'add-child' },
      { label: 'Delete', action: 'delete' }
    ]
  }
};

/**
 * Create a cosmos visualization for the cognitive architecture
 * @param {string} selector - CSS selector for the container element
 * @param {object} data - Hierarchical data representing the cognitive architecture
 * @param {object} options - Optional configuration overrides
 * @returns {object} - The visualization API
 */
function createCosmosVisualization(selector, data, options = {}) {
  // Merge options with default config
  const mergedConfig = {
    ...config,
    ...options,
    levelStyles: { ...config.levelStyles, ...(options.levelStyles || {}) },
    dimensionStyles: { ...config.dimensionStyles, ...(options.dimensionStyles || {}) },
    animation: { ...config.animation, ...(options.animation || {}) },
    interaction: { ...config.interaction, ...(options.interaction || {}) }
  };

  // Select the container element
  const container = d3.select(selector);

  // Create the SVG element
  const svg = container
    .append('svg')
    .attr('width', mergedConfig.width)
    .attr('height', mergedConfig.height)
    .attr('class', 'cosmos-visualization');

  // Create a group for the visualization
  const vis = svg
    .append('g')
    .attr('transform', `translate(${mergedConfig.width / 2}, ${mergedConfig.height / 2})`);

  // Create zoom behavior
  const zoom = d3.zoom()
    .scaleExtent(mergedConfig.interaction.zoomExtent)
    .on('zoom', (event) => {
      vis.attr('transform', event.transform);
    });

  // Apply zoom behavior to SVG
  svg.call(zoom);

  // Create a group for orbits
  const orbitsGroup = vis.append('g').attr('class', 'orbits');

  // Create a group for nodes
  const nodesGroup = vis.append('g').attr('class', 'nodes');

  // Create a group for labels
  const labelsGroup = vis.append('g').attr('class', 'labels');

  // Create a tooltip
  const tooltip = container
    .append('div')
    .attr('class', 'cosmos-tooltip')
    .style('position', 'absolute')
    .style('visibility', 'hidden')
    .style('background-color', 'rgba(0, 0, 0, 0.8)')
    .style('color', 'white')
    .style('padding', '8px')
    .style('border-radius', '4px')
    .style('pointer-events', 'none');

  // Create a context menu
  const contextMenu = container
    .append('div')
    .attr('class', 'cosmos-context-menu')
    .style('position', 'absolute')
    .style('visibility', 'hidden')
    .style('background-color', 'white')
    .style('border', '1px solid #ccc')
    .style('border-radius', '4px')
    .style('box-shadow', '0 2px 10px rgba(0, 0, 0, 0.2)')
    .style('padding', '4px 0')
    .style('z-index', '1000');

  // Add context menu items
  mergedConfig.interaction.contextMenuItems.forEach(item => {
    contextMenu
      .append('div')
      .attr('class', 'context-menu-item')
      .attr('data-action', item.action)
      .style('padding', '8px 12px')
      .style('cursor', 'pointer')
      .style('hover', 'background-color: #f0f0f0')
      .text(item.label)
      .on('click', function() {
        const action = d3.select(this).attr('data-action');
        const nodeData = d3.select(this.parentNode).datum();
        handleContextMenuAction(action, nodeData);
        hideContextMenu();
      });
  });

  // Function to handle context menu actions
  function handleContextMenuAction(action, nodeData) {
    switch (action) {
      case 'details':
        showNodeDetails(nodeData);
        break;
      case 'edit':
        editNode(nodeData);
        break;
      case 'add-child':
        addChildNode(nodeData);
        break;
      case 'delete':
        deleteNode(nodeData);
        break;
    }
  }

  // Function to show node details
  function showNodeDetails(nodeData) {
    console.log('Show details for:', nodeData);
    // Implementation will depend on the application's UI framework
  }

  // Function to edit a node
  function editNode(nodeData) {
    console.log('Edit node:', nodeData);
    // Implementation will depend on the application's UI framework
  }

  // Function to add a child node
  function addChildNode(nodeData) {
    console.log('Add child to:', nodeData);
    // Implementation will depend on the application's UI framework
  }

  // Function to delete a node
  function deleteNode(nodeData) {
    console.log('Delete node:', nodeData);
    // Implementation will depend on the application's UI framework
  }

  // Function to show the context menu
  function showContextMenu(event, d) {
    event.preventDefault();

    contextMenu
      .datum(d)
      .style('visibility', 'visible')
      .style('left', `${event.pageX}px`)
      .style('top', `${event.pageY}px`);
  }

  // Function to hide the context menu
  function hideContextMenu() {
    contextMenu.style('visibility', 'hidden');
  }

  // Hide context menu when clicking elsewhere
  d3.select('body').on('click', () => {
    hideContextMenu();
  });

  // Function to render the visualization
  function render() {
    // Clear existing elements
    orbitsGroup.selectAll('*').remove();
    nodesGroup.selectAll('*').remove();
    labelsGroup.selectAll('*').remove();

    // Create hierarchical layout
    const root = d3.hierarchy(data);

    // Draw orbits
    Object.entries(mergedConfig.levelStyles).forEach(([type, style]) => {
      if (style.orbitRadius > 0) {
        orbitsGroup
          .append('circle')
          .attr('r', style.orbitRadius)
          .attr('fill', 'none')
          .attr('stroke', style.orbitColor)
          .attr('stroke-width', 1)
          .attr('stroke-dasharray', '3,3')
          .attr('class', `orbit-${type}`);
      }
    });

    // Function to position nodes based on their level
    function positionNode(d) {
      const levelStyle = mergedConfig.levelStyles[d.data.type] || mergedConfig.levelStyles.locality;
      const orbitRadius = levelStyle.orbitRadius;

      // Position based on orbit and index within level
      const siblings = root.descendants().filter(node => node.depth === d.depth);
      const index = siblings.indexOf(d);
      const angle = (index / siblings.length) * 2 * Math.PI;

      return {
        x: orbitRadius * Math.cos(angle),
        y: orbitRadius * Math.sin(angle)
      };
    }

    // Draw nodes
    const nodes = nodesGroup
      .selectAll('.node')
      .data(root.descendants())
      .enter()
      .append('g')
      .attr('class', d => `node node-${d.data.type}`)
      .attr('transform', d => {
        const pos = positionNode(d);
        return `translate(${pos.x}, ${pos.y})`;
      });

    // Add circles for nodes
    nodes
      .append('circle')
      .attr('r', d => {
        const levelStyle = mergedConfig.levelStyles[d.data.type] || mergedConfig.levelStyles.locality;
        return levelStyle.radius;
      })
      .attr('fill', d => {
        const levelStyle = mergedConfig.levelStyles[d.data.type] || mergedConfig.levelStyles.locality;
        return levelStyle.color;
      })
      .attr('stroke', 'white')
      .attr('stroke-width', 1);

    // Add labels
    labelsGroup
      .selectAll('.label')
      .data(root.descendants().filter(d => d.depth <= 2)) // Only show labels for top 3 levels
      .enter()
      .append('text')
      .attr('class', 'label')
      .attr('transform', d => {
        const pos = positionNode(d);
        return `translate(${pos.x}, ${pos.y + 20})`;
      })
      .attr('text-anchor', 'middle')
      .attr('font-size', d => {
        const levelStyle = mergedConfig.levelStyles[d.data.type] || mergedConfig.levelStyles.locality;
        return levelStyle.radius * 0.8;
      })
      .text(d => d.data.title);

    // Add interactions
    nodes
      .on('mouseover', function(event, d) {
        // Show tooltip
        tooltip
          .html(`
            <div><strong>${d.data.title}</strong></div>
            <div>${d.data.type.toUpperCase()}</div>
            ${d.data.description ? `<div>${d.data.description}</div>` : ''}
            <div>Status: ${d.data.status}</div>
          `)
          .style('visibility', 'visible')
          .style('left', `${event.pageX + 10}px`)
          .style('top', `${event.pageY + 10}px`);

        // Highlight node
        d3.select(this).select('circle')
          .attr('stroke', 'yellow')
          .attr('stroke-width', 2);
      })
      .on('mousemove', function(event) {
        tooltip
          .style('left', `${event.pageX + 10}px`)
          .style('top', `${event.pageY + 10}px`);
      })
      .on('mouseout', function() {
        // Hide tooltip
        tooltip.style('visibility', 'hidden');

        // Remove highlight
        d3.select(this).select('circle')
          .attr('stroke', 'white')
          .attr('stroke-width', 1);
      })
      .on('click', function(event, d) {
        // Center and zoom to node
        const pos = positionNode(d);
        const transform = d3.zoomIdentity
          .translate(mergedConfig.width / 2 - pos.x, mergedConfig.height / 2 - pos.y)
          .scale(2);

        svg.transition()
          .duration(mergedConfig.animation.zoomDuration)
          .call(zoom.transform, transform);
      })
      .on('contextmenu', function(event, d) {
        showContextMenu(event, d);
      });
  }

  // Initial render
  render();

  // Return the visualization API
  return {
    render,
    svg,
    zoom,
    config: mergedConfig,
    updateData: function(newData) {
      data = newData;
      render();
    },
    updateConfig: function(newOptions) {
      Object.assign(mergedConfig, newOptions);
      render();
    }
  };
}

// In a browser environment, expose the function globally
// module.exports = {
//   createCosmosVisualization
// };

// Make the function available globally in browser environments
if (typeof window !== 'undefined') {
  window.createCosmosVisualization = createCosmosVisualization;
}
