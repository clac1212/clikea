#!/usr/bin/env python3
"""Catalogue CLIKEA : récupère, trie, structure et exporte les produits IKEA.

Étapes (relançables, tout est mis en cache dans scripts/catalog/cache/) :
  families   listes de produits ikea.com (France) -> gammes candidates
  fetch-fr   API de recherche ikea.com, France, une requête par gamme
  parse      articles par gamme (un seul nom, article simple, photo, type)
  llm        tri DeepSeek V4.1 Flash : jouable ou non, famille visuelle
  fetch-langs  types en anglais, allemand, espagnol, italien + avis, reliés par l'identifiant de photo
  build      catalogue final : article principal, cultes, difficulté de départ, orthographes
  images     photos WebP 640x640 dans img/
  sql        fichier SQL d'upsert vers Supabase (cache/upsert.sql)
  export     remplace PRODUCTS dans index.html
"""
import json, os, re, sys, time, random, subprocess, unicodedata, math, concurrent.futures as cf
import urllib.request, urllib.parse, urllib.error

ROOT = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(ROOT, '..', '..'))
CACHE = os.path.join(ROOT, 'cache')
UA = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130 Safari/537.36'
SEARCH = 'https://sik.search.blue.cdtapps.com/{cc}/search-result-page?q={q}&size=24&types=PRODUCT'
LANGS = {'en': 'gb/en', 'de': 'de/de', 'es': 'es/es', 'it': 'it/it'}
DELAY = 0.5  # 2 requêtes par seconde au plus
LLM_MODEL = 'opencode-go/deepseek-v4.1-flash'

# Cultes : sélection IKEA Icons 2023, page IKEA « iconic designs », presse (docs/PRODUITS.md).
ICONIC = ['BILLY', 'KALLAX', 'POÄNG', 'LACK', 'MALM', 'KLIPPAN', 'MAMMUT', 'SÖDERHAMN', 'DUKTIG', 'STOCKHOLM',
          'LISABO', 'RISATORP', 'RÅSKOG', 'EKTORP', 'BLÅHAJ', 'STRANDMON', 'LAMPAN', 'BURVIK', 'KYRRE', 'TURBO',
          'FAMNIG HJÄRTA', 'SINNERLIG', 'CHILIFRUKT', 'FRÖSET', 'BORGEBY', 'ODGER', 'LOBERGET', 'JANINGE', 'SYMFONISK',
          'BRUSEN', 'KRUX', 'FRAKTA', 'FROSTA', 'DOCKSTA', 'RENS', 'FÄRGRIK', 'HEMNES', 'PAX', 'IVAR', 'TROFAST',
          'GOSIG GOLDEN', 'MARIUS', 'TERTIAL', 'SKUBB', 'FEJKA', 'BEKVÄM', 'ALEX', 'MICKE', 'VITTSJÖ', 'NORDLI']


def path(*p):
    full = os.path.join(CACHE, *p)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    return full


def get(url, binary=False, tries=3):
    for k in range(tries):
        try:
            req = urllib.request.Request(url, headers={'User-Agent': UA, 'Accept': '*/*'})
            with urllib.request.urlopen(req, timeout=15) as r:
                data = r.read()
                return data if binary else data.decode('utf-8')
        except urllib.error.HTTPError as e:
            if e.code in (404, 410):
                return None
            time.sleep(2 + 3 * k)
        except Exception:
            time.sleep(2 + 3 * k)
    raise RuntimeError('échec ' + url)


def load(name, default=None):
    p = path(name)
    if not os.path.exists(p):
        return default
    with open(p) as f:
        return json.load(f)


def save(name, data):
    with open(path(name), 'w') as f:
        json.dump(data, f, ensure_ascii=False, indent=1)


def slugify(name):
    s = unicodedata.normalize('NFD', name.lower())
    s = ''.join(c for c in s if unicodedata.category(c) != 'Mn')
    return re.sub(r'[^a-z0-9]+', '-', s).strip('-')


# ---------- étapes ----------

