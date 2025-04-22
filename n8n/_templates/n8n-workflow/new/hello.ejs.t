---
to: n8n/core/workflows/<%= environment %>/<%= name %>.json
---
{
  "id": "<%= h.uuid() %>",
  "name": "<%= name %>",
  "active": false,
  "nodes": [
    {
      "parameters": {},
      "id": "<%= h.uuid() %>",
      "name": "Start",
      "type": "n8n-nodes-base.start",
      "typeVersion": 1,
      "position": [
        250,
        300
      ]
    }
  ],
  "connections": {},
  "staticData": null,
  "settings": {},
  "tags": <%= JSON.stringify(tags) %>,
  "pinData": {},
  "versionId": "<%= h.uuid() %>",
  "triggerCount": 0,
  "createdAt": "<%= new Date().toISOString() %>",
  "updatedAt": "<%= new Date().toISOString() %>"
}
