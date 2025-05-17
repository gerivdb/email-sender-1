/**
 * Generate Cosmos Data
 * 
 * This script generates data for the cosmos visualization from roadmap JSON files.
 */

const fs = require('fs');
const path = require('path');
const converter = require('./cosmos-data-converter');

// Configuration
const config = {
  jsonDir: path.join(__dirname, '../../roadmaps/json'),
  outputDir: path.join(__dirname, '../../roadmaps/visualization/data'),
  sampleOutputPath: path.join(__dirname, '../../roadmaps/visualization/data/sample-cosmos-data.json'),
  options: {
    maxDepth: 10,
    includeCompleted: true,
    includeCancelled: false,
    maxNodesPerLevel: 100,
    priorityFilter: null,
    dimensionFilters: {}
  }
};

// Ensure output directory exists
if (!fs.existsSync(config.outputDir)) {
  fs.mkdirSync(config.outputDir, { recursive: true });
}

// Generate sample data
console.log('Generating sample cosmos data...');
converter.generateSampleCosmosData(config.sampleOutputPath);

// Convert all roadmap JSON files to cosmos data
console.log('Converting all roadmap JSON files to cosmos data...');
converter.convertAllRoadmapsToCosmosData(config.jsonDir, config.outputDir, config.options);

// Generate filtered versions for specific use cases
console.log('Generating filtered versions...');

// High priority only
const highPriorityOptions = {
  ...config.options,
  priorityFilter: 'high'
};
converter.convertAllRoadmapsToCosmosData(
  config.jsonDir,
  path.join(config.outputDir, 'high-priority'),
  highPriorityOptions
);

// Short-term only
const shortTermOptions = {
  ...config.options,
  dimensionFilters: {
    temporal: { horizon: 'short_term' }
  }
};
converter.convertAllRoadmapsToCosmosData(
  config.jsonDir,
  path.join(config.outputDir, 'short-term'),
  shortTermOptions
);

// In-progress only
const inProgressOptions = {
  ...config.options,
  includeCompleted: false,
  statusFilter: 'in_progress'
};
converter.convertAllRoadmapsToCosmosData(
  config.jsonDir,
  path.join(config.outputDir, 'in-progress'),
  inProgressOptions
);

console.log('Data generation completed!');

// Generate a combined visualization data file for all roadmaps
console.log('Generating combined visualization data...');

// Get all cosmos data files
const cosmosDataFiles = fs.readdirSync(config.outputDir)
  .filter(file => file.endsWith('-cosmos.json'))
  .map(file => path.join(config.outputDir, file));

if (cosmosDataFiles.length > 0) {
  // Create a combined data structure
  const combinedData = {
    id: 'combined-root',
    title: 'Combined Cognitive Architecture',
    type: 'cosmos',
    status: 'in_progress',
    description: 'Combined visualization of all roadmaps',
    metadata: {
      temporal: { horizon: 'all' },
      cognitive: { complexity: 'systemic' },
      organizational: { responsibility: 'organizational' },
      strategic: { priority: 'all' }
    },
    children: []
  };
  
  // Add each roadmap as a child
  for (const file of cosmosDataFiles) {
    try {
      const data = JSON.parse(fs.readFileSync(file, 'utf8'));
      combinedData.children.push(data);
    } catch (error) {
      console.error(`Error reading ${file}:`, error);
    }
  }
  
  // Save the combined data
  const combinedOutputPath = path.join(config.outputDir, 'combined-cosmos-data.json');
  fs.writeFileSync(combinedOutputPath, JSON.stringify(combinedData, null, 2), 'utf8');
  console.log(`Generated combined cosmos data: ${combinedOutputPath}`);
}