def step_families():
    idx = get('https://www.ikea.com/sitemaps/sitemap.xml')
    maps = re.findall(r'<loc>([^<]*prod-fr-FR_\d+\.xml)</loc>', idx)
    counts = {}
    for m in maps:
        xml = get(m)
        for slug in re.findall(r'/fr/fr/p/([^/<]+)/?</loc>', xml):
            fam = slug.split('-')[0]
            counts[fam] = counts.get(fam, 0) + 1
        time.sleep(1)
    fams = sorted(counts.items(), key=lambda x: -x[1])
    save('families.json', [{'q': q, 'articles': n} for q, n in fams])
    print('gammes candidates :', len(fams), 'depuis', len(maps), 'fichiers')


def search(cc, q):
    p = path('search', cc.replace('/', '-'), slugify(q) + '.json')
    if os.path.exists(p):
        with open(p) as f:
            return json.load(f)
    raw = get(SEARCH.format(cc=cc, q=urllib.parse.quote(q)))
    data = json.loads(raw) if raw else {}
    items = (((data.get('searchResultPage') or {}).get('products') or {}).get('main') or {}).get('items') or []
    keep = []
    for it in items:
        pr = it.get('product') or {}
        keep.append({k: pr.get(k) for k in ('name', 'typeName', 'itemNo', 'itemNoGlobal', 'itemType', 'mainImageUrl',
                                             'mainImageAlt', 'ratingCount', 'ratingValue', 'badge', 'categoryPath',
                                             'pipUrl', 'salesPrice', 'tag', 'lastChance', 'onlineSellable')})
    with open(p, 'w') as f:
        json.dump(keep, f, ensure_ascii=False)
    time.sleep(DELAY)
    return keep


def step_fetch_fr(workers=4):
    fams = load('families.json')
    with cf.ThreadPoolExecutor(workers) as ex:
        for i, _ in enumerate(ex.map(lambda f: search('fr/fr', f['q']), fams)):
            if i % 100 == 0:
                print(i, '/', len(fams), flush=True)
    print('fr terminé')


IMG_ID = re.compile(r'_(pe\d+)_')


def article(it):
    url = it.get('mainImageUrl') or ''
    m = IMG_ID.search(url)
    price = ((it.get('salesPrice') or {}).get('numeral'))
    cats = [c.get('name') for c in (it.get('categoryPath') or []) if c.get('name')]
    badge = (it.get('badge') or {}).get('type')
    return {
        'item': it.get('itemNo'), 'type_fr': (it.get('typeName') or '').strip(), 'price': price,
        'image_url': url, 'image_id': m.group(1) if m else None, 'ratings_fr': it.get('ratingCount') or 0,
        'rating_value': it.get('ratingValue'), 'top_seller': badge == 'TOP_SELLER', 'category': ' › '.join(cats),
        'pip': it.get('pipUrl'), 'is_new': 'NEW' in json.dumps(it.get('tag') or '').upper(),
    }


def step_parse():
    fams = {}
    d = path('search', 'fr-fr')
    for fn in os.listdir(d):
        for it in json.load(open(os.path.join(d, fn))):
            name = (it.get('name') or '').strip()
            # ART = article simple ; SPR = combinaison vendue comme un seul produit (POÄNG fauteuil, canapés EKTORP…)
            if not name or '/' in name or it.get('itemType') not in ('ART', 'SPR'):
                continue
            a = article(it)
            if not a['type_fr'] or not a['image_id'] or not a['item']:
                continue
            fam = fams.setdefault(name, {})
            fam[a['item']] = a
    out = {}
    for name, arts in fams.items():
        lst = sorted(arts.values(), key=hero_key)
        out[name] = lst[:8]
    save('parsed.json', out)
    print('gammes avec au moins un article photographié :', len(out))


# Types d'articles qui ne représentent pas la gamme (housse, pièce, coussin de fauteuil…) : jamais choisis comme héros s'il existe mieux.
PART_TYPES = ('housse', 'pied', 'poignée', 'bouton', 'charnière', 'tablette', 'plateau', 'panneau', 'porte', 'façade', 'montant',
              'rail', 'coussin', 'planche', 'support', 'fixation', 'accessoire', 'pièce', 'tringle', 'tiroir', 'barre', 'cache',
              'protection', 'recharge', 'ampoule', 'abat-jour', 'structure', 'base', 'dossier', 'accoudoir', 'garniture')


