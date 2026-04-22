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
| `en-truss-design-matlab/` | **aktivní** | Posudek příhrad dle EN 1993-1-1 — `src/`, `examples/` |
| `reliability-truss-matlab/` | **aktivní** | Spolehlivostní analýza příhrad Monte Carlo (UQLab) — `src/`, `examples/` |
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

## Modul `en-truss-design-matlab`

Posudek ocelových příhradových vazníků dle EN 1993-1-1 (CHS trubkové průřezy). Využívá FEM solver z `fem-2d-truss-matlab` pro osové síly a provádí kompletní posudek na tah, tlak a vzpěr.

### Architektura

```
example_truss_hall_30m.m
  ↓ params (rozpětí, sklon, zatížení, sections 3–4 skupiny)
trussHallInputFn(params)
  ↓ nodes, members, sections (expandováno na nGroups), kinematic, loadParams
designCheckFn(nodes, members, sections, kinematic, loadParams)
  ↓ memberClassificationFn → bucklingLengthsFn → loadCombinationsFn
  ↓ pro každý kombo: linearSolverFn (FEM) → sectionCheckFn (EN 1993-1-1)
  ↓ results (N_Ed, util, status)
reportFn(params, nodes, members, sections, loadParams, results, filename)
  ↓ posudek_vaznik_30m.html
```

### Zdrojové soubory (`en-truss-design-matlab/src/`)

| Funkce | Popis |
|--------|-------|
| `trussHallInputFn(params)` | Generátor geometrie + zatěžovacích parametrů pro průmyslovou halu |
| `designCheckFn(nodes, members, sections, kinematic, loadParams)` | Orchestrátor posudku — FEM + EN 1993-1-1 |
| `loadCombinationsFn(loadParams)` | 5 KZS dle EN 1990 (Jandera OK-01) |
| `memberClassificationFn(members, nodes)` | Klasifikace prutů: top\_chord, bottom\_chord, diagonal, vertical |
| `bucklingLengthsFn(members, nodes, classification, params)` | L\_cr in-plane / out-of-plane dle Tab. 1.29 |
| `sectionCheckFn(N_Ed, A, i_radius, f_y, L_cr, curve, D, t)` | Posudek průřezu + vzpěr (Cl. 6.2, 6.3.1) |
| `windLoadsFn(v_b, terrain_cat, h, slope)` | Tlak větru dle EN 1991-1-4 |
| `reportFn(params, nodes, members, sections, loadParams, results, filename)` | HTML report s MathJax rovnicemi |

### Datové struktury

```matlab
% params — vstup pro trussHallInputFn
params.span            % [m] rozpětí
params.slope           % [-] sklon střechy
params.purlin_spacing  % [m] rozteč vaznic
params.h_support       % [m] výška v uložení
params.truss_spacing   % [m] vzdálenost vazníků
params.f_y             % [Pa] mez kluzu (355e6 pro S355)
params.E               % [Pa] modul pružnosti
params.g_roof          % [kN/m²] střešní plášť
params.g_purlins       % [kN/m] vaznice
params.s_k             % [kN/m²] sníh
params.w_suction       % [kN/m²] sání větru
params.sections        % struct s 3–4 skupinami (top, bot, diag, [vert])
params.topology        % 'pratt', 'howe', 'warren', 'warren_inverted'
params.shape           % 'saddle', 'flat', 'mono'
params.warren_verticals % logical — přidat svislice do Warren

% sections — vstupní skupiny (3 nebo 4)
sections.A             % [m²] plocha průřezu
sections.E             % [Pa] modul pružnosti
sections.I             % [m⁴] moment setrvačnosti
sections.i_radius      % [m] poloměr setrvačnosti
sections.curve         % cell: 'a','b','c','d' — vzpěrná křivka
sections.D             % [m] vnější průměr CHS
sections.t             % [m] tloušťka stěny CHS
```

### Symetrické skupiny průřezů

`trussHallInputFn` automaticky rozdělí diagonály a svislice do **symetrických podskupin** podle vzdálenosti od středu rozpětí. Každý pár prutů (levý + pravý, stejně daleko od středu) dostane vlastní section index.

**Číslování výstupních skupin:**

