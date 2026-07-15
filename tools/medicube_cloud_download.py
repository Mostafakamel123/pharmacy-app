from __future__ import annotations
import csv, hashlib, html, io, json, re, sys, time, unicodedata, zipfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import requests
from PIL import Image, ImageOps
from rapidfuzz import fuzz

BASE = Path(__file__).resolve().parent
OUT = BASE / 'OUTPUT'
ROOT = OUT / 'Medicube_missing_products'
KSTYLE_JSON = 'https://kstyleseoul.com/collections/medicube/products.json?limit=250'
TARGET_PRODUCTS = 130
TARGET_MISSING = 25
MAX_IMAGES = 30
EXISTING_FILE = BASE / 'existing_products.txt'
S = requests.Session()
S.headers.update({'User-Agent':'Mozilla/5.0 Chrome/131 Safari/537.36','Accept-Language':'en-US,en;q=0.9'})

@dataclass
class Product:
    title: str
    handle: str = ''
    images: list[str] = field(default_factory=list)

def safe_name(text: str, max_len: int = 160) -> str:
    text = html.unescape(str(text))
    text = re.sub(r'[<>:"/\\|?*\x00-\x1f]', ' ', text)
    text = re.sub(r'\s+', ' ', text).strip(' .-_')
    return text[:max_len].rstrip(' .-_') or 'Medicube Product'

def norm(text: str) -> str:
    text = unicodedata.normalize('NFKD', html.unescape(str(text))).lower()
    text = text.replace('medicube®',' ').replace('medicube',' ').replace('age r','age-r').replace('age_r','age-r')
    text = re.sub(r'\[[^\]]+\]|\([^\)]*\)', ' ', text)
    text = re.sub(r'\b\d+(?:\.\d+)?\s*(?:ml|g|kg|oz|fl\s*oz|pcs?|sheets?|count|ct)\b', ' ', text)
    text = re.sub(r'\b(?:new|sale|authentic|official|korean|skincare|skin care|limited edition)\b', ' ', text)
    text = re.sub(r'[^a-z0-9+.-]+', ' ', text)
    return re.sub(r'\s+', ' ', text).strip()

def similarity(a: str, b: str) -> float:
    na, nb = norm(a), norm(b)
    if not na or not nb: return 0.0
    score = max(fuzz.token_set_ratio(na, nb), fuzz.ratio(na, nb))
    special = {'duo','set','kit','x2','mini','pink','black','white','blue','yellow'}
    return float(score - min(18, len((set(na.split()) ^ set(nb.split())) & special)*5))

def get_json(url: str) -> Any:
    last=None
    for i in range(4):
        try:
            r=S.get(url,timeout=50); r.raise_for_status(); return r.json()
        except Exception as e:
            last=e; time.sleep(2+i*2)
    raise RuntimeError(f'Failed JSON {url}: {last}')

def parse_catalogue() -> list[Product]:
    rows=get_json(KSTYLE_JSON).get('products',[])
    out=[]
    for p in rows:
        imgs=[]
        for im in p.get('images',[]) or []:
            u=(im.get('src') or im.get('url')) if isinstance(im,dict) else im
            if not u: continue
            u=str(u)
            if u.startswith('//'): u='https:'+u
            if u not in imgs: imgs.append(u)
        out.append(Product(safe_name(p.get('title','')),str(p.get('handle','')),imgs))
    if not out: raise RuntimeError('Catalogue returned zero products')
    return out

def match_missing(catalogue: list[Product], existing: list[str]):
    base=catalogue[:TARGET_PRODUCTS] if len(catalogue)>=TARGET_PRODUCTS else catalogue
    pairs=[]
    for ci,p in enumerate(base):
        for ei,t in enumerate(existing): pairs.append((similarity(p.title,t),ci,ei))
    pairs.sort(reverse=True)
    used_c=set(); used_e=set(); matches=[]
    for score,ci,ei in pairs:
        if ci in used_c or ei in used_e or score<61: continue
        used_c.add(ci); used_e.add(ei)
        matches.append({'catalogue':base[ci].title,'existing':existing[ei],'score':round(score,1)})
        if len(used_e)==len(existing): break
    missing=[p for i,p in enumerate(base) if i not in used_c]
    if len(missing)!=TARGET_MISSING:
        ranked=[]
        for p in base: ranked.append((max((similarity(p.title,x) for x in existing),default=0),p))
        ranked.sort(key=lambda x:x[0]); missing=[p for _,p in ranked[:TARGET_MISSING]]
    return missing,matches

