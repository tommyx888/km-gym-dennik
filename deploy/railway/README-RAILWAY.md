# KM GYM Denník na Railway — postup krok za krokom

Denník (openGym) beží ako jeden Docker kontajner (nginx + Node API) s trvalým diskom pre dáta
členov. Railway ho zostaví priamo z GitHub repozitára, dá mu HTTPS a doménu `dennik.kmgym.sk`.
Cena: Hobby plán 5 $/mes (v cene je 5 $ spotreby – malý gym sa do toho zmestí).

Súbory, ktoré to zabezpečujú (už v repozitári):
- `railway.json` – hovorí Railway, že má stavať z `deploy/railway/Dockerfile` a kontrolovať `/api/health`.
- `deploy/railway/Dockerfile` – frontend + API + obrázky cvikov v jednom obraze.
- `deploy/railway/start.sh`, `nginx.conf.template` – spustenie oboch procesov na jednom porte.

---

## 0. Pred začiatkom (10 min)

1. **GitHub**: tento fork musí byť verejný repozitár (licencia AGPL – upravený kód ako služba).
   Na GitHube vytvor prázdny repozitár `km-gym-dennik` (Public, bez README) a z priečinka
   `Desktop\km-gym-dennik` spusti:
   ```
   git remote add origin git@github.com:tommyx888/km-gym-dennik.git
   git push -u origin main
   ```
2. **Railway účet**: https://railway.com → Login with GitHub. V `Account → Plans` vyber **Hobby**
   (potrebný na vlastnú doménu a trvalý disk; pýta kartu).
3. Pri prvom prepojení GitHubu povoľ Railway prístup k repozitáru `km-gym-dennik`
   (Configure GitHub App → vybrať repo).

## 1. Projekt a služba (5 min)

1. Dashboard → **+ New Project** → **Deploy from GitHub repo** → `tommyx888/km-gym-dennik`.
2. Railway vytvorí službu a hneď spustí prvý build. **Zatiaľ ho nechaj bežať** (alebo zruš),
   dôležité sú nasledujúce kroky – po nich sa nasadí znova automaticky.
3. Klikni na službu → **Settings**:
   - **Service name**: `dennik`.
   - **Region**: `EU West (Amsterdam)` – dáta členov ostanú v EÚ. (V Project Settings môže byť
     region aj na úrovni projektu – vyber EÚ.)
   - **Build**: skontroluj, že je `Builder: Dockerfile` a `Dockerfile Path: deploy/railway/Dockerfile`
     (číta sa z `railway.json`; ak by nie, nastav ručne).
   - **Deploy → Healthcheck Path**: `/api/health` (tiež z `railway.json`).

## 2. Trvalý disk – NUTNÉ pred prvou registráciou (2 min)

Bez disku by sa pri každom nasadení vymazali všetci členovia aj ich tréningy.

1. V projekte **pravý klik na službu `dennik` → Attach Volume** (alebo `+ Create → Volume`
   a pripoj k službe).
2. **Mount path**: `/data` (presne takto). Veľkosť nechaj predvolenú (0,5–1 GB stačí na roky).
3. Railway službu reštartuje.

## 3. Premenné prostredia (3 min)

Služba → **Variables** → **Raw Editor** → vlož a ulož:

```
RP_ID=dennik.kmgym.sk
ORIGIN=https://dennik.kmgym.sk
RP_NAME=KM GYM Denník
DEFAULT_LANG=sk
ALLOW_GUEST=0
INVITE_ONLY=0
FIRST_USER_ADMIN=1
TRUST_PROXY=1
SESSION_DAYS=90
```

Čo znamenajú: `RP_ID`/`ORIGIN` – doména, na ktorú sú viazané passkeys (**po registrácii prvých
členov už nemeniť**). `DEFAULT_LANG=sk` – appka štartuje v slovenčine. `ALLOW_GUEST=0` – bez
„Pokračovať bez účtu“ (len členovia). `INVITE_ONLY=0` **dočasne**, aby si sa mohol zaregistrovať
ako prvý = admin; v kroku 6 prepneš na `1`.

`PORT` nenastavuj – dodáva ho Railway. `DATA_DIR` je v obraze nastavený na `/data`.

## 4. Doména dennik.kmgym.sk (5 min + čakanie na DNS)

