import json, os, base64, urllib.request, urllib.error

token = os.environ.get("GITHUB_TOKEN", "")
repo = os.environ.get("GITHUB_REPOSITORY", "")

print("GITHUB_TOKEN set:", bool(token))
print("Repo:", repo)

# Read session data
try:
    with open("/tmp/session_data.json") as f:
        data = json.load(f)
    print("SSH:", data.get("ssh", ""))
    print("Web:", data.get("webUrl", ""))
except Exception as e:
    print("Failed to read session data:", e)
    data = {"ssh": "", "webUrl": "", "status": "ready"}

if not token or not repo:
    print("Missing credentials")
    exit(0)

content = json.dumps(data)
encoded = base64.b64encode(content.encode()).decode()
api = "https://api.github.com/repos/" + repo + "/contents/session.json"
h = {"Authorization": "token " + token, "Accept": "application/vnd.github+json"}

# Get existing SHA
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

# Create/update file
put_data = json.dumps({
    "message": "[bot] update session info",
    "content": encoded,
    "branch": "main",
    "sha": sha
}).encode()

req = urllib.request.Request(api, data=put_data, method="PUT", headers=h)
try:
    with urllib.request.urlopen(req) as resp:
        print("PUT status:", resp.status)
        print("Session info published!")
except urllib.error.HTTPError as e:
    print("PUT failed:", e.code, e.read().decode()[:300])
except Exception as e:
    print("PUT error:", e)
