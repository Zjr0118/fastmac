#!/bin/bash
# disable spotlight indexing
sudo mdutil -i off -a

# publish tmate connection info to session.json
python3 << 'PYEOF'
import json, os, base64, urllib.request

token = os.environ.get("GITHUB_TOKEN", "")
repo = os.environ.get("GITHUB_REPOSITORY", "")
ssh = os.environ.get("TMATE_SSH", "")
web = os.environ.get("TMATE_WEB_URL", "")

if not token or not repo:
    print("Missing GITHUB_TOKEN or GITHUB_REPOSITORY")
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
except Exception:
    pass

data = {"message": "[bot] update session info", "content": encoded, "branch": "main"}
if sha:
    data["sha"] = sha
req = urllib.request.Request(api, data=json.dumps(data).encode(), method="PUT", headers=h)
try:
    with urllib.request.urlopen(req) as resp:
        print("Session info published to session.json")
except Exception as e:
    print("Failed to publish: " + str(e))
PYEOF

echo "Session ready. Edit script-mac.sh to auto-run commands."
