#!/bin/bash
# disable spotlight indexing
sudo mdutil -i off -a 2>/dev/null

# Get tmate connection info
SSH_INFO="$TMATE_SSH"
WEB_INFO="$TMATE_WEB_URL"

# Fallback: try tmate display command
if [ -z "$SSH_INFO" ]; then
  for sock in /tmp/tmate.sock /var/folders/*/tmate.sock $(ls /tmp/tmate-*.sock 2>/dev/null); do
    if [ -S "$sock" ]; then
      SSH_INFO=$(tmate -S "$sock" display -p '#{tmate_ssh}' 2>/dev/null)
      WEB_INFO=$(tmate -S "$sock" display -p '#{tmate_web_url}' 2>/dev/null)
      [ -n "$SSH_INFO" ] && break
    fi
  done
fi

# Fallback: try default tmate socket
if [ -z "$SSH_INFO" ]; then
  SSH_INFO=$(tmate display -p '#{tmate_ssh}' 2>/dev/null)
  WEB_INFO=$(tmate display -p '#{tmate_web_url}' 2>/dev/null)
fi

echo "TMATE_SSH=[$SSH_INFO]"
echo "TMATE_WEB_URL=[$WEB_INFO]"

# Publish to session.json via GitHub API
python3 << PYEOF
import json, os, base64, urllib.request, urllib.error

token = os.environ.get("GITHUB_TOKEN", "")
repo = os.environ.get("GITHUB_REPOSITORY", "")
ssh = os.environ.get("TMATE_SSH", "") or "$SSH_INFO"
web = os.environ.get("TMATE_WEB_URL", "") or "$WEB_INFO"

print("GITHUB_TOKEN set:", bool(token))
print("Repo:", repo)
print("SSH:", ssh)
print("Web:", web)

if not token or not repo:
    print("Missing credentials")
    exit(0)

content = json.dumps({"ssh": ssh, "webUrl": web, "status": "ready"})
encoded = base64.b64encode(content.encode()).decode()
api = "https://api.github.com/repos/" + repo + "/contents/session.json"
h = {"Authorization": "token " + token, "Accept": "application/vnd.github+json"}

sha = None
try:
    req = urllib.request.Request(api, headers=h)
    with urllib.request.urlopen(req) as resp:
        sha = json.loads(resp.read()).get("sha")
    print("Existing file sha:", sha)
except urllib.error.HTTPError as e:
    print("GET file status:", e.code)
except Exception as e:
    print("GET file error:", e)

data = {"message": "[bot] session info", "content": encoded, "branch": "main"}
if sha:
    data["sha"] = sha
req = urllib.request.Request(api, data=json.dumps(data).encode(), method="PUT", headers=h)
try:
    with urllib.request.urlopen(req) as resp:
        print("PUT status:", resp.status)
        print("Session info published!")
except urllib.error.HTTPError as e:
    print("PUT failed:", e.code, e.read().decode()[:200])
except Exception as e:
    print("PUT error:", e)
PYEOF

echo "Done."
