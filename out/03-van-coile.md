# Ruben Van Coile (Ghent University): rešerše ke keynote „From Standardised to Adaptive Fire Testing" (IPW 2026, Padova)

> **UPOZORNĚNÍ K ZDROJŮM.** Plné texty jsem nečetl. Síťová politika prostředí blokuje přímý přístup na sciencedirect, cordis, biblio.ugent.be, researchgate, arXiv a další weby, fungovalo jen vyhledávání (WebSearch). Všechno níže tedy vychází z **úryvků ve výsledcích vyhledávání** (abstrakty, anotace, metadata). Čísla mají značku „(úryvek, neověřeno v PDF)". Během rešerše se vyčerpal limit vyhledávání pro celou session (200/200), takže některé plánované dotazy neproběhly. U dotčených položek píšu, co chybí.
> Značení stavu zdroje: **PT** = plný text (nikde), **Ú** = úryvek nebo abstrakt, **C** = jen citace/metadata, **N** = NEDOSTUPNÉ.

---

## 1. Kdo je a co reálně ovlivňuje

- Dříve pracoval jako structural fire engineer ve WSP (Londýn) a jako postdok na University of Edinburgh. Od října 2017 působí na Ghent University (výzkum, služby průmyslu, výuka). Od roku 2019 vede tým **SFE@UGent**, který se zaměřuje na pravděpodobnostní a rizikové metody ve structural fire engineering. Zdroj: SFPE Europe Issue 30 a profil laboratoře (Ú), https://www.sfpe.org/publications/periodicals/sfpeeuropedigital/sfpeeurope30/europeissue30feature3, https://www.researchgate.net/lab/SFE-UGent-Ruben-Van-Coile
- Podle SFPE Europe je **pravděpodobně první zástupce fire safety engineering, který získal ERC Starting Grant** (Ú, tamtéž).
- Je spoluzakladatelem spin-offu **Pyro Engineering** (performance-based structural fire engineering) (Ú, tamtéž).
- Na ResearchGate má titul „Professor (Associate)" a vzdělání PhD & MSc Civil Eng., LL.B. a PostGraduate Fire Safety Engineering (C, https://www.researchgate.net/profile/Ruben-Van-Coile). Právní vzdělání (LL.B.) je v souladu s tím, že ve svých pracích řeší akceptační kritéria a odpovědnost projektanta (viz §3.6).
- **Reálný vliv.** (a) Metodika pravděpodobnostního průkazu požární bezpečnosti a cílových úrovní spolehlivosti pro požár, tj. LCO a akceptační kritéria, spolu s D. Hopkinem, T. Gernayem a N. Elhami-Khorasani. (b) Od roku 2023 program AFireTest, který chce změnit roli požárních zkoušek (od klasifikace k informačně optimalizovaným zkouškám). Jeho zapojení do CEN TC250 nebo revize EN 1991-1-2/EN 1993-1-2 jsem **nedoložil**, vyhledávání k tomu nic nevrátilo.
- Vazba na IPW: jeho tým publikoval na **21. IPW (2025)**: Peng, Franchini, Jovanović, Van Coile, „Exploiting invalid test results for assessing the distribution of glazing fracture strength", ce/papers 2025 (Ú, https://onlinelibrary.wiley.com/doi/abs/10.1002/cepa.3342).
- Program IPW 2026 s názvem keynote jsem vyhledáváním **nenašel** (N). Název přebírám ze zadání.

---

## 2. Práce a projekty

