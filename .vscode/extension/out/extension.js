"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.deactivate = exports.activate = exports.SmartEmailSenderExtension = void 0;
const vscode = require("vscode");
const https = require("https");
const http = require("http");
const url_1 = require("url");
// Utilitaire pour remplacer fetch
function httpRequest(url, options = {}) {
    return new Promise((resolve, reject) => {
        const parsedUrl = new url_1.URL(url);
        const client = parsedUrl.protocol === 'https:' ? https : http;
        const requestOptions = {
            hostname: parsedUrl.hostname,
            port: parsedUrl.port,
            path: parsedUrl.pathname + parsedUrl.search,
            method: options.method || 'GET',
            headers: {
                'Content-Type': 'application/json',
                ...options.headers
            }
        };
        const req = client.request(requestOptions, (res) => {
            let data = '';
            res.on('data', (chunk) => {
                data += chunk;
            });
            res.on('end', () => {
                resolve({
                    ok: res.statusCode >= 200 && res.statusCode < 300,
                    status: res.statusCode,
                    json: () => Promise.resolve(JSON.parse(data)),
                    text: () => Promise.resolve(data)
                });
            });
        });
        req.on('error', reject);
        if (options.body) {
            req.write(options.body);
        }
        req.end();
    });
}
const path = require("path");
const fs = require("fs");
class SmartEmailSenderExtension {
    constructor(context) {
        this.isInfrastructureRunning = false;
        this.autoStartEnabled = true;
        this.autoHealingEnabled = false;
        this.context = context;
        this.outputChannel = vscode.window.createOutputChannel('Smart Email Sender');
        // Configuration
        const config = vscode.workspace.getConfiguration('smartEmailSender');
        this.autoStartEnabled = config.get('autoStart', true);
        this.autoHealingEnabled = config.get('autoHealing', false);
        const apiPort = config.get('apiPort', 8080);
        this.apiBaseUrl = `http://localhost:${apiPort}`;
        // Créer la status bar
        this.statusBarItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 100);
        this.statusBarItem.command = 'smartEmailSender.showStatus';
        this.statusBarItem.show();
        this.updateStatusBar('⏳', 'Initializing...', 'yellow');
        // Enregistrer les commandes
        this.registerCommands();
        // Détecter si on est dans le workspace EMAIL_SENDER_1
        this.detectWorkspace();
    }
    registerCommands() {
        const commands = [
            vscode.commands.registerCommand('smartEmailSender.startStack', () => this.startInfrastructure()),
            vscode.commands.registerCommand('smartEmailSender.stopStack', () => this.stopInfrastructure()),
            vscode.commands.registerCommand('smartEmailSender.restartStack', () => this.restartInfrastructure()),
            vscode.commands.registerCommand('smartEmailSender.showStatus', () => this.showDetailedStatus()),
            vscode.commands.registerCommand('smartEmailSender.enableAutoHealing', () => this.toggleAutoHealing()),
            vscode.commands.registerCommand('smartEmailSender.showLogs', () => this.showLogs())
        ];
        commands.forEach(cmd => this.context.subscriptions.push(cmd));
        this.context.subscriptions.push(this.statusBarItem);
        this.context.subscriptions.push(this.outputChannel);
    }
    async detectWorkspace() {
        if (!vscode.workspace.workspaceFolders) {
            this.updateStatusBar('❌', 'No workspace', 'red');
            return;
        }
        const workspaceRoot = vscode.workspace.workspaceFolders[0].uri.fsPath;
        const isEmailSenderWorkspace = workspaceRoot.includes('EMAIL_SENDER_1') ||
            fs.existsSync(path.join(workspaceRoot, 'cmd', 'infrastructure-api-server'));
        if (isEmailSenderWorkspace) {
            this.logOutput('📁 Smart Email Sender workspace detected');
            this.updateStatusBar('🏠', 'Workspace detected', 'blue');
            if (this.autoStartEnabled) {
                this.logOutput('🚀 Auto-start enabled, starting infrastructure...');
                await this.autoStartInfrastructure();
            }
            else {
                this.updateStatusBar('⚡', 'Ready (auto-start disabled)', 'yellow');
            }
        }
        else {
            this.updateStatusBar('📁', 'Not Email Sender workspace', 'gray');
        }
    }
    async autoStartInfrastructure() {
        try {
            // Vérifier si l'API server est déjà en cours d'exécution
            const isRunning = await this.checkApiServerStatus();
            if (isRunning) {
                this.logOutput('✅ Infrastructure already running');
                this.isInfrastructureRunning = true;
                await this.updateStatusFromApi();
                return;
            }
            // Démarrer l'infrastructure via PowerShell
            this.logOutput('🚀 Starting infrastructure...');
            this.updateStatusBar('⏳', 'Starting infrastructure...', 'yellow');
            const workspaceRoot = vscode.workspace.workspaceFolders[0].uri.fsPath;
            const scriptPath = path.join(workspaceRoot, 'scripts', 'phase2-advanced-monitoring.ps1');
            const autoHealingFlag = this.autoHealingEnabled ? '-EnableAutoHealing' : '';
            const command = `powershell.exe -ExecutionPolicy Bypass -File "${scriptPath}" -Action start ${autoHealingFlag}`;
            const terminal = vscode.window.createTerminal({
                name: 'Smart Infrastructure',
                cwd: workspaceRoot
            });
            terminal.sendText(command);
            terminal.show();
            // Attendre un peu puis vérifier le statut
            await this.delay(10000);
            await this.updateStatusFromApi();
        }
        catch (error) {
            this.logOutput(`❌ Auto-start failed: ${error}`);
            this.updateStatusBar('❌', 'Auto-start failed', 'red');
        }
    }
    async startInfrastructure() {
        try {
            this.logOutput('🚀 Starting infrastructure stack...');
            this.updateStatusBar('⏳', 'Starting...', 'yellow');
            const workspaceRoot = vscode.workspace.workspaceFolders[0].uri.fsPath;
            const scriptPath = path.join(workspaceRoot, 'scripts', 'phase2-advanced-monitoring.ps1');
            const autoHealingFlag = this.autoHealingEnabled ? '-EnableAutoHealing' : '';
            const command = `powershell.exe -ExecutionPolicy Bypass -File "${scriptPath}" -Action start ${autoHealingFlag}`;
            const terminal = vscode.window.createTerminal({
                name: 'Smart Infrastructure - Start',
                cwd: workspaceRoot
            });
            terminal.sendText(command);
            terminal.show();
            vscode.window.showInformationMessage('Infrastructure stack is starting...');
            // Vérifier le statut après démarrage
            await this.delay(15000);
            await this.updateStatusFromApi();
        }
        catch (error) {
            vscode.window.showErrorMessage(`Failed to start infrastructure: ${error}`);
            this.logOutput(`❌ Start failed: ${error}`);
        }
    }
    async stopInfrastructure() {
        try {
            this.logOutput('🛑 Stopping infrastructure stack...');
            this.updateStatusBar('⏳', 'Stopping...', 'yellow');
            const workspaceRoot = vscode.workspace.workspaceFolders[0].uri.fsPath;
            const scriptPath = path.join(workspaceRoot, 'scripts', 'phase2-advanced-monitoring.ps1');
            const command = `powershell.exe -ExecutionPolicy Bypass -File "${scriptPath}" -Action stop`;
            const terminal = vscode.window.createTerminal({
                name: 'Smart Infrastructure - Stop',
                cwd: workspaceRoot
            });
            terminal.sendText(command);
            terminal.show();
            vscode.window.showInformationMessage('Infrastructure stack is stopping...');
            this.isInfrastructureRunning = false;
            this.updateStatusBar('⏹️', 'Stopped', 'gray');
        }
        catch (error) {
            vscode.window.showErrorMessage(`Failed to stop infrastructure: ${error}`);
            this.logOutput(`❌ Stop failed: ${error}`);
        }
    }
    async restartInfrastructure() {
        this.logOutput('🔄 Restarting infrastructure stack...');
        await this.stopInfrastructure();
        await this.delay(5000);
        await this.startInfrastructure();
    }
    async showDetailedStatus() {
        try {
            const status = await this.getInfrastructureStatus();
            const services = await this.getServicesStatus();
            let statusMessage = `📊 Smart Email Sender Infrastructure Status\n\n`;
            statusMessage += `Overall Status: ${status.overall}\n`;
            statusMessage += `Monitoring Active: ${status.active}\n`;
            statusMessage += `Auto-Healing: ${status.autoHealingEnabled}\n`;
            statusMessage += `Services Monitored: ${status.servicesMonitored}\n\n`;
            if (services) {
                statusMessage += `🔧 Services:\n`;
                for (const [serviceName, serviceData] of Object.entries(services)) {
                    const service = serviceData;
                    const icon = service.health === 'healthy' ? '✅' : '❌';
                    statusMessage += `${icon} ${serviceName}: ${service.status} (${service.health})\n`;
                }
            }
            vscode.window.showInformationMessage(statusMessage, { modal: true });
        }
        catch (error) {
            vscode.window.showErrorMessage(`Failed to get status: ${error}`);
        }
    }
    async toggleAutoHealing() {
        try {
            this.autoHealingEnabled = !this.autoHealingEnabled;
            const action = this.autoHealingEnabled ? 'enable' : 'disable';
            const response = await httpRequest(`${this.apiBaseUrl}/api/v1/auto-healing/${action}`, {
                method: 'POST'
            });
            if (response.ok) {
                const message = `Auto-healing ${this.autoHealingEnabled ? 'enabled' : 'disabled'}`;
                vscode.window.showInformationMessage(message);
                this.logOutput(`🔧 ${message}`);
                await this.updateStatusFromApi();
            }
            else {
                throw new Error(`HTTP ${response.status}`);
            }
        }
        catch (error) {
            vscode.window.showErrorMessage(`Failed to toggle auto-healing: ${error}`);
        }
    }
    showLogs() {
        this.outputChannel.show();
    }
    async checkApiServerStatus() {
        try {
            const response = await httpRequest(`${this.apiBaseUrl}/api/v1/infrastructure/status`, {
                method: 'GET'
            });
            return response.ok;
        }
        catch {
            return false;
        }
    }
    async getInfrastructureStatus() {
        const response = await httpRequest(`${this.apiBaseUrl}/api/v1/monitoring/status`);
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }
        const data = await response.json();
        return data.data;
    }
    async getServicesStatus() {
        const response = await httpRequest(`${this.apiBaseUrl}/api/v1/infrastructure/status`);
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }
        const data = await response.json();
        return data.data;
    }
    async updateStatusFromApi() {
        try {
            const isRunning = await this.checkApiServerStatus();
            if (!isRunning) {
                this.updateStatusBar('❌', 'API Server not running', 'red');
                this.isInfrastructureRunning = false;
                return;
            }
            const status = await this.getInfrastructureStatus();
            this.isInfrastructureRunning = true;
            let icon = '✅';
            let text = 'Running';
            let color = 'lightgreen';
            if (!status.active) {
                icon = '⚠️';
                text = 'Monitoring inactive';
                color = 'yellow';
            }
            if (status.autoHealingEnabled) {
                icon = '💚';
                text += ' + Auto-Healing';
            }
            this.updateStatusBar(icon, `${text} (${status.servicesMonitored} services)`, color);
        }
        catch (error) {
            this.updateStatusBar('❌', 'Status check failed', 'red');
            this.logOutput(`⚠️ Status update failed: ${error}`);
        }
    }
    updateStatusBar(icon, text, color) {
        this.statusBarItem.text = `${icon} Smart Infrastructure: ${text}`;
        this.statusBarItem.tooltip = `Smart Email Sender Infrastructure\nClick for detailed status`;
        // Note: VS Code doesn't support colored status bar items directly
    }
    logOutput(message) {
        const timestamp = new Date().toLocaleTimeString();
        this.outputChannel.appendLine(`[${timestamp}] ${message}`);
    }
    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
    dispose() {
        this.statusBarItem.dispose();
        this.outputChannel.dispose();
    }
}
exports.SmartEmailSenderExtension = SmartEmailSenderExtension;
function activate(context) {
    console.log('Smart Email Sender workspace extension is now active!');
    const extension = new SmartEmailSenderExtension(context);
    // Actualiser le statut périodiquement
    const statusInterval = setInterval(async () => {
        if (extension['isInfrastructureRunning']) {
            await extension['updateStatusFromApi']();
        }
    }, 30000); // Toutes les 30 secondes
    context.subscriptions.push({
        dispose: () => {
            clearInterval(statusInterval);
            extension.dispose();
        }
    });
}
exports.activate = activate;
function deactivate() {
    console.log('Smart Email Sender workspace extension is now deactivated!');
}
exports.deactivate = deactivate;
//# sourceMappingURL=extension.js.map