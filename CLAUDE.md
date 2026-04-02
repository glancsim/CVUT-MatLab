# CLAUDE.md — Znalostní báze: FEM stability a lineární analýza

Tento soubor shromažďuje veškeré znalosti o projektu tak, aby je mohl využít libovolný Claude agent v budoucích sessions.

---

## Přehled projektu

Projekt implementuje FEM analýzu nosníkových a příhradových konstrukcí v MATLAB s verifikací proti OOFEM.

**Aktivní moduly:**

| Složka | Stav | Účel |
|--------|------|------|
| `fem-3d-frame-matlab/` | **aktivní** | 3D nosníkové rámy — `src/`, `tests/`, `examples/` |
| `fem-2d-frame-matlab/` | **aktivní** | 2D rámové konstrukce — `src/`, `tests/`, `examples/` |
| `fem-truss-2d-matlab/` | **aktivní** | 2D příhradové konstrukce — `src/`, `tests/`, `examples/` |
| `Diplomka/` | obsolete | původní kód diplomové práce, regresní testy 1–12 |

> **`Diplomka/` je obsolete** — slouží jen pro archivaci a regresní testy (Tests 1–12 s OOFEM verifikací).
> **Dříve `fem-stability-matlab/`** — přejmenováno na `fem-3d-frame-matlab/` v commit `26102bd` (2026-03-22).

---

## Datové struktury (MATLAB structs)

### `nodes` — uzly (fem-3d-frame-matlab)

```matlab
nodes.x       % (nnodes×1) souřadnice x [m]
nodes.y       % (nnodes×1) souřadnice y [m]
nodes.z       % (nnodes×1) souřadnice z [m]
nodes.dofs    % (nnodes×6) logical: true=volný DOF, false=vetknutý
nodes.ndofs   % (scalar) počet volných DOFů celkem
nodes.nnodes  % (scalar) počet uzlů
```

### `beams` — pruty (fem-3d-frame-matlab)

```matlab
beams.nodesHead  % (nbeams×1) index počátečního uzlu
beams.nodesEnd   % (nbeams×1) index koncového uzlu
beams.sections   % (nbeams×1) index průřezu (1-based do sections.*)
beams.angles     % (nbeams×1) pootočení průřezu kolem osy prutu [stupně]
beams.disc       % (nbeams×1) počet konečných prvků na prut
beams.nbeams     % (scalar) počet prutů
beams.vertex     % (nbeams×3) směrový vektor prutu (Δx,Δy,Δz)
beams.codeNumbers% (nbeams×12) globální kódová čísla DOFů pro oba konce
beams.XY         % (nbeams×3) referenční vektor pro lokální soustavu souřadnic
beams.releases   % (nbeams×2) VOLITELNÉ: [hlava_kloub, pata_kloub] — viz sekce Klouby
```

### `sections` — průřezy

```matlab
sections.id   % (nsec×1) ID z databáze sectionsSet.mat (nebo přímo vlastnosti níže)
sections.A    % (nsec×1) plocha průřezu [m²]
sections.Iy   % (nsec×1) moment setrvačnosti Iy [m⁴]
sections.Iz   % (nsec×1) moment setrvačnosti Iz [m⁴]
sections.Ix   % (nsec×1) torzní moment setrvačnosti [m⁴]
sections.E    % (nsec×1) Youngův modul [Pa]
sections.v    % (nsec×1) Poissonovo číslo [-]
```

Pokud `isfield(sections,'A')` = true, `testFn` použije průřezy přímo (debug/vlastní). Jinak načte z `sectionsSet.mat` pomocí `sections.id`.

### `kinematic` — okrajové podmínky (podpory)

```matlab
kinematic.x.nodes   % uzly s vetknutým posunem x
kinematic.y.nodes   % uzly s vetknutým posunem y
kinematic.z.nodes   % uzly s vetknutým posunem z
kinematic.rx.nodes  % uzly s vetknutým pootočením rx
kinematic.ry.nodes  % uzly s vetknutým pootočením ry
kinematic.rz.nodes  % uzly s vetknutým pootočením rz
```

### `loads` — styčníkové zatížení

