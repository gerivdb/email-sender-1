// conflict-resolution.js - Advanced conflict resolution interface with real-time updates

class ConflictResolutionManager {
    constructor() {
        this.ws = null;
        this.currentConflictId = null;
        this.reconnectAttempts = 0;
        this.maxReconnectAttempts = 5;
        this.isConnected = false;
        
        this.initializeWebSocket();
        this.setupEventListeners();
    }

    // WebSocket Management
    initializeWebSocket() {
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const wsUrl = `${protocol}//${window.location.host}/ws`;
        
        try {
            this.ws = new WebSocket(wsUrl);
            this.setupWebSocketHandlers();
        } catch (error) {
            console.error('WebSocket connection failed:', error);
            this.updateConnectionStatus(false);
        }
    }

    setupWebSocketHandlers() {
        this.ws.onopen = () => {
            console.log('WebSocket connected');
            this.isConnected = true;
            this.reconnectAttempts = 0;
            this.updateConnectionStatus(true);
        };

        this.ws.onmessage = (event) => {
            try {
                const message = JSON.parse(event.data);
                this.handleWebSocketMessage(message);
            } catch (error) {
                console.error('Error parsing WebSocket message:', error);
            }
        };

        this.ws.onclose = () => {
            console.log('WebSocket disconnected');
            this.isConnected = false;
            this.updateConnectionStatus(false);
            this.attemptReconnect();
        };

        this.ws.onerror = (error) => {
            console.error('WebSocket error:', error);
            this.updateConnectionStatus(false);
        };
    }

    attemptReconnect() {
        if (this.reconnectAttempts < this.maxReconnectAttempts) {
            this.reconnectAttempts++;
            console.log(`Attempting to reconnect... (${this.reconnectAttempts}/${this.maxReconnectAttempts})`);
            
            setTimeout(() => {
                this.initializeWebSocket();
            }, 3000 * this.reconnectAttempts); // Exponential backoff
        } else {
            console.error('Max reconnection attempts reached');
            this.showNotification('Connection lost. Please refresh the page.', 'error');
        }
    }

    updateConnectionStatus(connected) {
        const statusElement = document.getElementById('ws-status');
        if (statusElement) {
            statusElement.innerHTML = connected 
                ? '<span class="badge bg-success"><i class="fas fa-wifi me-1"></i>Connected</span>'
                : '<span class="badge bg-danger"><i class="fas fa-wifi me-1"></i>Disconnected</span>';
        }
    }

    // Message Handling
    handleWebSocketMessage(message) {
        switch (message.type) {
            case 'initial_status':
                this.updateDashboardStatus(message.data);
                break;
            case 'conflict_resolved':
                this.handleConflictResolved(message.data);
                break;
            case 'new_conflict':
                this.handleNewConflict(message.data);
                break;
            case 'sync_status_update':
                this.updateSyncStatus(message.data);
                break;
            case 'performance_update':
                this.updatePerformanceMetrics(message.data);
                break;
            default:
                console.log('Unknown message type:', message.type);
        }
    }

    // Event Listeners
    setupEventListeners() {
        // Handle page visibility changes
        document.addEventListener('visibilitychange', () => {
            if (!document.hidden && !this.isConnected) {
                this.initializeWebSocket();
            }
        });

        // Handle window beforeunload
        window.addEventListener('beforeunload', () => {
            if (this.ws) {
                this.ws.close();
            }
        });
    }

