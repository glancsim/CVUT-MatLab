# Bruno Sudret (ETH Zürich) – rešerše pro IPW 2026

> **UPOZORNĚNÍ – stav zdrojů.** Plné texty (arXiv PDF/HTML, ScienceDirect, uqlab.com, ETH Research Collection) **nebyly přečteny**: WebFetch/curl jsou blokované síťovou politikou prostředí. Vše níže vychází z **úryvků a souhrnů vyhledávače (WebSearch)**. Ty jsou generované a místy si odporují (upozorňuji na to u konkrétních míst). Čísla označená „(úryvek, neověřeno v PDF)“ je před citováním nutné ověřit v PDF. Vyhledávání skončilo po vyčerpání session limitu (200 dotazů, sdílený s ostatními agenty), takže některé věci zůstaly nedohledané. Jsou označené jako NEDOSTUPNÉ.
>
> Legenda stavu: **PT** = plný text (nikde) · **Ú** = abstrakt/úryvky · **C** = jen citace/bibliografie · **N** = NEDOSTUPNÉ.

---

## 1. Kdo je Sudret a co reálně ovlivňuje

- **Pozice:** profesor Risk, Safety and Uncertainty Quantification na ETH Zürich od roku 2012. Dříve působil jako research engineer pro strukturální spolehlivost v EDF R&D (Moret-sur-Loing), jako postdok na UC Berkeley (CEE) a jako directeur de recherche v Laboratoire Navier (ENPC/IFSTTAR/CNRS). Jeho výzkum: výpočetní metody UQ, spolehlivost, citlivostní analýza, bayesovská kalibrace a RBDO. (Zdroj: sudret.ibk.ethz.ch – CV a profil; úryvek.)
- **UQLab:** projekt vznikl v roce 2013 spolu se založením katedry. Cílem bylo „sebrat desetiletí výzkumu do jednoho nástroje“ (uqlab.com/about; úryvek). **UQLab 2.0 vyšel 1. 2. 2022 jako plně open source**, bez rozlišení akademických a komerčních uživatelů a bez nutnosti připojení k internetu (uqlab.com/release-notes; úryvek). Pro uživatele to je nejpřímější vliv: metody z jeho skupiny se do UQLabu dostávají typicky za 1–3 roky od publikace.
- **Škola (autoři relevantních prací):**
  - M. Moustapha (active learning, RBDO; autor AL a RBDO modulů UQLabu),
  - S. Marelli (spoluzakladatel UQLabu),
  - X. Zhu (GLaM, SPCE; vývoj stochastických emulátorů v UQLabu),
  - N. Lüthen (dokumentace SPCE),
  - A. V. Pires (stochastické a šumové limitní funkce),
  - P. Parisi (systémová spolehlivost).
  (Zdroj: uqlab.com/contributors, release notes, autorské řádky prací; úryvky.)
- **Ovlivňuje:** de facto standard benchmarkování active-learning reliability (survey 2022, 20 problémů × 39 strategií), modulární pojetí AL a RBDO a v posledních letech agendu **stochastických simulátorů** (emulace celé podmíněné distribuce výstupu).
- **Keynote IPW 2026:** „Active learning methods for structural reliability analysis of deterministic and stochastic systems“. Z abstraktu (dicea.unipd.it/ipw-2026-padova/agenda; úryvek) je známé toto:
  - AL iterativně obohacuje experimentální plán v oblastech blízko limitní plochy,
  - keynote „nejprve předloží sjednocený pohled na AL pro deterministické systémy“,
  - druhá část (stochastické systémy) se z úryvku nedala přečíst (N). Obsahově lze čekat linii Pires 2024 → 2025 → AL-SPCE 2025 (moje inference).
  - Workshop podle úryvku probíhá 23.–25. 9. 2026. Uživatel uvádí 24.–25., rozdíl je nutné ověřit v programu.

---

## 2. Práce