```matlab
loads.x.nodes;  loads.x.value   % síla v x [N]
loads.y.nodes;  loads.y.value   % síla v y [N]
loads.z.nodes;  loads.z.value   % síla v z [N]
loads.rx.nodes; loads.rx.value  % moment rx [N·m]
loads.ry.nodes; loads.ry.value  % moment ry [N·m]
loads.rz.nodes; loads.rz.value  % moment rz [N·m]
```

---

## Hlavní vstupní funkce (`fem-3d-frame-matlab/src/`)

| Funkce | Výstup |
|--------|--------|
| `linearSolverFn(sections, nodes, ndisc, kinematic, beams, loads)` | `displacements`, `endForces` |
| `stabilitySolverFn(sections, nodes, ndisc, kinematic, beams, loads [, solver [, relaxParam]])` | `Results.values`, `Results.vectors` |

`endForces.local` (12 × nelement): řádky 1–6 = nodesHead, 7–12 = nodesEnd. Složky: N, Vy, Vz, Mx, My, Mz v lokálních souřadnicích prutu.

Obě funkce propagují `beams.releases` na `elements.releases` interně — není třeba nic dalšího.

### Volitelný parametr `solver` v `stabilitySolverFn`

```matlab
Results = stabilitySolverFn(..., 'oofem')     % default — geometricMatrixFn (axiální složka)
Results = stabilitySolverFn(..., 'mc-guire')  % geometricMatrixMcGuireFn (N + My + Mz)
```

- `'oofem'` (default): geometrická matice pouze z osových sil N — jednodušší, ověřena OOFEM
- `'mc-guire'`: dle McGuire — zahrnuje příspěvky ohybových momentů My, Mz; složitější ale obecnější

Umístění: `fem-3d-frame-matlab/src/geometricMatrixMcGuireFn.m`

### Volitelný parametr `relaxParam` v `stabilitySolverFn`

```matlab
Results = stabilitySolverFn(..., 'oofem', 1e-8)   % relaxace s ε = 1e-8
Results = stabilitySolverFn(..., 'oofem', 0)       % bez relaxace (default)
```

**Účel:** regularizace K matice pro konstrukce s pruty s prakticky nulovým průřezem (topologická optimalizace).

**Matematická formulace** (Evgrafov 2005, rovnice 19–20):
```
Klasická stability: (K + λcr·Kg)·φ = 0
Relaxovaná:        (K + λcr·Kg + ε·I)·φ = 0
```

kde `ε = relaxParam * max(diag(K))`.

**Co ε·I dělá:**
- `K + ε·I` je vždy pozitivně definitní → žádný RCOND warning v EndForcesFn
- Pro velké pruty: ε je zanedbatelné → výsledky prakticky nezměněny
- Pro malé pruty (EI ≈ 0): ε dominuje → jejich kritické zatížení je extrémně velké → neovlivní globální módy
- Cholesky v `criticalLoadFn` vždy uspěje

**Kdy použít:** při přítomnosti prutů s `r_outer ≈ 0` nebo `A ≈ 0` (např. výsledky topologické optimalizace kde průřezy jdou plynule k nule). Typická hodnota: `1e-7` až `1e-10`.

**Implementace:** `stabilitySolverFn.m`, řádky 196–207 — regularizace se provede před `EndForcesFn` i před eigenvalue problémem.

---

## FEM pipeline (testFn.m — pouze Diplomka/)

```
test_input.m → testFn()
  1. Průřezy: sectionsSet.mat nebo přímé sections.A/Iy/...
  2. Uzly: nodes.dofs z kinematic (false = vetknutý)
  3. beamVertexFn      → beams.vertex (směrový vektor)
  4. codeNumbersFn     → beams.codeNumbers (globální kódová čísla)
  5. XYtoRotBeamsFn    → beams.XY (referenční vektor dle angles)
  6. discretizationBeamsFn → elements.codeNumbers, elements.vertex
     + propagace releases → elements.releases (viz Klouby)
  7. XYtoElementFn     → elements.XY
  8. sectionToElementFn → elements.sections
  9. transformationMatrixFn → T matice a délky elementů
 10. stiffnessMatrixFn → K_global (se statickou kondenzací pro klouby)
 11. EndForcesFn       → lokální vnitřní síly (přes K*u=f)
 12. geometricMoofemFn → K_g (geometrická matice z osových sil N)
 13. criticalLoadFn    → eigs(K, -Kg, 10, 'smallestabs') → vlastní čísla
 14. oofemTestFn       → porovnání s OOFEM
```