```
sec 1                      = horní pás
sec 2                      = dolní pás
sec 3 .. 2+nDiagGroups     = diagonály (vnější pár → nejnižší index)
sec 2+nDiagGroups+1 .. end = svislice  (vnější pár → nejnižší index)
```

**Příklad pro 8 polí (Warren inverted):**
- 4 skupiny diagonál: páry (1,8), (2,7), (3,6), (4,5) → sec 3–6
- 5 skupin svislic: páry (1,9), (2,8), (3,7), (4,6), střed (5) → sec 7–11
- Celkem: **11 skupin** (2 pásy + 4 diag + 5 vert)
- `members.sections`: diag = `3 4 5 6 6 5 4 3`, vert = `7 7 8 9 10 11 10 9 8`

**Vstup:** uživatel definuje jen 3–4 základní průřezy (top, bot, diag, [vert]). Funkce je interně expanduje replikací — výstupní `sections` má `nGroups` položek. Uživatel pak může individuálně přepsat libovolnou skupinu.

**Metadata v `loadParams.sectionGroups`:**

```matlab
loadParams.sectionGroups.nDiag    % počet skupin diagonál
loadParams.sectionGroups.nVert    % počet skupin svislic
loadParams.sectionGroups.diagIdx  % vektor indexů: [3, 4, ..., 2+nDiag]
loadParams.sectionGroups.vertIdx  % vektor indexů: [2+nDiag+1, ..., nGroups]
loadParams.sectionGroups.nGroups  % celkový počet skupin
```

**Algoritmus (v `trussHallInputFn`):**
1. Midpoint x-souřadnice prutu → vzdálenost od L/2
2. `unique(round(dist, 6))` → symetrické skupiny
3. Seřazení: vnější = nejnižší section index
4. Expand: replikace vstupního `sections(3)` do diag skupin, `sections(4)` do vert skupin

### Kombinace zatížení (5 KZS)

| KZS | Vzorec | Zaměření |
|-----|--------|----------|
| 1 | 1,35·G + 1,5·S | Max tlak v horním pásu |
| 2 | 1,35·G + 1,5·S + 0,9·Wt | Sníh + příčný vítr |
| 3 | 1,35·G + 1,5·Wt + 0,75·S | Vítr dominantní |
| 4 | 1,0·Gmin + 1,5·Wt | Uplift — příčný vítr |
| 5 | 1,0·Gmin + 1,5·Wl | Uplift — podélný vítr |

### Vzpěrné délky (Tab. 1.29, Jandera OK-01)

| Typ prutu | L\_cr v rovině | L\_cr z roviny |
|-----------|---------------|---------------|
| Horní pás | L\_sys | 0,9 × rozteč vaznic |
| Dolní pás | L\_sys | rozteč ztužení |
| Diagonála | 0,9 × L\_sys | 0,75 × L\_sys |
| Svislice | 0,9 × L\_sys | 0,75 × L\_sys |

Pro CHS (I\_y = I\_z) rozhoduje `max(L_cr_in, L_cr_out)`.

### Posudek průřezu (`sectionCheckFn`)

```matlab
% Třída průřezu CHS (EN 1993-1-1, Tab. 5.2)
ε = sqrt(235e6 / f_y);
Třída 1: D/t ≤ 50·ε²
Třída 2: D/t ≤ 70·ε²
Třída 3: D/t ≤ 90·ε²

% Vzpěr (Cl. 6.3.1)
λ̄ = (L_cr / i) / (π·√(E/f_y))
Φ = 0,5·(1 + α·(λ̄ − 0,2) + λ̄²)
χ = min(1 / (Φ + √(Φ² − λ̄²)), 1)
N_b,Rd = χ·A·f_y / γ_M1

% Využití
util = max(N_Ed_tah / N_pl_Rd,  |N_Ed_tlak| / N_b_Rd)
```

### Klasifikace prutů (`memberClassificationFn`)

Pokud `members.sections` existuje:
- sec 1 → `top_chord`
- sec 2 → `bottom_chord`
- sec ≥ 3: úhel > 75° → `vertical`, jinak → `diagonal`

Toto funguje správně i s expandovanými symetrickými skupinami (sec 3–11 se klasifikují podle úhlu).

