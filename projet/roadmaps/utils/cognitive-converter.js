/**
 * Cognitive Architecture Converter
 *
 * Utilities for converting between Markdown and JSON formats
 * for the cognitive architecture roadmap system.
 */

const fs = require('fs');
const path = require('path');

// Load hierarchy definitions
const hierarchyDefinitions = require('../models/hierarchy-definitions.json');
const dimensionDefinitions = require('../models/dimension-definitions.json');

/**
 * Convert a Markdown roadmap to JSON format
 * @param {string} markdownContent - The content of the Markdown file
 * @returns {object} - The roadmap in JSON format
 */
function markdownToJson(markdownContent) {
  const lines = markdownContent.split('\n');
  const roadmap = {
    id: generateId(),
    title: '',
    description: '',
    type: 'cosmos', // Default to highest level
    level: 1,
    status: 'planned',
    children: [],
    metadata: {
      temporal: {},
      cognitive: {},
      organizational: {},
      strategic: {}
    },
    tags: [],
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString()
  };

  let currentElement = roadmap;
  let currentLevel = 1;
  let elementStack = [roadmap];
  let inDescription = false;
  let descriptionBuffer = '';

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    // Check if this is a header line
    const headerMatch = line.match(/^(#+)\s+(.+?)(?:\s+\[([A-Z]+)\])?$/);
    if (headerMatch) {
      inDescription = false;
      const level = headerMatch[1].length;
      const title = headerMatch[2].trim();
      const type = headerMatch[3] ? headerMatch[3].toLowerCase() : getTypeForLevel(level);

      // Create new element
      const newElement = {
        id: generateId(),
        title: title,
        description: '',
        type: type,
        level: level,
        status: 'planned',
        children: [],
        metadata: {
          temporal: {},
          cognitive: {},
          organizational: {},
          strategic: {}
        },
        tags: [],
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };

      // If this is the first header, it's the roadmap title
      if (level === 1 && i === 0) {
        roadmap.title = title;
        roadmap.type = type;
        currentElement = roadmap;
        continue;
      }

      // Add to appropriate parent
      if (level > currentLevel) {
        // This is a child of the current element
        currentElement.children.push(newElement);
        elementStack.push(currentElement);
        currentElement = newElement;
      } else if (level === currentLevel) {
        // This is a sibling of the current element
        elementStack[elementStack.length - 2].children.push(newElement);
        currentElement = newElement;
      } else {
        // This is a higher level, pop the stack
        while (elementStack.length > 1 && level <= currentLevel) {
          elementStack.pop();
          currentLevel--;
        }
        elementStack[elementStack.length - 1].children.push(newElement);
        elementStack.push(newElement);
        currentElement = newElement;
      }

      currentLevel = level;
      continue;
    }

    // Check if this is a task line
    const taskMatch = line.match(/^(\s*)- \[([ x~])\]\s+(?:\*\*([^*]+)\*\*\s+)?(.+?)(?:\s+#(.+))?$/);
    if (taskMatch) {
      inDescription = false;
      const indentation = taskMatch[1].length / 2;
      const status = taskMatch[2] === ' ' ? 'planned' : (taskMatch[2] === 'x' ? 'completed' : 'in_progress');
      const id = taskMatch[3] || generateId();
      const title = taskMatch[4].trim();
      const tagsStr = taskMatch[5] || '';

      // Parse tags
      const tags = [];
      const metadata = {
        temporal: {},
        cognitive: {},
        organizational: {},
        strategic: {}
      };

      if (tagsStr) {
        const tagParts = tagsStr.split('#');
        for (const part of tagParts) {
          if (!part.trim()) continue;

          const tagMatch = part.match(/([^:]+)(?::(.+))?/);
          if (tagMatch) {
            const tagName = tagMatch[1].trim();
            const tagValue = tagMatch[2] ? tagMatch[2].trim() : true;

            // Check if this is a metadata tag (priority, complexity, etc.)
            let isMetadataTag = false;

            // Check each dimension for matching aspects
            for (const dimension of dimensionDefinitions.dimensions) {
              // Check if the tag matches any aspect key
              const matchingAspect = dimension.aspects.find(a =>
                a.key === tagName.toLowerCase() ||
                a.name.toLowerCase() === tagName.toLowerCase()
              );

              if (matchingAspect) {
                metadata[dimension.key][matchingAspect.key] = tagValue;
                isMetadataTag = true;
                break;
              }

              // Check common metadata tags
              const commonTags = {
                'priority': { dimension: 'strategic', aspect: 'priority' },
                'complexity': { dimension: 'cognitive', aspect: 'complexity' },
                'horizon': { dimension: 'temporal', aspect: 'horizon' },
                'sequence': { dimension: 'temporal', aspect: 'sequence' },
                'responsibility': { dimension: 'organizational', aspect: 'responsibility' },
                'value': { dimension: 'strategic', aspect: 'value' },
                'risk': { dimension: 'strategic', aspect: 'risk' }
              };

              if (commonTags[tagName.toLowerCase()]) {
                const tag = commonTags[tagName.toLowerCase()];
                metadata[tag.dimension][tag.aspect] = tagValue;
                isMetadataTag = true;
                break;
              }
            }

            // If not a metadata tag, add as regular tag
            if (!isMetadataTag) {
              tags.push(tagName);
            }
          }
        }
      }

      // Determine level based on indentation
      const level = 7 + indentation; // LOCALITÉS start at level 7

      // Create new element
      const newElement = {
        id: id,
        title: title,
        description: '',
        type: getTypeForLevel(level),
        level: level,
        status: status,
        children: [],
        metadata: metadata,
        tags: tags,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };

      // Add to appropriate parent
      if (level > currentLevel) {
        // This is a child of the current element
        currentElement.children.push(newElement);
        elementStack.push(currentElement);
        currentElement = newElement;
      } else if (level === currentLevel) {
        // This is a sibling of the current element
        elementStack[elementStack.length - 2].children.push(newElement);
        currentElement = newElement;
      } else {
        // This is a higher level, pop the stack
        while (elementStack.length > 1 && level <= currentLevel) {
          elementStack.pop();
          currentLevel--;
        }
        elementStack[elementStack.length - 1].children.push(newElement);
        elementStack.push(newElement);
        currentElement = newElement;
      }

      currentLevel = level;
      continue;
    }

    // Check if this is a description line
    if (line.trim().startsWith('>')) {
      inDescription = true;
      descriptionBuffer += line.replace(/^>\s*/, '') + '\n';
      continue;
    }

    // If we were in a description but this line is not a description line,
    // add the description to the current element
    if (inDescription && !line.trim().startsWith('>')) {
      currentElement.description = descriptionBuffer.trim();
      descriptionBuffer = '';
      inDescription = false;
    }

    // Check for metadata lines
    const metadataMatch = line.match(/^\s*\*\*([^:]+):\*\*\s+(.+)$/);
    if (metadataMatch) {
      const key = metadataMatch[1].trim().toLowerCase();
      const value = metadataMatch[2].trim();

      // Map common metadata keys to our structure
      switch (key) {
        case 'temporel':
        case 'temporal':
          parseMetadataString(value, 'temporal', currentElement.metadata);
          break;
        case 'cognitif':
        case 'cognitive':
          parseMetadataString(value, 'cognitive', currentElement.metadata);
          break;
        case 'organisationnel':
        case 'organizational':
          parseMetadataString(value, 'organizational', currentElement.metadata);
          break;
        case 'stratégique':
        case 'strategic':
          parseMetadataString(value, 'strategic', currentElement.metadata);
          break;
        default:
          // Add as custom metadata
          if (!currentElement.custom_metadata) {
            currentElement.custom_metadata = {};
          }
          currentElement.custom_metadata[key] = value;
      }

      continue;
    }
  }

  // If we ended with a description, add it to the current element
  if (inDescription) {
    currentElement.description = descriptionBuffer.trim();
  }

  return roadmap;
}

/**
 * Convert a JSON roadmap to Markdown format
 * @param {object} roadmap - The roadmap in JSON format
 * @returns {string} - The content of the Markdown file
 */
function jsonToMarkdown(roadmap) {
  let markdown = '';

  // Add the title
  const levelDef = hierarchyDefinitions.levels.find(l => l.type === roadmap.type) || hierarchyDefinitions.levels[0];
  // Check if the title already contains the level name in brackets
  const titleHasLevel = roadmap.title.match(/\s+\[[A-Z]+\]$/);
  if (titleHasLevel) {
    markdown += `${levelDef.markdown_representation.prefix}${roadmap.title}\n\n`;
  } else {
    markdown += `${levelDef.markdown_representation.prefix}${roadmap.title} [${levelDef.name}]\n\n`;
  }

  // Add the description
  if (roadmap.description) {
    markdown += `${roadmap.description.split('\n').map(line => `> ${line}`).join('\n')}\n\n`;
  }

  // Add metadata
  markdown += formatMetadata(roadmap.metadata);

  // Add children recursively
  for (const child of roadmap.children) {
    markdown += formatElement(child, 1);
  }

  return markdown;
}

/**
 * Format a roadmap element as Markdown
 * @param {object} element - The element to format
 * @param {number} depth - The current depth in the hierarchy
 * @returns {string} - The formatted Markdown
 */
function formatElement(element, depth) {
  let markdown = '';

  // Get the level definition
  const levelDef = hierarchyDefinitions.levels.find(l => l.type === element.type) ||
                  hierarchyDefinitions.levels.find(l => l.level === element.level) ||
                  hierarchyDefinitions.levels[6]; // Default to LOCALITÉS (level 7)

  // Format based on type
  if (element.level <= 6) {
    // Header-style elements (COSMOS to RÉGIONS)
    // Check if the title already contains the level name in brackets
    const titleHasLevel = element.title.match(/\s+\[[A-Z]+\]$/);
    if (titleHasLevel) {
      markdown += `${levelDef.markdown_representation.prefix}${element.title}\n\n`;
    } else {
      markdown += `${levelDef.markdown_representation.prefix}${element.title} [${levelDef.name}]\n\n`;
    }

    // Add description
    if (element.description) {
      markdown += `${element.description.split('\n').map(line => `> ${line}`).join('\n')}\n\n`;
    }

    // Add metadata
    markdown += formatMetadata(element.metadata);
  } else {
    // Task-style elements (LOCALITÉS to FONDATIONS)
    const statusChar = element.status === 'completed' ? 'x' : (element.status === 'in_progress' ? '~' : ' ');
    const indentation = ' '.repeat((element.level - 7) * 2);

    markdown += `${indentation}- [${statusChar}] **${element.id}** ${element.title}`;

    // Add tags
    if (element.tags && element.tags.length > 0) {
      markdown += ` #${element.tags.join(' #')}`;
    }

    markdown += '\n';

    // Add description
    if (element.description) {
      markdown += `${indentation}  ${element.description.split('\n').map(line => `> ${line}`).join(`\n${indentation}  `)}\n`;
    }

    // Add metadata
    const metadataLines = formatMetadata(element.metadata).split('\n');
    for (const line of metadataLines) {
      if (line.trim()) {
        markdown += `${indentation}  ${line}\n`;
      }
    }
  }

  // Add children recursively
  for (const child of element.children) {
    markdown += formatElement(child, depth + 1);
  }

  return markdown;
}

/**
 * Format metadata as Markdown
 * @param {object} metadata - The metadata object
 * @returns {string} - The formatted Markdown
 */
function formatMetadata(metadata) {
  let markdown = '';

  // Helper function to format a dimension
  const formatDimension = (dimensionKey) => {
    if (Object.keys(metadata[dimensionKey]).length > 0) {
      const dimension = dimensionDefinitions.dimensions.find(d => d.key === dimensionKey);
      if (!dimension) return '';

      const parts = [];

      for (const [key, value] of Object.entries(metadata[dimensionKey])) {
        // Try to find the aspect by key
        const aspect = dimension.aspects.find(a => a.key === key);

        if (aspect) {
          // Use the aspect name if found
          parts.push(`${aspect.name}: ${value}`);
        } else {
          // Use the key directly if no aspect is found (custom property)
          // Convert snake_case to Title Case
          const formattedKey = key
            .split('_')
            .map(word => word.charAt(0).toUpperCase() + word.slice(1))
            .join(' ');

          parts.push(`${formattedKey}: ${value}`);
        }
      }

      if (parts.length > 0) {
        return `**${dimension.name}**: ${parts.join(', ')}\n`;
      }
    }

    return '';
  };

  // Format each dimension
  markdown += formatDimension('temporal');
  markdown += formatDimension('cognitive');
  markdown += formatDimension('organizational');
  markdown += formatDimension('strategic');

  return markdown;
}

/**
 * Parse a metadata string into the metadata object
 * @param {string} metadataStr - The metadata string to parse
 * @param {string} dimensionKey - The dimension key
 * @param {object} metadata - The metadata object to update
 */
function parseMetadataString(metadataStr, dimensionKey, metadata) {
  const parts = metadataStr.split(',').map(p => p.trim());

  for (const part of parts) {
    const match = part.match(/([^:]+):\s*(.+)/);
    if (match) {
      const aspectName = match[1].trim();
      const value = match[2].trim();

      // Find the aspect key
      const dimension = dimensionDefinitions.dimensions.find(d => d.key === dimensionKey);
      if (dimension) {
        // Try to find by name first
        let aspect = dimension.aspects.find(a =>
          a.name.toLowerCase() === aspectName.toLowerCase()
        );

        // If not found by name, try to find by key
        if (!aspect) {
          aspect = dimension.aspects.find(a =>
            a.key.toLowerCase() === aspectName.toLowerCase()
          );
        }

        if (aspect) {
          metadata[dimensionKey][aspect.key] = value;
        } else {
          // If aspect not found, add it as a custom property
          const customKey = aspectName.toLowerCase().replace(/\s+/g, '_');
          metadata[dimensionKey][customKey] = value;
        }
      }
    }
  }
}

/**
 * Get the type for a given level
 * @param {number} level - The level number
 * @returns {string} - The type for that level
 */
function getTypeForLevel(level) {
  const levelDef = hierarchyDefinitions.levels.find(l => l.level === level);
  return levelDef ? levelDef.type : 'locality'; // Default to locality
}

/**
 * Generate a unique ID
 * @returns {string} - A unique ID
 */
function generateId() {
  return 'id-' + Math.random().toString(36).substr(2, 9);
}

/**
 * Convert a Markdown file to JSON
 * @param {string} markdownPath - Path to the Markdown file
 * @param {string} jsonPath - Path where the JSON file should be saved
 */
function convertMarkdownFileToJson(markdownPath, jsonPath) {
  try {
    const markdownContent = fs.readFileSync(markdownPath, 'utf8');
    const roadmap = markdownToJson(markdownContent);
    fs.writeFileSync(jsonPath, JSON.stringify(roadmap, null, 2), 'utf8');
    console.log(`Converted ${markdownPath} to ${jsonPath}`);
  } catch (error) {
    console.error(`Error converting ${markdownPath} to JSON:`, error);
  }
}

/**
 * Convert a JSON file to Markdown
 * @param {string} jsonPath - Path to the JSON file
 * @param {string} markdownPath - Path where the Markdown file should be saved
 */
function convertJsonFileToMarkdown(jsonPath, markdownPath) {
  try {
    const jsonContent = fs.readFileSync(jsonPath, 'utf8');
    const roadmap = JSON.parse(jsonContent);
    const markdown = jsonToMarkdown(roadmap);
    fs.writeFileSync(markdownPath, markdown, 'utf8');
    console.log(`Converted ${jsonPath} to ${markdownPath}`);
  } catch (error) {
    console.error(`Error converting ${jsonPath} to Markdown:`, error);
  }
}

module.exports = {
  markdownToJson,
  jsonToMarkdown,
  convertMarkdownFileToJson,
  convertJsonFileToMarkdown
};