// Create an HTML file that loads the combined data
const htmlContent = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Combined Cognitive Architecture Visualization</title>
  <link rel="stylesheet" href="../cosmos-visualization.css">
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Combined Cognitive Architecture Visualization</h1>
    </div>
    
    <div class="controls">
      <button id="reset-view">Reset View</button>
      <button id="toggle-labels">Toggle Labels</button>
      <select id="filter-level">
        <option value="all">All Levels</option>
        <option value="cosmos">COSMOS</option>
        <option value="galaxy">GALAXIES</option>
        <option value="stellar_system">SYSTÈMES STELLAIRES</option>
        <option value="planet">PLANÈTES</option>
        <option value="continent">CONTINENTS</option>
        <option value="region">RÉGIONS</option>
        <option value="locality">LOCALITÉS</option>
        <option value="district">QUARTIERS</option>
        <option value="building">BÂTIMENTS</option>
        <option value="foundation">FONDATIONS</option>
      </select>
      <select id="color-by">
        <option value="level">Color by Level</option>
        <option value="temporal">Color by Temporal</option>
        <option value="cognitive">Color by Cognitive</option>
        <option value="organizational">Color by Organizational</option>
        <option value="strategic">Color by Strategic</option>
        <option value="status">Color by Status</option>
      </select>
    </div>
    
    <div class="visualization-container">
      <div id="cosmos-vis" class="cosmos-visualization"></div>
      
      <div class="details-panel" id="details-panel">
        <button class="close-button" id="close-details">&times;</button>
        <h2 id="details-title">Node Details</h2>
        <dl>
          <dt>Type</dt>
          <dd id="details-type"></dd>
          
          <dt>Status</dt>
          <dd id="details-status"></dd>
          
          <dt>Description</dt>
          <dd id="details-description"></dd>
          
          <dt>Dimensions</dt>
          <dd id="details-dimensions">
            <div><span class="dimension-indicator dimension-temporal"></span> Temporal: <span id="details-temporal">-</span></div>
            <div><span class="dimension-indicator dimension-cognitive"></span> Cognitive: <span id="details-cognitive">-</span></div>
            <div><span class="dimension-indicator dimension-organizational"></span> Organizational: <span id="details-organizational">-</span></div>
            <div><span class="dimension-indicator dimension-strategic"></span> Strategic: <span id="details-strategic">-</span></div>
          </dd>
        </dl>
      </div>
    </div>
  </div>
  
  <script src="https://d3js.org/d3.v7.min.js"></script>
  <script src="../cosmos-visualization.js"></script>
  <script>
    // Load the data
    fetch('data/combined-cosmos-data.json')
      .then(response => response.json())
      .then(data => {
        // Initialize the visualization
        const visualization = createCosmosVisualization('#cosmos-vis', data);
        
        // Set up event handlers
        document.getElementById('reset-view').addEventListener('click', function() {
          visualization.svg.transition()
            .duration(750)
            .call(visualization.zoom.transform, d3.zoomIdentity);
        });
        
        document.getElementById('toggle-labels').addEventListener('click', function() {
          const labels = d3.selectAll('.labels');
          const currentVisibility = labels.style('display');
          labels.style('display', currentVisibility === 'none' ? 'block' : 'none');
        });
        
        document.getElementById('filter-level').addEventListener('change', function() {
          const level = this.value;
          if (level === 'all') {
            d3.selectAll('.node').style('display', 'block');
          } else {
            d3.selectAll('.node').style('display', 'none');
            d3.selectAll(\`.node-\${level}\`).style('display', 'block');
          }
        });
        
        document.getElementById('color-by').addEventListener('change', function() {
          const colorBy = this.value;
          
          if (colorBy === 'level') {
            // Reset to default colors
            d3.selectAll('.node circle').each(function(d) {
              const levelStyle = visualization.config.levelStyles[d.data.type] || visualization.config.levelStyles.locality;
              d3.select(this).attr('fill', levelStyle.color);
            });
          } else if (colorBy === 'status') {
            // Color by status
            const statusColors = {
              planned: '#2196f3',
              in_progress: '#ff9800',
              completed: '#4caf50',
              blocked: '#f44336',
              cancelled: '#9e9e9e'
            };
            
            d3.selectAll('.node circle').each(function(d) {
              const status = d.data.status || 'planned';
              d3.select(this).attr('fill', statusColors[status]);
            });
          } else {
            // Color by dimension
            const dimensionColors = {
              temporal: d3.scaleOrdinal()
                .domain(['immediate', 'short_term', 'medium_term', 'long_term'])
                .range(['#b3e5fc', '#4fc3f7', '#0288d1', '#01579b']),
              cognitive: d3.scaleOrdinal()
                .domain(['simple', 'moderate', 'complex', 'systemic'])
                .range(['#e1bee7', '#ba68c8', '#8e24aa', '#4a148c']),
              organizational: d3.scaleOrdinal()
                .domain(['individual', 'team', 'inter_team', 'organizational'])
                .range(['#c8e6c9', '#81c784', '#43a047', '#1b5e20']),
              strategic: d3.scaleOrdinal()
                .domain(['low', 'medium', 'high', 'critical'])
                .range(['#ffcdd2', '#ef9a9a', '#e57373', '#c62828'])
            };
            
            d3.selectAll('.node circle').each(function(d) {
              const dimension = d.data.metadata && d.data.metadata[colorBy];
              let color = '#9e9e9e'; // Default gray
              
              if (dimension) {
                // Find the first non-empty dimension value
                const dimensionValue = Object.values(dimension)[0];
                if (dimensionValue && dimensionColors[colorBy]) {
                  color = dimensionColors[colorBy](dimensionValue);
                }
              }
              
              d3.select(this).attr('fill', color);
            });
          }
        });
        
        // Details panel functionality
        function showNodeDetails(d) {
          const panel = document.getElementById('details-panel');
          document.getElementById('details-title').textContent = d.data.title;
          document.getElementById('details-type').textContent = d.data.type.toUpperCase();
          document.getElementById('details-status').textContent = d.data.status || 'planned';
          document.getElementById('details-description').textContent = d.data.description || 'No description';
          
          // Display dimension values
          const dimensions = ['temporal', 'cognitive', 'organizational', 'strategic'];
          dimensions.forEach(dim => {
            const element = document.getElementById(\`details-\${dim}\`);
            const metadata = d.data.metadata && d.data.metadata[dim];
            
            if (metadata && Object.keys(metadata).length > 0) {
              element.textContent = Object.entries(metadata)
                .map(([key, value]) => \`\${key}: \${value}\`)
                .join(', ');
            } else {
              element.textContent = '-';
            }
          });
          
          panel.classList.add('visible');
        }
        
        document.getElementById('close-details').addEventListener('click', function() {
          document.getElementById('details-panel').classList.remove('visible');
        });
        
        // Override the showNodeDetails function in the visualization
        visualization.showNodeDetails = showNodeDetails;
      })
      .catch(error => {
        console.error('Error loading data:', error);
        document.getElementById('cosmos-vis').innerHTML = \`
          <div style="color: red; padding: 20px;">
            Error loading data: \${error.message}
          </div>
        \`;
      });
  </script>
</body>
</html>`;

const combinedHtmlPath = path.join(__dirname, 'combined-visualization.html');
fs.writeFileSync(combinedHtmlPath, htmlContent, 'utf8');
console.log(`Generated combined visualization HTML: ${combinedHtmlPath}`);
