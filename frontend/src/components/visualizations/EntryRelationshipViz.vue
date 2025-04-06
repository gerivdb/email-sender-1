<template>
  <div class="entry-relationship-container">
    <div class="controls">
      <div class="filter-options">
        <div class="date-range">
          <label>Période:</label>
          <select v-model="dateRange">
            <option value="all">Toutes les entrées</option>
            <option value="month">Dernier mois</option>
            <option value="3months">3 derniers mois</option>
            <option value="6months">6 derniers mois</option>
            <option value="year">Dernière année</option>
          </select>
        </div>
        
        <div class="tag-filter">
          <label>Filtrer par tag:</label>
          <select v-model="selectedTag">
            <option value="">Tous les tags</option>
            <option v-for="tag in allTags" :key="tag.name" :value="tag.name">
              {{ tag.name }} ({{ tag.count }})
            </option>
          </select>
        </div>
      </div>
      
      <div class="display-options">
        <label>
          <input type="checkbox" v-model="showLabels" />
          Afficher les labels
        </label>
        <label>
          <input type="checkbox" v-model="groupByTag" />
          Grouper par tag
        </label>
      </div>
    </div>
    
    <div class="visualization" ref="visualization"></div>
    
    <div class="legend">
      <div class="legend-item">
        <div class="color-box entry"></div>
        <span>Entrée du journal</span>
      </div>
      <div class="legend-item">
        <div class="color-box github"></div>
        <span>Commit GitHub</span>
      </div>
      <div class="legend-item">
        <div class="color-box jira"></div>
        <span>Issue Jira</span>
      </div>
      <div class="legend-item">
        <div class="color-box notion"></div>
        <span>Page Notion</span>
      </div>
    </div>
    
    <div v-if="selectedNode" class="node-details">
      <div class="node-header">
        <h3>{{ selectedNode.title }}</h3>
        <span class="node-type" :class="selectedNode.type">{{ selectedNode.type }}</span>
      </div>
      
      <div v-if="selectedNode.type === 'entry'" class="entry-details">
        <p><strong>Date:</strong> {{ formatDate(selectedNode.date) }}</p>
        <p v-if="selectedNode.tags && selectedNode.tags.length > 0">
          <strong>Tags:</strong>
          <span 
            v-for="tag in selectedNode.tags" 
            :key="tag"
            class="tag-badge"
          >
            {{ tag }}
          </span>
        </p>
        <p v-if="selectedNode.excerpt"><em>{{ selectedNode.excerpt }}</em></p>
        <button @click="$emit('view-entry', selectedNode.id)" class="view-button">
          Voir l'entrée complète
        </button>
      </div>
      
      <div v-else-if="selectedNode.type === 'github'" class="github-details">
        <p><strong>Commit:</strong> {{ selectedNode.sha.substring(0, 7) }}</p>
        <p><strong>Date:</strong> {{ formatDate(selectedNode.date) }}</p>
        <p><strong>Auteur:</strong> {{ selectedNode.author }}</p>
        <p v-if="selectedNode.message"><em>{{ selectedNode.message }}</em></p>
        <button @click="openGitHubCommit(selectedNode.sha)" class="view-button">
          Voir sur GitHub
        </button>
      </div>
      
      <div v-else-if="selectedNode.type === 'jira'" class="jira-details">
        <p><strong>Issue:</strong> {{ selectedNode.key }}</p>
        <p><strong>État:</strong> {{ selectedNode.status }}</p>
        <p><strong>Assigné à:</strong> {{ selectedNode.assignee || 'Non assigné' }}</p>
        <p v-if="selectedNode.description"><em>{{ truncate(selectedNode.description, 150) }}</em></p>
        <button @click="openJiraIssue(selectedNode.key)" class="view-button">
          Voir sur Jira
        </button>
      </div>
      
      <div v-else-if="selectedNode.type === 'notion'" class="notion-details">
        <p><strong>Page:</strong> {{ selectedNode.title }}</p>
        <p><strong>Dernière modification:</strong> {{ formatDate(selectedNode.lastEdited) }}</p>
        <p v-if="selectedNode.excerpt"><em>{{ selectedNode.excerpt }}</em></p>
        <button @click="openNotionPage(selectedNode.id)" class="view-button">
          Voir sur Notion
        </button>
      </div>
      
      <div class="related-nodes">
        <h4>Éléments liés</h4>
        <ul>
          <li v-for="node in relatedNodes" :key="node.id">
            <a @click.prevent="selectNode(node)" href="#" :class="node.type">
              {{ node.title }}
            </a>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script>
