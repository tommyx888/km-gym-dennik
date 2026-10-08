# KM GYM Denník — nasadenie (openGym)

> **Railway (odporúčané, bez správy servera): pozri `deploy/railway/README-RAILWAY.md`.**
> Nižšie je alternatíva na vlastnom VPS.

Tréningový denník pre členov KM GYM: týždenný plán, vedený tréning, záznam sérií a váhy,
štatistiky, 1 324 cvikov s animáciami. Beží na vlastnom serveri, prihlásenie cez passkey
(Face ID / odtlačok), prístup len na pozvánku. Základ: openGym (AGPL v3), doplnené o
slovenský preklad UI a slovenčinu ako predvolený jazyk.

## Čo potrebuješ
- VPS s Dockerom (Hetzner CX22 ~4 €/mes, alebo čokoľvek s 2 GB RAM). Ubuntu 24.04.
- Subdoménu, napr. `dennik.kmgym.sk` → A záznam na IP servera.
- Otvorené porty 80 a 443.

## Inštalácia (~15 min)
```bash
# na serveri
apt update && apt install -y docker.io docker-compose-v2 caddy git
git clone https://github.com/<tvoj-github>/km-gym-dennik opengym   # tento repozitár (fork openGym)
cd opengym
cp deploy/.env .env                              # skontroluj RP_ID/ORIGIN
docker compose up -d --build                     # prvý build ~5 min, stiahne aj médiá cvikov (~140 MB)
cp deploy/Caddyfile /etc/caddy/Caddyfile && systemctl reload caddy
curl https://dennik.kmgym.sk/api/health          # {"ok":true,...}
```

## Prvé spustenie
1. V `.env` daj dočasne `INVITE_ONLY=0`, `docker compose up -d`. Otvor `https://dennik.kmgym.sk` na telefóne
   → **Vytvoriť nový profil**. Prvý profil je vďaka `FIRST_USER_ADMIN=1` admin.
2. Vráť `INVITE_ONLY=1` a `docker compose up -d`. V Nastaveniach → Účet uvidíš **Administrácia**.
4. V Administrácii generuj **pozývacie kódy** – jeden na člena. Kód pošli po kúpe členstva
   (SMS/e-mail, alebo ho vytlač na kartičku ku QR kódu).

## Prevádzka
- **Záloha** (všetko je v `data/`): `tar czf /root/dennik-$(date +%F).tar.gz data/` – daj do cronu denne.
- **Aktualizácia**: `git pull && docker compose up -d --build`.
- **Vypnúť člena**: Administrácia → Disable (po skončení členstva). Dáta mu ostanú, prihlási sa až po znovuzapnutí.
- Logy: `docker compose logs -f`.

## Licencia (dôležité)
openGym je pod **AGPL v3**. Keďže sme kód upravili (slovenčina) a prevádzkujeme ho ako
službu, musíme upravený zdroj sprístupniť – preto je tento fork **verejný na GitHube** a
v päte appky ostáva odkaz „zadarmo a open source (AGPL v3)“. Nič ďalšie netreba.
Animácie cvikov majú vlastné podmienky (NOTICE.md).

## Čo ostáva na Tomasa
- Subdoména + hosting (Railway alebo VPS) + GitHub repo (verejný fork).
- Rozhodnúť, či denník dostane každý člen automaticky (kód pri odovzdaní/aktivácii členstva)
  alebo na požiadanie.
- Voliteľne: štartovací plán KM GYM podľa vybavenia (App → Zdieľaj svoj plán → export súboru;
  ten súbor dáme na web, členovia si ho importujú).