### HTML report (`reportFn`)

Generuje self-contained HTML s MathJax:
1. Záhlaví (geometrie, materiál)
2. Průřezy — **dynamická tabulka** (sloučí řádky se stejným D/t)
3. Zatížení (5 KZS s citacemi EN 1990)
4. Vzpěrné délky
5. Metodika (EN 1993-1-1 rovnice)
6. Ukázkový výpočet — step-by-step pro kritický prut
7. Tabulka výsledků (barevně kódovaná)
8. Souhrn (OK / FAIL)

### Příklady

| Příklad | Popis |
|---------|-------|
| `example_truss_hall_30m.m` | Warren inverted, 24m, sedlový, S355, CHS |
| `example_truss_LLENTAB.m` | Nepravidelná příhrada z LLENTAB exportu |

### Záludnosti (`en-truss-design-matlab`)

1. **`memberClassificationFn` a sections > 2**: sec 1 = top, sec 2 = bottom, vše ostatní klasifikováno podle úhlu — bezpečné pro libovolný počet skupin.

2. **`reportFn` dynamická tabulka průřezů**: sloučí skupiny se stejným D/t do jednoho řádku (nereprodukuje 11 identických řádků, pokud mají stejný profil).

3. **FEM solver vyžaduje `sections.A` a `.E`**: `linearSolverFn` z `fem-2d-truss-matlab` indexuje `sections.A(members.sections(p))` — funguje s libovolným počtem skupin.

4. **Expand sections**: `trussHallInputFn` expanduje vstupní 3–4 skupiny na nGroups replikací. Zdrojový index pro diag = 3, pro vert = 4 (nebo 3 pokud vstup má jen 3 skupiny).

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

## Modul `reliability-truss-matlab` — vizualizace a výkonnost

### `plotTrussBetaFn` — vizualizace kritičnosti prutů

Umístění: `reliability-truss-matlab/src/plotTrussBetaFn.m`

```matlab
h = plotTrussBetaFn(nodes, members, results, kinematic)
```

Vykreslí příhradovou konstrukci s pruty barevně rozlišenými podle kritičnosti ze systémové spolehlivostní analýzy.

**Metrika: `results.member.critical_pct`** — podíl systémových selhání, v nichž byl daný prut nejslabším článkem (argmin g hodnot). Správná metrika pro "co optimalizovat":
- **Zelená (0 %)** — nikdy kritický → kandidát na zmenšení průřezu
- **Červená (80–100 %)** — dominantní příčina kolapsu → zvětšit průřez

**Diskrétní barevné pásy po 20 % relativně k nejkritičtějšímu prutu:**

| Pás | Barva |
|-----|-------|
| 0 % | Zelená (fixní) |
| 0–20 % | Světle zelená |
| 20–40 % | Žlutá |
| 40–60 % | Oranžová |
| 60–80 % | Tmavě oranžová |
| 80–100 % | Červená (fixní) |

**Adaptivní barvy** — barvy se interpolují dle počtu přítomných skupin:
- 1 nenulová skupina → červená
- 2 nenulové skupiny → žlutá + červená
- 3+ skupin → plný gradient světle zelená→červená

---

### Proč `critical_pct` místo per-member beta

**Per-member beta z `−Φ⁻¹(sum(g≤0)/n)` je nespolehlivý** při malém počtu vzorků:

Pro β_sys ≈ 4.3 → P_f,sys ≈ 8.5×10⁻⁶. Počet selhání prutu i v 1e7 vzorcích:
- Dominantní prut: ~82 selhání (CoV ~11 %) — ok
- Druhý prut (3.3 %): ~3 selhání (CoV ~58 %) — nespolehlivé
- Ostatní (0 %): 0 selhání → beta = Inf → vždy zelený (ŠPATNĚ)

**`critical_pct` je robustní** protože sleduje pořadí g hodnot (argmin) — tato událost nastane v každém vzorku, ne jen při systémovém selhání. Již při 100 systémových selháních (1e7 vzorků) je odhad stabilní.

**Vztah mezi `critical_pct` a β_i** (pro silně korelované pruty se sdílenými zatíženími):

