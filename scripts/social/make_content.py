#!/usr/bin/env python3
"""Contenus réseaux sociaux CLIKEA, générés à partir des vraies données du jeu.

Usage : make_content.py <dossier de sortie> [--date AAAA-MM-JJ] [--seed N]
Produit dans <dossier>/<date>/ :
  video.mp4        vidéo 9:16 « Devine avant la réponse » (8 produits, du plus connu au plus raté)
  carousel-NN.png  carrousel Instagram 1080 × 1350 (même quiz, réponses à la fin)
  x.png            image 1200 × 675 du piège de la veille
  content.json     produits, statistiques, textes (légendes TikTok / Instagram / X)
Règles : aucun produit d'une grille du 10 du jour d'aujourd'hui ou à venir (pas de spoiler) ;
les statistiques affichées sont les vraies réussites mesurées.
Dépend de : supabase CLI (projet lié), Pillow, imageio-ffmpeg, opencode (DeepSeek V4.1 Flash).
"""
import json, os, random, subprocess, sys, datetime, re
from PIL import Image, ImageDraw, ImageFont

REF = 'vubopkycvzzqufpqxpbg'
REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
LLM = 'opencode-go/deepseek-v4.1-flash'
MIN_N = 5  # réponses minimales pour afficher un pourcentage réel
BLUE, YELLOW, INK, WHITE, PAPER = (0, 88, 163), (255, 219, 0), (17, 17, 17), (255, 255, 255), (255, 253, 242)
FONT_BLACK = '/System/Library/Fonts/Supplemental/Arial Black.ttf'
FONT_BOLD = '/System/Library/Fonts/Supplemental/Arial Bold.ttf'


def font(size, black=True):
    return ImageFont.truetype(FONT_BLACK if black else FONT_BOLD, size)


def sql(q):
    out = subprocess.run(['supabase', 'db', 'query', '--linked', '--project-ref', REF, '-o', 'json', q],
                         capture_output=True, text=True, cwd=REPO).stdout
    return json.loads(out[out.index('{'):])['rows']


def ffmpeg():
    import imageio_ffmpeg
    return imageio_ffmpeg.get_ffmpeg_exe()


def pick_products(day, seed):
    """8 produits du réseau, jamais dans une grille d'aujourd'hui ou à venir, du plus trouvé au plus raté."""
    rows = sql(f"""
      with fut as (select distinct x from clikea_daily_grid g, unnest(g.products) x where g.day >= '{day}'),
      ans as (select product, count(*) n, avg(correct::int) ok from clikea_answers
              where format = 'photo' and source <> 'calib' group by product),
      r as (select value ref from clikea_settings where key = 'ref_theta')
      select f.name, a.image_path, a.type_fr, f.iconic, coalesce(ans.n, 0) n,
             coalesce(ans.ok, 0.25 + 0.75 / (1 + exp(-(r.ref - f.difficulty)))) ok
      from clikea_families f join clikea_articles a on a.family = f.name and a.is_main
      left join ans on ans.product = f.name, r
      where f.pool in ('core', 'seen') and f.active and f.playable and f.name not in (select x from fut)""")
    for r in rows:
        r['ok'] = float(r['ok'])
    rnd = random.Random(seed)
    known = [r for r in rows if r['ok'] >= 0.6]
    mid = [r for r in rows if 0.35 <= r['ok'] < 0.6]
    hard = [r for r in rows if r['ok'] < 0.35 and (r['iconic'] or r['n'] >= 3)] or [r for r in rows if r['ok'] < 0.35]
    sel = rnd.sample(known, 3) + rnd.sample(mid, 3) + rnd.sample(hard, 2)
    return sorted(sel, key=lambda r: -r['ok'])


def yesterday_trap(day):
    """Produit le plus raté du 10 du jour d'hier (au moins 2 réponses)."""
    rows = sql(f"""
      select u.x as name, a.image_path, a.type_fr, count(an.id) n, coalesce(avg(an.correct::int), 0) ok
      from clikea_daily_grid g cross join unnest(g.products) as u(x)
      join clikea_articles a on a.family = u.x and a.is_main
      left join clikea_answers an on an.product = u.x and an.day = g.day and an.source = 'daily' and an.format = 'photo'
      where g.day = date '{day}' - 1 group by u.x, a.image_path, a.type_fr having count(an.id) >= {MIN_N} order by ok limit 1""")
    return rows[0] if rows else None