    // Conflict Resolution Functions
    async resolveConflict(conflictId, resolution, customMerge = null) {
        const payload = {
            conflictId: conflictId,
            resolution: resolution
        };

        if (customMerge) {
            payload.customMerge = customMerge;
        }

        try {
            const response = await fetch('/api/sync/resolve', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(payload)
            });

            const result = await response.json();

            if (response.ok) {
                this.showNotification(`Conflict resolved: ${resolution}`, 'success');
                this.removeConflictFromUI(conflictId);
                this.updateConflictCount();
            } else {
                this.showNotification(`Error: ${result.error}`, 'error');
            }
        } catch (error) {
            console.error('Error resolving conflict:', error);
            this.showNotification('Failed to resolve conflict', 'error');
        }
    }

    showMergeDialog(conflictId) {
        this.currentConflictId = conflictId;
        const conflictElement = document.querySelector(`[data-id="${conflictId}"]`);
        
        if (conflictElement) {
            const sourceContent = conflictElement.querySelector('.source-content').textContent.trim();
            const targetContent = conflictElement.querySelector('.target-content').textContent.trim();
            
            // Pre-populate merge editor with combined content
            const mergeContent = this.generateMergeTemplate(sourceContent, targetContent);
            document.getElementById('merge-content').value = mergeContent;
            
            // Show modal
            const modal = new bootstrap.Modal(document.getElementById('mergeModal'));
            modal.show();
        }
    }

    generateMergeTemplate(sourceContent, targetContent) {
        return `<<<<<<< SOURCE (Markdown)
${sourceContent}
=======
${targetContent}
>>>>>>> TARGET (Database)

// Edit the content above to create your merged version
// Remove the conflict markers (<<<<<<< ======= >>>>>>>) when done`;
    }

    async submitCustomMerge() {
        const mergeContent = document.getElementById('merge-content').value;
        
        if (!mergeContent.trim()) {
            this.showNotification('Please enter merge content', 'warning');
            return;
        }

        // Check if conflict markers are still present
        if (mergeContent.includes('<<<<<<<') || mergeContent.includes('>>>>>>>')) {
            if (!confirm('Conflict markers detected. Continue anyway?')) {
                return;
            }
        }

        await this.resolveConflict(this.currentConflictId, 'custom', mergeContent);
        
        // Close modal
        const modal = bootstrap.Modal.getInstance(document.getElementById('mergeModal'));
        modal.hide();
    }

    // UI Update Functions
    handleConflictResolved(data) {
        this.removeConflictFromUI(data.conflictId);
        this.updateConflictCount();
        this.showNotification(`Conflict resolved: ${data.resolution}`, 'success');
    }

    handleNewConflict(data) {
        this.addConflictToUI(data);
        this.updateConflictCount();
        this.showNotification('New conflict detected', 'warning');
    }

    removeConflictFromUI(conflictId) {
        const conflictElement = document.querySelector(`[data-id="${conflictId}"]`);
        if (conflictElement) {
            conflictElement.style.transition = 'opacity 0.3s ease-out';
            conflictElement.style.opacity = '0';
            setTimeout(() => {
                conflictElement.remove();
                this.checkEmptyState();
            }, 300);
        }
    }

    addConflictToUI(conflictData) {
        const divergencesList = document.getElementById('divergences-list');
        const conflictHtml = this.generateConflictHTML(conflictData);
        
        // Add with animation
        const tempDiv = document.createElement('div');
        tempDiv.innerHTML = conflictHtml;
        const conflictElement = tempDiv.firstElementChild;
        
        conflictElement.style.opacity = '0';
        conflictElement.style.transform = 'translateY(-20px)';
        
        divergencesList.insertBefore(conflictElement, divergencesList.firstChild);
        
        // Animate in
        setTimeout(() => {
            conflictElement.style.transition = 'all 0.3s ease-in';
            conflictElement.style.opacity = '1';
            conflictElement.style.transform = 'translateY(0)';
        }, 100);
    }

    generateConflictHTML(conflict) {
        return `
            <div class="divergence-item mb-3" data-id="${conflict.id}">
                <div class="divergence-header d-flex justify-content-between align-items-center p-3 bg-light rounded-top">
                    <div>
                        <span class="file-path fw-bold">${conflict.filePath}</span>
                        <span class="badge bg-${this.getSeverityColor(conflict.severity)} ms-2">
                            ${conflict.severity}
                        </span>
                        <small class="text-muted ms-2">${new Date(conflict.timestamp).toLocaleString()}</small>
                    </div>
                    <div>
                        <span class="badge bg-warning">pending</span>
                    </div>
                </div>
                
                <div class="divergence-details border border-top-0 p-3">
                    <div class="row">
                        <div class="col-md-6">
                            <h6><i class="fas fa-file-alt me-1"></i>Source (Markdown)</h6>
                            <pre class="source-content bg-light p-2 rounded">${conflict.sourceContent}</pre>
                        </div>
                        <div class="col-md-6">
                            <h6><i class="fas fa-database me-1"></i>Target (Database)</h6>
                            <pre class="target-content bg-light p-2 rounded">${conflict.targetContent}</pre>
                        </div>
                    </div>
                    
                    <div class="resolution-controls mt-3">
                        <h6>Conflict Resolution</h6>
                        <div class="btn-group" role="group">
                            <button type="button" class="btn btn-outline-success" 
                                    onclick="conflictManager.resolveConflict('${conflict.id}', 'accept_source')">
                                <i class="fas fa-check me-1"></i>Accept Source
                            </button>
                            <button type="button" class="btn btn-outline-info" 
                                    onclick="conflictManager.resolveConflict('${conflict.id}', 'accept_target')">
                                <i class="fas fa-check me-1"></i>Accept Target
                            </button>
                            <button type="button" class="btn btn-outline-warning" 
                                    onclick="conflictManager.showMergeDialog('${conflict.id}')">
                                <i class="fas fa-code-branch me-1"></i>Custom Merge
                            </button>
                            <button type="button" class="btn btn-outline-secondary" 
                                    onclick="conflictManager.resolveConflict('${conflict.id}', 'ignore')">
                                <i class="fas fa-times me-1"></i>Ignore
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        `;
    }

    getSeverityColor(severity) {
        switch (severity.toLowerCase()) {
            case 'high': return 'danger';
            case 'medium': return 'warning';
            case 'low': return 'info';
            default: return 'secondary';
        }
    }

    updateConflictCount() {
        const conflictCount = document.querySelectorAll('.divergence-item').length;
        const countElement = document.getElementById('conflict-count');
        if (countElement) {
            countElement.textContent = conflictCount;
        }
    }

    checkEmptyState() {
        const divergencesList = document.getElementById('divergences-list');
        if (divergencesList.children.length === 0) {
            divergencesList.innerHTML = `
                <div class="alert alert-success text-center">
                    <i class="fas fa-check-circle me-2"></i>
                    No divergences detected. All systems are in sync!
                </div>
            `;
        }
    }

    // Dashboard Updates
    updateDashboardStatus(status) {
        // Update status cards
        document.getElementById('health-status').textContent = status.healthStatus;
        document.getElementById('active-syncs').textContent = status.activeSyncs.length;
        document.getElementById('conflict-count').textContent = status.conflictCount;
        
        if (status.lastSync) {
            const lastSyncDate = new Date(status.lastSync);
            document.getElementById('last-sync').textContent = lastSyncDate.toLocaleTimeString();
        }

        // Update performance metrics if available
        if (status.performanceMetrics) {
            this.updatePerformanceMetrics(status.performanceMetrics);
        }
    }

    updateSyncStatus(data) {
        this.updateDashboardStatus(data);
    }

    updatePerformanceMetrics(metrics) {
        // Update performance metrics in the UI
        // This would be implemented based on the specific metrics structure
        console.log('Performance metrics updated:', metrics);
    }

    // Utility Functions
    showNotification(message, type = 'info') {
        // Create notification element
        const notification = document.createElement('div');
        notification.className = `alert alert-${this.getAlertClass(type)} alert-dismissible fade show position-fixed`;
        notification.style.cssText = 'top: 20px; right: 20px; z-index: 9999; min-width: 300px;';
        
        notification.innerHTML = `
            ${message}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        `;

        document.body.appendChild(notification);

        // Auto-remove after 5 seconds
        setTimeout(() => {
            if (notification.parentNode) {
                notification.remove();
            }
        }, 5000);
    }

    getAlertClass(type) {
        switch (type) {
            case 'success': return 'success';
            case 'error': return 'danger';
            case 'warning': return 'warning';
            default: return 'info';
        }
    }
}

