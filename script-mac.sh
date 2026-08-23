#!/bin/bash
# disable spotlight indexing
sudo mdutil -i off -a 2>/dev/null

# Get tmate connection info from env (set by action-tmate outputs)
SSH_INFO="$TMATE_SSH"
WEB_INFO="$TMATE_WEB_URL"

# Fallback: try tmate display command
if [ -z "$SSH_INFO" ]; then
  for sock in /tmp/tmate.sock /var/folders/*/tmate.sock /tmp/tmate-*.sock; do
    if [ -S "$sock" ]; then
      SSH_INFO=$(tmate -S "$sock" display -p '#{tmate_ssh}' 2>/dev/null)
      WEB_INFO=$(tmate -S "$sock" display -p '#{tmate_web_url}' 2>/dev/null)
      [ -n "$SSH_INFO" ] && break
    fi
  done
fi

if [ -z "$SSH_INFO" ]; then
  SSH_INFO=$(tmate display -p '#{tmate_ssh}' 2>/dev/null)
  WEB_INFO=$(tmate display -p '#{tmate_web_url}' 2>/dev/null)
fi

echo "TMATE_SSH=[$SSH_INFO]"
echo "TMATE_WEB_URL=[$WEB_INFO]"

# Write session info to a temp file for Python to read
cat > /tmp/session_data.json << ENDJSON
{"ssh":"$SSH_INFO","webUrl":"$WEB_INFO","status":"ready"}
ENDJSON

# Publish to session.json via GitHub API
python3 /tmp/publish_session.py