---

## Klíčové funkce (fem-3d-frame-matlab)

### `stiffnessMatrixFn(elements, transformationMatrix)`

Sestavuje globální matici tuhosti. Lokální 12×12 matice ze čtyř 6×6 bloků (K11, K12, K21, K22) pro 3D Euler-Bernoulli prut. Kódová čísla 0 = vetknutý DOF (přeskočí se při assemblování).

**Statická kondenzace (klouby):** Pokud `elements.releases(cp,:)` obsahuje 1, zavolá se `releaseCondenseFn` po násobení E, před transformací. Uvolněné rotační DOFy **(5,6 = hlava; 11,12 = pata)** — jen ohybové momenty, ne torzní (DOF 4/10 zůstává). `stiffnesMatrix.local{cp}` se ukládá po kondenzaci → `EndForcesFn` vrátí 0 pro uvolněné momenty.

### `geometricMatrixFn(...)` a `geometricMatrixMcGuireFn(...)`

Geometrická matice pro analýzu stability.
- `geometricMatrixFn`: osová síla `N = (-F(1,cp) + F(7,cp)) / 2`. Kg_local symetrizována, transformována `T' * Kg * T`.
- `geometricMatrixMcGuireFn`: navíc zahrnuje ohybové momenty My, Mz dle McGuire.

### `codeNumbersFn(beams, nodes)`

Přiřadí globální kódová čísla volným DOFům (postupné číslování jen kde `nodes.dofs==1`). Výstup: `codes (nbeams×12)`.

### `discretizationBeamsFn(beams, nodes)`

Diskretizuje pruty na elementy. **Pozor:** při různých hodnotách `disc` pro jednotlivé pruty může být chyba (funguje jen pokud mají všechny pruty stejné `disc`).

### `XYtoRotBeamsFn(beams, angles)`

Počítá referenční vektor `XY` pro každý prut z `beams.angles`. Výstup `beams.XY (nbeams×3)`.

### `oofemInputFn(nodes, beams, loads, kinematic, sections, filename)`

Generuje `input.mat` pro Python runner. Klíčové výstupy: `oofem.nodes`, `oofem.beams`, `oofem.refNode`, `oofem.loads`, `oofem.sectionProp` (per-beam), `oofem.releases` (pro klouby).

**Důležité opravy (historické):**
- Průřezy se přiřazují per-beam (ne per-type) — opraveno pro správnou verifikaci Test 9
- Prázdná pole zatížení (loads.y.nodes=[]) se inicializují jako `zeros(0,2)` předem → Python nekrachuje

### `trussGeneratorFn(x_bot, x_top, h, ...)` — generátor příhrad

Umístění: `fem-3d-frame-matlab/src/trussGeneratorFn.m`

Generuje `nodes` a `beams` připravené pro `stabilitySolverFn`. Konstrukce v rovině XZ (y=0).

```matlab
[nodes, beams] = trussGeneratorFn(x_bot, x_top, h)
[nodes, beams] = trussGeneratorFn(x_bot, x_top, h, 'Topology', 'pratt', 'Plot', true)
```

**Parametry:**
- `x_bot` — x-souřadnice uzlů dolního pásu (n_b×1)
- `x_top` — x-souřadnice uzlů horního pásu (n_t×1)
- `h` — výška horního pásu:
  - **skalár** → plochý horní pás (konstantní výška)
  - **vektor (n_t×1)** → proměnná výška, např. sedlový tvar:
    ```matlab
    h_vec = h_max * (1 - abs(2*x/L - 1));   % lineární sedlo
    h_par = h_max * (1 - (2*x/L - 1).^2);  % parabolické sedlo
    ```
- `'Topology'`: `'pratt'` (default), `'howe'`, `'warren'`, `'vierendeel'`
- `'Sections'`: index průřezu pro všechny pruty (default: 1)
- `'Angles'`: pootočení průřezu [deg] (default: 0)
- `'Plot'`: `true/false` — zobrazit plotStructureFn (default: false)