def product_photo(path, size):
    im = Image.open(os.path.join(REPO, path)).convert('RGB')
    im.thumbnail((size, size))
    card = Image.new('RGB', (size, size), WHITE)
    card.paste(im, ((size - im.width) // 2, (size - im.height) // 2))
    return card


def center(d, y, text, f, fill, W):
    w = d.textlength(text, font=f)
    d.text(((W - w) / 2, y), text, font=f, fill=fill)


def wrap(d, text, f, maxw):
    words, lines, cur = text.split(), [], ''
    for w in words:
        t = (cur + ' ' + w).strip()
        if d.textlength(t, font=f) <= maxw:
            cur = t
        else:
            lines.append(cur); cur = w
    lines.append(cur)
    return lines


def logo(d, W, y):
    f = font(54)
    w = d.textlength('CLIKEA', font=f)
    d.ellipse(((W - w) / 2 - 40, y - 6, (W + w) / 2 + 40, y + 78), fill=YELLOW)
    d.text(((W - w) / 2, y + 4), 'CLIKEA', font=f, fill=BLUE)


def frame_text(W, H, lines, sub=None):
    im = Image.new('RGB', (W, H), BLUE)
    d = ImageDraw.Draw(im)
    logo(d, W, 180)
    f = font(96)
    y = H // 2 - 60 * len(lines)
    for ln in lines:
        center(d, y, ln, f, WHITE if ln != lines[-1] else YELLOW, W)
        y += 120
    if sub:
        fs = font(44, False)
        y += 40
        for ln in wrap(d, sub, fs, W - 160):
            center(d, y, ln, fs, WHITE, W); y += 60
    return im


def frame_question(W, H, k, n, prod, left, reveal):
    im = Image.new('RGB', (W, H), BLUE)
    d = ImageDraw.Draw(im)
    logo(d, W, 110)
    center(d, 260, f'N° {k} / {n}', font(64), YELLOW, W)
    im.paste(product_photo(prod['image_path'], 860), ((W - 860) // 2, 380))
    if reveal:
        f = font(120 if len(prod['name']) <= 9 else 84)
        center(d, 1300, prod['name'], f, YELLOW, W)
        center(d, 1460, prod['type_fr'], font(48, False), WHITE, W)
        # Un pourcentage n'est affiché que s'il repose sur au moins 5 vraies réponses.
        if prod['n'] >= MIN_N:
            center(d, 1560, f"{round(prod['ok'] * 100)} % des joueurs le trouvent", font(44, False), WHITE, W)
    else:
        center(d, 1320, 'Quel est son nom ?', font(76), WHITE, W)
        center(d, 1460, str(left), font(150), YELLOW, W)
    return im


def make_video(prods, out, hook_pct):
    W, H = 1080, 1920
    frames = []  # (image, durée)
    last = prods[-1]
    hook = (f"Le dernier, {100 - round(last['ok'] * 100)} % des joueurs le ratent." if last['n'] >= MIN_N
            else 'Du plus connu au plus vicieux.')
    frames.append((frame_text(W, H, ['8 produits IKEA.', 'Tu en trouves', 'combien ?'], hook), 2.6))
    for k, p in enumerate(prods, 1):
        for left in (3, 2, 1):
            frames.append((frame_question(W, H, k, len(prods), p, left, False), 1.0))
        frames.append((frame_question(W, H, k, len(prods), p, 0, True), 1.8))
    frames.append((frame_text(W, H, ['Ton score', 'en commentaire.'], 'Le 10 du jour, chaque jour : clikeagame.com'), 3.2))
    tmp = os.path.join(out, 'frames'); os.makedirs(tmp, exist_ok=True)
    lst = []
    for i, (im, dur) in enumerate(frames):
        fp = os.path.join(tmp, f'{i:03d}.png'); im.save(fp)
        lst.append(f"file '{fp}'\nduration {dur}")
    lst.append(f"file '{fp}'")
    open(os.path.join(tmp, 'list.txt'), 'w').write('\n'.join(lst))
    total = sum(d for _, d in frames)
    subprocess.run([ffmpeg(), '-y', '-loglevel', 'error', '-f', 'concat', '-safe', '0', '-i', os.path.join(tmp, 'list.txt'),
                    '-f', 'lavfi', '-t', str(total), '-i', 'anullsrc=r=44100:cl=stereo',
                    '-vf', 'fps=30,format=yuv420p', '-c:v', 'libx264', '-preset', 'medium', '-crf', '23',
                    '-c:a', 'aac', '-shortest', '-movflags', '+faststart', os.path.join(out, 'video.mp4')], check=True)
    for f in os.listdir(tmp):
        os.remove(os.path.join(tmp, f))
    os.rmdir(tmp)
    return round(total, 1)


def make_carousel(prods, out):
    W, H = 1080, 1350
    slides = [frame_text(W, H, ['8 produits IKEA.', 'Tu en trouves', 'combien ?'], 'Note tes réponses, la solution est à la fin.')]
    for k, p in enumerate(prods, 1):
        im = Image.new('RGB', (W, H), BLUE)
        d = ImageDraw.Draw(im)
        center(d, 70, f'N° {k} / {len(prods)}', font(64), YELLOW, W)
        im.paste(product_photo(p['image_path'], 900), ((W - 900) // 2, 190))
        center(d, 1150, 'Quel est son nom ?', font(60), WHITE, W)
        slides.append(im)
    im = Image.new('RGB', (W, H), BLUE)
    d = ImageDraw.Draw(im)
    center(d, 80, 'Les réponses', font(80), YELLOW, W)
    y = 230
    for k, p in enumerate(prods, 1):
        d.text((110, y), f'{k}.', font=font(56), fill=YELLOW)
        d.text((210, y), p['name'], font=font(56), fill=WHITE)
        if p['n'] >= MIN_N:
            d.text((210, y + 66), f"{round(p['ok'] * 100)} % des joueurs le trouvent", font=font(30, False), fill=WHITE)
        y += 128
    center(d, H - 110, 'Le 10 du jour : clikeagame.com', font(40, False), WHITE, W)
    slides.append(im)
    for i, s in enumerate(slides):
        s.save(os.path.join(out, f'carousel-{i + 1:02d}.png'))
    return len(slides)


def make_x(trap, out):
    W, H = 1200, 675
    im = Image.new('RGB', (W, H), BLUE)
    d = ImageDraw.Draw(im)
    im.paste(product_photo(trap['image_path'], 520), (60, 78))
    miss = 100 - round(float(trap['ok']) * 100)
    d.text((640, 120), 'Le piège d’hier', font=font(40, False), fill=WHITE)
    d.text((640, 180), f'{miss} %', font=font(150), fill=YELLOW)
    d.text((640, 360), 'des joueurs', font=font(52), fill=WHITE)
    d.text((640, 425), 'l’ont raté.', font=font(52), fill=WHITE)
    d.text((640, 540), 'Et toi, tu sais ce que c’est ?', font=font(32, False), fill=WHITE)
    im.save(os.path.join(out, 'x.png'))
    return miss


def captions(data):
    prompt = ("Tu écris pour le compte d'un jeu web gratuit, CLIKEA (clikeagame.com) : on voit la photo d'un produit IKEA "
              "et on doit trouver son nom. Ton : drôle, complice, court, en français, sans emoji excessif (2 maximum), "
              "jamais de récompense promise contre un like ou un abonnement. Ne révèle aucun nom de produit du quiz. "
              f"Le quiz compte exactement {data['count']} produits. N'invente aucun autre chiffre que ceux donnés ici. "
              "Réponds UNIQUEMENT par un objet JSON {\"tiktok\": \"...\", \"instagram\": \"...\", \"x\": \"...\"}.\n"
              "- tiktok : légende ≤ 150 caractères, appel à commenter son score, puis 4 hashtags dont #ikea et #quiz.\n"
              "- instagram : 2 phrases, appel à envoyer le post à quelqu'un, puis 5 hashtags.\n"
              f"- x : ≤ 200 caractères sur le piège d'hier ({data['x_miss']} % l'ont raté), sans lien (il est mis en réponse).\n")
    # Lancé depuis un dossier vide, entrée standard fermée : sinon l'appel peut ne jamais rendre.
    empty = '/tmp/clikea-llm'
    os.makedirs(empty, exist_ok=True)
    for _ in range(3):  # une réponse vide ou hors JSON arrive parfois : on retente
        try:
            out = subprocess.run(['opencode', 'run', '-m', LLM, '--', prompt], capture_output=True, text=True, timeout=120, cwd=empty,
                                 stdin=subprocess.DEVNULL).stdout  # sinon opencode attend l'entrée standard
        except subprocess.TimeoutExpired:
            continue
        m = re.search(r'\{.*\}', out, re.S)
        try:
            res = json.loads(m.group(0)) if m else {}
        except ValueError:
            res = {}
        if all(res.get(k) for k in ('tiktok', 'instagram', 'x')):
            return res
    return {}


def main():
    if len(sys.argv) < 2:
        print(__doc__); sys.exit(1)
    args = sys.argv[1:]
    day = args[args.index('--date') + 1] if '--date' in args else datetime.date.today().isoformat()
    seed = int(args[args.index('--seed') + 1]) if '--seed' in args else int(day.replace('-', ''))
    out = os.path.abspath(os.path.join(args[0], day))
    os.makedirs(out, exist_ok=True)
    prods = pick_products(day, seed)
    data = {'date': day, 'products': [{k: p[k] for k in ('name', 'type_fr', 'image_path')} | {'ok': round(p['ok'], 2), 'n': p['n']}
                                       for p in prods]}
    data['video_seconds'] = make_video(prods, out, None)
    data['carousel_slides'] = make_carousel(prods, out)
    trap = yesterday_trap(day)
    if trap:
        data['x_trap'] = trap['name']
        data['x_miss'] = make_x(trap, out)
    else:
        data['x_miss'] = None
    data['count'] = len(prods)
    data['captions'] = captions(data)
    data['link'] = 'https://clikeagame.com/?utm_source={net}&utm_campaign=' + day
    json.dump(data, open(os.path.join(out, 'content.json'), 'w'), ensure_ascii=False, indent=1)
    print(json.dumps({k: v for k, v in data.items() if k != 'products'}, ensure_ascii=False))


if __name__ == '__main__':
    main()
