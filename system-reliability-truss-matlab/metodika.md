# Metodika: system-reliability-truss-matlab

Systémová spolehlivost **staticky neurčitých** 2D pin-jointed příhrad. Na rozdíl od
`reliability-truss-matlab` (sériový systém `g_sys = min_p g_p`), zde selhání prutu
vede k redistribuci sil — konstrukce přežije, dokud počet odstraněných prutů
nepřekročí stupeň statické neurčitosti `gH` (vznikne mechanismus).

Zdroje (plně přečteny, PDF v Zotero uživatele):
1. Rodrigues da Silva, Torii, Beck (2024), *Structural Safety* 108:102448 — celkový
   rámec, implementujeme jen "system reliability assessment" (kap. 2.1, 3.1), NE
   optimalizaci CRPSO (kap. 3.2).
2. **Wei & Deng (2022)**, *Structural Safety* 95:102175 — jádro algoritmu (null space
   method), kompletně rozepsáno níže. Dva numerické příklady s referenčními čísly.
3. Pellegrino & Calladine (1986) — teorie rovnovážné matice/SVD, viz "Známá omezení".
4. Deng & Kwan (2005) — důkaz `V_k=0` ⟺ "necessary bar" (= Lemma 1 níže).

---

## 1. Datový model

Stejný jako `reliability-truss-matlab` / `fem-2d-truss-matlab`:
```matlab
members.nodesHead, members.nodesEnd, members.sections, members.nmembers
nodes.x, nodes.z, nodes.dofs        % 2 DOF/uzel: ux, uz
kinematic.x.nodes, kinematic.z.nodes
```
2D pin-jointed (axiální síly, žádné momenty) — MVP rozsah, žádné 3D.

---

## 2. Rovnovážná matice a null space (Wei & Deng, kap. 2)

Pro prut `k` mezi uzly `i,j`: kompatibilitní vztah (rov. 1-3)
```
e_k = a_k^T · d,   a_k = jednotkový směrový vektor prutu k v globálních DOF
                          (nenulový jen ve 4 složkách: ux_i,uz_i,ux_j,uz_j)
```
Rovnovážná matice `A` (N×nel, N = počet volných DOF): `A = [a_1,...,a_nel]` (rov. 6).
**Toto je přesně totéž, co dělá `transformationMatrixFn`/`codeNumbersFn` v
`fem-2d-truss-matlab` při skládání K matice, jen BEZ násobení `EA/L`** — lze
znovupoužít `memberVertexFn` (směrové kosiny) + `codeNumbersFn` (mapování na volné
globální DOF) k přímému sestavení `A` bez psaní nového FEM kódu.

Kritérium geometrické neměnnosti (rov. 9): `r(A) = N` ⟺ stabilní.
`gH = nel - r(A)` = stupeň statické neurčitosti = dimenze null-space `V` (rov. 13-14):
```
AV = 0,   V je (nel × gH) "null space basis matrix" (sloupce = states of self-stress)
```
`V` se počítá přes SVD `A` (jen JEDNOU pro celou konstrukci — hlavní výhoda metody).

### Lemma 1 — "necessary bar" (cut-set velikosti 1)

Element `i` je *necessary bar* (jeho jediné odstranění způsobí mechanismus) ⟺
`V_i = 0`, kde `V_i` je i-tý ŘÁDEK matice `V` (rov. 18). Důkaz viz Deng & Kwan (2005)
a Wei & Deng kap. 3.2.

### Lemma 2 — cut-set s více prvky

`k>1` prvků tvoří cut-set ⟺ `r(V_r) < k`, kde `V_r` je submatice `V` sestavená z
řádků odpovídajících těmto `k` prvkům (rov. 22). Minimální cut-set navíc vyžaduje,
že KAŽDÁ podmatice o `k-1` řádcích (libovolná (k-1)-podmnožina) má plnou hodnost
`k-1` (rov. 33) — jinak by šlo odebrat prvek a pořád by to byl cut-set (=> ne
minimální).

### Algoritmus hledání všech minimálních cut-sets (Wei & Deng, kap. 4)