**Slučování shodných uzlů (automatické):**
Po sestavení uzlů funkce detekuje koincidentní uzly (tolerance 1e-9 × rozsah) a sloučí je.
Klíčové pro sedlový tvar — krajní uzly horního pásu (z=0) splývají s dolním pásem.
Sloučení zabrání singularitě K matice. Duplikátní a nulové pruty jsou automaticky odstraněny.

---

## Modul `fem-2d-frame-matlab`

Lineární statika 2D rámových konstrukcí (Euler-Bernoulli, ohyb + osová síla). **S diskretizací** — každý fyzický prut = `ndisc` elementů.

### Datové struktury (liší se od 3D modulu!)

```matlab
% beams — 3 DOFy na uzel (ux, uz, ry)
beams.nodesHead   % (nbeams×1)
beams.nodesEnd    % (nbeams×1)
beams.sections    % (nbeams×1) — 1-based index průřezu
beams.releases    % (nbeams×2) VOLITELNÉ: klouby — viz níže

% nodes — pouze x a z (žádné y)
nodes.x    % (nnodes×1)
nodes.z    % (nnodes×1)

% kinematic — pouze x.nodes, z.nodes, ry.nodes (ne y, rx, rz)
% loads     — pouze x.nodes/value, z.nodes/value, ry.nodes/value

% sections
sections.A   % [m²]
sections.Iz  % [m⁴]
sections.E   % [Pa]
```

### Hlavní funkce

```matlab
[displacements, endForces] = linearSolverFn(sections, nodes, ndisc, kinematic, beams, loads)
% POZOR: jiná signatura než příhradový 2D modul (má ndisc, nemá nmembers)
```

**Výstupy `endForces.local`** — (6 × nelement):
```
řádek 1: N   na hlavě [N]   (+ = tah)
řádek 2: Vz  na hlavě [N]
řádek 3: My  na hlavě [N·m]
řádek 4–6: totéž na patě
```

### Klouby (`beams.releases`)

```matlab
beams.releases = false(nbeams, 2);
beams.releases(3, 1) = true;   % kloub na hlavě prutu 3
beams.releases(2, 2) = true;   % kloub na patě prutu 2
```

- Uvolňuje se pouze moment `ry` (bending) — osová síla a smyk přenášeny
- Metoda: statická kondenzace DOF 3 (hlava) nebo DOF 6 (pata) lokální matice

### Zdrojové soubory (`fem-2d-frame-matlab/src/`)

| Funkce | Popis |
|--------|-------|
| `beamVertexFn(beams, nodes)` | (nbeams×2) [Δx, Δz] |
| `codeNumbersFn(beams, nodes)` | (nbeams×6) kódová čísla |
| `discretizationBeamsFn(beams, nodes)` | elements.codeNumbers, .vertex |
| `sectionToElementFn(sections, beams)` | A, Iz, E per element |
| `transformationMatrixFn(elements)` | 6×6 T matice; t=[c,s,0;-s,c,0;0,0,1] |
| `stiffnessMatrixFn(elements, T)` | Globální K (sparse) + releaseCondenseFn |
| `EndForcesFn(K, f, T, elements)` | Řeší K·u=f; lokální vnitřní síly |
| `plotFrameFn(nodes, beams, loads, kinematic)` | 2D vizualizace |
| `oofemInputFn(nodes, beams, loads, kinematic, sections, filename)` | generuje input.mat pro Python runner (1 Beam2d na prut) |
| `oofemTestFn(nodes, beams, loads, kinematic, sections)` | spustí OOFEM a porovná posuny uzlů |

### Testy (`fem-2d-frame-matlab/tests/`)

| Test | Popis | Reference |
|------|-------|-----------|
| Test 1 | Konzola, Fz=−10 000 N na špičce, L=4 m | Analyticky: uz=FL³/(3EI), My=FL |
| Test 2 | Nosník vetknutý na obou koncích, Fz=−12 000 N uprostřed, L=6 m | Analyticky: uz=FL³/(192EI) |
| Test 3 | Portálový rám s kloubem na průvlaku, Fz=−5 000 N | FEM reference + OOFEM |