### 2.1 Franchini & Van Coile, „Quantifying the expected utility of fire tests and experiments before execution", Fire Safety Journal
- **Stav:** Ú (abstrakt a anotace z vyhledávání). PT nedostupný.
- **Bibliografie:** online vyšlo v roce 2025 (dle úryvku „September 2025"). biblio.ugent.be uvádí **vol. 159 (2026)**. Uvádím obojí, protože se liší rok online verze a rok ročníku. URL: https://www.sciencedirect.com/science/article/pii/S0379711225002024, https://biblio.ugent.be/publication/01KAEVPSYC8YEEJH65P15KJ092
- **Problém:** Zkoušky se dnes plánují bez toho, aby se předem vyčíslilo, co přinesou. Utilitu je podle autorů třeba kvantifikovat **před provedením**, s využitím existující znalosti o jevu, a to ve veličinách odpovídajících cíli dat: klasifikace výrobku, snížení nejistoty parametrů, minimální LCC, menší environmentální dopad (Ú).
- **Metoda:** Rámec staví na **Bayesian experimental design** (preposterior analysis). Připouští různé metriky utility: **expected information gain (EIG)**, **economic value of information (VoI)** a „environmental benefit of information". Tyto metriky mají „explicitně propojit laboratorní zkoušky se systémovými ukazateli" (bezpečnost, riziko, resilience, environmentální dopad) (Ú).
- **Výsledky (úryvek, neověřeno v PDF):**
  - Opakované zkoušky na kónickém kalorimetru (čas vznícení): informační zisk **se saturuje po 10–15 zkouškách**.
  - Druhá ukázka: **zjednodušená VoI analýza**, která porovnává dvě metody posouzení železobetonových konstrukcí po požáru.
- **Přiznaná omezení:** v úryvcích **nedoložena**. Z abstraktu jen vyplývá, že strukturální ukázka je „simplified" VoI analýza. Výpočetní náklady EIG (vnořené MC), volba prioru a citlivost na model zde nejsou dohledatelné (N).

### 2.2 Franchini & Van Coile, „Guiding adaptive fire testing through expected information gain", ICOSSAR'25 (Los Angeles)
- **Stav:** Ú. https://biblio.ugent.be/publication/01K1B9MTY0H8ZYHHDVGNXJF7RK
- **Metoda a výsledek:** Předběžná verze rámce z 2.1. EIG odhaduje, jak počet opakování sníží nejistotu predikce času vznícení. Případová studie je bench-scale flammability test (Ú).
- **Omezení:** N.

### 2.3 „How to make optimal use of your fire tests for performance-based design", 16th SFPE Conf. on PBD (2026)
- **Stav:** Ú. Autoři podle přehledu z vyhledávání Franchini & Van Coile (C). https://biblio.ugent.be/publication/01KQZFHE1FW04PGE6CC9JQBW3N
- **Metoda:** Virtuální simulace a **pre-posterior analýza** kvantifikují očekávanou utilitu každé zkoušky. Protokol se iterativně zpřesňuje.
- **Výsledek (úryvek, neověřeno v PDF):** „**beyond five furnace tests, additional testing provides negligible improvement**". Zkušební kampaň lze tedy optimalizovat předem. Jaká veličina a jaký konstrukční prvek se hodnotily, z úryvku nevyplývá.
- **Omezení:** N.

### 2.4 ERC StG AFireTest, „Adaptive Fire Testing: A new foundation stone for fire safety" (GA 101075556)
- **Stav:** Ú (CORDIS fact sheet přes úryvky). https://cordis.europa.eu/project/id/101075556, výsledky: https://cordis.europa.eu/project/id/101075556/results
- **Parametry:** podpis 8. 12. 2022, **trvání 1. 9. 2023 až 31. 8. 2028**, **příspěvek EU 1 500 000 €**, hostitel Ghent University (Ú).
- **Problém:** Současné paradigma požární bezpečnosti stojí na standardizovaných zkouškách z preskriptivního rámce. Ty neposkytují hlubší porozumění požárnímu chování výrobků (Ú). V tomto rámci ISO 834 představuje „pseudo-worst-case" expozici (viz 2.5).
- **Cíl a metoda:** „Adaptive Fire Testing". Optimální zkouška se vybírá z nekonečné množiny možných specifikací podle **maximálního očekávaného čistého informačního zisku (VoI)** a zkoušky se přizpůsobí konkrétnímu výrobku a jeho použití (Ú). Plánovaná případová studie se týká **moderního zasklení a nosného skla** (Ú, CORDIS).
- **Výstupy dohledané přes CORDIS/biblio (C/Ú):** 2.1–2.3; Peng et al. 2025 (IPW, ce/papers) a navazující článek „Incorporating invalid test results in glass fracture strength determination", Glass Struct. & Eng. 2026 (https://link.springer.com/article/10.1007/s40940-026-00331-9). Ten ukazuje, že neplatné výsledky zkoušek (lom mimo vnitřní kruh u co-axial double ring testu, norma žádá ≥ 30 platných) jsou **cenzorovaná data** využitelná bayesovským updatem (Ú). Dále „In-thickness absorption in soda-lime-silica glazing…" (2024) (C), „Adaptive fire testing: is design-optimized fire testing the future?" (C, https://biblio.ugent.be/publication/01K7EFVAS29Y4K9C5CHTY255J2), „AFireTest – Towards fully quantified fire performance" (C, https://biblio.ugent.be/publication/01K7EVJKY49ZWCFQTMXTEYSGED), „The role of furnace testing for performance-based design and future regulations" (C, https://biblio.ugent.be/publication/01KZ693MAX2BN02F775GCSKZ64) a „On the uncertainty of flashover correlations and its effect on risk assessment", FSJ 2026 (C, https://www.sciencedirect.com/science/article/pii/S037971122600127X).
- **Podcast:** Fire Science Show ep. 080 (C). https://www.firescienceshow.com/080-adaptive-fire-testing-a-new-foundation-stone-for-fire-safety-erc-stg-grant-with-ruben-van-coile/
- **Omezení:** N. Průběžná zpráva (periodic report) nebyla dostupná.

### 2.5 „Maximizing information obtained from standardized fire tests using a Bayesian framework" (předchůdce AFireTest)
- **Stav:** Ú. Vyšlo v **Acta Polytechnica CTU Proceedings** (repozitář ČVUT, https://dspace.cvut.cz/handle/10467/106388) a je i v biblio UGent (https://biblio.ugent.be/publication/8769846). Autory a rok jsem vyhledáváním nepotvrdil (limit), jde pravděpodobně o ASFE/IFireSS v Praze, ale to **neověřeno**.
- **Metoda:** Selhání prostě podepřené ŽB desky ve standardní zkoušce se modeluje a určí se parametry, které řídí čas porušení. **MCMC** aktualizuje jejich rozdělení z naměřené požární odolnosti. S posteriorními rozděleními se pak plně pravděpodobnostně spočte pravděpodobnost porušení při **přirozeném požáru** (Ú).
- **Význam:** Ze standardní zkoušky se inverzně získá informace a ta se přenese do jiného scénáře. To je jádro myšlenky „from standardised to adaptive".
- **Omezení:** N. Příklad je jediný prvek z betonu.

### 2.6 Yarmohammadian, Jovanović, Van Coile, „Sigmoid-based regression for physically informed temperature prediction of fire-exposed protected steel sections", ICOSSAR'25
- **Stav:** Ú. https://www.researchgate.net/publication/392771574
- **Problém:** Rychlá predikce **maximální teploty chráněné oceli** při fyzikálně založeném požáru, použitelná v pravděpodobnostním návrhu.
- **Metoda:** Datovou sadu **3 000 požárních scénářů** generuje Eurocode parametric fire curve s **lumped-mass přístupem**, tedy krokovou metodou typu EN 1993-1-2 [obecná znalost, neověřeno]. Vstupy jsou rozměry úseku, hustota požárního zatížení a vlastnosti izolace. Mezi prediktory patří max. teplota požární křivky a čas jejího dosažení. Model má omezený sigmoidní výstup a penalizační ztrátovou funkci, která cílí na konzervativní predikce (Ú).
- **Výsledky (úryvek, neověřeno v PDF):** Black-box modely (regularizovaná lineární regrese, NN) dosahují R² ≈ 0,99 (NN), ale jsou **fyzikálně nekonzistentní**: predikují teplotu oceli vyšší než teplota požáru. Lineární regrese je rychlá a přesná při velkých datech. Sigmoidní model inherentně respektuje fyzikální meze a je robustní i při **omezeném množství dat**.
- **Přiznaná omezení (z úryvku):** Implicitní je nekonzistence black-box modelů a závislost lineární regrese na velkých datech. Model predikuje **jen maximum teploty**, ne časový průběh, a platí jen v doméně EPFC + lumped mass. To vyplývá z popisu, výslovně přiznáno to v úryvku není.

### 2.7 Chaudhary, Van Coile, Gernay, „Potential of Surrogate Modelling for Probabilistic Fire Analysis of Structures", Fire Technology 57 (2021) 3151–3177
- **Stav:** Ú (abstrakt). https://link.springer.com/article/10.1007/s10694-021-01126-w
- **Problém:** Výpočet konstrukce za požáru je drahý i pro jednoduché modely, proto chtějí ML surrogát pro rychlou pravděpodobnostní analýzu a iterace návrhu (Ú).
- **Metoda:** Proof-of-concept na analytickém nelineárním modelu únosnosti ŽB desky a na numerickém modelu ŽB sloupu (Ú).
- **Výsledky a omezení:** N (čísla v úryvku nebyla).

### 2.8 Pravděpodobnostní průkaz, cílová spolehlivost, LCO
- **Hopkin, Fu, Van Coile, „Adequate fire safety for structural steel elements based upon life-time cost optimization", FSJ, 2020, č. 103095.** Ú, https://www.sciencedirect.com/science/article/abs/pii/S0379711220300631. Počítají fragility křivky chráněných ocelových nosníků (Pf jako funkce středního požárního zatížení, tloušťky izolace, stupně zatížení a využití). Při flashoveru použijí EPFC, jinak travelling fires. LCO pak dává optimální tloušťku izolace pro open-plan kancelář. Rámec je PD 7974-7:2019, kde PRA dokládá tolerovatelnost a ALARP. Čísla a omezení: N.
- **Van Coile & Hopkin (2018), „Target safety levels for insulated steel beams exposed to fire, based on Lifetime Cost Optimisation".** Ú, zřejmě Acta Polytechnica CTU Proceedings 2022 (DOAJ, https://doaj.org/article/fee1e0b6bdbc4093986433609db4570f, nepotvrzeno). Motivace: **chybějící jasné cílové úrovně spolehlivosti pro požár brzdí pravděpodobnostní návrh**. Model zahrnuje pravděpodobnost vzniku požáru, úspěšného potlačení a porušení a náklady sanace (Ú).
- **Van Coile, Hopkin, Lange, Jomaas, Bisby (2019), „The Need for Hierarchies of Acceptance Criteria for Probabilistic Risk Assessments in Fire Engineering", Fire Technology 55(4) 1111–1146.** Ú, https://link.springer.com/article/10.1007/s10694-018-0746-7. Tvrdí, že PRA je nutná tam, kde se nelze opřít o kolektivní zkušenost profese (neobvyklé návrhy). Nejasný je vztah absolutních, komparativních a ALARP kritérií i odpovědnost projektanta. Navrhují „objektivní proxy" přiměřené bezpečnosti a uznávají, že „acceptable safety" je subjektivní a v čase proměnná (Ú).
- **Van Coile, Balomenos, Pandey, Caspeele (2017), „An Unbiased Method for Probabilistic Fire Safety Engineering, Requiring a Limited Number of Model Evaluations", Fire Technology 53(5) 1705–1744.** C, abstrakt nedostupný. Podle úryvku řeší, že MCS je pro nelineární požární modely příliš drahá.
- **Gernay, Van Coile, Elhami Khorasani et al. (2019), „Efficient uncertainty quantification method applied to structural fire engineering computations", Eng. Struct. 183, 1–17.** C.
- **Qureshi, Ni, Elhami Khorasani, Van Coile, Hopkin, Gernay (2020), „Probabilistic Models for Temperature-Dependent Strength of Steel and Concrete", J. Struct. Eng. 146(6).** C, https://doi.org/10.1061/(asce)st.1943-541x.0002621.
- **Van Coile, Caspeele, Taerwe: globální součinitel odolnosti pro burnout ŽB desek** (C/Ú). Podle úryvku kalibrovaný globální součinitel umožní explicitní spolehlivostní návrh bez plně pravděpodobnostního výpočtu. Téma „adjusted partial safety factors for fire" pro ocel **nedohledáno** (N).
- **Reprodukovatelnost pecí:** Van Coileova práce k rozptylu standardní zkoušky **nedohledána** (N). Našel jsem jen obecnou kritiku standardních pecí jako „poorly controlled and variable" (MDPI Fire 6(1):5, review, https://www.mdpi.com/2571-6255/6/1/5, Ú). Ta není od něj.

---

## 3. Průsečík s disertací (RBDO CHS vazníků pod sníh, vítr, teplota)

**Co může použít**
1. **EIG/VoI před provedením (2.1–2.3) jako obecný nástroj.** Formálně je to totéž, co potřebuje při rozhodování, co měřit nebo zpřesnit. Například zda doplnit data o sněhu nebo větru v lokalitě, zda zkoušet f_y nebo tloušťky CHS stěn, nebo zda kalibrovat modelovou nejistotu vzpěru. Na utilitu „economic VoI" lze napojit RBDO cenovou funkci. Výsledky typu „saturace po 10–15 / 5 zkouškách" jsou dobrý argument pro plánování vlastních zkoušek (např. vzpěr CHS prutů).
2. **Cenzorovaná data přes bayesovský update (glass, 2.4).** Přímo přenosné na neplatné nebo nedoběhnuté zkoušky (run-out, porušení mimo měřenou oblast).
3. **Fyzikálně omezený surrogát (2.6).** Poučení pro jeho PCE/Kriging v UQLab: NN s R² ≈ 0,99 přesto porušila fyzikální mez. Stojí za to zavést omezení výstupu a asymetrickou (konzervativní) ztrátu, pokud surrogát vstupuje do RBDO omezení.
4. **Inverze standardní zkoušky do jiného scénáře přes MCMC (2.5).** Analogie: kalibrace modelových parametrů ze zkoušek nebo z Scia/OOFEM a jejich přenos do jiných kombinací zatížení.
5. **LCO a hierarchie akceptačních kritérií (2.8).** Opora pro volbu cílového β v RBDO a pro diskusi, proč β z EN 1990 není pro neobvyklé konstrukce samozřejmé.

**Co nepokrývá**
- **Klimatická teplota (EN 1991-1-5) není požár.** U něj teplota degraduje materiál (stovky °C), u uživatele vyvolává vynucené deformace a síly ve staticky neurčitých příhradách při zanedbatelné degradaci [obecná znalost, neověřeno]. Surrogáty z 2.6 nejsou přenosné, přenosná je jen metodika.
- **Kombinace požáru s dalšími zatíženími** (mimořádná návrhová situace, ψ₁/ψ₂ se sněhem a větrem) se v nalezených úryvcích neobjevuje (N). Práce jsou převážně na úrovni prvku, zatížení je většinou dáno stupněm využití.
- **CHS příhrady a systémové selhání:** nic nenalezeno. Ukázky jsou ŽB deska, ŽB sloup, chráněný ocelový nosník, sklo. Redistribuce ve staticky neurčité soustavě (cut-sets, PNET) chybí.
- **RBDO (optimalizace s omezením na spolehlivost):** LCO v 2.8 optimalizuje jednu proměnnou (tloušťku izolace), nejde o víceparametrický RBDO.

---

## 4. Otázky do diskuse (EN + proč)

1. *In your FSJ framework the economic VoI of a test is linked to system-level outcomes, yet the structural demonstration is a "simplified" VoI analysis for post-fire assessment of RC members. How does the expected utility change when the decision is made at the structural-system level, e.g. a statically indeterminate truss where one member test informs several correlated failure modes?*
   Proč: jeho demonstrace jsou na úrovni prvku, uživatel řeší systémové selhání. Otázka míří na to, jak se VoI propaguje přes korelované cut-sets.

2. *You report that the information gain saturates after 10–15 cone calorimeter trials and, for furnace tests, beyond about five tests. How sensitive is that plateau to the prior and to model-form uncertainty of the simulator that generates the virtual tests? Is model uncertainty itself treated as a learnable parameter?*
   Proč: preposterior analýza stojí na simulátoru. Pokud je chybný, bod saturace je artefakt. Omezení není v úryvcích přiznáno.

3. *Your ICOSSAR'25 sigmoid model enforces physical bounds on the maximum steel temperature because NNs with R² ≈ 0.99 still predicted steel hotter than the gas. When such surrogates enter a reliability constraint, how do you quantify and propagate surrogate error, and would an active-learning scheme near the limit state (AK-MCS style) be preferable to a globally trained, conservatively biased regressor?*
   Proč: most k Sudretovi. Konzervativní bias globálně zkresluje Pf, jde o to, zda chce přesnost u meze, nebo bezpečnost všude.

4. *AFireTest adapts the test to the product and its application. For codified design, how would adaptively obtained, product-specific posteriors be translated back into partial factors or a target β? Who owns the calibration, the manufacturer or the code committee, given your 2019 argument about hierarchies of acceptance criteria?*
   Proč: most ke Köhlerovi (kalibrace norem). Adaptivní zkoušky rozbíjejí standardizaci, na které stojí kalibrace γ.

5. *Fire is treated as an accidental situation with its own target levels, derived from LCO. For steel roofs under combined snow, wind and thermal actions, do you see a consistent way to include the fire situation in a single multi-hazard RBDO, or should the LCO-derived targets for fire remain decoupled from ULS targets?*
   Proč: uživatelova kombinovaná zatížení. U Van Coile nebyla kombinace s klimatickými zatíženími nalezena. Míří to i ke Gardonimu (multi-hazard, regionální riziko).

---

## 5. Zdroje a stav

| # | Zdroj | URL | Stav |
|---|---|---|---|
| 1 | Franchini & Van Coile, FSJ 2025/vol.159 2026, expected utility of fire tests | https://www.sciencedirect.com/science/article/pii/S0379711225002024 ; https://biblio.ugent.be/publication/01KAEVPSYC8YEEJH65P15KJ092 | Ú |
| 2 | Franchini & Van Coile, ICOSSAR'25, EIG | https://biblio.ugent.be/publication/01K1B9MTY0H8ZYHHDVGNXJF7RK | Ú |
| 3 | „Which test is the best?…", J. Phys. Conf. Ser. 3121 (2025) | https://biblio.ugent.be/publication/01K7KMVMNZ8H9HPDNHCB20X085 | C |
| 4 | „How to make optimal use of your fire tests for PBD", SFPE PBD 2026 | https://biblio.ugent.be/publication/01KQZFHE1FW04PGE6CC9JQBW3N | Ú |
| 5 | CORDIS AFireTest 101075556 (+ results) | https://cordis.europa.eu/project/id/101075556 | Ú |
| 6 | Maximizing information… Bayesian framework (Acta Polytech. CTU Proc.) | https://dspace.cvut.cz/handle/10467/106388 ; https://biblio.ugent.be/publication/8769846 | Ú (autoři/rok neověřeny) |
| 7 | Yarmohammadian, Jovanović, Van Coile, ICOSSAR'25 sigmoid | https://www.researchgate.net/publication/392771574 | Ú |
| 8 | Chaudhary, Van Coile, Gernay, Fire Technol. 2021 | https://link.springer.com/article/10.1007/s10694-021-01126-w | Ú |
| 9 | Hopkin, Fu, Van Coile, FSJ 2020, LCO steel | https://www.sciencedirect.com/science/article/abs/pii/S0379711220300631 | Ú |
| 10 | Van Coile & Hopkin, Target safety levels insulated steel beams (LCO) | https://doaj.org/article/fee1e0b6bdbc4093986433609db4570f | Ú (vydání nepotvrzeno) |
| 11 | Van Coile et al. 2019, Hierarchies of acceptance criteria, Fire Technol. 55(4) | https://link.springer.com/article/10.1007/s10694-018-0746-7 | Ú |
| 12 | Van Coile, Balomenos, Pandey, Caspeele 2017, Fire Technol. 53(5) | https://www.semanticscholar.org/paper/73bcd7a8502909b043cb18a0679ca1c78e72ba8f | C |
| 13 | Gernay, Van Coile, Elhami Khorasani et al. 2019, Eng. Struct. 183 | (jen citace v úryvku) | C |
| 14 | Qureshi et al. 2020, J. Struct. Eng. 146(6) | https://doi.org/10.1061/(asce)st.1943-541x.0002621 | C |
| 15 | Peng, Franchini, Jovanović, Van Coile, IPW 2025, ce/papers | https://onlinelibrary.wiley.com/doi/abs/10.1002/cepa.3342 | Ú |
| 16 | Incorporating invalid test results in glass fracture strength, GSE 2026 | https://link.springer.com/article/10.1007/s40940-026-00331-9 | Ú |
| 17 | SFPE Europe 30 (bio) | https://www.sfpe.org/publications/periodicals/sfpeeuropedigital/sfpeeurope30/europeissue30feature3 | Ú |
| 18 | Fire Science Show ep. 080 a 045 | https://www.firescienceshow.com/080-adaptive-fire-testing-a-new-foundation-stone-for-fire-safety-erc-stg-grant-with-ruben-van-coile/ | C |
| 19 | (souvislost se Sudretem) Wagner, Fahrni, Klippel, Frangi, Sudret, Bayesian calibration heat transfer fire insulation panels, Eng. Struct. | https://arxiv.org/abs/1909.07060 | Ú. Není od Van Coile. PCE + PCA surrogát pro bayesovskou kalibraci z pecních zkoušek |
| — | Program IPW 2026 / abstrakt keynote | — | N |
| — | Van Coile a reprodukovatelnost pecí; adjusted partial factors pro ocel za požáru; role v CEN TC250 | — | N |