Vstup: `V^T` (gH × nel).
1. Pokud existují nulové sloupce `V^T` (= nulové řádky `V`) → odpovídající prvky
   jsou "necessary bars" → přidat jako cut-set velikosti 1 do `Θ`. Odstranit tyto
   sloupce z `V^T` (zůstane `b'` sloupců).
2. Řádkové elementární úpravy na (zredukované) `V^T` → echelon tvar `Ṽ^T`
   (se záměnou sloupců, viz Fig. 2 ve Wei&Deng) — `gH` "kroků" (pivotů), krok `i`
   má `b_i` sloupců.
3. Vyber libovolnou kombinaci po jednom sloupci z každého z `gH` kroků → tvoří
   "maximal linearly independent subset" (celkem `Π b_i` kombinací). Pro každou
   takovou kombinaci `{v_b1,...,v_bs}` (s=gH) sestav `V_b^T` (s×s, čtvercová,
   regulární).
4. Pro každý ZBÝVAJÍCÍ sloupec `v_p` (mimo aktuální bázi) spočti kombinační
   koeficienty (rov. 35): `γ_p = (V_b^T)^{-1} · v_p`.
   - Pokud má `γ_p` nulové složky → prvek `p` + prvky odpovídající NENULOVÝM
     složkám `γ_p` tvoří minimální cut-set → přidat do `Θ` (pokud tam ještě není).
5. Opakovat pro všechny `Π b_i` kombinace bází; sloučit duplicity.

**Implementační poznámka:** `gH` je typicky malý (2-7 i pro reálné konstrukce
z článku 2024), takže `Π b_i` je zvládnutelné i hrubou silou (žádná potřeba
optimalizovat toto hledání pro MVP).

### 2.1 DŮLEŽITÝ NÁLEZ: mezera v algoritmu Wei & Deng (2022) pro cut-sety velikosti `gH+1`

**Kontext objevu:** při reprodukci referenčního příkladu (15-prutová příhrada,
Wei&Deng kap. 6.1) s geometrií ověřenou pixel-přesně z Fig. 3 (PDF vyrenderováno
a porovnáno ručně) náš kompletní (Lemma 1 + Lemma 2, bez zkratek) algoritmus
najde **57 minimálních cut-sets**, zatímco paper uvádí **32**. Rozdíl (25 množin)
je systematický a plně vysvětlitelný — jde o mezeru v publikované metodě, ne o
chybu naší implementace ani o nejednoznačnost geometrie.

**Matematické pozadí:** Cut-set kritérium (Lemma 2, rov. 22 ve Wei&Deng) je
`r(V_r) < k`. Pro `k = gH+1` prvků je `V_r` matice `(gH+1)×gH` — její hodnost je
**triviálně** ≤ `gH < k` pro NAPROSTO libovolnou volbu `gH+1` prvků, nezávisle na
geometrii. To je čistý důsledek počítání stupňů volnosti: `gH` = počet "nadbytečných"
prutů nad rámec minima potřebného pro stabilitu. Odeberou-li se všechny prvky
jedné (staticky určité, tj. stabilní) `gH`-tice, konstrukce je přesně "vyčerpaná"
(nulová rezerva) — libovolný `(gH+1)`. prut navíc **musí** způsobit mechanismus,
protože redundance už byla celá spotřebována. Minimalita takové `(gH+1)`-tice pak
závisí jen na tom, zda VŠECHNY její `gH`-podmnožiny byly samy o sobě ještě stabilní
(pak je to nová, minimální množina) — a to obecně splněno být MŮŽE.

**Konkrétní příklad (15-prutová příhrada):** trojice `{1,3,8}` (svislice u uzlu 1,
svislice u uzlu 5, dolní pás pole 1) je stabilní, staticky určitá (rank `V_r`=3=gH,
plná hodnost — proto ji Wei&Deng použili přímo jako bázi `V_b` ve svém Table 1).
Přidáním libovolného dalšího prutu, např. `10` (dolní pás pole 3), vznikne
`{1,3,8,10}` — matematicky nutně mechanismus, a ověřeno (rank + kontrola všech
4 trojpodmnožin + robustnost vůči perturbaci geometrie o 0.01 %), že jde o
**skutečný, minimální** 4-prutý cut-set.