import * as d3 from 'd3';
import { mapGetters } from 'vuex';

export default {
  name: 'EntryRelationshipViz',
  props: {
    width: {
      type: Number,
      default: 800
    },
    height: {
      type: Number,
      default: 600
    }
  },
  data() {
    return {
      dateRange: '3months',
      selectedTag: '',
      showLabels: true,
      groupByTag: false,
      selectedNode: null,
      relatedNodes: [],
      simulation: null,
      svg: null,
      nodes: [],
      links: [],
      nodeElements: null,
      linkElements: null,
      textElements: null,
      zoom: null
    };
  },
  computed: {
    ...mapGetters('journal', ['allEntries', 'allTags']),
    ...mapGetters('github', ['allCommits']),
    ...mapGetters('jira', ['allIssues']),
    ...mapGetters('notion', ['allPages']),
    
    filteredData() {
      // Filtrer les entrées par date
      let entries = [...this.allEntries];
      
      if (this.dateRange !== 'all') {
        const now = new Date();
        let cutoffDate;
        
        switch (this.dateRange) {
          case 'month':
            cutoffDate = new Date(now.setMonth(now.getMonth() - 1));
            break;
          case '3months':
            cutoffDate = new Date(now.setMonth(now.getMonth() - 3));
            break;
          case '6months':
            cutoffDate = new Date(now.setMonth(now.getMonth() - 6));
            break;
          case 'year':
            cutoffDate = new Date(now.setFullYear(now.getFullYear() - 1));
            break;
        }
        
        entries = entries.filter(entry => new Date(entry.date) >= cutoffDate);
      }
      
      // Filtrer par tag si nécessaire
      if (this.selectedTag) {
        entries = entries.filter(entry => 
          entry.tags && entry.tags.includes(this.selectedTag)
        );
      }
      
      return entries;
    }
  },
  watch: {
    dateRange() {
      this.updateVisualization();
    },
    selectedTag() {
      this.updateVisualization();
    },
    showLabels() {
      this.updateLabels();
    },
    groupByTag() {
      this.updateVisualization();
    },
    allEntries() {
      this.updateVisualization();
    },
    allCommits() {
      this.updateVisualization();
    },
    allIssues() {
      this.updateVisualization();
    },
    allPages() {
      this.updateVisualization();
    }
  },
  mounted() {
    this.initVisualization();
    this.fetchData();
  },
  methods: {
    async fetchData() {
      // Charger les données nécessaires
      if (this.allEntries.length === 0) {
        await this.$store.dispatch('journal/fetchEntries');
      }
      
      if (this.allTags.length === 0) {
        await this.$store.dispatch('journal/fetchTags');
      }
      
      if (this.allCommits.length === 0) {
        await this.$store.dispatch('github/fetchCommits');
      }
      
      if (this.allIssues.length === 0) {
        await this.$store.dispatch('jira/fetchIssues');
      }
      
      if (this.allPages.length === 0) {
        await this.$store.dispatch('notion/fetchPages');
      }
      
      this.updateVisualization();
    },
    
    initVisualization() {
      const container = this.$refs.visualization;
      
      // Créer le SVG
      this.svg = d3.select(container)
        .append('svg')
        .attr('width', this.width)
        .attr('height', this.height)
        .attr('viewBox', [0, 0, this.width, this.height]);
      
      // Ajouter un groupe pour le graphe
      const g = this.svg.append('g');
      
      // Ajouter le zoom
      this.zoom = d3.zoom()
        .scaleExtent([0.1, 4])
        .on('zoom', (event) => {
          g.attr('transform', event.transform);
        });
      
      this.svg.call(this.zoom);
      
      // Ajouter les groupes pour les liens et les nœuds
      g.append('g').attr('class', 'links');
      g.append('g').attr('class', 'nodes');
      g.append('g').attr('class', 'texts');
      
      // Créer la simulation de force
      this.simulation = d3.forceSimulation()
        .force('link', d3.forceLink().id(d => d.id).distance(100))
        .force('charge', d3.forceManyBody().strength(-300))
        .force('center', d3.forceCenter(this.width / 2, this.height / 2))
        .force('collision', d3.forceCollide().radius(30));
    },
    
    updateVisualization() {
      if (this.allEntries.length === 0) return;
      
      // Préparer les données
      const { nodes, links } = this.prepareGraphData();
      this.nodes = nodes;
      this.links = links;
      
      // Mettre à jour les liens
      this.linkElements = this.svg.select('.links')
        .selectAll('line')
        .data(links, d => `${d.source.id}-${d.target.id}`);
      
      this.linkElements.exit().remove();
      
      const newLinks = this.linkElements.enter()
        .append('line')
        .attr('stroke-width', d => Math.sqrt(d.value))
        .attr('stroke', '#999')
        .attr('stroke-opacity', 0.6);
      
      this.linkElements = newLinks.merge(this.linkElements);
      
      // Mettre à jour les nœuds
      this.nodeElements = this.svg.select('.nodes')
        .selectAll('circle')
        .data(nodes, d => d.id);
      
      this.nodeElements.exit().remove();
      
      const newNodes = this.nodeElements.enter()
        .append('circle')
        .attr('r', d => this.getNodeRadius(d))
        .attr('fill', d => this.getNodeColor(d))
        .attr('stroke', '#fff')
        .attr('stroke-width', 1.5)
        .style('cursor', 'pointer')
        .on('click', (event, d) => this.selectNode(d))
        .call(this.drag());
      
      this.nodeElements = newNodes.merge(this.nodeElements);
      
      // Mettre à jour les labels
      this.updateLabels();
      
      // Mettre à jour la simulation
      this.simulation.nodes(nodes);
      this.simulation.force('link').links(links);
      
      // Appliquer le groupement par tag si nécessaire
      if (this.groupByTag) {
        this.simulation.force('x', d3.forceX().x(d => this.getTagPosition(d).x).strength(0.3));
        this.simulation.force('y', d3.forceY().y(d => this.getTagPosition(d).y).strength(0.3));
      } else {
        this.simulation.force('x', null);
        this.simulation.force('y', null);
      }
      
      this.simulation.alpha(1).restart();
      
      // Mettre à jour les positions à chaque tick
      this.simulation.on('tick', () => {
        this.linkElements
          .attr('x1', d => d.source.x)
          .attr('y1', d => d.source.y)
          .attr('x2', d => d.target.x)
          .attr('y2', d => d.target.y);
        
        this.nodeElements
          .attr('cx', d => d.x)
          .attr('cy', d => d.y);
        
        if (this.textElements) {
          this.textElements
            .attr('x', d => d.x)
            .attr('y', d => d.y + this.getNodeRadius(d) + 12);
        }
      });
    },
    
    updateLabels() {
      if (!this.nodes) return;
      
      this.textElements = this.svg.select('.texts')
        .selectAll('text')
        .data(this.showLabels ? this.nodes : [], d => d.id);
      
      this.textElements.exit().remove();
      
      const newTexts = this.textElements.enter()
        .append('text')
        .text(d => this.truncate(d.title, 20))
        .attr('text-anchor', 'middle')
        .attr('font-size', '10px')
        .attr('fill', '#333');
      
      this.textElements = newTexts.merge(this.textElements);
    },
    
    prepareGraphData() {
      const nodes = [];
      const links = [];
      const nodeMap = new Map();
      
      // Ajouter les entrées du journal
      this.filteredData.forEach(entry => {
        const node = {
          id: entry.file,
          title: entry.title,
          type: 'entry',
          date: entry.date,
          tags: entry.tags || [],
          excerpt: entry.excerpt
        };
        
        nodes.push(node);
        nodeMap.set(node.id, node);
      });
      
      // Ajouter les commits GitHub liés
      this.allCommits.forEach(commit => {
        // Vérifier si le commit est lié à une entrée
        const linkedEntries = this.filteredData.filter(entry => 
          commit.linkedEntries && commit.linkedEntries.includes(entry.file)
        );
        
        if (linkedEntries.length > 0) {
          const node = {
            id: `github-${commit.sha}`,
            title: commit.message.split('\n')[0],
            type: 'github',
            sha: commit.sha,
            date: commit.date,
            author: commit.author,
            message: commit.message
          };
          
          nodes.push(node);
          nodeMap.set(node.id, node);
          
          // Créer les liens
          linkedEntries.forEach(entry => {
            links.push({
              source: node.id,
              target: entry.file,
              value: 1
            });
          });
        }
      });
      
      // Ajouter les issues Jira liées
      this.allIssues.forEach(issue => {
        // Vérifier si l'issue est liée à une entrée
        const linkedEntries = this.filteredData.filter(entry => 
          issue.linkedEntries && issue.linkedEntries.includes(entry.file)
        );
        
        if (linkedEntries.length > 0) {
          const node = {
            id: `jira-${issue.key}`,
            title: issue.summary,
            type: 'jira',
            key: issue.key,
            status: issue.status,
            assignee: issue.assignee,
            description: issue.description
          };
          
          nodes.push(node);
          nodeMap.set(node.id, node);
          
          // Créer les liens
          linkedEntries.forEach(entry => {
            links.push({
              source: node.id,
              target: entry.file,
              value: 1
            });
          });
        }
      });
      
      // Ajouter les pages Notion liées
      this.allPages.forEach(page => {
        // Vérifier si la page est liée à une entrée
        const linkedEntries = this.filteredData.filter(entry => 
          page.linkedEntries && page.linkedEntries.includes(entry.file)
        );
        
        if (linkedEntries.length > 0) {
          const node = {
            id: `notion-${page.id}`,
            title: page.title,
            type: 'notion',
            lastEdited: page.lastEdited,
            excerpt: page.excerpt
          };
          
          nodes.push(node);
          nodeMap.set(node.id, node);
          
          // Créer les liens
          linkedEntries.forEach(entry => {
            links.push({
              source: node.id,
              target: entry.file,
              value: 1
            });
          });
        }
      });
      
      // Ajouter les liens entre entrées (related)
      this.filteredData.forEach(entry => {
        if (entry.related && entry.related.length > 0) {
          entry.related.forEach(relatedFile => {
            if (nodeMap.has(relatedFile)) {
              links.push({
                source: entry.file,
                target: relatedFile,
                value: 2
              });
            }
          });
        }
      });
      
      return { nodes, links };
    },
    
    getNodeRadius(node) {
      switch (node.type) {
        case 'entry':
          return 10;
        case 'github':
          return 8;
        case 'jira':
          return 8;
        case 'notion':
          return 8;
        default:
          return 6;
      }
    },
    
    getNodeColor(node) {
      switch (node.type) {
        case 'entry':
          return '#4299e1'; // blue-500
        case 'github':
          return '#68d391'; // green-400
        case 'jira':
          return '#f6ad55'; // orange-400
        case 'notion':
          return '#9f7aea'; // purple-400
        default:
          return '#a0aec0'; // gray-400
      }
    },
    
    getTagPosition(node) {
      if (node.type !== 'entry' || !node.tags || node.tags.length === 0) {
        return { x: this.width / 2, y: this.height / 2 };
      }
      
      // Utiliser le premier tag pour le positionnement
      const tag = node.tags[0];
      const tagIndex = this.allTags.findIndex(t => t.name === tag);
      
      if (tagIndex === -1) {
        return { x: this.width / 2, y: this.height / 2 };
      }
      
      // Disposer les tags en cercle
      const tagCount = this.allTags.length;
      const angle = (tagIndex / tagCount) * 2 * Math.PI;
      const radius = Math.min(this.width, this.height) * 0.4;
      
      return {
        x: this.width / 2 + radius * Math.cos(angle),
        y: this.height / 2 + radius * Math.sin(angle)
      };
    },
    
    drag() {
      const simulation = this.simulation;
      
      function dragstarted(event) {
        if (!event.active) simulation.alphaTarget(0.3).restart();
        event.subject.fx = event.subject.x;
        event.subject.fy = event.subject.y;
      }
      
      function dragged(event) {
        event.subject.fx = event.x;
        event.subject.fy = event.y;
      }
      
      function dragended(event) {
        if (!event.active) simulation.alphaTarget(0);
        event.subject.fx = null;
        event.subject.fy = null;
      }
      
      return d3.drag()
        .on('start', dragstarted)
        .on('drag', dragged)
        .on('end', dragended);
    },
    
    selectNode(node) {
      this.selectedNode = node;
      
      // Trouver les nœuds liés
      this.relatedNodes = [];
      
      this.links.forEach(link => {
        if (link.source.id === node.id) {
          const targetNode = this.nodes.find(n => n.id === link.target.id);
          if (targetNode && !this.relatedNodes.some(n => n.id === targetNode.id)) {
            this.relatedNodes.push(targetNode);
          }
        } else if (link.target.id === node.id) {
          const sourceNode = this.nodes.find(n => n.id === link.source.id);
          if (sourceNode && !this.relatedNodes.some(n => n.id === sourceNode.id)) {
            this.relatedNodes.push(sourceNode);
          }
        }
      });
      
      // Mettre en évidence le nœud sélectionné et ses liens
      this.nodeElements
        .attr('opacity', d => (d.id === node.id || this.relatedNodes.some(n => n.id === d.id)) ? 1 : 0.3);
      
      this.linkElements
        .attr('opacity', d => (d.source.id === node.id || d.target.id === node.id) ? 0.8 : 0.1);
      
      if (this.textElements) {
        this.textElements
          .attr('opacity', d => (d.id === node.id || this.relatedNodes.some(n => n.id === d.id)) ? 1 : 0.3);
      }
    },
    
    resetSelection() {
      this.selectedNode = null;
      this.relatedNodes = [];
      
      this.nodeElements.attr('opacity', 1);
      this.linkElements.attr('opacity', 0.6);
      
      if (this.textElements) {
        this.textElements.attr('opacity', 1);
      }
    },
    
    openGitHubCommit(sha) {
      const repoUrl = this.$store.getters['github/repoUrl'];
      window.open(`${repoUrl}/commit/${sha}`, '_blank');
    },
    
    openJiraIssue(key) {
      const jiraUrl = this.$store.getters['jira/jiraUrl'];
      window.open(`${jiraUrl}/browse/${key}`, '_blank');
    },
    
    openNotionPage(id) {
      const notionUrl = this.$store.getters['notion/notionUrl'];
      window.open(`${notionUrl}/${id}`, '_blank');
    },
    
    formatDate(dateString) {
      if (!dateString) return '';
      const date = new Date(dateString);
      return date.toLocaleDateString('fr-FR', {
        year: 'numeric',
        month: 'short',
        day: 'numeric'
      });
    },
    
    truncate(text, length) {
      if (!text) return '';
      return text.length > length ? text.substring(0, length) + '...' : text;
    }
  }
};
</script>