```matlab
% Spuštění testů
cd 'fem-2d-frame-matlab/tests'
run_all_tests         % spustí testy 1–3 (reference se vygenerují automaticky)

% OOFEM verifikace (vyžaduje WSL + Python 3)
cd 'fem-2d-frame-matlab/tests/Test 3'
run_oofem             % porovná výsledky s OOFEM
```

**Tolerance:** 0.01 %

### OOFEM infrastruktura (`fem-2d-frame-matlab`)

- Binary: `tests/oofem/oofem` (Linux ELF, spouštěn přes WSL — zkopírován z 3D modulu)
- Python runner: `tests/oofem/oofem.py` — generuje `test.in` (LinearStatic, domain 2dBeam, Beam2d prvky), spustí OOFEM, parsuje `test.out`, uloží `displacements.mat`
- Mapping souřadnic: naše XZ rovina → OOFEM XZ rovina; naše z → OOFEM z (D_w, DOF 3); naše ry → OOFEM R_v (DOF 5)
- Každý fyzický prut = 1 element (Euler-Bernoulli je pro bodové zatížení exaktní s ndisc=1)
- Klouby: `dofstocondense 1 3` (hlava) nebo `dofstocondense 1 6` (pata) — shodné číslování s MATLAB

---

## Modul `fem-truss-2d-matlab`

Lineární statika 2D příhrad (pin-jointed, axiální síly pouze). **Bez diskretizace** — každý fyzický prut = 1 element.

### Datové struktury (liší se od 3D modulu!)

```matlab
% members (místo beams) — 2 DOFy na uzel (ux, uz)
members.nodesHead   % (nmembers×1)
members.nodesEnd    % (nmembers×1)
members.sections    % (nmembers×1) — 1-based index průřezu
members.nmembers    % (scalar) — nastavit před voláním nebo nastaví linearSolverFn

% nodes — pouze x a z (žádné y)
nodes.x    % (nnodes×1)
nodes.z    % (nnodes×1)
nodes.dofs % (nnodes×2) logical: col1=ux, col2=uz  (nastaví linearSolverFn)

% kinematic — pouze x.nodes a z.nodes (ne y, rx, ry, rz)
% loads     — pouze x.nodes/value a z.nodes/value

% sections — skalár nebo vektor (stejné pro všechny pruty nebo per-type)
sections.A   % [m²]
sections.E   % [Pa]
```

### Hlavní funkce

```matlab
[displacements, endForces] = linearSolverFn(sections, nodes, kinematic, members, loads)
% POZOR: jiná signatura než 3D modul (není ndisc, není y-koordinát)
```

**Výstupy:**
- `displacements.global` — sparse vektor (ndofs×1); použít `full()` při výpisu
- `endForces.local` — (4×nmembers): **řádek 1 = N** [N], kladné = tah, záporné = tlak

### Zdrojové soubory (`fem-truss-2d-matlab/src/`)

| Funkce | Popis |
|--------|-------|
| `memberVertexFn(members, nodes)` | (nmembers×2) [Δx, Δz] |
| `codeNumbersFn(members, nodes)` | (nmembers×4) kódová čísla: [ux_h, uz_h, ux_e, uz_e] |
| `transformationMatrixFn(elements)` | 4×4 T matice + délky; T=[c,s,0,0; -s,c,0,0; 0,0,c,s; 0,0,-s,c] |
| `stiffnessMatrixFn(elements, T)` | Globální K (sparse), k_local=EA/L·diag([1,0,-1,0]) |
| `EndForcesFn(K, f, T, elements)` | Řeší K·u=f; N=EA/L·(u_end_axial−u_head_axial) |
| `plotTrussFn(nodes, members, loads, kinematic)` | 2D vizualizace s podporami a zatížením |

### Testy (`fem-truss-2d-matlab/tests/`)

| Test | Popis | Reference |
|------|-------|-----------|
| Test 1 | Symetrická 3-prutová příhrada, Fz=−1000 N na vrcholu | Analyticky: N1=N2=−707.1 N, N3=500 N |
| Test 2 | Prattova příhrada (4 pole, 8 uzlů, 13 prutů), Fz=−10 kN | FEM reference (staticky určitá → exaktní) |
| Test 3 | 3-prutová příhrada s diagonálou, Fx=10 000 N | Analyticky: N1=7500, N2=10 000, N3=−12 500 N |

