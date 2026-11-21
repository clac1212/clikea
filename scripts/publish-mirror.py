#!/usr/bin/env python3
"""Publie le jeu sur le miroir here.now (mêmes fichiers que GitHub Pages).

Usage :
    python3 scripts/publish-mirror.py [slug] [dossier]

Le slug par défaut est clever-bloom-q2pw. La clé API est lue dans
~/.herenow/credentials (mode 0600). Sans clé, here.now publierait un site
anonyme qui expire en 24 h : ce script refuse ce cas.
"""

import hashlib
import json
import os
import sys
import urllib.request
from concurrent.futures import ThreadPoolExecutor

API = "https://here.now/api/v1"
CLIENT = "opencode/clikea"
DEFAULT_SLUG = "clever-bloom-q2pw"
ROOT_FILES = ["index.html", "og.png", "robots.txt", "sitemap.xml"]
TYPES = {
    ".html": "text/html; charset=utf-8",
    ".png": "image/png",
    ".webp": "image/webp",
    ".txt": "text/plain; charset=utf-8",
    ".xml": "application/xml",
}


def main():
    slug = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_SLUG
    root = os.path.abspath(sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(__file__), ".."))

    cred = os.path.expanduser("~/.herenow/credentials")
    if not os.path.exists(cred):
        sys.exit("Clé here.now absente : " + cred)
    token = open(cred, encoding="utf-8").read().strip()
    headers = {"Authorization": "Bearer " + token, "X-HereNow-Client": CLIENT}

    paths = [p for p in ROOT_FILES if os.path.exists(os.path.join(root, p))]
    img_dir = os.path.join(root, "img")
    if os.path.isdir(img_dir):
        paths += ["img/" + f for f in sorted(os.listdir(img_dir)) if f.endswith(".webp")]

    files = []
    for rel in paths:
        data = open(os.path.join(root, rel), "rb").read()
        files.append({
            "path": rel,
            "size": len(data),
            "contentType": TYPES.get(os.path.splitext(rel)[1], "application/octet-stream"),
            "sha256": hashlib.sha256(data).hexdigest(),
        })

    req = urllib.request.Request(
        API + "/publish/" + slug,
        method="PUT",
        data=json.dumps({"files": files}).encode(),
        headers=dict(headers, **{"content-type": "application/json"}),
    )
    resp = json.load(urllib.request.urlopen(req, timeout=120))
    upload = resp.get("upload") or resp
    version_id = upload["versionId"]
    targets = upload.get("uploads", [])
    print("version %s · %d fichiers · %d déjà à jour" % (
        version_id, len(targets), len(upload.get("skipped", []))))

    def send(target):
        data = open(os.path.join(root, target["path"]), "rb").read()
        r = urllib.request.Request(
            target["url"], method=target.get("method", "PUT"),
            data=data, headers=target["headers"])
        with urllib.request.urlopen(r, timeout=120) as rr:
            return target["path"], rr.status

    fails = []
    with ThreadPoolExecutor(max_workers=8) as ex:
        for path, status in ex.map(send, targets):
            if status not in (200, 201, 204):
                fails.append((path, status))

    if fails:
        sys.exit("Échec d'envoi : %s" % fails[:5])

    fin = urllib.request.Request(
        API + "/publish/" + slug + "/finalize",
        method="POST",
        data=json.dumps({"versionId": version_id}).encode(),
        headers=dict(headers, **{"content-type": "application/json"}),
    )
    out = json.load(urllib.request.urlopen(fin, timeout=120))
    print("en ligne :", out.get("siteUrl") or ("https://" + slug + ".here.now/"))


if __name__ == "__main__":
    main()