### 2.1 Moustapha, Marelli, Sudret (2022): *Active learning for structural reliability: Survey, general framework and benchmark*
- **Bibliografie (ověřeno ve více úryvcích):** Structural Safety **96**, 102174 (2022). arXiv:2106.01713. Stav: **Ú**.
- **Problém:** AL metod je mnoho, ale chybí společný rámec a férové srovnání.
- **Metoda:** modulární rámec se čtyřmi nezávislými bloky:
  - metamodel,
  - spolehlivostní metoda,
  - learning function,
  - stopping criterion.

  Prototypem je starší konferenční práce „A global framework for active learning reliability in UQLab“ (Moustapha, Marelli, Sudret). Úryvek ji řadí na ICOSSAR v Šanghaji a „září 2017“. To si protiřečí: 13. ICOSSAR v Šanghaji se konal 2021/22 [obecná znalost, neověřeno]. Rok je nutné ověřit.
- **Výsledky (úryvek, neověřeno v PDF):**
  - benchmark tvoří **20 problémů** (z toho 11 z TNO benchmarku) a **39 AL strategií**,
  - **PC-Kriging + subset simulation** vychází „obecně nejlépe“,
  - surrogaty v „overkill“ nastavení jsou lepší než přímé metody bez surrogatu.
- **Přiznaná omezení:** z úryvků **nejsou známa** (N). Zejména není doloženo, co autoři píší o vysoké dimenzi, velmi malých Pf a systémech.

### 2.2 Moustapha & Sudret (2019): *Surrogate-assisted RBDO: a survey and a unified modular framework*
- **Bibliografie:** Struct. Multidisc. Optim. **60**, 2157–2176 (2019), doi:10.1007/s00158-019-02290-y. arXiv:1901.03311 (preprint má podtitul „…a new general framework“). Stav: **Ú**.
- **Metoda:** RBDO jako tři nezávislé, vzájemně neintruzivní bloky: adaptivní surrogát, spolehlivostní analýza a optimalizace (úryvek Springer).
- **Výsledky a čísla:** N (úryvky neobsahovaly benchmarková čísla).
- **Omezení:** N.

### 2.3 Moustapha, Parisi, Marelli, Sudret (2024): *Reliability analysis of arbitrary systems based on active learning and global sensitivity analysis*
- **Bibliografie:** Reliab. Eng. Syst. Saf. **248**, 110150 (2024). arXiv:2305.19885. Stav: **Ú** (pouze abstrakt).
- **Problém:** systémová spolehlivost s více limitními funkcemi (sériové, paralelní i obecné systémy).
- **Metoda:** subset simulation + Kriging/PC-Kriging s obohacovacím schématem, které podle abstraktu cíleně řeší slabiny této třídy metod. Název zmiňuje i globální citlivostní analýzu, podrobnosti jsou N.
- **Relevance:** **přímo** navazuje na uživatelovy cut-sets + PNET (viz sekci 4).
- **Výsledky a omezení:** N.

### 2.4 Pires, Moustapha, Marelli, Sudret (2024): *Reliability analysis for data-driven noisy models using active learning*
- **Bibliografie:** Structural Safety, 2024 (ScienceDirect S0167473024001140; úryvek uvádí listopad 2024). **Číslo ročníku a článku nebylo ověřeno.** Vyhledávač napsal „volume 102“, což je zjevně chybná interpretace. arXiv:2401.10796, Zenodo 14186960. Stav: **Ú**.
- **Problém:** limitní funkce je zatížená šumem (nedeterministický simulátor nebo data-driven model). FORM/SORM jsou přitom stavěné na deterministické modely.
- **Metoda:** GP regrese s odšumováním (denoising) + **noise-aware learning function**. Cílem je Pf **podkladového bezšumového** modelu.
- **Příklady:** benchmarkové funkce + „FE model realistického rámu“ (úryvek). Čísla: N.
- **Omezení:** N.