<style scoped>
.entry-relationship-container {
  @apply flex flex-col h-full;
}

.controls {
  @apply flex justify-between mb-4;
}

.filter-options {
  @apply flex;
}

.date-range, .tag-filter {
  @apply flex items-center mr-4;
}

.date-range label, .tag-filter label {
  @apply mr-2;
}

.date-range select, .tag-filter select {
  @apply px-3 py-1 border border-gray-300 rounded-lg bg-white focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent;
}

.display-options {
  @apply flex items-center;
}

.display-options label {
  @apply flex items-center ml-4;
}

.display-options input {
  @apply mr-2;
}

.visualization {
  @apply flex-1 border border-gray-200 rounded-lg overflow-hidden;
}

.legend {
  @apply flex flex-wrap mt-4;
}

.legend-item {
  @apply flex items-center mr-4 mb-2;
}

.color-box {
  @apply w-4 h-4 mr-2 rounded;
}

.color-box.entry {
  @apply bg-blue-500;
}

.color-box.github {
  @apply bg-green-400;
}

.color-box.jira {
  @apply bg-orange-400;
}

.color-box.notion {
  @apply bg-purple-400;
}

.node-details {
  @apply mt-4 p-4 border border-gray-200 rounded-lg bg-gray-50;
}

.node-header {
  @apply flex items-center justify-between mb-2;
}

.node-header h3 {
  @apply mt-0 text-xl font-semibold;
}

.node-type {
  @apply px-2 py-1 rounded-full text-white text-xs;
}

.node-type.entry {
  @apply bg-blue-500;
}

.node-type.github {
  @apply bg-green-400;
}

.node-type.jira {
  @apply bg-orange-400;
}

.node-type.notion {
  @apply bg-purple-400;
}

.tag-badge {
  @apply inline-block px-2 py-1 mr-1 mb-1 bg-gray-200 rounded-full text-xs;
}

.view-button {
  @apply mt-2 px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2;
}

.related-nodes {
  @apply mt-4 pt-4 border-t border-gray-200;
}

.related-nodes h4 {
  @apply text-lg font-semibold mb-2;
}

.related-nodes ul {
  @apply pl-6;
}

.related-nodes a {
  @apply hover:underline;
}

.related-nodes a.entry {
  @apply text-blue-500;
}

.related-nodes a.github {
  @apply text-green-600;
}

.related-nodes a.jira {
  @apply text-orange-600;
}

.related-nodes a.notion {
  @apply text-purple-600;
}
</style>
