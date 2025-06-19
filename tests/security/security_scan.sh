#!/bin/bash

# Security & Penetration Test Script
# Action 048 - Tests Sécurité & Penetration Testing

set -e

echo "=== [SECURITY & PENETRATION TEST] ==="
echo "Date: $(date)"
echo "Host: $(uname -a)"
echo

# 1. Basic port scan (localhost)
echo "[1] Port scan (localhost)..."
if command -v nmap >/dev/null 2>&1; then
  nmap -p 5678,8080,3000,80,443 localhost
else
  echo "nmap not installed, skipping port scan."
fi

# 2. HTTP security headers check (N8N & Go API)
for url in "http://localhost:5678" "http://localhost:8080"; do
  echo "[2] Checking security headers for $url ..."
  curl -s -D - "$url" -o /dev/null | grep -iE 'x-frame-options|x-content-type-options|strict-transport-security|content-security-policy|referrer-policy|permissions-policy'
done

# 3. Basic vulnerability scan (Nikto if available)
if command -v nikto >/dev/null 2>&1; then
  echo "[3] Nikto scan (localhost:5678)..."
  nikto -host http://localhost:5678 || true
  echo "[3] Nikto scan (localhost:8080)..."
  nikto -host http://localhost:8080 || true
else
  echo "Nikto not installed, skipping vulnerability scan."
fi

# 4. OWASP ZAP (manual/CI step)
echo "[4] OWASP ZAP (manual/CI):"
echo "  - Run ZAP against http://localhost:5678 and http://localhost:8080"
echo "  - Check for XSS, CSRF, open redirects, etc."

# 5. API endpoint fuzzing (optional)
echo "[5] API endpoint fuzzing (manual/CI):"
echo "  - Use tools like ffuf, wfuzz, or Burp Suite for endpoint fuzzing"
echo "  - Example: ffuf -u http://localhost:8080/FUZZ -w wordlist.txt"

echo
echo "=== [SECURITY TEST COMPLETE] ==="