```matlab
% Spuštění testů
cd 'fem-truss-2d-matlab/tests'
generate_references   % 1× před prvním spuštěním
run_all_tests         % spustí testy 1–3
```

**Tolerance:** 0.001 % (FEM je exaktní pro staticky určité příhrady).

### Záludnosti (fem-truss-2d-matlab)

- `sections.A` a `.E` jsou skaláry → `sections.A(members.sections)` funguje (MATLAB indexace)
- `elements.sections` se přepisuje ze struct indexů na struct vlastností (`struct()`) v `linearSolverFn` — nutné, jinak dot-indexing error
- `displacements.global` je sparse — vždy `full(displacements.global)` pro výpis/indexaci
- Znaménková konvence: **N > 0 = tah**, N < 0 = tlak; uloženo v `endForces.local(1,:)`
- DOF pořadí: [ux, uz] — **liší se od 3D modulu** kde je [ux, uy, uz, rx, ry, rz]

---

## Kloubová spojení (beams.releases)

```matlab
beams.releases = false(nbeams, 2);
beams.releases(2, 2) = true;   % prut 2, patní konec = kloub
beams.releases(4, 1) = true;   % prut 4, hlavový konec = kloub
```

**Jak funguje:**
- Chybějící pole = zpětně kompatibilní (vše rámové)
- Kloubový konec = nulové momenty (ohybové DOFy **5,6** = hlava; **11,12** = pata lokálně)
- Torzní moment (DOF 4/10) se **neuvolňuje** — kloub přenáší kroucení
- Metoda: statická kondenzace K_cond = K(s,s) − K(s,r)·K(r,r)⁻¹·K(r,s)
- Uvolnění platí jen pro 1. element (hlava) a poslední element (pata) každého prutu
- OOFEM: zapisuje `dofstocondense N d1...dN` do Beam3d elementu v test.in

> **Historická chyba:** commit `d63124c` omylem vrátil `releaseCondenseFn` na DOFy [4,5,6]/[10,11,12].
> Opraveno v `0f43846` — správné jsou **[5,6]/[11,12]** (jen ohyb, ne torze).

---

## Vizualizace

### `plotStructureFn` (fem-3d-frame-matlab)

Umístění: `fem-3d-frame-matlab/src/plotStructureFn.m`

```matlab
plotStructureFn(nodes, beams, loads)
plotStructureFn(nodes, beams, loads, kinematic)
```

| Prvek | Barva | Styl |
|-------|-------|------|
| Pruty | Černá | plná čára |
| Uzly | Černá | vyplněný kruh |
| Kloub (beams.releases) | Černá | prázdný kruh ○ |
| Podpora – posun | Modrá | plná šipka → uzel |
| Podpora – pootočení | Zelená | čárkovaná šipka - - → uzel |
| Síla | Červená | šipka + popisek [N] |
| Moment | Fialová | dvojitá šipka ------>> + popisek [N·m] |

### `plotTrussFn` (fem-truss-2d-matlab)

Umístění: `fem-truss-2d-matlab/src/plotTrussFn.m` — 2D verze (plot místo plot3).

### `plotModeShapeFn` ← **NAPLÁNOVÁNO, ZATÍM NEIMPLEMENTOVÁNO**

Umístění: `fem-3d-frame-matlab/src/plotModeShapeFn.m` (soubor NEEXISTUJE)

Plán: `C:\Users\simon\.claude\plans\clever-hopping-fiddle.md`

```matlab
plotModeShapeFn(nodes, beams, kinematic, Results)
```

Algoritmus (z plánu):
1. Rekonstrukce `nodes.dofs` z `kinematic`
2. Mapování `Results.vectors(:,1)` → uzlové posuny přes `codeNumbersFn`
3. Hermitovská interpolace podél každého prutu (30 bodů, shape functions N1–N4)
4. Barevné kódování příčného posunu: zelená→žlutá→červená (`surface` trick)
5. Animace: 40 snímků × `sin()` fáze × scaleFactor → ~25 fps, Ctrl+C ukončí
6. Auto-škálování: 15 % L_char / max posun translačních DOFů

---

## Benchmarky a příklady

