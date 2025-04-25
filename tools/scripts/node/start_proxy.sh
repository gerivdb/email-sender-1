#!/bin/bash
cd "$(dirname "$0")"
npm install express axios ws
node unified_proxy.js
