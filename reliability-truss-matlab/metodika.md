# Kontrolní report: reliability-truss-matlab

## Kontext

Uživatel potřebuje ověřit, že výpočet všech náhodných veličin a jejich přepočet na zatížení / odolnost je správný. Tento soubor slouží jako kontrolní podklad: pro každou RV je zde 1) definice v UQLab, 2) normalizační postup, 3) jak se dostává do limitní funkce. Na konci jsou vyznačeny dvě nekonzistence, které stojí za zkontrolování.

---

## 1. Přehled toku dat

```
example_reliability_30m.m
  └── trussHallInputFn(params)                 → nodes, members, sections, loadParams
  └── systemReliabilityFn(..., mcOpts)
        ├── memberClassificationFn             → klasifikace prutů (top/bot/diag/vert)
        ├── bucklingLengthsFn                  → L_cr (nmembers × 1)
        ├── alpha_imp z sections.curve         → imperfekce křivky 'a' → 0.21
        ├── defineRandomVariablesFn            → UQLab Marginals (nG + 10 veličin)
        ├── 3× linearSolverFn                  → N_perm, N_snow, N_sw  (vlivové koef.)
        ├── uq_createModel(limitStateFastFn)
        └── uq_createAnalysis('Reliability', 'Subset'/'MCS')
              └── N× limitStateFastFn(X)        → g_sys  (min přes pruty)
```

---

## 2. Tabulka všech náhodných veličin

nG = počet průřezových skupin (v example_30m: 5 profilů, ale sections má nG položek z `trussHallInputFn` — pro 30m Warren inverted typicky **nGroups ≠ 5**, protože trussHallInput expanduje diagonály/svislice do symetrických párů).

| # | Proměnná | Rozdělení | Střední hodnota | COV | Normalizace | Zdroj |
|---|----------|-----------|-----------------|-----|-------------|-------|
| 1 | R1 | Lognormal | `1/exp(-1.645·COV)` ≈ 1.086 | 0.05 | 5%-fraktil = 1 → f_y,5% = f_yk | JRC TR Tab. 3.7 |
| 2..nG+1 | d_sg | Gaussian | `sections.D(sg)` (nominal) | 0.005 | nominál | JRC TR A.4 |
| nG+2 | G_s | Gaussian | 1.00 | 0.025 | multiplikátor vl. tíhy | JRC TR |
| nG+3 | G_P | Gaussian | 1.00 | 0.10 | multiplikátor stálého | JRC TR |
| nG+4 | Q1 | Gumbel | `1/(1+2.593·COV)` ≈ 0.658 | 0.20 | 98%-fraktil = 1 → s_g,98% = s_k | EN 1991-1-3:2025 |
| nG+5 | θ_Q2 | Lognormal | 0.81 | 0.26 | model. nejistota sněhu (časově nezávislá) | JRC TR |
| nG+6 | μ₁ | Lognormal | 0.80 | 0.20 | tvarový součinitel sněhu | EN 1991-1-3 |
| nG+7 | C_e | Lognormal | 1.00 | 0.15 | expoziční součinitel | EN 1991-1-3 |
| nG+8 | θ_R | Lognormal | 1.15 | 0.05 | model. nejistota — tah | JRC TR |
| nG+9 | θ_b | Lognormal | 1.00 | 0.10 | model. nejistota — vzpěr | JRC TR |
| nG+10 | θ_E | Lognormal | 1.00 | 0.05 | model. nejistota — účinky zatížení | JRC TR |

### Detail normalizace

**R1 (mez kluzu):**
```
μ_R1 = 1 / exp(−1.645 · COV)    # pro malé COV ≈ e^(1.645·COV)
```
→ zaručí, že **P(R1 < 1) = 5 %**, tj. f_y,5% = R1,5% · f_y,nom = 1 · f_y,nom = f_yk. ✔

**Q1 (sníh na zemi):**
```
K98 = (√6/π) · (γ + |ln(−ln 0.98)|) = 2.593    # Eulerova konstanta γ = 0.5772
μ_Q1 = 1 / (1 + K98 · COV)
```
→ P(Q1 < 1) = 98 %, tedy s_g,98% = 1 · s_k = s_k (= 50letý max dle EN). ✔

**d_i (průměry CHS):**
Normální rozdělení s μ = nominální průměr, σ = 0.005·μ. Tloušťky t **nejsou** náhodné (deterministické).