### Torri benchmark

Umístění: `fem-3d-frame-matlab/examples/example_stability_torri.m`

Klasický benchmark pro stabilitu nosníkových konstrukcí.
- 5 uzlů, 6 prutů; trubka r_outer=0.04 m, r_inner=0.035 m, ocel E=210 GPa
- Uzly 1 a 3 vetknuty (x, y, z, rz); zatížení Fz=−1000 N na uzlu 5
- ndisc=16; výstup: lambda_cr (lambda1, lambda2)

---

## OOFEM verifikace

### Pipeline

```
testFn → oofemTestFn → oofemInputFn → uloží input.mat
       → spustí Python: python oofem.py (WSL)
       → oofem.py generuje test.in, spustí ./oofem -f test.in
       → načte eigen.mat, porovná vlastní čísla
```

### Umístění

Každý test má vlastní kopii: `oofem` binárky, `oofem.py` skriptu a `oofem.cmd`.

### Záludnosti OOFEM vstupu

- Čísla uzlů musí být **integer** (ne float `2.0`) v Set definicích — OOFEM SIGABRT jinak
- `oofem.py` přetypovává přes `int(beam[0])` atd.
- `dofstocondense` formát: `dofstocondense N d1 d2 ...` (N = počet, pak čísla DOFů 1–12)

### Srovnání vlastních čísel

`oofemTestFn` porovnává jen kladná vlastní čísla seřazená vzestupně. Testy 6 a 7 mají nenulové chyby jen na vyšších módech (≥6) — akceptovatelné.

---

## Testovací infrastruktura (Diplomka)

### Spuštění jednoho testu

```matlab
cd 'stability-tests/Test 1'
test_input;
[errors, h, sv] = testFn(sections, nodes, ndisc, kinematic, beams, loads);
```

### Testy 1–12 (Diplomka)

- **Testy 1–5:** základní geometrie, chyby ~0 %
- **Test 6:** chyby jen módy ≥6 (max ~28 %) — akceptovatelné
- **Test 7:** chyby jen módy ≥6 (max ~47 %) — akceptovatelné
- **Test 8:** 0 %
- **Test 9:** byl 114 % → opraveno opravou průřezů per-beam v oofemInputFn → 0 %
- **Testy 10–12:** přidány; 10–11 = portálový rám s klouby, 12 = Torri benchmark

### fem-3d-frame-matlab testy (Tests 1–12)

```matlab
cd 'fem-3d-frame-matlab/tests'
run_all_tests   % spustí testy 1–12 vs OOFEM
```

---

## Datové toky a vazby mezi soubory

```
test_input.m
  ↓ sections, nodes, ndisc, kinematic, beams, loads
stabilitySolverFn / linearSolverFn
  ↓ volá src/*.m
  ↓ (stability) → oofemTestFn → oofemInputFn → input.mat → oofem.py → eigen.mat
  ↓ returns: Results nebo displacements/endForces
```

### Kritické závislosti

- `stiffnessMatrixFn` potřebuje `elements.releases` (nebo ho ignoruje pokud chybí)
- `geometricMatrixFn` bere lokální síly z `EndForcesFn` — závisí na správné K matici
- `oofemInputFn` generuje `oofem.sectionProp` per-beam (ne per-type!) — klíčové pro správnost

---

## Repozitáře

| Repozitář | URL | Obsah |
|-----------|-----|-------|
| CVUT-MatLab | https://github.com/glancsim/CVUT-MatLab | MATLAB kód |
| cvut-python | https://github.com/glancsim/cvut-python | Python OOFEM runner (`oofem.py`) |

### Větve

- `main` — stabilní verze
- `claude/fervent-agnesi` — aktuální vývojová větev
- `feat/plot-structure-fn` — sloučena do main

---

## Chronologie změn

