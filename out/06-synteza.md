# 06 — Syntéza: pět keynotes IPW 2026 vs. RBDO ocelových konstrukcí pod klimatickými zatíženími

> **Stav podkladů.** Syntéza vychází výhradně ze souborů 01–05. Ty stojí na abstraktech a úryvcích z vyhledávání. **Plný text žádné práce nebyl přečten** (síťová politika, viz 00-plan.md). Tvrzení níže jsou tedy tak silná jako úryvky, na kterých stojí. Odkazy typu „01 §2.2" vedou do příslušného souboru a sekce, kde je uveden primární zdroj. Vlastní úsudky jsou označeny **[úsudek]**.

---

## 1. Kde se přístupy překrývají

| Téma | Köhler (01) | Sudret (02) | Van Coile (03) | O'Connor (04) | Gardoni (05) |
|---|---|---|---|---|---|
| **Cílová spolehlivost / akceptace** | risk-informed kalibrace norem jako rozhodovací problém (01 §2.1, §2.3) | — (bere omezení jako dané) | LCO cíle pro požár; hierarchie akceptačních kritérií (03 §2.8) | β_t podle typu porušení a následků (DRD); β_t z life safety + ekonomické optimalizace (Diamantidis et al. 2024) (04 §E1, §F) | společenský dopad (capability approach, DII) (05 §2.6) |
| **Bayesovský update / modelová nejistota** | JCSS PMC, modely nejistot v JRC 2024 (01 §2.4–2.5) | bayesovská kalibrace (škola), denoising GP (02 §2.4) | MCMC ze standardní zkoušky → přirozený požár; cenzorovaná data (03 §2.4–2.5) | aktualizace základních veličin v EN 1990-2; APFM/DVM (04 §1, §A) | model únosnosti s korekčním členem (2002) (05 §2.1) |
| **Surrogáty / adaptivita** | — | AL framework, stochastické emulátory, RBDO bez double-loop (02 §2.1–2.7) | fyzikálně omezený surrogát teploty oceli; výběr zkoušek přes EIG (03 §2.1, §2.6) | review adaptivních metamodelů, AK-MCS (04 §B) | redukce výpočetní ceny v hierarchických/síťových modelech (05 §2.4, §2.6) |
| **Hodnota informace** | normativní teorie rozhodování (01 §2.3) | learning functions = implicitní VoI [úsudek] | explicitní EIG / economic VoI (03 §2.1) | updating z měření jako úspora nákladů (04 §E3) | — |
| **Systém vs. prvek** | prvkové návrhové rovnice (9 kombinací) (01 §2.2) | AL pro obecné systémy, RESS 2024 (02 §2.3) | prvky (deska, sloup, nosník, sklo) (03 §3) | pruty + styčníky příhradového mostu (04 §E2) | sítě, hierarchické systémy (05 §2.4, §2.6) |

**Společné jádro [úsudek]:** všech pět nahrazuje „jedno číslo z normy" pravděpodobnostním modelem, který se učí z dat: ze zkoušek (Van Coile, Gardoni), z měření (O'Connor), ze simulací (Sudret) nebo z kalibračních domén (Köhler). Liší se tím, **kdo rozhoduje** (normotvůrce, projektant, správce, region) a **o čem** (γ, návrh, zkouška, zásah, obnova).

---

## 2. Kde si protiřečí (nebo aspoň táhnou opačně)

1. **Standardizace vs. specifičnost.**
   - Köhler kalibruje γ pro *třídu* konstrukcí nad standardizovanými modely (01 §2.2).
   - Van Coile chce opustit standardní zkoušku ve prospěch výrobkově specifické adaptivní zkoušky (03 §2.4).
   - O'Connor posuzuje *konkrétní* most s aktualizovanými daty (04 §1).
   - Kalibrace γ ale předpokládá právě tu standardizaci, kterou oba rozbíjejí. Otázka 03-Q4 a 04-Q1 na to míří. **[úsudek]** Pro RBDO je to podstatné: RBDO jedné haly je v Köhlerově rámci „mimo kód" a potřebuje vlastní zdůvodnění β_t.