### 2.5 Pires, Moustapha, Marelli, Sudret (2025): *Reliability analysis for non-deterministic limit-states using stochastic emulators*
- **Bibliografie:** Structural Safety **117**, 102621 (2025), pp. 1–14. arXiv:2412.13731. ETH report RSUQ-2024-011A. Stav: **Ú**.
- **Problém:** simulátor je sám stochastický: opakovaný běh se stejnými vstupy dává jiný výstup. Motivací je větrná turbína: aeroelastický model je deterministický, ale buzení je 10min náhodné pole větru dané makroparametry (střední rychlost, turbulence). Přímé MCS je proto nepraktické.
- **Metoda:** stochastické emulátory **GLaM** a **SPCE** umožňují levný výpočet **podmíněné funkce pravděpodobnosti poruchy** Pf(x). SPCE mapuje latentní náhodnou proměnnou na cílovou podmíněnou distribuci přes PCE. Ilustrační příklad je modifikovaný stochastický R–S s latentními proměnnými.
- **Výsledky (úryvek, neověřeno v PDF):**
  - emulátory dávají přesné Pf „i v režimu malých dat, N ≤ 1 000“,
  - box-ploty jsou konzistentně užší než u přímého MCS se stejným počtem plných simulací, tedy nižší rozptyl odhadu,
  - v jednom příkladu vystupují velikosti ED N = {500; 5 000; 50 000}.
- **Přiznaná omezení:** navazující práce AL-SPCE (2.6) v abstraktu uvádí, že současné metody „stále vyžadují velké trénovací sady pro přesné odhady spolehlivosti, což omezuje praktičnost“. To je nepřímé přiznání omezení 2.5.

### 2.6 Pires, Moustapha, Marelli, Sudret (2025): *AL-SPCE – Reliability analysis for nondeterministic models using SPCE and active learning*
- **Bibliografie:** arXiv:2507.04553 (6. 7. 2025). Podle úryvku „submitted to Structural Safety“, stav publikace je N. Stav: **Ú**.
- **Metoda:** active learning nad SPCE pro stochastické simulátory.
- **Výsledky jednoho příkladu (úryvek, neověřeno v PDF):**
  - referenční Pf = 7,511·10⁻⁴ (MCS s 10⁸ vzorky, CoV ≈ 0,5 %),
  - 15 nezávislých běhů,
  - při 250 vzorcích dává AL-SPCE medián Pf 6,399·10⁻⁴ s CoV 11,1 %,
  - statický ED se stejným počtem vzorků dává 8,879·10⁻⁴ s CoV 69,0 %.
- **Omezení:** N. Poznámka k číslům: medián AL-SPCE při 250 vzorcích je stále ~15 % pod referencí (můj výpočet z úryvkových čísel).

### 2.7 Moustapha & Sudret (2026): *High-dimensional RBDO using stochastic emulators* — PRIORITA
- **Bibliografie:** arXiv:**2604.05759**, podáno 7. 4. 2026, kategorie stat.CO/stat.ME/stat.ML. Předchůdce: konferenční příspěvek „Reliability-based design optimization for high-dimensional problems using stochastic emulators“ (2025) v ETH Research Collection, handle 20.500.11850/745059. Konference ani čísla v něm nejsou známé (N). Stav: **Ú** (abstrakt + fragmenty sekcí přes souhrny vyhledávače).
- **Problém:** RBDO je vnořená úloha (optimalizace × spolehlivost). I se surrogaty je ve vysoké dimenzi neúnosná, protože klasický surrogát (Kriging) se staví v plném prostoru návrhových i náhodných proměnných.
- **Metoda (abstrakt + úryvky):**
  1. Deterministická limitní funkce g(d, X) a nejistoty vstupů X se sloučí do **jednoho stochastického simulátoru**, jehož **jediným explicitním vstupem je návrhový vektor d** („stochasticization“). Nejistota vstupů se přesune do latentního prostoru.
  2. V **prostoru návrhových proměnných** se natrénuje stochastický emulátor (**GLaM** nebo **SPCE**) podmíněné distribuce odezvy Y | d.
  3. Pf(d) nebo kvantil se z emulátoru počítají **semi-analyticky, bez MCS**.
  4. Tím vznikne **deterministické zobrazení d → omezení spolehlivosti**, což **rozbíjí double-loop**. Pak stačí standardní deterministický optimalizátor.
  - SPCE zavádí umělou latentní proměnnou a šumový člen kvůli numerické stabilitě. GLaM používá GLD, jejíž parametry jsou PCE vstupů.