// Dashboard Management Functions
async function refreshDashboard() {
    try {
        const response = await fetch('/api/sync/status');
        const status = await response.json();
        
        if (response.ok) {
            conflictManager.updateDashboardStatus(status);
        } else {
            console.error('Failed to refresh dashboard:', status.error);
        }
    } catch (error) {
        console.error('Error refreshing dashboard:', error);
    }
}

async function refreshDivergences() {
    try {
        const response = await fetch('/api/sync/conflicts');
        const data = await response.json();
        
        if (response.ok) {
            updateDivergencesList(data.conflicts);
        } else {
            console.error('Failed to refresh divergences:', data.error);
        }
    } catch (error) {
        console.error('Error refreshing divergences:', error);
    }
}

function updateDivergencesList(conflicts) {
    const divergencesList = document.getElementById('divergences-list');
    
    if (conflicts.length === 0) {
        divergencesList.innerHTML = `
            <div class="alert alert-success text-center">
                <i class="fas fa-check-circle me-2"></i>
                No divergences detected. All systems are in sync!
            </div>
        `;
        return;
    }

    divergencesList.innerHTML = conflicts.map(conflict => 
        conflictManager.generateConflictHTML(conflict)
    ).join('');
}

async function loadSyncHistory() {
    try {
        const response = await fetch('/api/sync/history?limit=10');
        const data = await response.json();
        
        if (response.ok) {
            updateSyncHistory(data.history);
        } else {
            console.error('Failed to load sync history:', data.error);
        }
    } catch (error) {
        console.error('Error loading sync history:', error);
    }
}

