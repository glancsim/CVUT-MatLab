# system-reliability-truss-matlab

Systémová spolehlivostní analýza **staticky neurčitých** příhradových konstrukcí.

Na rozdíl od [`reliability-truss-matlab`](../reliability-truss-matlab) (staticky určitá příhrada —
selhání libovolného prutu = kolaps, sériový systém `g_sys = min_p g_p`), staticky neurčitá
konstrukce má redundanci: selhání jednoho prutu vede k **redistribuci sil**, nikoli nutně ke
kolapsu. Systémová spolehlivost proto vyžaduje modelování postupného selhávání (progressive
collapse) nebo enumeraci dominantních selhávacích módů (cut-sets).

> **Stav: ve vývoji.** Struktura složek založena dle `reliability-truss-matlab`. Metodika a
> implementace budou doplněny — viz `metodika.md`.

## Struktura

```
system-reliability-truss-matlab/
├── src/                  ← Zdrojové funkce (algoritmus systémové spolehlivosti)
├── examples/             ← Referenční příklady (staticky neurčité příhrady)
├── tests/                ← Validační testy
└── metodika.md           ← Metodický podklad (RV, limitní funkce, algoritmus)
```

## Závislosti

- `fem-truss-2d-matlab/src` — lineární FEM řešič (staticky neurčité příhrady řeší stejně jako určité)
- `reliability-truss-matlab/src` — sdílené komponenty (definice RV, CHS vlastnosti, posudek prutu)
- UQLab — Monte Carlo / Subset Simulation infrastruktura