1. Služba → **Settings → Networking → Public Networking → + Custom Domain** → `dennik.kmgym.sk`.
2. Railway ukáže hodnotu pre **CNAME** (niečo ako `xxxxx.up.railway.app`).
3. U registrátora domény kmgym.sk (DNS správa) pridaj záznam:
   - Typ **CNAME**, názov/host **dennik**, hodnota = to, čo ukázal Railway, TTL 300 (alebo auto).
4. Vráť sa do Railway – po 1–30 min sa pri doméne objaví zelená fajka a vystaví sa certifikát.
   Dovtedy môžeš testovať na dočasnej adrese `*.up.railway.app` (Generate Domain), ale **passkey tam
   nebude fungovať** – je viazaný na `dennik.kmgym.sk`. Nezakladaj si tam profil.

## 5. Prvé spustenie a admin (5 min)

1. Deployments → počkaj na **Active** (prvý build 3–6 min, sťahuje aj 140 MB obrázkov cvikov).
2. Otvor `https://dennik.kmgym.sk/api/health` → musí vrátiť `{"ok":true,"users":0}`.
3. Na **telefóne** otvor `https://dennik.kmgym.sk` → **Vytvoriť nový profil** → meno „Tomáš“ →
   potvrď passkey (Face ID / odtlačok). Si prvý užívateľ → automaticky **admin**.
4. Nastavenia → Účet → **Administrácia** – mala by sa zobraziť.
5. Odporúčané: Nastavenia → Účet → **Pridať passkey** aj z počítača (druhé zariadenie),
   nech sa do administrácie dostaneš aj bez telefónu.

## 6. Zamknúť registráciu (1 min)

Variables → `INVITE_ONLY` zmeň na `1` → Railway automaticky nasadí znova (cca 1 min, dáta ostávajú).
Odteraz nový profil vyžaduje pozývací kód.

## 7. Prepojiť s webom (2 min)

V `Desktop\km-gym\lib\site.ts` nastav:
```ts
tracker: { url: 'https://dennik.kmgym.sk', ... }
```
commit + push → na webe sa aktivuje tlačidlo „Otvoriť denník“ (stránka Denník, členská zóna)
a v administrácii členov pribudne odkaz „Otvoriť admin denníka“.

## Každodenná prevádzka

- **Nový člen**: v denníku Administrácia → Pozvánky → vygeneruj kód → na webe `/admin` ho vlož
  členovi → člen ho vidí v členskej zóne, zaregistruje sa passkeyom.
- **Koniec členstva**: na webe nastav „Skončené“, v denníku Administrácia → Disable.
- **Aktualizácia appky**: v `km-gym-dennik` spusti `git pull upstream main` (upstream =
  `https://github.com/DuarteSantos8/openGym`), vyrieš prípadné konflikty, `git push` → Railway
  nasadí sám. Pred veľkým updatom si pozri CHANGELOG.
- **Záloha**: Railway → Volume → **Backups** (Hobby plán má denné zálohy ručne/automaticky).
  Navyše raz za mesiac: Railway CLI `railway ssh` → `tar czf /tmp/d.tgz /data` – alebo si
  v denníku Nastavenia → Záloha stiahni export (každý člen aj sám).
- **Logy**: služba → Deployments → View Logs. Hľadaj `gym-api on :3000 (rpID=dennik.kmgym.sk…)`.

## Keď niečo nejde

| Problém | Čo s tým |
|---|---|
| Build zlyhá na sťahovaní obrázkov | Railway → Redeploy (GitHub dataset bol chvíľu nedostupný). |
| `/api/health` 502 | Pozri logy – API nenaštartovalo; typicky zlá premenná. |
| Passkey „neplatná doména“ | `RP_ID` musí byť presne `dennik.kmgym.sk` a otvárať cez túto doménu (nie up.railway.app). |
| Po nasadení zmizli členovia | Volume nie je pripojený na `/data` – krok 2. |
| Doména bez certifikátu > 1 h | Skontroluj CNAME (bez proxy/„oranžového mraku“ ak je DNS v Cloudflare). |

## Licencia
openGym je AGPL v3. Fork s úpravami (slovenčina, Railway balík) je verejný na GitHube – tým je
podmienka splnená. V appke ostáva odkaz na zdroj. Obrázky cvikov majú vlastné podmienky (NOTICE.md).