def hero_key(a):
    t = a['type_fr'].lower()
    part = any(t.startswith(w) for w in PART_TYPES)
    return (part, -a['top_seller'], -a['ratings_fr'], a['item'])


LLM_PROMPT = """Tu tries des produits IKEA pour un jeu : on montre la photo, le joueur doit retrouver le nom du produit.
Pour chaque image jointe, dans l'ordre, j'indique le nom IKEA et le type. Réponds UNIQUEMENT par un tableau JSON, un objet par image :
{"name": "<nom tel que donné>", "playable": true|false, "visual_family": "<une valeur EXACTE de la liste ci-dessous>", "reason": "<5 mots max>"}
Familles visuelles autorisées : canapé, fauteuil, chaise, tabouret et banc, table, bureau, lit, literie et matelas, armoire et penderie, commode et caisson, buffet et meuble TV, étagère et bibliothèque, rangement mural, boîte et panier, meuble de cuisine, luminaire de plafond, lampe à poser, lampadaire, miroir, tapis, textile et rideau, coussin et plaid, vaisselle, verre et carafe, ustensile de cuisine, casserole et poêle, salle de bain, décoration, plante artificielle et cache-pot, cadre et horloge, jouet et peluche, enfant et bébé, extérieur, électronique et maison connectée, divers.
playable = true seulement si : un objet entier et reconnaissable, photographié seul sur fond clair, qu'un client d'IKEA pourrait mémoriser (meuble, luminaire, déco, textile, vaisselle, ustensile, jouet, rangement).
playable = false si : pièce détachée, accessoire de montage, pied, poignée, charnière, housse seule, recharge, consommable, nourriture, plante vivante, carte cadeau, produit sans forme distinctive (vis, câble, ampoule standard), photo en gros plan d'un détail, ou mise en scène où l'objet n'est pas identifiable.
Produits :
"""


VISUAL = set(x.strip().lower() for x in LLM_PROMPT.split('Familles visuelles autorisées :')[1].split('\n')[0].rstrip('.').split(','))


def llm_batch(batch):
    files = []
    lines = []
    for i, (name, a) in enumerate(batch):
        p = path('thumbs', slugify(name) + '-' + a['item'] + '.jpg')
        if not os.path.exists(p):
            data = get(a['image_url'].split('?')[0] + '?f=s', binary=True)
            with open(p, 'wb') as f:
                f.write(data)
        files += ['-f', p]
        lines.append(f'{i + 1}. {name} — {a["type_fr"]}')
    cmd = ['opencode', 'run', '-m', LLM_MODEL] + files + ['--', LLM_PROMPT + '\n'.join(lines)]
    out = subprocess.run(cmd, capture_output=True, text=True, timeout=600, cwd=CACHE).stdout
    m = re.search(r'\[\s*\{.*\}\s*\]', out, re.S)
    if not m:
        raise RuntimeError('réponse LLM illisible : ' + out[-300:])
    res = json.loads(m.group(0))
    by = {slugify(r.get('name', '')): r for r in res}
    out = {}
    for i, (name, _) in enumerate(batch):
        r = by.get(slugify(name))
        if r is None and len(res) == len(batch):
            r = res[i]  # nom recopié autrement : on se fie à l'ordre, la réponse suit l'ordre des images
        out[name] = r
    return out