$$\beta_i \approx -\Phi^{-1}\!\left(\frac{\text{crit\_pct}(i)}{100} \times P_{f,sys}\right)$$

Lze použít pro převod na betovou škálu po dokončení analýzy.

---

### Paměťová optimalizace `limitStateFastFn` — running counts

**Původní store (SMAZÁNO):** akumuloval celé matice `g_member` a `fail_mode`:
- 1e7 vzorků × 29 prutů × 8 B = **4.6 GB**
- 1e8 vzorků → **47 GB** → crash na 32 GB RAM

**Nový store:** pouze průběžné součty (running counts):

```matlab
store.critical_count   % (nmembers×1) histogram nejslabšího článku
store.n_tension_fail   % (nmembers×1) počet tahových selhání
store.n_buckling_fail  % (nmembers×1) počet vzpěrných selhání
store.nEval            % (scalar) celkový počet vyhodnocení
```

Paměť: **< 1 KB** bez ohledu na počet vzorků. Výsledky `critical_pct`, `n_tension_fail`, `n_buckling_fail` jsou identické.

**Ztráta:** `results.member.g_member` se již neukládá. Nepoužívá se v žádné aktivní funkci.

**Výkonnostní srovnání (29 prutů, 1e7 vzorků):**
- Před optimalizací: ~150 s
- Po optimalizaci: ~99 s (**~34 % zrychlení**)

---

### Doporučený počet vzorků pro publikaci

| Vzorky | Čas (~29 prutů) | Selhání (β≈4.3) | CoV Pf |
|--------|----------------|-----------------|--------|
| 1e6 | ~10 s | ~8 | ~35 % |
| 1e7 | ~99 s | ~85 | ~10 % |
| **1e8** | **~17 min** | **~850** | **~3 %** |

Pro vizualizaci `critical_pct` stačí 1e7 (100+ selhání → stabilní pořadí kritičnosti). Pro publikační kvalitu β_sys doporučeno 1e8.

**`batchSize = 1e6`** — doporučeno pro 1e8 (méně overhead, RAM ~230 MB per batch).

---

## MAC verifikace — MATLAB vs. Scia Engineer

Modul pro porovnání vlastních tvarů stabilitní analýzy mezi MATLAB solverem a Scia Engineer pomocí **MAC (Modal Assurance Criterion)**.

### Funkce (`fem-3d-frame-matlab/src/`)

| Funkce | Popis |
|--------|-------|
| `macCriterionFn(Phi_A, Phi_B)` | Čistý vektorizovaný výpočet MAC matice |
| `sciaImportFn(csvFile, nodes, kinematic)` | Import CSV ze Scia, matching uzlů dle souřadnic, remapování na MATLAB DOF pořadí |
| `macComparisonFn(nodes, beams, kinematic, Results, scia_phi)` | Orchestrace: extrakce φ na původních uzlech, výpočet MAC, pass/fail výstup |

### `macCriterionFn`

```matlab
macMatrix = macCriterionFn(Phi_A, Phi_B)
% Phi_A: (ndof × nA),  Phi_B: (ndof × nB)
% → macMatrix: (nA × nB),  hodnoty v [0, 1]
```

Vzorec (abs kvůli libovolnému znaménku eigenvektoru):
```
MAC(i,j) = |Φ_A(:,i)' · Φ_B(:,j)|²  /  (‖Φ_A(:,i)‖² · ‖Φ_B(:,j)‖²)
```

### `sciaImportFn`

```matlab
[scia_phi, node_map] = sciaImportFn(csvFile, nodes, kinematic)
[scia_phi, node_map] = sciaImportFn(csvFile, nodes, kinematic, 'Tolerance', 1e-3)
[scia_phi, node_map] = sciaImportFn(csvFile, nodes, kinematic, 'CoordScale', 1e-3)
```

**Očekávaný CSV formát:**
```
mode,node_id,x,y,z,ux,uy,uz,rx,ry,rz
1,1,0.000,0.000,0.000,0.0,0.0,0.0,0.0,0.0,0.0
1,2,1.000,0.000,0.000,0.285,0.005,...
```
- `x,y,z` v metrech — klíčové pro spatial matching
- `ux,uy,uz` v metrech (Scia exportuje mm → dělit 1000)
- `rx,ry,rz` v radiánech (Scia exportuje mrad → dělit 1000)
- `node_id` slouží jen pro diagnostiku — matching probíhá dle souřadnic