- **Příklady:** abstrakt uvádí jen „benchmarky s dimenzí od nízké po velmi vysokou, včetně případu se **stochastickým buzením**“. Srovnává se s **Kriging-based přístupem formulovaným v plném vstupním prostoru**. Konkrétní dimenze a identitu příkladů se ověřit nepodařilo (N). Jeden souhrn vyhledávače zmínil „10-bar truss“ a jiný „wind turbine, earthquake, tornado“, oba však zjevně míchají jiné zdroje. **Nepoužívat bez ověření.**
- **Výsledky (úryvek, neověřeno v PDF):**
  - efektivita je srovnatelná s Krigingem v nízké dimenzi a s rostoucí dimenzí je výrazně lepší (to je přímo v abstraktu),
  - konvergence trvá „zlomky sekund ve všech příkladech“, zatímco Kriging ve vysokodimenzionálním případě potřebuje „téměř 100 s“,
  - Kriging je silně citlivý na dimenzi i složitost modelu, cena emulátorového přístupu je na dimenzi „z velké části necitlivá“ a na složitosti surrogátu závisí jen slabě,
  - velikosti ED 100/300/500: GLaM a SPCE doběhnou pod 1 s, jsou o ≥ 1 řád rychlejší než Kriging a „rychlejší i než MC double-loop s původním modelem“. Úspora vůči Kriging double-loop je „2–3 řády“.
  - Pozor, **tyto časy jsou čas optimalizace a surrogátu, ne počet volání modelu.** Počty volání drahého modelu se z úryvků zjistit nepodařilo (N).
- **Přesnost – ROZPOR v úryvcích:**
  - (a) „Kriging poskytuje téměř dokonalou aproximaci pro všechny velikosti vzorku, zatímco GLaM/SPCE jsou méně přesné v jádru distribuce, ale lépe sedí v chvostech → dostatečně přesné Pf a kvantily“,
  - (b) „Kriging konzistentně selhává v reprodukci správných podmíněných distribucí pro všechny velikosti ED“.
  - Pravděpodobně jde o různé příklady nebo veličiny. **Ověřit v PDF.**
- **Přiznaná omezení:** z úryvků vyplývá jediné nepřímé přiznání, a to **nižší přesnost GLaM/SPCE v jádru distribuce** (viz a). Ostatní omezení jsou N. Z externích zdrojů:
  - GLaM je podle UQLab features „omezen na unimodální stochastické odezvy“ (uqlab.com/features; úryvek),
  - skupina z jiné instituce (arXiv:2608.05006, GSS-SPCE pro performance-based risk optimization, návrh ploch BRB prutů 2podlažní ocelové budovy) uvádí, že SPCE „není specificky navrženo k přesné reprezentaci chvostu“ a má potíže při malém počtu dat u velkých prahů poškození. To je **kritika třetí strany, ne přiznání autorů.**

### 2.8 Zhu & Sudret – původní práce ke stochastickým emulátorům (stav **C/Ú**)
| Práce | Bibliografie | Hlavní myšlenka |
|---|---|---|
| Replication-based emulation … using generalized lambda distributions | IJUQ **10**(3), 249–275, 2020; arXiv:1911.09067 | GLD s parametry jako PCE vstupů, trénuje se s **replikacemi** (opakovanými běhy v témže bodě) |
| Emulation of stochastic simulators using generalized lambda models | SIAM/ASA JUQ **9**(4), 1345–1380, 2021; doi:10.1137/20M1337302; arXiv:2007.00996 | GLaM: parametry GLD jako PCE vstupů, podle navazujících citací **bez nutnosti replikací** |
| Global sensitivity analysis for stochastic simulators based on GLaM | arXiv:2005.01309 (časopis neověřen) | GSA stochastických simulátorů přes GLaM |
| Stochastic polynomial chaos expansions to emulate stochastic simulators | IJUQ **13**(2), 31–52, 2023; arXiv:2202.03344 | SPCE: latentní proměnná + šumový člen v PCE, bez parametrického tvaru, zvládne i **multimodální** odezvy |
| MF-GLaM (multifidelity GLaM) | CMAME 2025 (S0045782525007704); arXiv:2507.10303 | víceúrovňová (multifidelity) varianta GLaM |

