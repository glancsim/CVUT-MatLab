# CLAUDE.md — Znalostní báze: FEM stability a lineární analýza

Tento soubor shromažďuje veškeré znalosti o projektu tak, aby je mohl využít libovolný Claude agent v budoucích sessions.

---

## Přehled projektu

Projekt implementuje 3D FEM analýzu nosníkových konstrukcí (prutové soustavy) v MATLAB s verifikací proti OOFEM.

**Aktivní modul: `fem-stability-matlab/`**

> **`Diplomka/` je obsolete** — slouží jen pro archivaci a regresní testy (Tests 1–12 s OOFEM verifikací).
> Veškerý nový vývoj probíhá výhradně v `fem-stability-matlab/`.

| Složka | Stav | Účel |
|--------|------|------|
| `fem-stability-matlab/` | **aktivní** | `src/` = funkce, `tests/` = testy, `examples/` = ukázky |
| `Diplomka/` | obsolete | původní kód diplomové práce, regresní testy 1–12 |

---

## Datové struktury (MATLAB structs)

### `nodes` — uzly

```matlab
nodes.x       % (nnodes×1) souřadnice x [m]
nodes.y       % (nnodes×1) souřadnice y [m]
nodes.z       % (nnodes×1) souřadnice z [m]
nodes.dofs    % (nnodes×6) logical: true=volný DOF, false=vetknutý
nodes.ndofs   % (scalar) počet volných DOFů celkem
nodes.nnodes  % (scalar) počet uzlů
```

### `beams` — pruty

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

## Hlavní vstupní funkce (`fem-stability-matlab/src/`)

| Funkce | Vstup | Výstup |
|--------|-------|--------|
| `linearSolverFn(sections, nodes, ndisc, kinematic, beams, loads)` | — | `displacements`, `endForces` |
| `stabilitySolverFn(sections, nodes, ndisc, kinematic, beams, loads)` | — | `Results.values`, `Results.vectors` |

`endForces.local` (12 × nelement): řádky 1–6 = nodesHead, 7–12 = nodesEnd. Složky: N, Vy, Vz, Mx, My, Mz v lokálních souřadnicích prutu.

Obě funkce propagují `beams.releases` na `elements.releases` interně — není třeba nic dalšího.

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

## Klíčové funkce

### `stiffnessMatrixFn(elements, transformationMatrix)`

Sestavuje globální matici tuhosti. Lokální 12×12 matice ze čtyř 6×6 bloků (K11, K12, K21, K22) pro 3D Euler-Bernoulli prut. Kódová čísla 0 = vetknutý DOF (přeskočí se při assemblování).

**Statická kondenzace (klouby):** Pokud `elements.releases(cp,:)` obsahuje 1, zavolá se `releaseCondenseFn` po násobení E, před transformací. Uvolněné rotační DOFy (4,5,6 = hlava; 10,11,12 = pata) se kondenzují ven. `stiffnesMatrix.local{cp}` se ukládá po kondenzaci → `EndForcesFn` vrátí 0 pro uvolněné momenty.

### `geometricMoofemFn(...)`

Geometrická matice pro analýzu stability. Osová síla: `N = (-F(1,cp) + F(7,cp)) / 2`. Kg_local symmetrizována, transformována: `T' * Kg * T`. Používá pouze axiální složku — pootočení průřezu neovlivňuje výsledek stability (Iy=Iz → trubkové průřezy fungují stejně).

### `codeNumbersFn(beams, nodes)`

Přiřadí globální kódová čísla volným DOFům (postupné číslování jen kde `nodes.dofs==1`). Výstup: `codes (nbeams×12)`.

### `discretizationBeamsFn(beams, nodes)`

Diskretizuje pruty na elementy. **Pozor:** při různých hodnotách `disc` pro jednotlivé pruty může být chyba (používá `c` z poslední iterace vnější smyčky pro indexaci — funguje jen pokud mají všechny pruty stejné `disc`).

### `XYtoRotBeamsFn(beams, angles)`

Počítá referenční vektor `XY` pro každý prut z `beams.angles` (pootočení průřezu). Výstup `beams.XY (nbeams×3)`.

### `oofemInputFn(nodes, beams, loads, kinematic, sections, filename)`

Generuje `input.mat` pro Python runner. Klíčové výstupy: `oofem.nodes`, `oofem.beams`, `oofem.refNode`, `oofem.loads`, `oofem.sectionProp` (per-beam), `oofem.releases` (pro klouby).

**Důležité opravy (historické):**
- Průřezy se přiřazují per-beam (ne per-type) — opraveno pro správnou verifikaci Test 9
- Prázdná pole zatížení (loads.y.nodes=[]) se inicializují jako `zeros(0,2)` předem → Python nekrachuje

---

## Kloubová spojení (beams.releases)

Přidáno v `feat: kloubove/ramove spoje prutu`.