---

## 3. Sestavení zatížení (`reliabilityLoadsFn`)

Vstupy: `G_s`, `G_P`, `s_roof` (všechny již realizace RV)

```
q_perm  = G_P · g_roof                   [kN/m²]         (plášť + vaznice)
q_net   = q_perm + s_roof                [kN/m²]
Fz_top  = −q_net · b · trib · 1e3        [N]             (na každý uzel horního pásu)
Fz_sw   = G_s · selfWeight.values        [N]             (vlastní tíha)
```
kde `b = truss_spacing`, `trib` = zatěžovací šířky uzlů.

**Poznámka:** `reliabilityLoadsFn` bere **již přepočítaný** `s_roof` [kN/m²], nikoli surový `Q1`. Přepočet Q1 → s_roof je v limitní funkci, ne tady.

---

## 4. Superpozice ve `limitStateFastFn` (zrychlená verze)

Protože FEM je lineární a vazník staticky určitý, předpočítají se 3 jednotkové úlohy:

| Vektor | Zátěž | Velikost |
|--------|-------|----------|
| `N_perm` | G_P = 1, ostatní = 0 | odezva na `g_roof` = 1 kN/m² |
| `N_snow` | s_roof = 1, ostatní = 0 | odezva na 1 kN/m² střešního sněhu |
| `N_sw` | G_s = 1, ostatní = 0 | odezva na nominální vlastní tíhu |

Každý vzorek:
```
N_Ed(k,:) = G_P(k) · N_perm  +  s_roof(k) · N_snow  +  G_s(k) · N_sw
```

Platí přesně pro staticky určité příhrady (pozice sil nezávisí na EA). U staticky neurčitých by vnesla malou chybu přes náhodné A — komentář říká < 0.01 %.

---

## 5. Výpočet průřezových vlastností ze vzorku

```
d_inner(k,sg) = d(k,sg) − 2·t_nom(sg)
A(k,sg)       = π/4 · (d² − d_inner²)
I(k,sg)       = π/64 · (d⁴ − d_inner⁴)
i(k,sg)       = √(I / A)
```
✔ `limitStateFn` i `limitStateFastFn` toto počítají shodně (přes `CHS_propertiesFn` resp. vektorizovaně).

---

## 6. Limitní funkce pro jeden prut

```
f_y(k) = R1(k) · f_y,nom                 [Pa]
```

**Tah** (N_Ed ≥ 0):
```
g = θ_R · f_y · A  −  θ_E · N_Ed
```
— bez γ součinitelů (to je pro reliabilitu správné: γ v LSF nepatří).

**Tlak** (N_Ed < 0) — EN 1993-1-1, Cl. 6.3.1:
```
λ_1    = π · √(E / f_y)
λ_bar  = (L_cr / i) / λ_1
Φ      = 0.5 · (1 + α · (λ_bar − 0.2) + λ_bar²)         α z křivky 'a' = 0.21
χ      = min( 1 / (Φ + √(Φ² − λ_bar²)) , 1 )
g      = θ_b · χ · f_y · A  −  θ_E · |N_Ed|
```

**Systémová (sériová) limitní funkce:**
```
g_sys(k) = min_p  g(k, p)
Pf       = P(g_sys ≤ 0)
β        = −Φ⁻¹(Pf)
```
✔ Pro staticky určitý vazník odpovídá realitě (jediný selhávající prut = kolaps).

---

## 7. ⚠ Nekonzistence k prověření

### 7.1 Přepočet sněhu se liší mezi pomalou a rychlou verzí

**`limitStateFn.m` (ř. 103):**
```matlab
s_roof = tQ2_k * mu1_k * 0.8 * 1.0 * s_g_k;   % C_e = 0.8, C_t = 1.0 (hardcoded)
```
→ Součinitel **C_e = 0.8** je **hardcoded**, náhodná veličina `Ce_k` (X(:,nG+7)) je rozbalena ale **NEPOUŽITA** (`#ok<NASGU>`).

**`limitStateFastFn.m` (ř. 75):**
```matlab
s_roof = tQ2 .* mu1 .* s_g;                   % BEZ faktoru 0.8, BEZ Ce!
```
→ Chybí jak pevný faktor 0.8, tak náhodná Ce.