**Kde přesně paperu tenhle případ uniká:** Wei&Deng krok 6 (jejich vlastní popis
algoritmu) zní doslova: cut-set se ze zkoumané kombinace (báze + prvek `p`)
zaznamená, **jen pokud** koeficienty `γ_p = V_b^{-1} v_p` obsahují alespoň jednu
nulu. Jejich vlastní Tabulka 1 to potvrzuje: pro `p=10` s bází `{1,3,8}` uvádějí
`γ = [-1, 1, 1]` (žádná nula) a výsledek "—" (nezaznamenáno) — přestože jde,
jak výše dokázáno, o platný minimální cut-set. Jejich algoritmus tedy **strukturálně
nedokáže najít žádný minimální cut-set velikosti přesně `gH+1`, který nemá
nulový koeficient v ŽÁDNÉ použitelné bázové kombinaci** — což je přesně
matematicky legitimní, ale metodicky nepokrytý okrajový případ.

**Proč na tom prakticky (numericky) málo záleží:** cut-set velikosti `gH+1`
vyžaduje současné selhání o jeden prut více než ty menší (velikosti ≤`gH`) →
nižší pravděpodobnost (vyšší `β` sekvence, viz kap. 4) → zanedbatelný příspěvek
k `Pf,sys` a navíc pravděpodobně vysokou korelaci se sdílenými menšími cut-sety
(PNET je pohltí). To je konzistentní s tím, že paper i přes tuhle mezeru dosáhl
shody s MCS na −0.41 % (kap. 6.2) — mezera existuje, ale nemá prakticky
pozorovatelný dopad na výslednou `β_sys`.

**Rozhodnutí pro tuto implementaci:** `nullSpaceCutSetsFn` používá ÚPLNÉ
vyhledávání (Lemma 1 + Lemma 2 bez omezení na velikost ≤`gH`), tj. NEreplikuje
tuhle mezeru — bezpečnější pro nástroj na posuzování spolehlivosti (nechceme
tiše přehlížet skutečný mechanismus). Důsledek: naše `cutSets` výstupy budou
obecně obsahovat i cut-sety velikosti `gH+1`, které se v publikovaných příkladech
Wei&Deng neobjevují. Toto je zdokumentovaný, zdůvodněný rozdíl oproti zdrojové
publikaci, ne bug.

**Toto je poznatek hodný publikace** (uživatel: zapracovat do vlastního článku) —
jde o konkrétní, důkazuschopné doplnění/opravu metody Wei & Deng (2022), ne jen
implementační detail.

**Referenční ověření — 15-prutová příhrada (Wei&Deng kap. 6.1, Fig. 3, rov. 50):**
Přesná geometrie ověřena renderem Fig. 3 z PDF (ne jen textový popis):
uzly (x,z): 1=(0,0), 2=(0,1), 3=(1,0), 4=(1,1), 5=(2,0), 6=(2,1), 7=(3,0), 8=(3,1);
podpory: uzly 1 a 7 oba kloubově vetknuté (x i z), N=12 volných DOF (přesně dle
paperu). Pruty: 1=(1-2) svislice, 2=(3-4) svislice, 3=(5-6) svislice, 4=(7-8)
svislice, 5=(2-4) horní pás, 6=(4-6) horní pás, 7=(6-8) horní pás, 8=(1-3) dolní
pás, 9=(3-5) dolní pás, 10=(5-7) dolní pás, 11=(1-4) diagonála pole1 (vzestupná),
12=(2-3) diagonála pole1 (sestupná), 13=(4-5) diagonála pole2 (jediná, sestupná),
14=(6-7) diagonála pole3 (sestupná), 15=(5-8) diagonála pole3 (vzestupná).