```matlab
beams.releases = false(nbeams, 2);
beams.releases(2, 2) = true;   % prut 2, patní konec = kloub
beams.releases(4, 1) = true;   % prut 4, hlavový konec = kloub
```

**Jak funguje:**
- Chybějící pole = zpětně kompatibilní (vše rámové)
- Kloubový konec = nulové momenty (DOFy 4,5,6 nebo 10,11,12 lokálně)
- Metoda: statická kondenzace K_cond = K(s,s) − K(s,r)·K(r,r)⁻¹·K(r,s)
- Uvolnění platí jen pro 1. element (hlava) a poslední element (pata) každého prutu
- OOFEM: zapisuje `dofstocondense N d1...dN` do Beam3d elementu v test.in

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

`oofemTestFn` porovnává jen kladná vlastní čísla seřazená vzestupně. Chyba se počítá zvlášť pro translační a rotační DOFy (normalizace po max). Testy 6 a 7 mají nenulové chyby jen na vyšších módech (≥6) — akceptovatelné (FEM méně přesný pro vyšší módy).

---

## Vizualizace: plotStructureFn

Umístění: `fem-stability-matlab/src/plotStructureFn.m`

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

Délky šipek: 15 % `L_char` (= max rozpětí konstrukce). Škálování zatížení: lineárně na arrow_len.

---

## Testovací infrastruktura (Diplomka)

### Spuštění jednoho testu

```matlab
cd 'stability-tests/Test 1'
test_input;
[errors, h, sv] = testFn(sections, nodes, ndisc, kinematic, beams, loads);
```

### Testy 1–12

- **Testy 1–5:** základní geometrie, chyby ~0 %
- **Test 6:** chyby jen módy ≥6 (max ~28 %) — akceptovatelné
- **Test 7:** chyby jen módy ≥6 (max ~47 %) — akceptovatelné
- **Test 8:** 0 %
- **Test 9:** byl 114 % → opraveno opravou průřezů per-beam v oofemInputFn → 0 %
- **Testy 10–12:** přidány, fungovaly po zkopírování oofem binárky a opravě:
  - Empty Y loads: inicializace `disc_loads.Y = zeros(0,2)` předem
  - Float node numbers v Set: přetypování přes `int()`

### Diagnostické skripty

- `Test 9/diag_test9_h1.m` — 4 scénáře (trubkové/originální, angle 0/45)
- `Test 9/diag_test9_h2.m` — 3 scénáře (4 sloupce, diagonální prut, svislý prut)

---

## Datové toky a vazby mezi soubory

```
test_input.m
  ↓ sections, nodes, ndisc, kinematic, beams, loads
testFn.m
  ↓ volá Resources/*.m
  ↓ oofemTestFn → oofemInputFn → input.mat → oofem.py → eigen.mat
  ↓ returns: errors, h, sortedValues
```

### Kritické závislosti

- `stiffnessMatrixFn` potřebuje `elements.releases` (nebo ho ignoruje pokud chybí)
- `geometricMoofemFn` bere lokální síly z `EndForcesFn` — závisí na správné K matici
- `oofemInputFn` generuje `oofem.sectionProp` per-beam (ne per-type!) — klíčové pro správnost

---

## Repozitáře

| Repozitář | URL | Obsah |
|-----------|-----|-------|
| CVUT-MatLab | https://github.com/glancsim/CVUT-MatLab | MATLAB kód |
| cvut-python | https://github.com/glancsim/cvut-python | Python OOFEM runner (`oofem.py`) |

### Větve

- `main` — stabilní verze
- `claude/fervent-agnesi` — aktuální vývojová větev (releases, vizualizace, opravy)
- `feat/plot-structure-fn` — sloučena do main (plotStructureFn)

---

## Časté záludnosti a historické opravy

1. **`sections` per-beam vs per-type** (oofemInputFn): průřezy musí být přiřazeny per-beam (každý prut dostane vlastní SimpleCS), jinak OOFEM sdílí průřezy nesprávně.

2. **Float node numbers v OOFEM Set**: Python numpy float → `2.0` místo `2` → OOFEM SIGABRT. Fix: `int(beam[0])` všude.

3. **Prázdné loads pole**: `loads.y.nodes = []` → for-smyčka 0× → `disc_loads.Y` nikdy nepřiřazena → Python ValueError. Fix: `disc_loads.Y = zeros(0,2)` před smyčkami.

4. **`discretizationBeamsFn` bug s různými disc**: funkce používá `c` z poslední iterace pro indexaci elementů — funguje jen pokud `ndisc` je stejné pro všechny pruty (což `testFn` zajišťuje: `beams.disc = ones(nr,1)*ndisc`).

5. **Kloubový test (Test 9 byl 114 %)**: příčinou byl bug v oofemInputFn s průřezy, ne samotná geometrie/klouby. Po opravě 0 %.