def step_llm(workers=8, size=8):
    parsed = load('parsed.json')
    done = load('llm.json', {})
    # Réévalue une gamme si son article héros a changé depuis le dernier tri.
    for n, arts in parsed.items():
        if n in done and done[n].get('item') not in (None, arts[0]['item']):
            del done[n]
        elif n in done and done[n].get('item') is None:
            old = sorted(arts, key=lambda a: (-a['top_seller'], -a['ratings_fr'], a['item']))[0]['item']
            if old != arts[0]['item']:
                del done[n]
            else:
                done[n]['item'] = old
    todo = [(n, arts[0]) for n, arts in sorted(parsed.items()) if n not in done]
    items = {n: a['item'] for n, a in todo}
    batches = [todo[i:i + size] for i in range(0, len(todo), size)]
    print('lots à trier :', len(batches), flush=True)
    with cf.ThreadPoolExecutor(workers) as ex:
        futs = {ex.submit(llm_batch, b): b for b in batches}
        for k, fu in enumerate(cf.as_completed(futs)):
            try:
                for name, r in fu.result().items():
                    if r is not None:
                        vf = (r.get('visual_family') or '').strip().lower()
                        done[name] = {'item': items[name], 'playable': bool(r.get('playable')), 'visual_family': vf if vf in VISUAL else 'divers',
                                      'reason': (r.get('reason') or '')[:80]}
            except Exception as e:
                print('lot en échec :', str(e)[:200], flush=True)
            if k % 10 == 0:
                save('llm.json', done)
                print(k, '/', len(batches), 'triés :', len(done), flush=True)
    save('llm.json', done)
    print('LLM terminé :', len(done), 'gammes, dont jouables :', sum(1 for v in done.values() if v['playable']))


def step_fetch_langs():
    parsed, llm = load('parsed.json'), load('llm.json', {})
    names = [n for n in parsed if (llm.get(n) or {}).get('playable')]
    langs = load('langs.json', {})
    todo = [n for n in names if n not in langs]
    # Préchauffe le cache en parallèle (3 requêtes simultanées), puis assemble sans réseau.
    with cf.ThreadPoolExecutor(3) as ex:
        for i, _ in enumerate(ex.map(lambda job: search(*job), [(cc, n) for n in todo for cc in LANGS.values()])):
            if i % 200 == 0:
                print('requêtes', i, '/', 4 * len(todo), flush=True)
    for i, n in enumerate(todo):
        ids = {a['image_id']: a['item'] for a in parsed[n]}
        rec = {}
        for code, cc in LANGS.items():
            for it in search(cc, n):
                if (it.get('name') or '').strip() != n or it.get('itemType') not in ('ART', 'SPR'):
                    continue
                m = IMG_ID.search(it.get('mainImageUrl') or '')
                if m and m.group(1) in ids:
                    item = ids[m.group(1)]
                    r = rec.setdefault(item, {})
                    if (it.get('typeName') or '').strip() and 'type_' + code not in r:
                        r['type_' + code] = it['typeName'].strip()
                    r['ratings_' + code] = max(r.get('ratings_' + code, 0), it.get('ratingCount') or 0)
                    if (it.get('badge') or {}).get('type') == 'TOP_SELLER':
                        r['top_' + code] = True
        langs[n] = rec
        if i % 50 == 0:
            save('langs.json', langs)
            print(i, '/', len(names), n, flush=True)
    save('langs.json', langs)
    print('langues terminé :', len(langs))


def strip_accents(s):
    s = unicodedata.normalize('NFD', s.replace('Ø', 'O').replace('ø', 'o'))
    return ''.join(c for c in s if unicodedata.category(c) != 'Mn')