2. **Filozofie surrogátu: přesnost u meze vs. konzervativnost všude.**
   - Sudretova škola staví surrogáty, které jsou přesné u limitní plochy (AL) nebo ve chvostu (02 §2.1, §2.7).
   - Van Coileův sigmoidní model záměrně zavádí konzervativní bias přes asymetrickou ztrátu (03 §2.6).
   - **[úsudek]** Ve spolehlivostním omezení RBDO vede konzervativní surrogát k systematicky nadhodnocené Pf, tedy k předimenzování. Jde o dva neslučitelné cíle: fyzikální konzistenci vs. nezkreslenou Pf.

3. **PCE a dimenze.**
   - Teixeira, Nogal, O'Connor (2021) označují dimenzi za „significant threat" pro PCE a vyzdvihují AK-MCS (04 §B).
   - Moustapha & Sudret (2026) staví RBDO na PCE-založených emulátorech (GLaM/SPCE) a tvrdí, že cena je na dimenzi „z velké části necitlivá" (02 §2.7).
   - Rozpor je jen zdánlivý **[úsudek]**: Sudret staví emulátor v prostoru návrhových proměnných *d* a náhodné vstupy schovává do latentní proměnné. Právě tady se ale dá ptát, co to stojí v přesnosti chvostu (02-Q3).
   - Sudretův vlastní benchmark (2022) doporučuje PC-Kriging + SuS, tedy ne čistý Kriging (02 §2.1).

4. **Odkud se bere β_t.**
   - Normové β (Köhler rámec EN 1990, 01 §2.2).
   - Ekonomické optimum a life safety (Diamantidis 2024, 04 §F; Van Coile LCO, 03 §2.8).
   - Společenské capabilities (Gardoni, 05 §2.6).
   - Tři zdroje obecně nedávají stejné číslo. Pro RBDO musíš **explicitně zvolit a obhájit** jeden z nich.

5. **Stacionarita.**
   - Köhlerovy kalibrace i Sýkorova analýza sníh×vítr předpokládají stacionaritu (01 §2.7, §3).
   - Gardoniho SDE degradace (05 §2.5) i Larsson Ivanov et al. 2022 (01 §2.7) ukazují, že v čase se mění odolnost i zatížení.
   - Nikdo z pěti (v nalezených úryvcích) nekombinuje nestacionární zatížení s návrhem.

---

## 3. Mezera, kterou nepokrývá nikdo — a kam spadá tvoje téma

Podle doložených úryvků **nikdo z pěti** neřeší tuto kombinaci:

> **Návrh (optimalizaci) nové ocelové konstrukce s cílovou spolehlivostí na úrovni systému, pod souběžnými, vzájemně závislými a potenciálně nestacionárními klimatickými zatíženími (sníh + vítr + teplota), kde rozhodují ne-hladké limitní stavy stability a návrhové proměnné jsou diskrétní (katalog CHS).**

Rozpad podle toho, co komu chybí:

| Složka mezery | Kdo je nejblíž | Co mu chybí (dle 01–05) |
|---|---|---|
| RBDO | Sudret (02 §2.7) | kombinace zatížení v čase, diskrétní katalog, systém/stabilita, Pf ≤ 10⁻⁵ doložené |
| Model sněhu | Köhler / JCSS PMC (01 §2.5) | závislost sněhu a větru (C_e dle 2025 závisí na větru!), teplota, návrh jedné konstrukce |
| Závislost sníh–vítr | Sýkora, JCSS TUM 2024 (01 §2.7) | obsah slidů nedostupný; předpoklad stacionarity |
| Teplota (EN 1991-1-5) | **nikdo** | Van Coile řeší požár (degradace materiálu), ne klimatickou teplotu (03 §3) |
| Systémová spolehlivost | Sudret RESS 2024 (02 §2.3), Gardoni sítě (05 §2.4) | ani jeden nepracuje s vzpěrem, redistribucí a cut-sets v příhradě |
| Modelová nejistota vzpěru CHS | Gardoni 2002 (metoda) (05 §2.1) | aplikace na ocel nedoložena |
| Nestacionarita | Larsson Ivanov 2022 (kontext 01), Gardoni SDE (05) | nikdo ji nepromítá do návrhu |