**Důsledek:**
- Rychlá verze dává **systematicky 1,25× větší sníh** než pomalá (protože 1/0.8 = 1.25) → nižší β.
- V obou verzích je nadefinovaná náhodná `C_e` (Lognormal, μ=1, COV 0.15), ale **ani jedna ji nezapojuje do výpočtu**.

**Co by mělo být (dle EN 1991-1-3:2025, rov. 7.3):**
```
s = μ_1 · C_e · C_t · s_k              (EN deterministické)
s_roof = θ_Q2 · μ_1 · C_e · C_t · s_g  (reliability s modelovou nejistotou)
```
tj. `s_roof = tQ2 .* mu1 .* Ce .* s_g` (C_t = 1 pro běžné střechy).

### 7.2 Výchozí μ pro `mu1` je 0.80 — záměrně, nebo omylem za 0.8·C_e?

V `defineRandomVariablesFn` je `mu1_mean = 0.80`. Hlavička funkce uvádí v komentáři:
```
.mu1_mean, .mu1_cov     (default: 0.8*Ce_mean, 0.20)
```
ale kód je `'mu1_mean', 0.80` (konstanta, nezávisle na Ce_mean).

Pro plochou střechu se sklonem ≤ 30° EN 1991-1-3 Tab. 5.2 dává μ_1 = 0.8. Takže hodnota 0.8 je správně jako **tvarový součinitel** — ne jako 0.8·Ce. Komentář v hlavičce je matoucí.

---

## 8. Rychlá verifikace příkladem

Pro example_30m (f_y = 355 MPa, S355, křivka 'a') vezmi prut horního pásu (TR 108×5) s N_Ed z deterministického posudku a spočti:

```
A      = π · 0.005 · (0.108 − 0.005)      = 1.618e-3 m²
I      = π/64 · (0.108⁴ − 0.098⁴)         = ...
i      = √(I/A)
λ_1    = π · √(210e9 / 355e6)             = 76.41
λ_bar  = (L_cr / i) / λ_1
χ      = ... (křivka a, α = 0.21)
N_b,Rd = χ · f_y · A                       [N]
```

Pro β_cíl = 3.8 musí platit Pf ≤ 7.2·10⁻⁵. V example_30m.m se výsledek porovnává s cílem.

---

## 9. Doporučení k opravě (ne nyní — až schválíš)

1. **Sjednotit `limitStateFn` a `limitStateFastFn`** — rozhodnout, zda sníh má:
   - (a) používat náhodnou `Ce` (viz 7.1 — fyzikálně správné), nebo
   - (b) držet deterministické C_e = 0.8 (a RV Ce odstranit z `defineRandomVariablesFn`).
2. **Opravit komentář u `mu1_mean`** — odstranit matoucí `0.8*Ce_mean`.
3. **Ověřit, jestli regresní výsledek β z example_30m odpovídá** po opravě (pravděpodobně se změní ve 2. desetinném místě).

---

## 10. Kritické soubory

- `reliability-truss-matlab/src/defineRandomVariablesFn.m` — definice RV
- `reliability-truss-matlab/src/limitStateFn.m` — LSF referenční (FEM na každý vzorek)
- `reliability-truss-matlab/src/limitStateFastFn.m` — LSF vektorizovaná (superpozice)
- `reliability-truss-matlab/src/reliabilityLoadsFn.m` — přepočet RV → uzlová síla
- `reliability-truss-matlab/src/systemReliabilityFn.m` — orchestrátor
- `reliability-truss-matlab/src/CHS_propertiesFn.m` — A, i z d, t
- `reliability-truss-matlab/examples/example_reliability_30m.m` — referenční příklad

## 11. Verifikace reportu

- Ruční ověření 5 vzorků: vygenerovat X z `uq_getSample(myInput, 5)`, spustit obě LSF a porovnat. Rozdíl **musí** být přesně v faktoru sněhu, vše ostatní shodné.
- Kontrola Q1: spočítat empirický 98%-fraktil z 10⁶ vzorků Gumbel(μ_Q1, σ_Q1) → má být ≈ 1.000.
- Kontrola R1: empirický 5%-fraktil Lognormal(μ_R1, σ_R1) → má být ≈ 1.000.

---

**Status:** Report k revizi. Jakmile se rozhodneš, zda chceš (a) sjednotit obě verze s Ce, nebo (b) odstranit RV Ce, pak přejdu do implementace oprav.