---

## 3. Co je v UQLabu

| Metoda | Modul UQLab | Stav / verze | Zdroj |
|---|---|---|---|
| PCE, Kriging, PC-Kriging | Metamodelling (PCE, Kriging, PCK) | dlouhodobě dostupné [obecná znalost, neověřeno] | uqlab.com/user-manuals; manuál PC-Kriging (ResearchGate) |
| SVR / SVC | Support vector machines | uvedeno v release notes. Úryvek je spojuje s 2.0, ale přesná verze je nejistá | uqlab.com/release-notes (úryvek) |
| Active learning reliability (modulární AL, asynchronní učení) | Reliability → Active learning | manuál **UQLab-V2.0-117 (2022)**. Verze prvního zavedení je N | Moustapha/Marelli/Sudret, manuál; release notes (úryvek) |
| Line sampling | Reliability | přidáno ve **v2.1** | release notes (úryvek) |
| RBDO | Reliability-based design optimization | manuál **UQLab-V2.1-115 (2024)**. Existoval i manuál 2019, modul tedy pochází z řady 1.x (verze N) | uqlab.com/rbdo-user-manual (úryvek) |
| GLaM | Stochastic emulators → GLaM | součást v2.1.0 (citace v MF-GLaM). Release notes: „omezeno na unimodální odezvy, (semi-)analytické podmíněné rozdělení a kvantily“. Verze zavedení (2.0 vs. 2.1) je nejistá | uqlab.com/features, release-notes (úryvek) |
| SPCE | Stochastic emulators → SPCE | manuál **UQLab-V2.1-121 (2024)**, Lüthen, Zhu, Marelli, Sudret. Zvládá multimodální odezvy bez replikací | uqlab.com/spce-user-manual (úryvek) |
| Stochastic spectral embedding, Random fields | SSE, RF | nové ve **v2.0 (2022)** | release notes (úryvek) |
| Systémová spolehlivost AL (Moustapha 2024) | ? | **N** – nezjištěno, zda je implementováno | — |
| AL-SPCE, noisy-AL (Pires) | ? | **N** – nezjištěno | — |
| Stochastické emulátory v RBDO (2026) | ? | **N**. Z úryvků není známo, zda je v RBDO modulu | — |

Datum vydání v2.1 se nepodařilo zjistit (N). Podle manuálů spadá do roku 2024.

---

## 4. Průsečík s tématem uživatele (RBDO příhradových CHS vazníků, sníh + vítr + teplota)

**Co lze použít:**
1. **Klimatické zatížení jako „vnitřní náhodnost“ stochastického simulátoru (2.5, 2.7).** Analogie z Pires 2025: turbína = deterministický model + stochastické buzení. U haly platí FEM příhrady (deterministický) + náhodný sníh, vítr a teplota. Můžeš je schovat do latentního prostoru a emulovat Y | d, tedy rozdělení využití nebo rezervy pro návrh d (průřezy skupin CHS). V UQLabu to jde přes moduly GLaM/SPCE hned (v2.1).
2. **RBDO na průřezy (2.7).** Návrhové proměnné jsou D, t symetrických skupin: po expanzi 3–4 základních skupin až ~11 skupin, tj. ~22 spojitých proměnných. Náhodných proměnných je výrazně víc: zatížení, f_y, E, imperfekce, případně pro každý prut zvlášť. Právě tady má dle abstraktu výhodu přístup, který staví surrogát jen v d-prostoru.
3. **Systémová spolehlivost (2.3).** AL se subset simulation a PC-Kriging pro obecné systémy je přímý konkurent nebo doplněk k vlastnímu cut-sets + PNET. Stojí za srovnání na staticky neurčité příhradě.
4. **Benchmark metodika (2.1).** Pro volbu AL v UQLabu je výchozí doporučení PC-Kriging + SuS (úryvek).