| Datum | Commit | Popis |
|-------|--------|-------|
| 2026-03-27 | `01e036e` | `stabilitySolverFn` — relaxační parametr dle Evgrafov (2005), `K_reg = K + ε·I` |
| 2026-03-27 | `3973a00` | `criticalLoadFn` — Cholesky-transformace → spolehlivý eigenvalue solver |
| 2026-03-23 | `d2df4f3` | `trussGeneratorFn` — sedlový horní pás (h jako vektor) + auto-slučování shodných uzlů |
| 2026-03-22 | `fedf4f3` | `trussGeneratorFn` — generátor rámové příhradové konstrukce (Pratt/Howe/Warren/Vierendeel) |
| 2026-03-22 | `3402cb2` | Test 12 (Torri benchmark) v fem-3d-frame-matlab + podpora přímých průřezů v run_single_test |
| 2026-03-22 | `26102bd` | Přejmenování `fem-stability-matlab` → `fem-3d-frame-matlab`; nový modul `fem-truss-2d-matlab`; plán `plotModeShapeFn` |
| 2026-03-22 | `04a8ed4` | Přidání příkladu Torri benchmark (`example_stability_torri.m`) |
| 2026-03-22 | `df23cae` | Přidání `geometricMatrixMcGuireFn` (druhý solver) |
| 2026-03-22 | `073ab71` | Volitelný parametr `solver` v `stabilitySolverFn` |
| 2026-03-20 | `0f43846` | Testy 10–11 pro vnitřní klouby + **oprava `releaseCondenseFn`** (DOFy 5,6/11,12 — jen ohyb) |
| 2026-03-20 | `d63124c` | Oprava `geometricMatrixFn` a `run_single_test` — testy 1–9 prochází |
| 2026-03-20 | `af06f84` | Momentové zatížení vykresleno čárkovaně v `plotStructureFn` |
| 2026-03-20 | `7befdcc` | Kloub uvolňuje jen ohybové momenty (My, Mz), ne torzní |
| 2026-03-20 | `7a16ead` | Migrace OOFEM infrastruktury do `fem-stability-matlab` (nyní `fem-3d-frame-matlab`) |
| 2026-03-20 | `ab39492` | CLAUDE.md — Diplomka označena obsolete, popis `linearSolverFn` |
| 2026-03-20 | `8357d73` | `linearSolverFn` s klouby + čistý příklad s vnitřními silami |
| 2026-03-20 | `80cc975` | Příklad kloubového spoje + `releases` v `stabilitySolverFn` |

---

## Časté záludnosti a historické opravy

1. **`sections` per-beam vs per-type** (oofemInputFn): průřezy musí být přiřazeny per-beam (každý prut dostane vlastní SimpleCS), jinak OOFEM sdílí průřezy nesprávně.

2. **Float node numbers v OOFEM Set**: Python numpy float → `2.0` místo `2` → OOFEM SIGABRT. Fix: `int(beam[0])` všude.

3. **Prázdné loads pole**: `loads.y.nodes = []` → for-smyčka 0× → `disc_loads.Y` nikdy nepřiřazena → Python ValueError. Fix: `disc_loads.Y = zeros(0,2)` před smyčkami.

4. **`discretizationBeamsFn` bug s různými disc**: funguje jen pokud `ndisc` je stejné pro všechny pruty.

5. **Kloubový test (Test 9 byl 114 %)**: příčinou byl bug v oofemInputFn s průřezy, ne klouby. Po opravě 0 %.

6. **`releaseCondenseFn` regrese**: commit `d63124c` omylem uvolňoval torzní DOF (4/10). Správné jsou DOFy 5,6/11,12 (jen ohyb).

7. **`elements.sections` konflikt v fem-truss-2d-matlab**: `elements = members` kopíruje `members.sections` (numeric array); pak `elements.sections.A = ...` → dot-indexing error. Fix: `secIdx = members.sections; elements.sections = struct(); elements.sections.A = sections.A(secIdx)`.

8. **Sedlový horní pás — koincidentní uzly**: krajní uzly horního pásu s z=0 splývají s dolním pásem → singulární K. Fix: automatické slučování uzlů v `trussGeneratorFn`.

9. **`displacements.global` je sparse**: vždy `full()` před indexací nebo výpisem.

10. **Malé pruty → singulární K + lokální boulení**: pruty s `r_outer ≈ 0` způsobují `RCOND ≈ 1e-24` v `EndForcesFn` a zaplaví eigenvalue výsledky lokálními módy. Fix: `stabilitySolverFn(..., 'oofem', 1e-8)` — relaxační parametr přidá `ε·I` ke K (Evgrafov 2005).