function updateSyncHistory(history) {
    const historyElement = document.getElementById('sync-history');
    
    if (!history || history.length === 0) {
        historyElement.innerHTML = '<p class="text-muted">No sync history available.</p>';
        return;
    }

    historyElement.innerHTML = `
        <div class="table-responsive">
            <table class="table table-sm table-striped">
                <thead>
                    <tr>
                        <th>Timestamp</th>
                        <th>Operation</th>
                        <th>Status</th>
                        <th>Duration</th>
                        <th>Details</th>
                    </tr>
                </thead>
                <tbody>
                    ${history.map(entry => `
                        <tr>
                            <td>${new Date(entry.timestamp).toLocaleString()}</td>
                            <td>${entry.operation}</td>
                            <td>
                                <span class="badge bg-${entry.status === 'success' ? 'success' : 'danger'}">
                                    ${entry.status}
                                </span>
                            </td>
                            <td>${entry.duration || 'N/A'}</td>
                            <td>${entry.details || ''}</td>
                        </tr>
                    `).join('')}
                </tbody>
            </table>
        </div>
    `;
}

function initializeDashboard() {
    // Initialize the conflict resolution manager
    window.conflictManager = new ConflictResolutionManager();
    
    // Set up periodic refresh
    setInterval(refreshDashboard, 30000); // Every 30 seconds
}

// Global functions for HTML onclick handlers
function resolveConflict(conflictId, resolution) {
    if (window.conflictManager) {
        window.conflictManager.resolveConflict(conflictId, resolution);
    }
}

function showMergeDialog(conflictId) {
    if (window.conflictManager) {
        window.conflictManager.showMergeDialog(conflictId);
    }
}

function submitCustomMerge() {
    if (window.conflictManager) {
        window.conflictManager.submitCustomMerge();
    }
}