def fake_spellings(name, real):
    """Fausses orthographes crédibles qui changent des lettres, jamais seulement un accent
    (le jeu ignore les accents), et jamais un vrai nom IKEA. Une variante par famille de piège si possible."""
    n = name
    base = strip_accents(n)
    real_plain = {strip_accents(r) for r in real}
    classes = [
        # sons proches
        [('K', 'C'), ('C', 'K'), ('CK', 'K'), ('K', 'CK'), ('KS', 'X'), ('X', 'KS'), ('V', 'W'), ('W', 'V'), ('J', 'Y'),
         ('Y', 'J'), ('I', 'Y'), ('Y', 'I'), ('Å', 'O'), ('Å', 'AA'), ('Ä', 'E'), ('Ö', 'Ø'), ('Ö', 'EU'), ('S', 'Z'), ('Z', 'S'),
         ('F', 'PH'), ('T', 'TH'), ('G', 'GH'), ('Q', 'K')],
        # lettres doublées ou simples
        [],
        # voyelles voisines
        [('E', 'A'), ('A', 'E'), ('O', 'U'), ('U', 'O'), ('I', 'E'), ('E', 'I')],
    ]
    found = [[], [], []]
    for k in (0, 2):
        for a, b in classes[k]:
            i = n.find(a)
            while i != -1:
                found[k].append(n[:i] + b + n[i + len(a):])
                i = n.find(a, i + 1)
    for i in range(len(n) - 1):  # lettre doublée -> simple
        if n[i] == n[i + 1] and n[i].isalpha():
            found[1].append(n[:i] + n[i + 1:])
    for i, c in enumerate(n):  # consonne simple -> doublée
        if c in 'LMNPRSTKFGD' and 0 < i < len(n) - 1 and n[i + 1] != c and n[i - 1] != c:
            found[1].append(n[:i] + c + c + n[i + 1:])
    rnd = random.Random(n)
    ok = lambda v: v != n and strip_accents(v) != base and strip_accents(v) not in real_plain and v not in real
    pools = []
    for f in found:
        f = sorted(set(v for v in f if ok(v)))
        rnd.shuffle(f)
        pools.append(f)
    out = []
    while len(out) < 3 and any(pools):  # une variante de chaque famille à tour de rôle
        for f in pools:
            while f and len(out) < 3:
                v = f.pop()
                if strip_accents(v) not in {strip_accents(o) for o in out}:
                    out.append(v)
                    break
    return out


def seed_difficulty(r_total, top, iconic):
    d = 2.0 - 0.6 * math.log10(1 + r_total) - 0.5 * top - 1.0 * iconic
    return round(max(-3.0, min(3.0, d)), 2)


TRANSLATE_PROMPT = """Traduis ces types de produits IKEA (libellés courts du site français) dans le libellé court qu'IKEA utiliserait en anglais (Royaume-Uni), allemand, espagnol et italien.
Réponds UNIQUEMENT par un objet JSON : {"<type français>": {"en": "...", "de": "...", "es": "...", "it": "..."}, ...}
Types :
"""


def translate_types(types):
    cache = load('translations.json', {})
    todo = sorted(t for t in set(types) if t not in cache)
    for i in range(0, len(todo), 40):
        chunk = todo[i:i + 40]
        out = subprocess.run(['opencode', 'run', '-m', LLM_MODEL, '--', TRANSLATE_PROMPT + '\n'.join(chunk)],
                             capture_output=True, text=True, timeout=600, cwd=CACHE).stdout
        m = re.search(r'\{.*\}', out, re.S)
        if not m:
            print('traduction illisible, lot ignoré', flush=True)
            continue
        for k, v in json.loads(m.group(0)).items():
            if k in chunk and all(v.get(c) for c in LANGS):
                cache[k] = {c: v[c].strip() for c in LANGS}
        save('translations.json', cache)
        print('traductions', min(i + 40, len(todo)), '/', len(todo), flush=True)
    return cache