`gH=3` — **shoda s paperem**. Necessary bars `{6,13}` — **shoda s paperem**.
20 cut-setů velikosti 2 a 10 cut-setů velikosti 3 — **přesná shoda** s
publikovaným seznamem (32 = 2 necessary + 20 + 10):
```
[13], [6], [1,2], [3,4], [1,5], [3,7], [1,8,9], [1,11], [1,12], [3,14], [3,15],
[2,5], [2,8,9], [2,11], [2,12], [5,8,9], [5,11], [5,12], [8,9,11], [11,12],
[8,9,12], [4,7], [4,14], [4,15], [7,14], [7,15], [14,15], [3,9,10], [4,9,10],
[7,9,10], [9,10,14], [9,10,15]
```
**Navíc** (naše úplné hledání, viz 2.1 výše): 25 cut-setů velikosti 4, tvaru
`{jeden z [1,2,5,11,12]} × {jeden z [3,4,7,14,15]} × {8,10}` — matematicky
platné, publikací nezachycené. Celkem `cutSets` = 57.

**Referenční ověření — 3-prutová příhrada (2024-paper, Fig. 1, Table 1):**
cut-sets jako funkce úhlu `θ` prutu 3: pro θ=0°: `{[2],[1,3]}`; θ=1°,45°,89°:
`{[1,2],[1,3],[2,3]}`; θ=90°: `{[1],[2,3]}`. Dobrý test hraničních případů
(degenerace, kdy dva pruty splynou směrem).

---

## 3. Limitní funkce sekvence selhání

Failure sequence = permutace prvků jednoho minimálního cut-setu. Pro prvek `i`
na pozici v sekvenci (po prvcích `l < i`, tj. l selhaly dřív) — rov. 13-14 (2024)
/ rov. 36 (Wei&Deng):
```
g_i(d,X) = S_i·A_i − sign(N_i)·( Σ_j b_ij·P_j + Σ_{l<i} a_il·η_l·S_l·A_l )
```
- `S_i` = dovolené napětí prutu `i` (RV, Gaussovské)
- `A_i` = plocha průřezu prutu `i` (typicky deterministická nebo RV — viz níže)
- `b_ij` = vlivový koeficient prutu `i` od vnějšího zatížení `j` **na konstrukci
  s již odstraněnými pruty `1..i-1`**
- `a_il` = vlivový koeficient redistribuce zbytkové síly prutu `l` (aplikované
  jako jednotková samo-vyrovnaná dvojice sil v koncových uzlech prutu `l`, ve
  směru jeho původní osy) **na konstrukci s odstraněnými pruty `1..l`**
- `η_l ∈ [0,1]`: 0 = křehké (žádná zbytková síla), 1 = plně tažné

**DŮLEŽITÉ:** `b_ij` i `a_il` se musí přepočítat pro KAŽDÝ stav redukované
konstrukce (tj. pro sekvenci délky `m` je potřeba `m` FEM řešení) — ale toto se
dělá JEN JEDNOU na reprezentativní pořadí každého cut-setu, ne pro každý MC
vzorek. To je hlavní výpočetní úspora oproti brute-force progressive-collapse MC.

### Modelovací rozhodnutí: `R_i = S_i·A_i` jako přímá Gaussovská RV

Cornell index + PNET (níže) vyžadují **lineární** `g` v Gaussovských RV. Proto
`R_i` (odolnost prutu) modelujeme jako RV přímo (mean/cov), NE odvozenou
stochasticky z náhodného průřezu přes nelineární vzpěrnou křivku EN 1993-1-1.
Přesně takto postupují oba zdrojové články (2024-paper Table 2: mean/COV `R_i`
zadány přímo). Nominální (deterministickou) hodnotu lze získat z existujícího
posudku — `en-truss-design-matlab/src/sectionCheckFn.m` nebo tah/vzpěr vzorce v
`reliability-truss-matlab/src/limitStateFastFn.m` — a kolem ní nasadit RV.

---

## 4. Cornell index a "equivalent planes" (Wei & Deng, kap. 5, rov. 36-47)

Failure sequence = parallel subsystem (všechny prvky musí selhat současně):
```
Z_i = Σ_j α_ij·U_j + β_i    (standardizované Gaussovské U_j, rov. 37)
P(∩ Z_i < 0) = Φ_m(-β; ρ),   ρ_ij = α_i^T·α_j     (rov. 38)
β_p = -Φ^{-1}(Φ_m(-β; ρ))                          (rov. 39, MATLAB: mvncdf)
```
Pro KAŽDÝ minimální cut-set: vygenerovat všechny permutace jeho prvků (failure
modes), spočítat `β_p` pro každou, vybrat **nejnižší `β_p`** (= nejpravděpodobnější
sekvence, reprezentant cut-setu).

