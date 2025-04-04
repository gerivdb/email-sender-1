@echo off
set N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
echo Connexion au serveur BifrostMCP sur le port 8009...
supergateway --sse http://localhost:8009/email-sender-1/sse %*