**Co metody (dle dostupných úryvků) nepokrývají nebo nedokládají:**
- **Diskrétní návrhové proměnné (katalog CHS).** 2.7 staví na spojitém d a deterministickém optimalizátoru. Diskrétní výběr z katalogu není v úryvcích zmíněn (N). Relaxace + zaokrouhlení nemusí zachovat Pf.
- **Více limitních funkcí se stabilitou.** 2.7 mluví o „reliability constraint“. Zda emulátor pokrývá **systém** (min přes pruty; vzpěr vs. tah; lokální vs. globální stabilita), není doloženo. Min přes mnoho limitních funkcí je **ne-hladký**, což může narušit PCE-parametrizaci GLD i unimodalitu (GLaM je unimodální).
- **Časově proměnná zatížení a jejich kombinace.** Stochastické buzení v 2.7 je jeden příklad (identita N). Kombinace sníh × vítr × teplota (Turkstra, Ferry-Borges–Castanheta) a extrémy za referenční dobu úryvky neřeší.
- **Vysoké β ≈ 3,8–4,7 (EN 1990, RC2, 50 let / 1 rok).** Doložené příklady mají Pf ~10⁻⁴ (AL-SPCE: 7,5·10⁻⁴, tj. β ≈ 3,2). Pro Pf ~10⁻⁵–10⁻⁶ je rozhodující kvalita **chvostu**. Tu u SPCE kritizuje třetí strana (arXiv:2608.05006) a samotné úryvky 2.7 přiznávají horší přesnost v jádru (rozpor viz 2.7).
- **Epistemická nejistota surrogátu.** GLaM/SPCE dávají bodový odhad Pf(d). Zda je k dispozici i nejistota odhadu pro řízení AL v RBDO, není z 2.7 známo (N). AL-SPCE ji zřejmě řeší pro analýzu, ne pro RBDO.

---

## 5. Otázky na Sudreta (EN + proč)

1. *In the 2026 arXiv paper (2604.05759) you turn the limit-state g(d, X) into a stochastic simulator whose only input is the design vector d, and optimise with a deterministic solver. How does this carry over to discrete design variables, e.g. choosing tube sections from a standard CHS catalogue? Can the emulator of Y | d be trusted between the catalogue points, or does rounding the relaxed optimum break the reliability constraint?*
   — Uživatel navrhuje z katalogu. Metoda stojí na hladké spojité mapě d → Pf.

2. *In a truss, failure is really a system event: the minimum over dozens of member checks, where compression members fail by buckling and tension members by yielding. That minimum is non-smooth and may be multimodal. GLaM is restricted to unimodal responses. Does the stochastic-emulator RBDO handle system-level constraints, or does it need one emulator per limit state? How would it fit with your 2024 RESS work on system reliability (subset simulation + PC-Kriging)?*
   — Jde přímo na uživatelovu systémovou spolehlivost a stabilitu (vzpěr).

3. *The benchmarks in AL-SPCE and in the 2025 Structural Safety paper reach Pf around 10⁻⁴. Code calibration targets β around 3.8 to 4.7, i.e. Pf down to 10⁻⁶. Other authors (arXiv:2608.05006) report that SPCE is not designed to capture the tails. What would you change in the emulator, or in the active-learning criterion, to control the tail accuracy at such targets?*
   — Normové úrovně spolehlivosti; navazuje na Köhlerovu kalibraci.

4. *For climatic actions (snow, wind and temperature as load combinations over the reference period), would you put the time-variant load process into the latent variables of the stochastic simulator, or keep the extreme-value load models as explicit random inputs? What does each choice mean for which reliability you actually compute: annual, 50-year, or conditional on the design?*
   — Kombinace a časová proměnnost zatížení; úryvky 2.7 zmiňují jen jeden případ se „stochastic excitation“.

