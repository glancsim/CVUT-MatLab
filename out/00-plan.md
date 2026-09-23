# Plán rešerše — keynotes IPW 2026 (Padova, 24.–25. 9. 2026)

## Omezení prostředí (zjištěno 23. 9. 2026, před začátkem práce)
- Síťová politika cloudového sandboxu **blokuje přímé stahování**: arxiv.org, zenodo.org,
  sciencedirect.com, eurocodes.jrc.ec.europa.eu, uqlab.com, wikipedia, semanticscholar,
  crossref, openalex… (WebFetch → `EGRESS_BLOCKED`, curl → 403 na CONNECT).
- Funkční je pouze **WebSearch** (vyhledávač vrací titulky, URL a úryvky/shrnutí stránek).
- Složka `./pdfs/` **neexistuje** — žádné lokální PDF.
- Důsledek: **žádná práce nemohla být přečtena v plném textu.** Stav zdrojů se proto
  značí jako:
  - `úryvky (WebSearch)` — abstrakt / části textu z výsledků vyhledávání, neověřeno v PDF,
  - `jen citace` — známo jen z odkazů jinde,
  - `NEDOSTUPNÉ` — nenalezeno nic věrohodného.
- Čísla převzatá z úryvků jsou označena; kde úryvek nic neříká, text to přizná a nedomýšlí.
- Pro plnou verzi: povolit v nastavení prostředí širší síťový přístup (nebo domény výše),
  případně nahrát PDF do `./pdfs/` a rešerši zopakovat.

## Kontext uživatele (pro sekce „průsečík")
Doktorand K132 FSv ČVUT; disertace: RBDO ocelových konstrukcí pod kombinovanými klimatickými
zatíženími (sníh, vítr, teplota). V repozitáři už existuje:
- `reliability-truss-matlab/` — Monte Carlo (UQLab) staticky určité příhrady, G + S
  (vítr zatím v reliability modelu **není**), EN 1991-1-3 parametrizace sněhu (C_e, C_t, μ₁),
- `system-reliability-truss-matlab/` — systémová spolehlivost staticky neurčitých příhrad
  (null-space cut-sets, Cornell / equivalent planes / PNET),
- `en-truss-design-matlab/` — deterministický posudek EN 1993-1-1 + 5 KZS,
- `WindModel/` — analýza větrných maxim.

## Postup (po řečnících)
| # | Řečník | Soubor | Priorita zdrojů |
|---|--------|--------|-----------------|
| 1 | J. Köhler (NTNU/JCSS) — sníh | `01-kohler.md` | Köhler-Sørensen-Ellingwood 2024; reliability 2. generace EC; JRC 2024; Köhler & Baravalle 2019; EN 1991-1-3:2025 vs 2003 |
| 2 | B. Sudret (ETH) — active learning | `02-sudret.md` | **Moustapha & Sudret 2026 (arXiv 2604.05759)**; survey 2106.01713; Pires et al. 2025; GLaM, SPCE; UQLab implementace |
| 3 | R. Van Coile (UGent) — adaptive fire testing | `03-van-coile.md` | Franchini & Van Coile 2025 FSJ; ERC AFireTest 101075556; surrogate teplot chráněné oceli |
| 4 | A. O'Connor (TCD) — existující mosty | `04-oconnor.md` | Orcesi et al. 2024 SEI; Teixeira-Nogal-O'Connor 2021 StrSaf |
| 5 | P. Gardoni (UIUC) — regional risk | `05-gardoni.md` | Gardoni-Der Kiureghian-Mosalam 2002; RESS 241/247/251 (2024) |
| 6 | Syntéza | `06-synteza.md` | překryvy/rozpory, mezera, networking, priority |

Každý soubor: kdo je → práce (problém, metoda, výsledky s čísly, přiznaná omezení) →
průsečík s disertací → 3–5 konkrétních otázek → seznam zdrojů se stavem.

## Průběh (doplněno po dokončení)
- Všech 5 rešerší proběhlo paralelně (1 agent = 1 řečník), každá jen přes WebSearch.
- Během práce se vyčerpal **sdílený limit 200 vyhledávání na session**. Poslední dotazy
  u všech řečníků proto neproběhly. Co zůstalo neověřené, je v každém souboru výslovně uvedeno.
- Program IPW 2026 (dicea.unipd.it/ipw-2026-padova/agenda) potvrzuje keynotes Köhler,
  Sudret, O'Connor a Gardoni. Van Coile v nalezených úryvcích programu nebyl dohledán.
  Úryvek u Sudreta uvádí termín workshopu 23.–25. 9. 2026, což je nutné ověřit.
- Co číst jako první, až bude přístup k plným textům: 06-synteza.md §6.