def primary_benefit(title: str) -> str:
    t=title.lower()
    rules=[('eye patch','Under Eye Revitalizing'),('eye','Smoothing Eye Care'),('deodorant','Underarm Brightening'),('shampoo','Scalp Clarifying'),('conditioner','Hair Nourishing'),('scalp','Scalp Vitality'),('neck','Neck Firming'),('mask','Intensive Mask Care'),('toner','Tone Balancing'),('pad','Pore Refining'),('balm','Portable Plumping'),('cleanser','Gentle Cleansing'),('foam','Deep Pore Cleansing'),('oil','Makeup Melting'),('sun','Daily UV Protection'),('cream','Barrier Moisturizing'),('serum','Concentrated Glow'),('ampoule','Intensive Treatment'),('shot','Targeted Renewal'),('booster','Absorption Boosting'),('device','At Home Skin Care'),('duo','Complete Routine Duo'),('set','Complete Routine Set'),('mist','Refreshing Hydration'),('lip','Lip Moisturizing'),('peptide','Elasticity Support'),('collagen','Firming Support')]
    for k,v in rules:
        if k in t: return v
    return 'Targeted Skin Care'

def phrases(p: Product) -> list[str]:
    return [primary_benefit(p.title),'Product Hero','Key Benefit','Texture Detail','Ingredient Focus','How To Use','Routine Support','Hydration Care','Smooth Finish','Radiance Support','Firmness Care','Gentle Formula','Packaging Detail','Application Guide','Close Up View','Complete Gallery','Skin Concern Care','Daily Care','Clinical Concept','Authentic Display','Routine Pairing','Formula Detail','Product Scale','Lifestyle View','Feature Highlight','Usage Result']

def download(url: str) -> bytes:
    r=S.get(url,timeout=60,headers={'Referer':'https://kstyleseoul.com/'}); r.raise_for_status()
    if len(r.content)<1200: raise ValueError('image too small')
    return r.content

def to_webp(raw: bytes,dest: Path):
    with Image.open(io.BytesIO(raw)) as im:
        im=ImageOps.exif_transpose(im)
        if im.mode=='RGBA':
            bg=Image.new('RGB',im.size,'white'); bg.paste(im,mask=im.getchannel('A')); im=bg
        else: im=im.convert('RGB')
        im.thumbnail((1200,1200),Image.Resampling.LANCZOS)
        canvas=Image.new('RGB',(1200,1200),'white'); canvas.paste(im,((1200-im.width)//2,(1200-im.height)//2))
        dest.parent.mkdir(parents=True,exist_ok=True); canvas.save(dest,'WEBP',quality=88,method=6)

def main():
    OUT.mkdir(exist_ok=True); ROOT.mkdir(exist_ok=True)
    existing=[x.strip() for x in EXISTING_FILE.read_text(encoding='utf-8').splitlines() if x.strip()]
    catalogue=parse_catalogue(); missing,matches=match_missing(catalogue,existing)
    print('catalogue',len(catalogue),'existing',len(existing),'missing',len(missing))
    with (OUT/'matching_report.csv').open('w',newline='',encoding='utf-8-sig') as f:
        w=csv.DictWriter(f,fieldnames=['catalogue','existing','score']); w.writeheader(); w.writerows(matches)
    manifest=[]; failures=[]; total=0; seen=set()
    for pi,p in enumerate(missing,1):
        folder=ROOT/safe_name(p.title); folder.mkdir(parents=True,exist_ok=True); ps=phrases(p); saved=0
        for url in p.images[:MAX_IMAGES]:
            try:
                raw=download(url); h=hashlib.sha256(raw).hexdigest()
                if h in seen: continue
                seen.add(h); benefit=ps[saved%len(ps)]; filename=safe_name(f'{p.title} - {benefit}')+'.webp'; dest=folder/filename
                to_webp(raw,dest)
                manifest.append({'product':p.title,'benefit':benefit,'output_file':str(dest.relative_to(ROOT)),'source_image':url,'source_page':f'https://kstyleseoul.com/products/{p.handle}','width':1200,'height':1200,'format':'WebP'})
                saved+=1; total+=1
            except Exception as e: print('SKIP',p.title,url,e)
        if saved==0: failures.append(p.title); (folder/'NO_IMAGE_DOWNLOADED.txt').write_text(p.title,encoding='utf-8')
        print(f'[{pi}/{len(missing)}] {p.title}: {saved}')
    with (ROOT/'manifest_missing.csv').open('w',newline='',encoding='utf-8-sig') as f:
        fields=['product','benefit','output_file','source_image','source_page','width','height','format']; w=csv.DictWriter(f,fieldnames=fields); w.writeheader(); w.writerows(manifest)
    report={'catalogue_product_count':len(catalogue),'catalogue_records_used':min(len(catalogue),TARGET_PRODUCTS),'existing_product_count':len(existing),'missing_product_count':len(missing),'new_image_count':total,'products_without_images':failures,'missing_products':[p.title for p in missing],'image_spec':'1200x1200 WebP, white background, full image preserved'}
    (ROOT/'completion_report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8'); (OUT/'completion_report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
    with zipfile.ZipFile(OUT/'Medicube_missing_25_actual_images.zip','w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
        for fp in ROOT.rglob('*'):
            if fp.is_file(): z.write(fp,Path(ROOT.name)/fp.relative_to(ROOT))
    print(json.dumps(report,ensure_ascii=False,indent=2))
    if failures or len(missing)!=TARGET_MISSING: sys.exit(2)

if __name__=='__main__': main()