def step_build():
    parsed, llm, langs = load('parsed.json'), load('llm.json', {}), load('langs.json', {})
    ko = load('ko.json', {})  # rempli par fetch-ko (à relancer après build pour les nouvelles gammes)
    # Types manquants : d'abord la traduction déjà vue dans la gamme pour le même type français, sinon DeepSeek.
    need = []
    for n, arts in parsed.items():
        if (llm.get(n) or {}).get('playable') and n in langs:
            rec = langs[n]
            seen = {}
            for a in arts:
                for c in LANGS:
                    v = rec.get(a['item'], {}).get('type_' + c)
                    if v:
                        seen.setdefault(a['type_fr'], {})[c] = v
            for a in arts:
                r = rec.setdefault(a['item'], {})
                for c in LANGS:
                    if not r.get('type_' + c) and seen.get(a['type_fr'], {}).get(c):
                        r['type_' + c] = seen[a['type_fr']][c]
                if not all(r.get('type_' + c) for c in LANGS):
                    need.append(a['type_fr'])
    tr = translate_types(need)
    for n, rec in langs.items():
        for a in parsed.get(n, []):
            r = rec.setdefault(a['item'], {})
            for c in LANGS:
                if not r.get('type_' + c) and a['type_fr'] in tr:
                    r['type_' + c] = tr[a['type_fr']][c]
    real = set(parsed.keys())
    fams = []
    for n, arts in parsed.items():
        L = llm.get(n)
        if not L or not L['playable'] or n not in langs:
            continue
        rec = langs[n]
        best = None
        # L'article montré est celui que le LLM a examiné : photo, famille visuelle et types restent cohérents.
        judged = [a for a in arts if a['item'] == L.get('item')]
        for a in (judged or arts):
            r = rec.get(a['item'], {})
            tot = a['ratings_fr'] + sum(r.get('ratings_' + c, 0) for c in LANGS)
            score = (all(r.get('type_' + c) for c in LANGS), a['item'] == arts[0]['item'], tot)
            if best is None or score > best[0]:
                best = (score, a, r, tot)
        _, a, r, tot = best
        if a['price'] is None:
            continue
        if not all(r.get('type_' + c) for c in LANGS):
            continue  # type manquant dans une langue : le jeu n'affiche jamais un type d'un autre article
        top = a['top_seller'] or any(r.get('top_' + c) for c in LANGS)
        iconic = n in ICONIC
        fams.append({
            'name': n, 'slug': slugify(n), 'iconic': iconic, 'visual_family': L['visual_family'] or 'divers',
            'llm_reason': L['reason'], 'ratings_total': tot, 'top_seller': top,
            'seed_difficulty': seed_difficulty(tot, top, iconic), 'spellings': fake_spellings(n, real),
            'article': {'item': a['item'], 'type_fr': a['type_fr'], 'type_en': r['type_en'], 'type_de': r['type_de'],
                        'type_es': r['type_es'], 'type_it': r['type_it'], 'type_ko': ko.get(n), 'price': a['price'], 'image_url': a['image_url'],
                        'image_id': a['image_id'], 'category': a['category'], 'pip': a['pip'], 'is_new': a['is_new'],
                        'image_path': 'img/' + slugify(n) + '.webp'},
        })
    fams.sort(key=lambda f: f['name'])
    save('catalog.json', fams)
    print('catalogue :', len(fams), 'gammes jouables ; cultes présents :', sum(f['iconic'] for f in fams),
          '; cultes absents :', sorted(set(ICONIC) - {f['name'] for f in fams}))