**Volitelné parametry:**
- `'Tolerance'` — max vzdálenost uzlů [m] pro matching, default 1e-3
- `'CoordScale'` — škálování souřadnic ze Scia (1e-3 pokud Scia exportuje v mm)
- `'DofOrder'` — permutace DOFů pokud Scia používá jiné pořadí než [ux,uy,uz,rx,ry,rz]

### `macComparisonFn`

```matlab
[macMatrix, passed, details] = macComparisonFn(nodes, beams, kinematic, Results, scia_phi)
[macMatrix, passed, details] = macComparisonFn(..., macThreshold)  % default 0.90
```

- Extrahuje `matlab_phi = Results.vectors(1:ndofs_orig, :)` — pouze původní fyzické uzly (bez diskretizačních)
- `ndofs_orig = max(max(codeNumbersFn(beams_tmp, nodes_tmp)))` — rekonstruováno interně z `beams` + `kinematic`
- `details.diagonal_mac`, `details.best_match`, `details.best_match_idx`

### Záporné eigenvalues — důležité!

`stabilitySolverFn` může vrátit záporné vlastní čísla. Záporný λ = vzpěr při **obráceném smyslu zatížení** (tažené pruty). Scia záporné módy standardně nezobrazuje.

**Před MAC porovnáním vždy filtrovat:**
```matlab
pos_idx = find(Results.values > 0);
Results_pos.values  = Results.values(pos_idx);
Results_pos.vectors = Results.vectors(:, pos_idx);
[macMatrix, passed, details] = macComparisonFn(nodes, beams, kinematic, Results_pos, scia_phi);
```

Bez filtrace by MATLAB mód 1 (záporný) byl porovnáván se Scia módem 1 (kladným) → MAC FAIL.

### Typický workflow

```matlab
% 1. Stabilita
Results = stabilitySolverFn(sections, nodes, ndisc, kinematic, beams, loads);

% 2. Import Scia (CSV musí mít souřadnice v m, posuny v m, rotace v rad)
[scia_phi, ~] = sciaImportFn('scia_modes.csv', nodes, kinematic);

% 3. Filtr záporných módů
pos_idx = find(Results.values > 0);
Results_pos.values  = Results.values(pos_idx);
Results_pos.vectors = Results.vectors(:, pos_idx);

% 4. MAC
[macMatrix, passed, details] = macComparisonFn(nodes, beams, kinematic, Results_pos, scia_phi);

% 5. Heatmap
figure; imagesc(macMatrix); colorbar; clim([0 1]); colormap(flipud(gray));
xlabel('Scia mód'); ylabel('MATLAB mód');
```

### Příklady (`fem-3d-frame-matlab/examples/`)

| Soubor | Průřez sloupů | CSV dat | λ₁ (Scia) |
|--------|--------------|---------|-----------|
| `example_scia_frame.m` | IPE240 | `scia_modes.csv` — 10 módů | 548.06 |
| `example_scia_frame_shs_columns.m` | SHS 240×240×15 → kolaps diagonál | `scia_modes_shs.csv` — 10 módů | 1413.39 |

**SHS 240×240×15 vlastnosti:**
- A = 1.350×10⁻² m², Iy = Iz = 1.1441×10⁻⁴ m⁴
- IT = 1.7086×10⁻⁴ m⁴ (Bredt: `4·A_m²·t/s = 4·225²·15/900 mm⁴`)

### Generování CSV ze Scia exportu (Python)

Scia exportuje Excel s listy v **obráceném pořadí** (mód 10 = první list). Jednotky: mm a mrad.

