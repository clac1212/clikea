#!/usr/bin/env python3
"""Page de validation des contenus : review_page.py <dossier social> <dossier de sortie> [dates...]
Copie vidéos et images des jours demandés (par défaut : tous) et écrit index.html, à publier sur here.now."""
import json, os, shutil, sys, html

src, dst = sys.argv[1], sys.argv[2]
days = sys.argv[3:] or sorted(d for d in os.listdir(src) if os.path.exists(os.path.join(src, d, 'content.json')))
os.makedirs(dst, exist_ok=True)
blocks = []
for day in days:
    c = json.load(open(os.path.join(src, day, 'content.json')))
    os.makedirs(os.path.join(dst, day), exist_ok=True)
    files = sorted(f for f in os.listdir(os.path.join(src, day)) if f.endswith(('.mp4', '.png')))
    for f in files:
        shutil.copy(os.path.join(src, day, f), os.path.join(dst, day, f))
    cap = c.get('captions', {})
    car = ''.join(f'<img src="{day}/{f}" alt="">' for f in files if f.startswith('carousel'))
    xim = f'<img class="x" src="{day}/x.png" alt="">' if 'x.png' in files else '<p class="muted">Pas de piège d’hier (moins de 5 réponses).</p>'
    prods = ', '.join(f"{p['name']}" for p in c['products'])
    esc = lambda t: html.escape(t or '—')
    blocks.append(f'''
<section><h2>{day}</h2>
<p class="muted">Quiz : {esc(prods)} · aucun produit des grilles du 10 du jour à venir.</p>
<div class="row">
  <div class="col"><h3>TikTok · Reels · Shorts</h3><video src="{day}/video.mp4" controls playsinline preload="metadata"></video>
    <p class="cap">{esc(cap.get('tiktok'))}</p><p class="muted">Lien : clikeagame.com/?utm_source=tiktok</p></div>
  <div class="col"><h3>Carrousel Instagram</h3><div class="car">{car}</div><p class="cap">{esc(cap.get('instagram'))}</p></div>
  <div class="col"><h3>X · Bluesky</h3>{xim}<p class="cap">{esc(cap.get('x'))}</p><p class="muted">Lien en réponse : clikeagame.com/?utm_source=x</p></div>
</div></section>''')
page = f'''<!doctype html><html lang="fr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>CLIKEA — Contenus à valider</title>
<style>
body{{margin:0;background:#F2EFE7;color:#111;font-family:"Helvetica Neue",Helvetica,Arial,sans-serif}}
header{{background:#0058A3;color:#fff;padding:24px 20px;border-bottom:6px solid #FFDB00}}
header h1{{margin:0;font-size:30px;text-transform:uppercase;font-weight:900}}header p{{margin:8px 0 0;color:#e6f0f8;max-width:70ch}}
main{{max-width:1180px;margin:0 auto;padding:20px}}
section{{background:#fff;border:2px solid #111;padding:16px;margin-bottom:22px}}
h2{{margin:0 0 4px;font-size:22px}}h3{{margin:0 0 8px;font-size:13px;text-transform:uppercase;letter-spacing:.06em}}
.row{{display:grid;grid-template-columns:repeat(3,1fr);gap:18px;margin-top:12px}}
.col{{min-width:0}}video{{width:100%;max-width:300px;aspect-ratio:9/16;background:#000;display:block}}
.car{{display:flex;gap:6px;overflow-x:auto;scroll-snap-type:x mandatory}}.car img{{height:300px;scroll-snap-align:start}}
img.x{{width:100%}}.cap{{background:#FFF6C9;border-left:4px solid #111;padding:10px;font-size:14px}}.muted{{color:#767676;font-size:12px}}
@media (max-width:900px){{.row{{grid-template-columns:1fr}}}}
</style></head><body>
<header><h1>Contenus à valider</h1><p>Générés à partir des vraies données du jeu. Rien n’est publié tant que César ou Ben n’a pas validé. Pour corriger : dire quoi changer (texte, produit, format).</p></header>
<main>{''.join(blocks)}</main></body></html>'''
open(os.path.join(dst, 'index.html'), 'w').write(page)
print(os.path.join(dst, 'index.html'), len(days), 'jour(s)')
