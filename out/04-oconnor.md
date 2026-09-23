# Alan O'Connor (TCD): příprava na keynote IPW 2026

**Keynote:** „Probabilistic Analysis and Reliability-Based Assessment of Existing Bridges“, IPW 2026, Padova, 24.–25. 9. 2026.

> **Upozornění ke zdrojům.** Síťová politika blokuje WebFetch/curl (jeden kontrolní pokus na hal.science skončil `EGRESS_BLOCKED`). **Žádný plný text jsem nečetl.** Všechno níže pochází z úryvků vyhledávání (abstrakty, anotace vydavatelů, profilové stránky). Kromě toho se v průběhu práce vyčerpal sdílený rozpočet vyhledávání session (200/200). Proto zůstaly některé linie neověřené (klima × infrastruktura, abnormální vozidla, detaily příspěvku o dopravním zatížení z IABSE 2021). U každého bodu uvádím stav zdroje: **abstrakt/úryvek**, **jen citace**, nebo **NEDOSTUPNÉ**.

---

## 1. Kdo to je a co reálně ovlivňuje

- Na TCD vede Chair of Structural Engineering (Dept. of Civil, Structural & Environmental Eng.) a je vedoucím School of Engineering. Profesorskou inaugurační přednášku „Spanning the Void: The Trials and Triumphs of a Bridge Engineer“ měl 3. 4. 2025 (úryvek, [TCD news](https://www.tcd.ie/engineering/news/2025/professor-alan-oconnor-delivers-inaugural-lecture-spanning-the-void-the-trials-and-triumphs-of-a-bridge-engineer/)).
- Oficiální oborový profil zní: „risk and resilience analysis of critical infrastructure, asset lifecycle performance optimisation, code development/calibration and probabilistic safety assessment“ (úryvek, [IPW agenda](https://dicea.unipd.it/ipw-2026-padova/agenda), [TCD profil](https://www.tcd.ie/civileng/people/academic-staff-/oconnoaj/)).
- **Praxe a normy:**
  - Je spoluzakladatelem ROD Innovative Solutions (ROD-IS, od 2009). Firmu založil s E. O'Brienem (UCD) a konzultantem Roughan & O'Donovan. Zaměřuje se na komerční aplikace výzkumu bezpečnosti mostů (úryvek, [Irish Times](https://www.irishtimes.com/business/retail-and-services/future-proof-eugene-o-brien-rod-innovative-solutions-1.1702843)).
  - S I. Enevoldsenem (Rambøll) pracoval na dánské směrnici pro pravděpodobnostní hodnocení mostů. Úryvek ji označuje za „first of its kind in the world“ (viz práce E).
- **EU projekty:** Byl koordinátorem FP7 **RAIN** (Risk Analysis of Infrastructure Networks in response to extreme weather). Rozpočet 4,77 mil. €, 15 organizací, 8 zemí; tematicky kaskádové hazardy a časově závislá zranitelnost (úryvek, [TCD TRIP](https://www.tcd.ie/transport-research/our-research/research-projects/Risk-Planning-for-Infrastructure-Networks/), [CORDIS 608166](https://cordis.europa.eu/project/id/608166/reporting)). Účast v dalších projektech (INFRARISK, SAFE-10-T, SAFEWAY…) jsem **neověřil**, vyhledávání ji nepotvrdilo.
- **Metriky:** Google Scholar má podle úryvku 5 062 citací a ResearchGate 195 publikací (úryvek, neověřeno, čísla se mění).
- **Čím reálně ovlivňuje obor (moje syntéza z výše uvedeného):**
  1. Kalibrace zatížení dopravou z WIM dat pro hodnocení existujících mostů.
  2. Převod pravděpodobnostního hodnocení do praxe správců (Dánsko).
  3. Normotvorba pro existující konstrukce přes IABSE TG1.3.
  4. Resilience sítí (s M. Nogal).
  5. Surrogate/adaptivní metody spolehlivosti (s R. Teixeirou).

**Obsah keynote podle abstraktu** (úryvek, [IPW agenda](https://dicea.unipd.it/ipw-2026-padova/agenda)):
- Hodnocení bezpečnosti „from first principles“.
- Rámec **prEN 1990 Part 2** pro hodnocení existujících konstrukcí na základě spolehlivosti.
- Vazba na implementaci řízenou správcem: **směrnice dánského Roads Directorate z roku 2024** pro hodnocení existujících mostů na základě spolehlivosti.
- Pravděpodobnostní modelování odolnosti, zatížení, modelové nejistoty a módů porušení, včetně běžné dopravy i abnormálních/těžkých vozidel.

**Normový kontext:** EN 1990-2:2026 („Assessment of existing structures“) vyšla 19. 3. 2026 a nahrazuje CEN/TS 17440:2020. Obsahuje principy průzkumu, aktualizace základních veličin a modelů a ověřovací techniky. Neobsahuje pravidla pro zahájení hodnocení ani materiálově specifická pravidla (úryvek, [iTeh](https://standards.iteh.ai/catalog/standards/cen/7e6834b2-a6f0-4053-866c-7d2117f86bf8/en-1990-2-2026), [BSI](https://knowledge.bsigroup.com/products/eurocode-basis-of-structural-and-geotechnical-design-assessment-of-existing-structures)). Konkrétní hodnoty β_t v EN 1990-2 jsem **nezjistil** (NEDOSTUPNÉ).

---

## 2. Práce

### A. Orcesi, Diamantidis, O'Connor, Palmisano, **Sýkora**, Boros, Caspeele, Chateauneuf, Mandić Ivanković, Lenner, Kušter Marić, Nadolski, Schmidt, Skokandić, Van der Spuy (2024)
**„Investigating Partial Factors for the Assessment of Existing Reinforced Concrete Bridges“**, *Structural Engineering International* 34(1), 55–70, DOI [10.1080/10168664.2023.2204115](https://doi.org/10.1080/10168664.2023.2204115). Open access kopie existuje na [HAL hal-05032466](https://hal.science/hal-05032466), ale fetch byl blokovaný.

- **Stav:** abstrakt/úryvky. Plný text NEDOSTUPNÝ.
- **Kontext:** Je to výstup **IABSE TG1.3 „Calibration of Partial Safety Factors for the Assessment of Existing Bridges“**, ne TG1.1. **M. Sýkora (Kloknerův ústav ČVUT)** je spoluautor, jde o přímou lokální vazbu (úryvek, [T&F abs](https://www.tandfonline.com/doi/abs/10.1080/10168664.2023.2204115), [IABSE TG1.3](https://iabse.org/TG1.3)).
- **Problém:** Cílem je formát dílčích součinitelů pro existující mosty, který umí zohlednit dodatečné informace o materiálu, zatížení a lokálních defektech. Zároveň má vyvážit konzervativnost, aby se neinvestovalo zbytečně do výměny nebo zesílení (úryvek abstraktu).
- **Metoda:**
  - Úryvek zmiňuje *design value method* (DVM) a *adjusted partial factor method* (APFM) z fib Bulletin 80, aplikované v případových studiích TG1.3. DVM dává základ pro odvození dílčích součinitelů, APFM dává úpravové faktory k součinitelům pro nové konstrukce dle EN 1990 (úryvek z vyhledávání k TG1.3/fib 80).
  - **Pozor:** z úryvku nelze jednoznačně poznat, zda to popisuje tuto SEI práci, nebo související studii [Gino et al. 2020, Structural Concrete](https://onlinelibrary.wiley.com/doi/abs/10.1002/suco.201900231). Ta aplikuje fib 80 na předpjatý most ze 90. let v severní Itálii. Úryvek uvádí, že v TG1.3 byly řešeny „two bridge case studies“.
- **Klíčové výsledky:**
  - Z úryvku: pokud se návrhové modely odolnosti upraví pro hodnocení existujících konstrukcí, musí se kvantifikovat jejich nejistota a podle ní upravit materiálový součinitel.
  - Konkrétní čísla (γ_M, β_t, CoV) **NEDOSTUPNÁ**.
- **Přiznaná omezení:** NEDOSTUPNÉ, bez plného textu je nedokládám.

### B. Teixeira, Nogal, O'Connor (2021)
**„Adaptive approaches in metamodel-based reliability analysis: A review“**, *Structural Safety* 89, 102019, DOI [10.1016/j.strusafe.2020.102019](https://doi.org/10.1016/j.strusafe.2020.102019), open access (CC).

- **Stav:** abstrakt a úryvky.
- **Problém:** Adaptivní metamodelování ve spolehlivosti je roztříštěné a jednotlivé techniky spolu málo interagují. Pro praktika je proto těžké vybrat metodu (úryvek abstraktu, [ScienceDirect](https://www.sciencedirect.com/science/article/pii/S0167473020300989), [TU Delft portal](https://research.tudelft.nl/en/publications/adaptive-approaches-in-metamodel-based-reliability-analysis-a-rev)).
- **Metoda:** Review čtyř rodin metamodelů: response surfaces, PCE, SVM a Kriging. Obsahuje teorii, srovnávací diskusi aplikací a faktory ovlivňující efektivitu adaptivity (úryvek abstraktu).
- **Klíčová zjištění (dle úryvků):**
  - Adaptivní Kriging (pionýrské AK-MCS) dává velmi efektivní poměr mezi přesností a počtem vyhodnocení funkce.
  - U PCE je dimenze d „significant threat“ pro efektivitu.
  - Autoři chtějí review jako „first step for the unification of the field“, aby se výzkum netříštil do stále užších linií.
- **Přiznaná omezení:** Nad rámec zmínky o dimenzi u PCE jsou NEDOSTUPNÁ.
- **Navazující práce (jen citace/abstrakt):**
  - Teixeira, Nogal, O'Connor, Martinez-Pastor (2020): „Reliability assessment with density scanned adaptive Kriging“, *RESS* 199. Kandidátní body learning funkcí tvoří husté shluky; density scanning je identifikuje, paralelizuje výpočty a omezuje tvorbu shluků v DoE (abstrakt, [ideas.repec](https://ideas.repec.org/a/eee/reensy/v199y2020ics0951832019307434.html)).
  - „Reliability analysis using a multi-metamodel complement-basis approach“, *RESS* 205 (jen citace).
  - Kriging pro únavu věží offshore VE, *Int. J. Fatigue* 125 (2019) 454–467 (úryvek, [ScienceDirect](https://www.sciencedirect.com/science/article/abs/pii/S0142112319301355)).
  - Aplikační doménou těchto prací jsou offshore VE, ne mosty. O'Connor je zde spoluautor, tahounem je Teixeira.

### C. O'Connor & O'Brien (2005)
**„Traffic load modelling and factors influencing the accuracy of predicted extremes“**, *Can. J. Civ. Eng.* 32(1), 270–278, DOI [10.1139/l04-092](https://doi.org/10.1139/l04-092).

- **Stav:** abstrakt.
- **Problém:** Normové deterministické modely zatížení dopravou jsou konzervativní. Při návrhu to příliš nevadí, ale **při hodnocení to může být kritické** (abstrakt).
- **Metoda:** Simulace dopravy ze statistik WIM a citlivostní studie.
- **Výsledky:** Studie zkoumá, jak extrém ovlivňuje přesnost dat, délka záznamu a metoda predikce extrému. Hodnocení založená na WIM jsou „generally accepted as less conservative“ (abstrakt). Čísla NEDOSTUPNÁ.
- **Související (abstrakt):** Enright & O'Brien (2013), *SIE* 9(12). Výsledky MC simulace extrémů jsou citlivé na předpoklady o hmotnostech vozidel, počtu náprav, rozvorech a mezerách ([T&F](https://www.tandfonline.com/doi/abs/10.1080/15732479.2012.688753)). O'Connor zde **není** autorem.

### D. Boros, Lenner, O'Connor, Orcesi, Schmidt, van der Spuy, **Sýkora** (2021)
**„Traffic loads for the assessment of existing bridges“**, IABSE Congress Ghent, 22.–24. 9. 2021.

- **Stav:** jen citace. Obsah NEDOSTUPNÝ; úryvek říká pouze, že jde o podskupinu TG1.3 pro aktualizaci zatížení dopravou ([Structurae](https://structurae.net/en/literature/conference-paper/traffic-loads-for-the-assessment-of-existing-bridges), [RG](https://www.researchgate.net/publication/353761355_Traffic_loads_for_the_assessment_of_existing_bridges)).
- Je to druhá práce se Sýkorou.

### E. Dánská linie (O'Connor, Enevoldsen a spol.)

**E1: „Probability-based assessment of highway bridges according to the new Danish guideline“**, *Structure and Infrastructure Engineering* 5(2), 2009 ([T&F](https://www.tandfonline.com/doi/abs/10.1080/15732470601022955)).
- **Stav:** abstrakt.
- Popisuje směrnici DRD, podle úryvku první svého druhu na světě. Obsahuje principy modelování nejistot včetně modelových. Požadavek bezpečnosti v MSÚ je stanoven **podle typu porušení a jeho následků**.
- Hodnotu β_t / p_f jsem **nedoložil** (NEDOSTUPNÉ).

**E2: O'Connor, Pedersen, Gustavsson, Enevoldsen (2009): „Probability-Based Assessment and Optimised Maintenance Management of a Large Riveted Truss Railway Bridge“**, *SEI* 19(4) ([T&F](https://www.tandfonline.com/doi/abs/10.2749/101686609789847136)).
- **Stav:** abstrakt.
- **Ocelový nýtovaný příhradový most.** Pravděpodobnostní modely MSÚ pro pruty i nýtované styčníky. EVD zatížení vlakem se odvozují z počtu vagonů na kritické délce příčinkové čáry.
- **Výsledek (kvalitativní):** vyšší „load rating“ kritických prvků/styčníků než deterministicky. Úryvek zároveň mluví o „steel arch bridge“, takže typologie není z úryvku jasná.
- **Omezení:** NEDOSTUPNÁ.

**E3: Enevoldsen (2011): „Practical implementation of probability based assessment methods for bridges“**, *SIE* 7(7–8) ([T&F](https://www.tandfonline.com/doi/abs/10.1080/15732479.2010.496992)).
- **Stav:** abstrakt.
- Úryvek jmenuje jen Enevoldsena, spoluautorství O'Connora nepotvrzuje.
- Výsledky konzistentně ukazují vyšší load ratings a „considerable financial savings“, bez čísel.

**E4: Směrnice DRD 2024** (na tu odkazuje keynote).
- **Stav:** obsah NEDOSTUPNÝ.
- K prosincové směrnici 2024 z projektu dánských zatěžovacích zkoušek existuje jen nepřímý úryvek: target load se volí tak, aby zkouška prokázala dostatečnou spolehlivost, a několik mostů bylo překlasifikováno na vyšší kapacitu ([T&F 2026](https://www.tandfonline.com/doi/full/10.1080/15732479.2026.2647031)).
- Není jisté, zda jde o tutéž směrnici, kterou O'Connor zmiňuje.

### F. Doplňkové, související s komunitou TG1.3 a JCSS
- **Diamantidis, Tanner, Holický, Madsen, Sýkora (2024)**, „On reliability assessment of existing structures“, *Structural Safety* ([ScienceDirect](https://www.sciencedirect.com/science/article/abs/pii/S0167473024000237)).
  - **Stav:** abstrakt. O'Connor není autor, ale jde o normotvorné zázemí (JCSS) a o dva autory z ČVUT/KÚ.
  - Závěry abstraktu:
    - Bayesovská aktualizace umožňuje zahrnout všechny nejistoty a výsledky zkoušek.
    - **Cílová spolehlivost má vycházet z bezpečnosti osob a ekonomické optimalizace.**
    - Praxe potřebuje rozšířené normové vodítko.
- **Nogal, O'Connor, Caulfield, Martinez-Pastor (2016)**, „Resilience of traffic networks: From perturbation to recovery via a dynamic restricted equilibrium model“, *RESS* ([ScienceDirect](https://www.sciencedirect.com/science/article/abs/pii/S0951832016302915)).
  - **Stav:** abstrakt.
  - Index resilience je založen na nákladech cesty a „stress level“ uživatelů. Existuje i varianta pro extrémní počasí (2015).

---

## 3. Průsečík s disertací (RBDO ocelových CHS vazníků, sníh/vítr/teplota)

**Co lze použít:**
1. **Rozlišení β_t pro nové a existující konstrukce.**
   - Keynote staví na EN 1990-2, práce A na úpravě dílčích součinitelů pro existující konstrukce.
   - Pro RBDO nových hal to přímo neplatí. Hodí se ale jako argument, co je „rezerva“ nového návrhu a jak ji normy záměrně dělí mezi nejistotu a ekonomii.
   - Diamantidis et al. 2024 doporučují β_t z life safety a ekonomické optimalizace. To je přímá opora pro volbu β_t v RBDO.
2. **Formát DVM/APFM (fib 80).** Nabízí most mezi jeho Monte Carlo výsledky a deterministickým posudkem EN 1993-1-1. Umožňuje zpětně odvodit „ekvivalentní γ“ pro optimalizovaný vazník.
3. **Surrogate reliability (práce B).** AK-MCS má podle review velmi dobrý poměr přesnosti a počtu volání. Obecně to podporuje nasazení adaptivního Krigingu (UQLab) místo hrubého MC v RBDO smyčce. Problém dimenze u PCE je relevantní, protože RBDO s mnoha skupinami průřezů (až 11 skupin v `trussHallInputFn`) plus klimatické veličiny rychle zvyšuje d.
4. **Systémové chování příhrad (E2).** Pravděpodobnostní hodnocení **ocelové příhrady** s MSÚ zvlášť pro pruty a styčníky je nejbližší analogie k jeho cut-set/PNET modulu. Úryvek ale neříká nic o systémové spolehlivosti; zda šlo o prvkové β, nebo o systém, je NEDOSTUPNÉ.
5. **Modelování extrémů zatížení z měřených dat (C).** Metodická analogie ke sněhu a větru (EVD, délka záznamu, citlivost extrému na metodu). Otázky přesnosti dat a délky záznamu jsou přenositelné.

**Co nepokrývá:**
- **Zatížení:** Linie O'Connora je doprava (WIM, vlaky, abnormální vozidla). Kombinace klimatických zatížení (sníh + vítr + teplota, Turkstra/Ferry Borges–Castanheta) v nalezených pracích **není**. RAIN řeší extrémní počasí na úrovni sítí a resilience, ne kombinaci zatížení na prvek.
- **Návrh vs. hodnocení:** Všechny jeho práce míří na hodnocení existujících konstrukcí a aktualizaci. RBDO ani optimalizaci průřezů jsem u něj nenašel. „Asset lifecycle performance optimisation“ je údržba, ne topologie nebo dimenzování.
- **Typologie:** Mosty (ŽB, předpjaté, ocelové nýtované), ne haly s CHS vazníky. Stabilita a vzpěr jako mód porušení se v úryvcích nezmiňuje.
- **Surrogate:** Review B je metodický přehled bez vazby na mosty nebo normy. Aplikace týmu jsou offshore VE.

---

## 4. Otázky pro diskusi

1. **(k práci A, APFM/DVM):** *"In the TG1.3 work, the adjusted partial factor method modifies EN 1990 partial factors for existing bridges. If a new steel roof truss is designed directly by RBDO to a target β, is there a consistent way to back-calculate equivalent partial factors from the optimum, and would you expect them to fall below the EN 1993 values the way the assessment factors do?"*
   Proč: Testuje, zda je jejich rámec obousměrný (hodnocení i návrh). Míří na to, co metoda neřeší, tedy optimalizaci.
2. **(k práci C a keynote, extrémy z dat):** *"Your 2005 paper showed that the predicted traffic extreme depends on the length of the WIM record and on the prediction method. For climatic actions — ground snow, wind, temperature — the records are typically 30–60 years and non-stationary under climate change. How does the prEN 1990-2 / Danish framework treat load-model non-stationarity, or is stationarity assumed for the remaining working life?"*
   Proč: Klima vs. doprava je hlavní mezera. Nestacionarita se v nalezených pracích neobjevila.
3. **(k E1/E2, systém vs. prvek):** *"In the riveted truss railway bridge assessment, limit states were modelled separately for members and riveted joints. Was the classification based on the weakest element's β, or on a system reliability measure? In a statically indeterminate truss, how does the Danish guideline account for redundancy and post-buckling load redistribution?"*
   Proč: Navazuje na jeho cut-set/PNET práci. Z úryvku není jasné, zda řešili systém. Vzpěr tlačených prutů je u hal dominantní.
4. **(k práci B, dimenze a normový kontext):** *"Your review with Teixeira and Nogal flags dimensionality as a major threat to PCE and positions adaptive Kriging (AK-MCS) as highly efficient. In a reliability-based assessment under prEN 1990-2, which requires a defensible Pf near 10⁻⁵–10⁻⁶, what convergence or stopping criterion would you accept from an adaptive surrogate as sufficient evidence for a code-compliant decision?"*
   Proč: Spojuje jeho dvě linie (surrogates a normy), které v úryvcích spolu nejsou propojené. Hodnoty Pf jsou jen ilustrační a formulované podmíněně.
5. **(k Diamantidis et al. 2024 / keynote, β_t):** *"The JCSS-based view is that target reliability should follow from life safety and economic optimisation. For a lightweight roof where snow dominates and failure is sudden (buckling of compression chords), would you differentiate β_t by failure type — ductile vs. brittle, warning vs. no warning — as the Danish guideline does by 'failure type and consequence'?"*
   Proč: Dánská směrnice podle úryvku diferencuje β_t podle typu porušení. To je přímo aplikovatelné na vzpěr pásů v RBDO.

---

## 5. Zdroje a jejich stav

| # | Zdroj | Stav |
|---|-------|------|
| 1 | IPW 2026 agenda (abstrakt keynote): https://dicea.unipd.it/ipw-2026-padova/agenda | úryvek |
| 2 | Orcesi et al. 2024, SEI 34(1): https://doi.org/10.1080/10168664.2023.2204115 ; HAL https://hal.science/hal-05032466 | abstrakt/úryvek; PDF blokováno |
| 3 | IABSE TG1.3: https://iabse.org/TG1.3 | úryvek |
| 4 | Teixeira, Nogal, O'Connor 2021, Struct. Saf. 89: https://doi.org/10.1016/j.strusafe.2020.102019 | abstrakt/úryvky |
| 5 | Teixeira et al. 2020, RESS 199 (density scanned AK): https://ideas.repec.org/a/eee/reensy/v199y2020ics0951832019307434.html | abstrakt |
| 6 | Teixeira et al. 2019, IJ Fatigue 125: https://www.sciencedirect.com/science/article/abs/pii/S0142112319301355 | úryvek |
| 7 | O'Connor & O'Brien 2005, CJCE 32(1): https://doi.org/10.1139/l04-092 | abstrakt |
| 8 | Enright & O'Brien 2013, SIE 9(12): https://www.tandfonline.com/doi/abs/10.1080/15732479.2012.688753 | abstrakt |
| 9 | Boros et al. 2021, IABSE Ghent: https://structurae.net/en/literature/conference-paper/traffic-loads-for-the-assessment-of-existing-bridges | jen citace |
| 10 | Danish guideline, SIE 5(2) 2009: https://www.tandfonline.com/doi/abs/10.1080/15732470601022955 | abstrakt |
| 11 | O'Connor et al. 2009, SEI 19(4), nýtovaný příhradový most: https://www.tandfonline.com/doi/abs/10.2749/101686609789847136 | abstrakt |
| 12 | Enevoldsen 2011, SIE 7(7–8): https://www.tandfonline.com/doi/abs/10.1080/15732479.2010.496992 | abstrakt |
| 13 | Směrnice DRD 2024 | NEDOSTUPNÉ (jen nepřímý úryvek: https://www.tandfonline.com/doi/full/10.1080/15732479.2026.2647031) |
| 14 | Diamantidis et al. 2024, Struct. Saf.: https://www.sciencedirect.com/science/article/abs/pii/S0167473024000237 | abstrakt |
| 15 | Gino et al. 2020, Struct. Concrete (fib 80): https://onlinelibrary.wiley.com/doi/abs/10.1002/suco.201900231 | úryvek |
| 16 | Nogal et al. 2016, RESS: https://www.sciencedirect.com/science/article/abs/pii/S0951832016302915 | abstrakt |
| 17 | RAIN (FP7 608166): https://cordis.europa.eu/project/id/608166/reporting ; https://www.tcd.ie/transport-research/our-research/research-projects/Risk-Planning-for-Infrastructure-Networks/ | úryvek |
| 18 | EN 1990-2:2026: https://standards.iteh.ai/catalog/standards/cen/7e6834b2-a6f0-4053-866c-7d2117f86bf8/en-1990-2-2026 | úryvek (anotace) |
| 19 | TCD profil / inaugurace: https://www.tcd.ie/civileng/people/academic-staff-/oconnoaj/ ; https://www.tcd.ie/engineering/news/2025/professor-alan-oconnor-delivers-inaugural-lecture-spanning-the-void-the-trials-and-triumphs-of-a-bridge-engineer/ | úryvek |
| 20 | ROD-IS: https://www.irishtimes.com/business/retail-and-services/future-proof-eugene-o-brien-rod-innovative-solutions-1.1702843 | úryvek |
| 21 | Publikační seznam https://www.tcd.ie/research/profiles/?profile=oconnoaj | NEDOSTUPNÉ (nefetchováno; linie odvozeny z vyhledávání) |
| 22 | Linie klima × infrastruktura, abnormální vozidla, další EU projekty | NEOVĚŘENO (vyčerpán rozpočet vyhledávání) |