**Equivalent performance function** (rov. 40-47): aby šly reprezentanti různých
cut-setů vzájemně korelačně porovnávat, nahradí se jejich (obecně nelineární
kombinovaná) `β_p` jedním ekvivalentním lineárním `Z̃_k = Σ α̃_kj·U_j + β̃_k`, kde:
```
β̃_k = β_p                                          (rov. 45)
α̃_kj = (∂β_p(ε)/∂ε_j)|_{ε=0} / ||...||             (rov. 46-47, First-order senzitivita)
```
(`ε_j` = poruchy standardizovaných RV, Taylorův rozvoj rov. 41-44).

## 5. PNET — systémová spolehlivost (rov. 48-49)

Pro `q` minimálních cut-setů (= `q` ekvivalentních `β̃_k`, seřazeno vzestupně):
1. `ρ_1k = α̃_1^T · α̃_k` (korelace s aktuálně nejhorším reprezentantem)
2. Práh `ρ_0` (0.7–0.85): pokud `ρ_1k ≥ ρ_0` → cut-set `k` je "kompletně
   korelovaný" s reprezentantem → NEpřidávat samostatně (redundantní)
3. Opakovat pro zbylé (dokud nejsou všechny seskupeny) → `w` reprezentativních
   skupin
4. `Pf_sys = 1 - Π_{i=1}^{w} (1 - Pf_i)` (rov. 48), `β_sys = -Φ^{-1}(Pf_sys)` (rov. 49)

**Referenční ověření — 3-podlažní příhrada (Wei&Deng kap. 6.2, Fig. 4, Table 2-4):**
16 elementů, 6 volných uzlů, 3 nezávislá horizontální zatížení `p3,p5,p7`
(mean=44.45 kN, COV=0.1), 8 typů průřezů s danými `A_i` a mean `R_i` (Table 2),
COV `R_i`=0.05 (nekorelované mezi typy) nebo COV=0.08 pro plné korelace v rámci
typu. **78 minimálních cut-sets. `ρ_0=0.7` → β_sys = 3.001162** (MCS 1e7:
3.013374, rozdíl -0.41 %). Přesná geometrie a zatížení musí být reprodukovány
(Fig. 4 + Table 2 v paperu) — hlavní end-to-end regresní test celého pipeline.

**Naše implementace: `β_sys = 3.0011`** — v podstatě přesná shoda s paperovou
metodou (3.001162) i s MCS (3.013374). 78/78 cut-sets nalezeno přesně (na rozdíl
od 15-prutové příhrady zde `gH+1`-mezera ze sekce 2.1 evidentně nenastává pro
tuhle konkrétní geometrii).

**Drobná neshoda v jednotlivých hodnotách (nemá vliv na `β_sys`):** paperova
Table 3 ("pět nejnižších β_i^e") uvádí pro `{9,3,14}` hodnotu 3.2199 — identickou
s hodnotami pro `{4,9}` a `{9,10}`. My pro `{9,3,14}` počítáme `β_p=4.2882`.
Toto je **matematicky vynucené**: `β_p({9,3,14})` musí být ≥ `β_p({9})` (základní
pravděpodobnostní monotonie — průnik více současných selhání má vždy ≤
pravděpodobnost než libovolná jeho podmnožina), takže hodnota identická s `{9}`
samotným by monotonii porušovala, pokud by šlo o skutečně nezávisle spočtenou
`β_p` (ne o zaokrouhlení). Náš výsledek `4.2882` byl nezávisle ověřen přímou
Monte Carlo simulací (2×10⁷ vzorků společné pravděpodobnosti `P(Z_9<0,Z_3<0,
Z_14<0)`) → `β_MC=4.296`, v souladu s naší analytickou hodnotou. Podobně
`{9,3,7}`: paper 4.1503, my 3.9716 (naopak nižší) — MC opět potvrzuje naši
hodnotu jako korektní. **Závěr: naše `β_p` čísla jsou nezávisle numericky
ověřená správná; paperova Table 3 pro tyhle dvě konkrétní 3-prvkové kombinace
neodpovídá vlastní definici `β̃_k=β_p` (rov. 45) — nejspíš tisková chyba nebo
jejich implementace nezkoušela všech `3!` pořadí sekvence.** Nemá to žádný
dopad na validovaný výsledek `β_sys`, protože obě sporné kombinace nejsou
PNET-dominantní (viz `pnetSystemReliabilityFn` výstup — obě jsou seskupeny
pod reprezentanta `{4,9}`).