```python
import pandas as pd, re

all_sheets = pd.read_excel('output.xlsx', sheet_name=None, dtype=str)

# Seřadit dle eigenvalue vzestupně
sheet_list = []
for name, df in all_sheets.items():
    lam = float(re.search(r'[\d,]+$', df['Stav'].iloc[0]).group().replace(',', '.'))
    sheet_list.append((lam, df))
sheet_list.sort(key=lambda x: x[0])

rows = []
for mode_idx, (lam, df) in enumerate(sheet_list, start=1):
    for _, row in df.iterrows():
        node_num = int(str(row['Jméno']).replace('N', ''))
        x, y, z = xyz[node_num - 1]   # souřadnice z MATLAB modelu
        rows.append({
            'mode': mode_idx, 'node_id': node_num,
            'x': x, 'y': y, 'z': z,
            'ux': float(str(row['Ux [mm]']).replace(',', '.'))   / 1000,
            'uy': float(str(row['Uy [mm]']).replace(',', '.'))   / 1000,
            'uz': float(str(row['Uz [mm]']).replace(',', '.'))   / 1000,
            'rx': float(str(row['Φx [mrad]']).replace(',', '.')) / 1000,
            'ry': float(str(row['Φy [mrad]']).replace(',', '.')) / 1000,
            'rz': float(str(row['Φz [mrad]']).replace(',', '.')) / 1000,
        })

pd.DataFrame(rows).to_csv('scia_modes.csv', index=False, float_format='%.9f')
```

### Záludnosti MAC modulu

1. **Záporné eigenvalues**: vždy filtrovat `pos_idx = find(Results.values > 0)` před MAC — viz výše.

2. **Jednotky v CSV**: Scia exportuje mm a mrad → v CSV musí být m a rad. Dělit 1000.

3. **Pořadí listů v Excel exportu ze Scia**: listy jsou v obráceném pořadí — třídit dle eigenvalue.

4. **Český desetinný oddělovač**: Scia exportuje `285,9` místo `285.9` → `.replace(',', '.')` při parsování.

5. **node_id vs. souřadnice**: `sciaImportFn` matchuje uzly dle prostorových souřadnic, ne dle `node_id`. Číslování uzlů v Scia a MATLABu se může lišit — ale pokud sedí, číslo Ni = index i v MATLAB.

6. **`ndofs_orig` extrakce**: `macComparisonFn` rekonstruuje `ndofs_orig` voláním `codeNumbersFn` — potřebuje `beams.nodesHead`, `beams.nodesEnd`, `beams.sections`, `beams.angles` a `kinematic`.

---

## Chronologie změn

| Datum | Commit | Popis |
|-------|--------|-------|
| 2026-04-22 | `15b36ad` | `limitStateFastFn` — store přepracován na running counts, paměť O(nmembers) místo O(n×m); `systemReliabilityFn` přizpůsoben |
| 2026-04-22 | `89a7d71` | `plotTrussBetaFn` — vizualizace kritičnosti prutů diskrétními pásy; `example_reliability_24m.m` aktualizován |
| 2026-04-21 | `8484354` | `scia_modes.csv` rozšířen na 10 módů; filtr záporných eigenvalues před MAC |
| 2026-04-21 | `ccb10d5` | `example_scia_frame_shs_columns` — SHS 240×240×15 sloupy, kolaps diagonál |
| 2026-04-21 | `bb59257` | `macCriterionFn`, `sciaImportFn`, `macComparisonFn` — MAC verifikace vs. Scia |
| 2026-04-08 | `26a0ffb` | `trussHallInputFn` — symetrické skupiny průřezů diagonál a svislic; `reportFn` dynamická tabulka |
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

11. **`gca` jako proměnná shadowuje built-in** (MATLAB): zápis `gca.Property = value` vytvoří lokální struct `gca` a MATLAB pak odmítne `gca` jako funkci **v celé funkci** (i na řádcích před přiřazením). Fix: vždy `ax = gca; ax.Property = value`.

12. **Per-member beta z MC je nespolehlivý** (`reliability-truss-matlab`): `−Φ⁻¹(sum(g≤0)/n)` dává Inf pro pruty které nikdy neselhají v izolaci, přestože jsou nejčastěji nejslabším článkem systému. Používat `critical_pct` pro vizualizaci a optimalizační rozhodnutí.

13. **`limitStateFastFn` store a RAM při 1e8+**: původní store akumuloval `g_member` (nSamples×nmembers) → 47 GB při 1e8. Opraveno v commit `15b36ad` — store nyní drží jen running counts (< 1 KB).
