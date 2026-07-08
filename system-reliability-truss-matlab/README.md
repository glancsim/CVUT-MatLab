# system-reliability-truss-matlab

Systémová spolehlivostní analýza **staticky neurčitých** příhradových konstrukcí.

Na rozdíl od [`reliability-truss-matlab`](../reliability-truss-matlab) (staticky určitá příhrada —
selhání libovolného prutu = kolaps, sériový systém `g_sys = min_p g_p`), staticky neurčitá
konstrukce má redundanci: selhání jednoho prutu vede k **redistribuci sil**, nikoli nutně ke
kolapsu. Systémová spolehlivost proto vyžaduje modelování postupného selhávání (progressive
collapse) nebo enumeraci dominantních selhávacích módů (cut-sets).

**Stav: implementováno a ověřeno.** Null-space metoda (Wei & Deng 2022) pro hledání
minimálních cut-sets + Cornell index / equivalent planes / PNET (Rodrigues da Silva et al.
2024) pro výpočet systémové `Pf`. Ověřeno proti oběma zdrojovým paperům
(`β_sys ≈ 3.001` na 3-podlažní příhradě) i nezávislou brute-force progressive-collapse
Monte Carlo. Metodika viz `metodika.md`.

## Struktura

```
system-reliability-truss-matlab/
├── src/                  ← Zdrojové funkce (algoritmus systémové spolehlivosti)
├── examples/             ← Referenční příklady (staticky neurčité příhrady)
├── tests/                ← Validační testy (progressiveCollapseMCFn — nezávislý MC oracle)
├── metodika.md           ← Metodický podklad (RV, limitní funkce, algoritmus)
└── odvozeni.tex/.pdf     ← Kompletní matematické odvození Fáze A–C (důkazy Lemma 1/2, Cornell/PNET)
```

## Zdrojové soubory (`src/`)

| Funkce | Popis |
|--------|-------|
| `equilibriumMatrixFn` | Rovnovážná matice `A` a její null space `V` (SVD) |
| `nullSpaceCutSetsFn` | Hledání všech minimálních cut-sets (Lemma 1 + Lemma 2, Wei & Deng) |
| `reducedStructureInfluenceFn` | Vlivové koeficienty `b_ij`, `a_il` na redukované konstrukci |
| `sequenceLimitStateFn` | Limitní funkce sekvence selhání `g_i(d,X)` |
| `cornellIndexFn` | Cornell index `β_p` pro danou failure sequence |
| `mostProbableSequenceFn` | Nejpravděpodobnější permutace prvků cut-setu |
| `equivalentPlaneFn` | Ekvivalentní lineární performance function pro cut-set |
| `pnetSystemReliabilityFn` | PNET agregace cut-setů → `β_sys` |
| `systemReliabilityFn` | Orchestrátor celého pipeline |

## Závislosti

- `fem-truss-2d-matlab/src` — lineární FEM řešič (staticky neurčité příhrady řeší stejně jako určité)
- `reliability-truss-matlab/src` — sdílené komponenty (definice RV, CHS vlastnosti, posudek prutu)
- UQLab — Monte Carlo / Subset Simulation infrastruktura