def step_images(workers=4):
    from PIL import Image
    import io
    fams = load('catalog.json')

    def one(f):
        out = os.path.join(REPO, f['article']['image_path'])
        meta = path('imgsrc', f['slug'] + '.txt')
        if os.path.exists(out) and os.path.exists(meta) and open(meta).read() == f['article']['image_id']:
            return 0
        data = get(f['article']['image_url'].split('?')[0] + '?f=m', binary=True)
        im = Image.open(io.BytesIO(data)).convert('RGB')
        im.thumbnail((640, 640))
        canvas = Image.new('RGB', (640, 640), (255, 255, 255))
        canvas.paste(im, ((640 - im.width) // 2, (640 - im.height) // 2))
        canvas.save(out, 'WEBP', quality=78, method=6)
        open(meta, 'w').write(f['article']['image_id'])
        time.sleep(DELAY)
        return 1

    with cf.ThreadPoolExecutor(workers) as ex:
        n = sum(ex.map(one, fams))
    print('photos écrites :', n, '/', len(fams))


def q(v):
    if v is None:
        return 'null'
    if isinstance(v, bool):
        return 'true' if v else 'false'
    if isinstance(v, (int, float)):
        return repr(v)
    if isinstance(v, list):
        return 'array[' + ','.join(q(x) for x in v) + ']::text[]' if v else "'{}'::text[]"
    return "'" + str(v).replace("'", "''") + "'"


def step_sql():
    fams = load('catalog.json')
    lines = ['begin;']
    for f in fams:
        a = f['article']
        lines.append(
            'insert into public.clikea_families (name, slug, iconic, visual_family, llm_reason, ratings_total, top_seller, seed_difficulty, difficulty, spellings, active, playable) values ('
            + ','.join(q(x) for x in [f['name'], f['slug'], f['iconic'], f['visual_family'], f['llm_reason'], f['ratings_total'],
                                       f['top_seller'], f['seed_difficulty'], f['seed_difficulty'], f['spellings']])
            + ', true, true) on conflict (name) do update set slug = excluded.slug, iconic = excluded.iconic, visual_family = excluded.visual_family,'
            ' llm_reason = excluded.llm_reason, ratings_total = excluded.ratings_total, top_seller = excluded.top_seller,'
            ' seed_difficulty = excluded.seed_difficulty, spellings = excluded.spellings, active = true, playable = true, updated_at = now(),'
            ' difficulty = case when clikea_families.n_first = 0 then excluded.seed_difficulty else clikea_families.difficulty end;')
        lines.append(
            'insert into public.clikea_articles (item_no, family, is_main, type_fr, type_en, type_de, type_es, type_it, type_ko, price, image_url, image_id, image_path, category, pip_url, is_new) values ('
            + ','.join(q(x) for x in [a['item'], f['name'], True, a['type_fr'], a['type_en'], a['type_de'], a['type_es'], a['type_it'], a.get('type_ko'),
                                       a['price'], a['image_url'], a['image_id'], a['image_path'], a['category'], a['pip'], a['is_new']])
            + ') on conflict (item_no) do update set family = excluded.family, is_main = true, type_fr = excluded.type_fr, type_en = excluded.type_en,'
            ' type_de = excluded.type_de, type_es = excluded.type_es, type_it = excluded.type_it, type_ko = excluded.type_ko, price = excluded.price, image_url = excluded.image_url,'
            ' image_id = excluded.image_id, image_path = excluded.image_path, category = excluded.category, pip_url = excluded.pip_url, is_new = excluded.is_new, updated_at = now();')
    names = ','.join(q(f['name']) for f in fams)
    lines.append(f'update public.clikea_articles set is_main = false where family in ({names}) and item_no not in ({",".join(q(f["article"]["item"]) for f in fams)});')
    lines.append(f'update public.clikea_families set active = false, updated_at = now() where name not in ({names});')
    # Lots de 200 gammes (limite de taille d'une requête), puis la désactivation des gammes disparues.
    body, tail = lines[1:-2], lines[-2:]
    files = []
    for i in range(0, len(body), 400):
        f = path('upsert-%02d.sql' % (len(files) + 1))
        open(f, 'w').write('begin;\n' + '\n'.join(body[i:i + 400]) + '\ncommit;')
        files.append(f)
    f = path('upsert-%02d.sql' % (len(files) + 1))
    open(f, 'w').write('begin;\n' + '\n'.join(tail) + '\ncommit;')
    files.append(f)
    for old in os.listdir(CACHE):
        if old.startswith('upsert') and path(old) not in files:
            os.remove(path(old))
    print('SQL :', len(files), 'fichiers upsert-NN.sql dans', CACHE, '·', len(fams), 'gammes')


def step_export():
    """PRODUCTS dans index.html, à partir de la base (difficulté à jour) passée en JSON sur stdin."""
    rows = json.load(sys.stdin)
    prods = []
    for r in rows:
        t = {'fr': r['type_fr'], 'en': r['type_en'], 'es': r['type_es'], 'de': r['type_de'], 'it': r['type_it']}
        if r.get('type_ko'):
            t['ko'] = r['type_ko']
        prods.append({'n': r['name'], 't': t,
                      'p': float(r['price']) if r['price'] is not None else None, 'i': r['image_path'], 'k': 1 if r['iconic'] else 0,
                      'd': round(float(r['difficulty']), 2), 'v': r['visual_family'], 'o': r['spellings'] or []})
    html_p = os.path.join(REPO, 'index.html')
    html = open(html_p).read()
    # Produits de grilles déjà jouées absents du nouveau catalogue : gardés pour rejouer ces grilles,
    # marqués x = 1 (jamais tirés, jamais proposés comme faux noms).
    keep = load('keep.json', [])
    have = {p['n'] for p in prods}
    old = json.loads(re.search(r'const PRODUCTS = (\[.*?\]);\n', html, re.S).group(1))
    for o in old:
        if o['n'] in keep and o['n'] not in have:
            prods.append({'n': o['n'], 't': o['t'], 'p': o.get('p'), 'i': o['i'], 'k': 0, 'd': o.get('d', 1.0),
                          'v': o.get('v', 'divers'), 'o': [], 'x': 1})
    prods.sort(key=lambda p: p['n'])
    new = 'const PRODUCTS = ' + json.dumps(prods, ensure_ascii=False, separators=(',', ':')) + ';\n'
    html, n = re.subn(r'const PRODUCTS = \[.*?\];\n', lambda m: new, html, count=1, flags=re.S)
    assert n == 1, 'PRODUCTS introuvable'
    open(html_p, 'w').write(html)
    print('PRODUCTS exporté :', len(prods), 'gammes')


def step_fetch_ko():
    """Type coréen de l'article montré : ikea.com/kr/ko relié par l'identifiant de photo, sinon un autre article
    de la gamme au même type français, sinon DeepSeek. Les noms coréens s'écrivent « BILLY 빌리 »."""
    fams, parsed = load('catalog.json'), load('parsed.json')
    with cf.ThreadPoolExecutor(4) as ex:
        list(ex.map(lambda f: search('kr/ko', f['name']), fams))
    ko = {}
    missing = []
    for f in fams:
        n = f['name']
        ids = {a['image_id']: a for a in parsed.get(n, [])}
        by_type = {}
        hit = None
        for it in search('kr/ko', n):
            nm = (it.get('name') or '').strip()
            if (nm != n and not nm.startswith(n + ' ')) or '/' in nm or not (it.get('typeName') or '').strip():
                continue
            m = IMG_ID.search(it.get('mainImageUrl') or '')
            if m and m.group(1) in ids:
                by_type.setdefault(ids[m.group(1)]['type_fr'], it['typeName'].strip())
                if m.group(1) == f['article']['image_id']:
                    hit = it['typeName'].strip()
        t = hit or by_type.get(f['article']['type_fr'])
        if t:
            ko[n] = t
        else:
            missing.append(f)
    cache = load('translations_ko.json', {})
    todo = sorted({f['article']['type_fr'] for f in missing} - set(cache))
    for i in range(0, len(todo), 60):
        chunk = todo[i:i + 60]
        prompt = ('Traduis ces types de produits IKEA (libellés courts du site français) en coréen, comme sur ikea.com/kr/ko '
                  '(ex. Bibliothèque -> 책장, Fauteuil -> 암체어). Réponds UNIQUEMENT par un objet JSON {"<type français>": "<coréen>"}.\nTypes :\n')
        out = subprocess.run(['opencode', 'run', '-m', LLM_MODEL, '--', prompt + '\n'.join(chunk)],
                             capture_output=True, text=True, timeout=600, cwd=CACHE).stdout
        m = re.search(r'\{.*\}', out, re.S)
        if m:
            cache.update({k: v.strip() for k, v in json.loads(m.group(0)).items() if k in chunk and v})
            save('translations_ko.json', cache)
        print('coréen traduit', min(i + 60, len(todo)), '/', len(todo), flush=True)
    for f in missing:
        if f['article']['type_fr'] in cache:
            ko[f['name']] = cache[f['article']['type_fr']]
    save('ko.json', ko)
    print('coréen :', len(ko), '/', len(fams), '(ikea.com/kr :', len(fams) - len(missing), ')')


STEPS = {'families': step_families, 'fetch-fr': step_fetch_fr, 'parse': step_parse, 'llm': step_llm,
         'fetch-langs': step_fetch_langs, 'fetch-ko': step_fetch_ko, 'build': step_build, 'images': step_images, 'sql': step_sql, 'export': step_export}

if __name__ == '__main__':
    if len(sys.argv) < 2 or sys.argv[1] not in STEPS:
        print(__doc__)
        sys.exit(1)
    STEPS[sys.argv[1]]()