**Tvoje pozice [úsudek]:** stojíš na průsečíku, kde se **Köhlerův model zatížení** (co je náhodné a jak to spolu souvisí) potkává se **Sudretovým výpočtem** (jak to efektivně optimalizovat), a přidáváš dvě věci, které nikdo z nich nemá: **systém se stabilitou** (tvůj cut-sets/PNET modul) a **třetí klimatické zatížení** (teplota). Nejsilnější argument „proč moje téma": nová EN 1991-1-3:2025 sama zavádí závislost sněhu na větru přes C_e (Thiis et al. 2022, 01 §2.7). Nezávislé kombinování sníh+vítr v RBDO je tím pádem v rozporu s normou.

---

## 4. Koho seznámit s kým a proč

> Pozor: nevím, kdo se s kým zná. Všichni jsou v JCSS, IPW a ICOSSAR komunitě a řada z nich se zná jistě. Uvádím **tematické** vazby, kde má smysl rozhovor zprostředkovat nebo na něj odkázat.

1. **Sýkora (Kloknerův ústav ČVUT) → tvůj klíč ke Köhlerovi i O'Connorovi.**
   - Sýkora je spoluautor O'Connora (Orcesi et al. 2024; Boros et al. 2021; 04 §A, §D).
   - Na JCSS workshopu v TUM 2024 přednášel o interakci sníh×vítr ve stejném bloku, kde Köhler a Sørensen mluvili o kombinačních součinitelích (01 §1, §2.7).
   - **Akce:** před konferencí nebo na ní požádej Sýkoru o představení a o jeho TUM slidy. To je nejlevnější a nejvýnosnější krok celé cesty.

2. **Köhler ↔ Sudret.**
   - Kalibrace norem (Köhler & Hingorani: doména 9 kombinací × široký rozsah zatížení; 01 §2.2) je výpočetně „RBDO nad doménou".
   - Sudretův emulátor v návrhovém prostoru (02 §2.7) by mohl kalibraci zlevnit.
   - Sudret zase potřebuje od Köhlera, jaké Pf má smysl cílit (10⁻⁶ vs. jeho příklady ~10⁻⁴; 02 §4).
   - **Ty jsi přirozený most:** používáš UQLab a zároveň modely zatížení z EN.