---

## 6. Progressive-collapse Monte Carlo (nezávislý oracle, `tests/`)

Pro křížovou validaci (bez null-space/PNET aproximací): per vzorek RV
iterativně: (1) spočti FEM na aktuální (redukované) konstrukci, (2) najdi prut
s nejnižším `g_i`, (3) pokud `g_i ≤ 0`: "odeber" ho (η=0: nulová tuhost i síla;
η=1: zbytková síla jako uzlová zátěž), (4) zkontroluj mechanismus (singularita K
/ `rank(A)` pokles) → pokud mechanismus: vzorek = systémové selhání; jinak
opakuj od (1). `β_MC = -norminv(nFail/nSamples)`.

---

## 7. Známé omezení

Ze SVD-based kritéria (Pellegrino & Calladine 1986): rank-deficience `A` po
odebrání prvků detekuje mechanismus (`m>0`), ale nerozlišuje **infinitezimální**
mechanismus (může být zpevněn stavem samo-napětí — first-order stiffness) od
**konečného** mechanismu. Pro běžné (nepředpjaté) příhrady bez kabelů/tensegrity
toto nehrozí. Neřešeno numericky v MVP — pokud budoucí konstrukce zahrnou
předpjaté prvky, je nutno toto revidovat.

---

## 8. Stav implementace

- [x] Fáze A: `equilibriumMatrixFn.m`, `nullSpaceCutSetsFn.m` — ověřeno na
      3-prutové (přesná shoda Table 1) a 15-prutové příhradě (přesná geometrie
      z Fig. 3; necessary bars + všechny cut-sety velikosti 2,3 přesně sedí;
      +25 cut-setů velikosti `gH+1` navíc oproti paperu — zdůvodněno a
      zdokumentováno v sekci 2.1 jako záměrný rozdíl, ne bug)
- [x] Fáze B: `reducedStructureInfluenceFn.m` (b_ij, a_il přes `linearSolverFn`)
      — nezávisle ověřeno (přesná shoda s přímým `linearSolverFn` na neredukované
      konstrukci, stabilita po odebrání 1 prutu, samo-vyrovnaná zbytková síla
      (net force ~0), mechanismus správně vyvolá singularity warning při
      odebrání celého cut-setu {1,2})
- [x] Fáze C: `sequenceLimitStateFn`, `cornellIndexFn`, `mostProbableSequenceFn`,
      `equivalentPlaneFn`, `pnetSystemReliabilityFn`, `systemReliabilityFn` —
      ověřeno na 3-podlažní příhradě (`example_3story_truss.m`):
      gH=4 (shoda), 78 minimálních cut-setů (přesná shoda s paperem),
      β_sys = 3.0011 (paper: 3.001162, MCS 1e7: 3.013374) — prakticky
      přesná shoda s paperovou vlastní metodou.
- [x] Fáze D: `progressiveCollapseMCFn.m` (nezávislý MC oracle, brute-force
      progressive collapse bez PNET/Cornell aproximace) — na 3-podlažní
      příhradě s 2e4 vzorky dal β_MC ≈ 3.02-3.04 (konzistentní s
      β_sys=3.0011 v mezích očekávaného MC šumu při tomto počtu vzorků).
      `example_warren_xbrace.m` — nová jednorozponová Warren příhrada
      s plným X-ztužením ve všech 3 polích (16 prutů, gH=3, 91 cut-setů),
      kloub+posuvná podpora (na rozdíl od oboustranně vetknuté věže z
      3-podlažního příkladu). Běží end-to-end, konečný a smysluplný
      výsledek (β_sys i β_MC), viz hlavička souboru pro detaily/volbu
      zatížení.