5. *Your comparison with Kriging in 2604.05759 reports wall-clock times: fractions of a second versus about 100 s. How many runs of the expensive model do GLaM and SPCE need in the design space, compared with Kriging in the full input space? And does the stochastic-emulator approach also support adaptive enrichment, like AL-SPCE, inside RBDO?*
   — Úryvky dávají čas, ne počet volání FEM, což je pro drahý FEM+stabilitu to podstatné.

---

## 6. Zdroje a stav

| # | Zdroj | URL | Stav |
|---|---|---|---|
| 1 | Moustapha, Marelli, Sudret 2022, Struct. Saf. 96, 102174 | https://arxiv.org/abs/2106.01713 ; https://www.sciencedirect.com/science/article/pii/S0167473021000965 | Ú |
| 2 | Moustapha & Sudret 2019, SMO 60:2157–2176 | https://link.springer.com/article/10.1007/s00158-019-02290-y ; https://arxiv.org/pdf/1901.03311 | Ú |
| 3 | Moustapha, Parisi, Marelli, Sudret 2024, RESS 248, 110150 | https://arxiv.org/abs/2305.19885 | Ú (abstrakt) |
| 4 | Pires et al. 2024, Struct. Saf. (ročník N) | https://arxiv.org/abs/2401.10796 ; https://www.sciencedirect.com/science/article/pii/S0167473024001140 | Ú |
| 5 | Pires et al. 2025, Struct. Saf. 117, 102621 | https://arxiv.org/abs/2412.13731 ; https://www.sciencedirect.com/science/article/pii/S0167473025000499 | Ú |
| 6 | Pires et al. 2025, AL-SPCE | https://arxiv.org/abs/2507.04553 | Ú |
| 7 | Moustapha & Sudret 2026, high-dim RBDO | https://arxiv.org/abs/2604.05759 ; https://arxiv.org/html/2604.05759 | Ú (fragmenty) |
| 8 | Moustapha & Sudret 2025, konferenční předchůdce | https://www.research-collection.ethz.ch/handle/20.500.11850/745059 | C |
| 9 | Zhu & Sudret 2020, IJUQ 10 | https://arxiv.org/abs/1911.09067 | C/Ú |
| 10 | Zhu & Sudret 2021, SIAM/ASA JUQ 9(4) | https://doi.org/10.1137/20m1337302 ; https://arxiv.org/pdf/2007.00996 | C/Ú |
| 11 | Zhu & Sudret 2023, IJUQ 13(2) | https://arxiv.org/abs/2202.03344 | C/Ú |
| 12 | MF-GLaM (CMAME 2025) | https://arxiv.org/pdf/2507.10303 | C |
| 13 | GSS-SPCE (třetí strana, kritika chvostu SPCE) | https://arxiv.org/html/2608.05006 | Ú |
| 14 | UQLab release notes / features / manuály (AL, RBDO, SPCE) | https://www.uqlab.com/release-notes ; https://www.uqlab.com/features ; https://www.uqlab.com/rbdo-user-manual ; https://www.uqlab.com/spce-user-manual | Ú |
| 15 | Sudret CV / profil | https://sudret.ibk.ethz.ch/the-chair/people/prof-dr-bruno-sudret/curriculum-vitae.html ; https://www.uqlab.com/about | Ú |
| 16 | IPW 2026 program (abstrakt keynote, jen 1. část) | https://dicea.unipd.it/ipw-2026-padova/agenda | Ú (částečně N) |
| 17 | „A global framework for AL reliability in UQLab“ (ICOSSAR, rok sporný) | https://www.researchgate.net/publication/372958736 | C |

**NEDOSTUPNÉ:**
- jakýkoli plný text,
- dimenze a identita příkladů v 2604.05759 a počty volání modelu,
- omezení přiznaná v sekcích Conclusions,
- ročník Pires 2024,
- verze zavedení GLaM, AL a RBDO modulů a datum v2.1,
- druhá část abstraktu keynote.