3. **Van Coile ↔ Sudret.**
   - EIG/VoI výběr zkoušek (03 §2.1) je formálně příbuzný active learningu.
   - Sudretova skupina už dělala bayesovskou kalibraci z pecních zkoušek (Wagner, …, Sudret; 03 zdroj #19).
   - Otevřený spor o konzervativní vs. přesný surrogát (viz §2 bod 2) je dobrý společný bod debaty.

4. **O'Connor ↔ Gardoni.**
   - Oba řeší časově proměnnou spolehlivost existující infrastruktury (O'Connor updating, Nogal resilience sítí; Gardoni SDE degradace, regionální resilience; 04 §F, 05 §2.5–2.6).
   - O'Connorův projekt RAIN (extrémní počasí a sítě; 04 §1) a Gardoniho regional multi-hazard mají přímý tematický průnik.

5. **Gardoni ↔ Köhler.**
   - Bayesovské modely únosnosti s korekčním členem (05 §2.1) jsou přesně ten typ modelové nejistoty, který JCSS PMC a kalibrace potřebují (01 §2.4).
   - Pro tebe prakticky: Gardoniho metoda + Köhlerův rámec = zdůvodněné θ_R pro vzpěr CHS.

---

## 5. Priority: na koho se zaměřit

| Pořadí | Řečník | Proč | Klíčová otázka |
|---|---|---|---|
| **1** | **Köhler** | Jediný s tématem přímo o tvém dominantním zatížení (sníh). Je prezident JCSS a nový JCSS model sněhu (01 §2.5) je pravděpodobně model, který máš převzít. Máš k němu kontakt přes Sýkoru. | 01-Q1 (sníh a vítr jako závislé procesy při nové C_e) |
| **2** | **Sudret** | Autor metody, kterou můžeš nasadit hned (UQLab v2.1: GLaM/SPCE, RBDO modul; 02 §3). Priority paper 2604.05759 řeší přesně RBDO ve vysoké dimenzi. Otázky na diskrétní katalog a systém míří na jeho slabiny. | 02-Q1 (katalog CHS) nebo 02-Q2 (systém + vzpěr, GLaM unimodální) |
| **3** | **Gardoni** | Keynote (regionální riziko) je od tebe dál. Jeho metoda z 2002 je ale nejpřímější nástroj na modelovou nejistotu vzpěru a je EiC RESS 2020–2025 (05 §1), tedy relevantní pro publikování. | 05-Q1 (imperfekce v testech vs. v populaci) |
| **4** | **O'Connor** | Hodnocení existujících mostů, doprava, tematicky vzdálenější. Užitečný pro zdůvodnění β_t podle typu porušení (vzpěr = náhlé porušení; 04 §E1). Spojení přes Sýkoru. | 04-Q5 (diferenciace β_t podle typu porušení) |
| **5** | **Van Coile** | Požár a zkoušky, nejmenší přímý průnik. Klimatická teplota ≠ požár (03 §3). VoI rámec je ale přenositelný na otázku, co měřit (sníh v lokalitě, f_y, t CHS). | 03-Q3 (konzervativní surrogát v omezení spolehlivosti) |

**[úsudek]** Pokud máš čas jen na dva delší rozhovory: Köhler (co je náhodné) a Sudret (jak to spočítat). Tito dva dohromady pokrývají celou tvou metodiku a navzájem si odhalují slabiny: Köhler nedělá návrh, Sudret nedělá model zatížení.

---

## 6. Než se zeptáš: co ověřit (otázky stojí na úryvcích)

Některé otázky v 01–05 navazují na tvrzení, která známe jen z úryvků. Před použitím je buď ověř v PDF, nebo je formuluj podmíněně („If I understood correctly…"):

| Otázka | Tvrzení, na kterém stojí | Riziko |
|---|---|---|
| 01-Q1 | C_e v EN 1991-1-3:2025 závisí na větru v sezóně (Thiis et al. 2022, abstrakt) | nízké (abstrakt), ale ověř finální znění normy |
| 01-Q3 | Köhler & Hingorani používají prvkové rovnice | nízké (abstrakt) |
| 02-Q3 | příklady Sudretovy skupiny mají Pf ~10⁻⁴ | **střední**: doloženo jen AL-SPCE, 2604.05759 neznáme |
| 02-Q5 | 2604.05759 srovnává časy, ne počty volání | **střední**: úryvky si u přesnosti odporují (02 §2.7) |
| 03-Q2 | saturace po 10–15 / 5 zkouškách | střední (úryvek) |
| 04-Q3 | nýtovaný příhradový most, pruty + styčníky | **střední**: úryvek zmiňuje i „arch bridge" (04 §E2) |
| 05-Q1 | databáze testů ŽB sloupů v 2002 | nízké (abstrakt) |

Nejvyšší prioritu má přečíst **arXiv 2604.05759** a **Köhler & Hingorani (Zenodo 8104027)**, jsou volně dostupné. Stačí je otevřít z počítače mimo tento sandbox.

---

## 7. Zdroje

Syntéza necituje nic mimo soubory 01–05; úplné seznamy zdrojů se stavem jsou na konci každého z nich. Všechny zdroje mají stav **abstrakt/úryvky**, **jen citace** nebo **nedostupné**. **Plný text: žádný.**
