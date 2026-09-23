# 05 — Paolo Gardoni: „An Overview of Regional Risk Analysis" (keynote IPW 2026, Padova)

> **Upozornění ke zdrojům.** Síťová politika prostředí blokuje WebFetch/curl. Jediný pokus o stažení open-access PDF (UCL Discovery, Nocera et al. 2024) skončil chybou `EGRESS_BLOCKED`. **Žádný plný text nebyl přečten.** Všechno níže vychází z úryvků vyhledávače (WebSearch): abstrakty, anotace vydavatelů, profily a bibliografické záznamy. Vyhledávací rozpočet session (200 dotazů) se vyčerpal dřív, než jsem stihl ověřit všechno, co jsem chtěl (viz §6). Čísla z abstraktů označuji „(úryvek, neověřeno v PDF)". Kde vycházím z vlastní obecné znalosti, píšu „[obecná znalost, neověřeno]".
>
> Stavy zdrojů: **PT** = plný text (nikde), **ABS** = abstrakt nebo úryvek, **CIT** = jen bibliografická citace, **N/A** = nedostupné.

---

## 1. Kdo je a co reálně ovlivňuje

- Profesor na CEE, University of Illinois Urbana-Champaign (UIUC), od září 2013 ředitel **MAE Center** (Multi-hazard Approach to Engineering; původně Mid-America Earthquake Center, NSF ERC, založeno 1997). Spoluředitel Societal Risk Management Program. Zdroj: mae.cee.illinois.edu/about, cee.illinois.edu profil (ABS).
- **Editor-in-Chief RESS (Reliability Engineering & System Safety), 2020–2025.** Zakladatel a EiC časopisu *Sustainable and Resilient Infrastructure* (Taylor & Francis), 2015–2020, poté „Founding Editor" (profil ise.illinois.edu / ciri.illinois.edu, ABS). Na RESS má tedy editorský vliv, což vysvětluje hustotu jeho vlastních článků v RESS.
- Podle programu IPW 2026 (dicea.unipd.it, úryvek): 11 knih, více než 270 recenzovaných článků, více než 90 zvaných přednášek, EiC dvou časopisů, členství v 12 redakčních radách. Podle jiného profilu přes 58 mil. USD grantového financování (úryvek, neověřeno).
- Institucionální vazba: NIST Center of Excellence for Risk-Based Community Resilience Planning (Colorado State), testbedy Centerville, Seaside a Shelby County, platforma IN-CORE (Guidotti et al. 2016; Ellingwood et al. 2016; úryvky).
- Myšlenková linie: „Berkeley škola" Der Kiureghiana (bayesovské pravděpodobnostní modely s korekčním členem) → fragility → životnost a degradace → síťové modely infrastruktury → regionální riziko a resilience → společenský dopad (capability approach s filozofkou Colleen Murphy). Regionální riziko je u něj **seismické a multi-hazard pro infrastrukturní sítě**, ne klimatická zatížení budov.
- Obsah keynote: nemám abstrakt pro IPW 2026. Nejbližší doložený proxy je jeho webinář „An overview of regional risk & resilience analysis" (UNSW, 2022; IEEE vTools). Podle anotace pokrývá: obecnou formulaci regionálního rizika a resilience, více hazardů a více typů infrastruktury, degradaci a vzájemné závislosti, kaskádu od fyzického poškození k pravděpodobnosti a délce přerušení provozu firem, a příklad hypotetického zemětřesení v New Madrid seismic zone (ABS, youtube.com/watch?v=sg4OGqU85ZQ). Je pravděpodobné, ale nedoložené, že keynote bude mít podobnou osnovu.

---

## 2. Jednotlivé práce

### 2.1 Gardoni, Der Kiureghian, Mosalam (2002). *Probabilistic capacity models and fragility estimates for reinforced concrete columns based on experimental observations.* J. Eng. Mech. 128(10), 1024–1038
- **Stav:** ABS. Bibliografie ověřena: autoři, ročník, svazek, číslo, strany (ascelibrary, experts.illinois.edu).
- **Problém:** deterministické normové a mechanické modely únosnosti mají systematický bias a neznámý rozptyl. Chybí konzistentní pravděpodobnostní model únosnosti prvku, který by rozlišoval aleatorní a epistemickou nejistotu.
- **Metoda (abstrakt):** pravděpodobnostní model únosnosti konstruovaný **bayesovskou aktualizací** neznámých parametrů z experimentálních pozorování. Model bere v úvahu aleatorní i epistemickou nejistotu. Z anotací souvisejících prací (úryvek) plyne obecný tvar: deterministický model + **korekční člen** (odstraňuje bias) + **chyba modelu** (zbylá nejistota). Konkrétní tvar, tj. transformace, vysvětlující funkce h_i(x), homoskedastické normální ε, výběr členů postupnou eliminací, je [obecná znalost, neověřeno].
- **Aplikace:** univariátní a bivariátní modely **deformační a smykové únosnosti kruhových ŽB sloupů** při cyklickém zatížení, postavené na velkém souboru existujících experimentů. Z nich bodové a intervalové odhady fragility, které odrážejí epistemickou nejistotu. Fragility typického mostního pilíře v závislosti na maximální deformaci a smykové poptávce (ABS).
- **Čísla:** v úryvcích žádná.
- **Přiznaná omezení:** v úryvcích nedoložena. Jeden souhrn vyhledávače zmiňoval práci s cenzorovanými daty. Mechanismus (část vzorků neselhala) je [obecná znalost, neověřeno].
- Navazující práce, jen CIT a ABS: Gardoni, Mosalam, Der Kiureghian (2003), *Probabilistic seismic demand models and fragility estimates for RC bridges*, J. Earthquake Eng. 7(sup001). Tatáž bayesovská metodika pro modely poptávky, „accounts for all relevant uncertainties, including model error" (úryvek).

### 2.2 Nocera, Contento, Gardoni (2024). *Risk analysis of supply chains: The role of supporting structures and infrastructure.* RESS 241, 109623
- **Stav:** ABS. Přiřazení ke svazku 241 je jednoznačné (sciencedirect S0951832023005379, ideas.repec). Existuje OA preprint na UCL Discovery, ale ten je **N/A**, protože fetch byl zablokován.
- **Problém:** modelovat resilience firem a jejich dodavatelských řetězců. Potřebuje formulaci, která predikuje dopad hazardu na funkčnost podpůrných staveb a infrastruktury a kaskádový dopad ztráty funkčnosti na výkon řetězce (úryvek abstraktu).
- **Metoda a výstupy:** výstupní metriky jsou dostupnost zboží, odhadované ztráty a jejich distribuční důsledky, tj. kdo nese ztrátu (úryvek). Detaily modelu a případové studie N/A.
- **Čísla a omezení:** nedoloženo.

### 2.3 Lan, Gardoni, Weng, Shen, He, Pan (2024). *Modeling the evolution of industrial accidents triggered by natural disasters using dynamic graphs: typhoon-induced domino accidents in storage tank areas.* RESS 241
- **Stav:** ABS (sciencedirect S0951832023005707, ideas.repec v241). **Svazek 241 obsahuje dva Gardoniho články.** Gardoni tu není první autor.
- **Problém:** Natech, tj. domino havárie nádrží v pobřežní energetické infrastruktuře během tajfunu, které se rychle šíří. Dosavadní studie se soustředily na primární událost.
- **Metoda:** „Natech-related domino evolution graph" (NT-DEG), dynamický graf evoluce havárie pod časově proměnným působením přírodního hazardu, plus identifikace kritických jednotek (úryvek).
- **Výsledky:** validace integrovanou simulací ukázala, že metoda přesně identifikuje kritické jednotky a opatření na nich výrazně zmenšují kaskádu (úryvek, kvalitativně, bez čísel).
- **Omezení:** nedoloženo.

### 2.4 Yu, Sharma, Gardoni (2024). *Functional Connectivity Analysis for modeling flow in infrastructure.* RESS 247, 110042
- **Stav:** ABS a highlights (sciencedirect S0951832024001170). Přiřazení ke svazku 247 je jednoznačné. Jiný Gardoniho článek v tomto svazku jsem nenašel, ale úplnost ověřit nemohu (dblp N/A).
- **Problém:** výpadek infrastruktury po hazardu narušuje ekonomiku, záchranné akce a obnovu. Plné analýzy toku jsou výpočetně drahé, čistě topologická konektivita je nepřesná.
- **Metoda:** infrastruktura jako **funkčně vážená konektivitní síť**. Váhy se počítají ze „supply ratios" pro nepoškozenou a poškozenou síť. Metoda funguje s nízkým časovým rozlišením (highlights).
- **Výsledky:** nižší časové rozlišení a vážená konektivita snižují výpočetní náklady. Na benchmarcích autoři porovnávají koncepci i výpočetní náročnost s tokovými analýzami (highlights, bez čísel).
- **Omezení:** v úryvcích nejsou. Implicitně jde o kompromis mezi přesností a cenou vůči plné tokové analýze. Míra chyby nedoložena.
- Kontext: navazuje na Sharma & Gardoni (2022), *Mathematical modeling of interdependent infrastructure: an object-oriented approach for generalized network-system analysis*, RESS 217 (ABS). Tam infrastruktura vystupuje jako sada zobecněných tokových síťových objektů.

### 2.5 Iannacone, Gardoni (2024). *Modeling deterioration and predicting remaining useful life using stochastic differential equations [and limited data].* RESS 251, 110251
- **Stav:** ABS (sciencedirect S0951832024003235, ideas.repec v251). Přiřazení ke svazku 251 je jednoznačné. Titul se mezi zdroji liší: profil UIUC uvádí „…and limited data", ScienceDirect a RePEc titul bez tohoto dovětku.
- **Problém:** degradace snižuje spolehlivost a vyvolává údržbu. Odhad zbytkové životnosti (RUL) vyžaduje model degradačních procesů.
- **Metoda:** **stochastické diferenciální rovnice (SDE)** popisují vývoj stavových proměnných ve spojitém čase bez diskretizace časové osy. Rozšiřuje dřívější SDE model. Model se **kalibruje z dat SHM** a obsahuje numerické příklady (úryvek s osnovou sekcí). Bayesovskou kalibraci zmiňuje jen souhrn vyhledávače (neověřeno).
- **Čísla a omezení:** nedoloženo.

### 2.6 Další klíčové práce (stručně, ABS nebo CIT)

| Práce | Stav | Co doloženo |
|---|---|---|
| Kumar, Gardoni (2014), *Renewal theory-based life-cycle analysis of deteriorating engineering systems*, Struct. Safety 50, 94–102 | ABS | Časově proměnná spolehlivost a náklady životního cyklu přes teorii obnovy. Aplikace na most v seismické oblasti. |
| Kumar, Cline, Gardoni (2015), stochastický rámec degradace | CIT/ABS | Degradace = gradual (koroze, únava) + shock (zemětřesení, povodně). Stavově závislé modely. |
| Jia, Gardoni (2018), *State-dependent stochastic models…*, Struct. Safety | ABS (titul) | Více degradačních procesů a jejich interakce. |
| Sharma, Tabandeh, Gardoni (2018), *Extended and generalized fragility functions*, J. Eng. Mech. 144(9) | ABS | Multivariátní intenzitní míry, více stavů poškození přes softmax. Odstraňuje předpoklad společného rozptylu. Markovské a skryté markovské modely pro časovou závislost stavů. |
| Iannacone, Sharma, Tabandeh, Gardoni (2022), *Modeling time-varying reliability and resilience of deteriorating infrastructure*, RESS 217, 108074 | ABS | Vliv degradace na schopnost obnovy. Víceškálový model obnovy snižuje výpočetní náklady. |
| Tabandeh, Sharma, Gardoni (2022), *Uncertainty propagation in risk and resilience analysis of hierarchical systems*, RESS 219, 108208 | ABS | Šíření nejistoty v hierarchických systémech. Hlavní obtíže: složitý výpočetní workflow a vysoká dimenze pravděpodobnostního prostoru. |
| Sharma, Tabandeh, Gardoni (2020), *Regional resilience analysis: a multiscale approach…*, Comput.-Aided Civ. Infrastruct. Eng. | ABS | Hierarchický model obnovy s „recovery zones", kde komponenty ve zóně sdílí prioritu. Optimalizace resilience. |
| Guidotti, Chmielewski, Unnikrishnan, Gardoni, McAllister, van de Lindt (2016), *Modeling the resilience of critical infrastructure: the role of network dependencies*, Sust. Resil. Infrastruct. 1(3–4), 153–168 | ABS | Jednotná metodika pro závislé a vzájemně závislé sítě, šestikrokový pravděpodobnostní postup. Aplikace: vodovod Seaside (OR), seismická událost. |
| Gardoni, Murphy (2010), *Gauging the societal impacts of natural disasters using a capability approach*, Disasters | ABS | Disaster Impact Index (DII) = dopad na capabilities jednotlivců, interpretovatelný jako dopad na obyvatele. Capability approach do katastrof zavedli Murphy & Gardoni 2006. |
| Gardoni (ed.) (2018), *Routledge Handbook of Sustainable and Resilient Infrastructure*, 898 s. | ABS (anotace) | Více než 40 příspěvků, důraz na propojení udržitelnosti a resilience. Kapitola Nocera, Tabandeh, Guidotti, Boakye, Gardoni o physics-based fragility functions (CIT). |

**Klimatická změna a vítr/hurikány:** Gardoniho práci o nestacionaritě klimatu **jsem nedohledal (N/A)**. Dotazy vracely práce jiných autorů. Neříkám, že neexistuje, jen že jsem ji nedoložil.

---

## 3. Průsečík s tématem disertace (RBDO ocelových CHS vazníků pod sněhem, větrem a teplotou)

### Co lze převzít
1. **Bayesovský pravděpodobnostní model únosnosti s korekčním členem (2002)** přímo na **modelovou nejistotu vzpěru CHS**. Tvar by byl ln N_b,test = ln N_b,EC3(x) + Σθ_i·h_i(x) + σε. Vysvětlující proměnné: λ̄, D/t, f_y, výrobní postup (za tepla/za studena). Výstup: posteriorní rozdělení θ a σ nahradí paušální θ_R ~ LN(1, V) v UQLab modelu. Umožňuje oddělit epistemickou část (nejistotu parametrů) od aleatorní a spočítat intervalový odhad P_f, podobně jako Gardoniho „point and interval estimates of fragility". Kombinaci s EC3 křivkami je nutné postavit sám. Gardoni ji pro ocel nedokládá.
2. **Regionální formulace → portfolio hal.** Logika regionálního rizika (hazard s prostorovou korelací → fragility komponent → systém → následky) se dá přenést z „síť infrastruktury pod zemětřesením" na „soubor hal pod sněhovou událostí". Korelace s_k mezi lokalitami by měla podobnou roli jako prostorová korelace pohybů půdy. To je analogie a návrh, Gardoni sníh ani vítr pro budovy nedokládá.
3. **Víceproměnné fragility (Sharma et al. 2018)** pro fragility vazníku jako funkci (s, w) nebo (s, w, ΔT) místo jedné intenzitní míry. Softmax pro více stavů poškození odpovídá hierarchii: první prut → mechanismus (cut-sets).
4. **Stochastická degradace a SDE (Kumar & Gardoni; Iannacone & Gardoni 2024)** pro korozi CHS a úbytek tloušťky t(t) v časově závislé spolehlivosti. „Shock" složka může reprezentovat extrémní sněhovou událost.
5. **Šíření nejistoty v hierarchických systémech (Tabandeh et al. 2022)** koncepčně odpovídá jeho řetězci prut → systém (cut-sets/PNET) → portfolio.

### Co nepokrývá
- **Návrh a optimalizaci.** Gardoniho práce jsou posouzení rizika a resilience a optimalizace obnovy (recovery). Návrh prvků, RBDO a kalibraci γ-součinitelů nedokládá.
- **Kombinaci více klimatických zatížení na jednom prvku** (Turkstra, Ferry Borges–Castanheta, sníh + vítr + teplota). Multi-hazard u něj znamená hlavně souběh hazardů a degradace na úrovni sítí. Kombinační pravidla zatížení v úryvcích nejsou.
- **Nestacionaritu klimatu u sněhu a větru.** Nedoloženo.
- **Ocel a stabilitu.** Doložené aplikace jsou ŽB sloupy a mosty, sítě, nádrže a dodavatelské řetězce.

---

## 4. Otázky do diskuse (EN + proč)

1. **Probabilistic capacity models (Gardoni et al. 2002):** *"Your Bayesian capacity models calibrate a correction term on a large but heterogeneous test database of RC columns. For steel CHS members in buckling, test databases are dominated by laboratory specimens with measured imperfections. How would you treat the mismatch between the imperfection distribution in the tests and in the as-built population? Would it go into the correction term, the error term, or a separate hierarchical level?"*
   — Proč: model uncertainty pro vzpěr je u mě dominantní. Korekční člen z testů ale nemusí odpovídat realitě staveb. Otázka míří na přenositelnost metody mimo populaci testů.

2. **Regional risk (webinar 2022 / keynote):** *"Your regional framework propagates spatially correlated hazard intensities (e.g., ground motion) to many assets. For snow, the load on a roof is a transformed ground snow field (exposure, drift, melt), and design is governed by codified characteristic values rather than site-specific hazard. Does the framework have a place for code-prescribed load models, or does it require physics- or data-based site hazard for every asset?"*
   — Proč: testuje, jestli jde regionální logiku propojit s normovým návrhem (EN 1991-1-3), nebo jen s posouzením.

3. **Multivariate fragilities (Sharma, Tabandeh, Gardoni 2018):** *"Extended fragility functions handle multivariate intensity measures. For concurrent snow, wind and temperature, the joint distribution of the intensities in time matters as much as the fragility. How do you recommend combining multivariate fragilities with load-combination models where the maxima do not coincide?"*
   — Proč: kombinace zatížení je mezera, kterou Gardoni v doložených pracích neřeší, a pro mě je klíčová.

4. **Risk vs. design:** *"Most of your recent RESS work (e.g., Nocera et al. 2024; Yu et al. 2024) optimizes mitigation or recovery given existing assets. Have you seen or tried formulations where regional risk metrics, such as the distribution of losses across an asset portfolio, enter a reliability-based design optimization of the individual asset as constraints?"*
   — Proč: přímý most k RBDO. Otázka ukazuje, že regionální metriky zatím slouží k posouzení, ne k návrhu.

5. **Deterioration with limited data (Iannacone & Gardoni 2024):** *"With SDE-based deterioration calibrated on SHM data, how do you avoid confounding a nonstationary load trend (e.g., climate-driven snow load change) with a deterioration trend in the resistance, when both reduce the safety margin over time?"*
   — Proč: nestacionarita klimatu a degradace se ve spolehlivosti v čase sčítají. Otázka míří na identifikovatelnost, kterou metoda řešit nemusí.

---

## 5. Seznam zdrojů

| # | Zdroj | URL | Stav |
|---|---|---|---|
| 1 | Gardoni, Der Kiureghian, Mosalam 2002, JEM 128(10) | https://ascelibrary.org/doi/10.1061/(ASCE)0733-9399(2002)128:10(1024) ; https://experts.illinois.edu/en/publications/probabilistic-capacity-models-and-fragility-estimates-for-reinfor/ | ABS |
| 2 | Gardoni, Mosalam, Der Kiureghian 2003, J. Earthq. Eng. 7 | https://www.worldscientific.com/doi/10.1142/S1363246903001024 | ABS |
| 3 | Nocera, Contento, Gardoni 2024, RESS 241, 109623 | https://www.sciencedirect.com/science/article/abs/pii/S0951832023005379 ; OA preprint https://discovery.ucl.ac.uk/10182291/1/Risk_analysis_of_supply_chains%20.pdf | ABS; PDF N/A (blokováno) |
| 4 | Lan, Gardoni et al. 2024, RESS 241 | https://www.sciencedirect.com/science/article/abs/pii/S0951832023005707 | ABS |
| 5 | Yu, Sharma, Gardoni 2024, RESS 247, 110042 | https://www.sciencedirect.com/science/article/pii/S0951832024001170 | ABS/highlights |
| 6 | Iannacone, Gardoni 2024, RESS 251, 110251 | https://www.sciencedirect.com/science/article/pii/S0951832024003235 ; https://ideas.repec.org/a/eee/reensy/v251y2024ics0951832024003235.html | ABS |
| 7 | Sharma, Gardoni 2022, RESS 217 | https://ideas.repec.org/a/eee/reensy/v217y2022ics0951832021005470.html | ABS |
| 8 | Iannacone, Sharma, Tabandeh, Gardoni 2022, RESS 217, 108074 | https://www.sciencedirect.com/science/article/abs/pii/S0951832021005731 | ABS |
| 9 | Tabandeh, Sharma, Gardoni 2022, RESS 219, 108208 | https://www.sciencedirect.com/science/article/abs/pii/S0951832021006876 | ABS |
| 10 | Sharma, Tabandeh, Gardoni 2018, JEM 144(9) | https://doi.org/10.1061/(asce)em.1943-7889.0001478 | ABS |
| 11 | Sharma, Tabandeh, Gardoni 2020, CACAIE | https://onlinelibrary.wiley.com/doi/abs/10.1111/mice.12606 | ABS |
| 12 | Kumar, Gardoni 2014, Struct. Safety 50 | https://www.sciencedirect.com/science/article/abs/pii/S0167473014000307 | ABS |
| 13 | Jia, Gardoni 2018 (state-dependent models) | https://www.sciencedirect.com/science/article/abs/pii/S0167473017301066 | CIT |
| 14 | Guidotti et al. 2016, SRI 1(3–4) | https://www.tandfonline.com/doi/abs/10.1080/23789689.2016.1254999 ; https://pmc.ncbi.nlm.nih.gov/articles/PMC5557302/ | ABS (PMC plný text N/A, nečteno) |
| 15 | Gardoni, Murphy 2010, Disasters | https://onlinelibrary.wiley.com/doi/10.1111/j.1467-7717.2010.01160.x | ABS |
| 16 | Gardoni (ed.) 2018, Routledge Handbook | https://www.routledge.com/Routledge-Handbook-of-Sustainable-and-Resilient-Infrastructure/Gardoni/p/book/9780367659622 | anotace |
| 17 | Webinář „An overview of regional risk & resilience analysis" (2022) | https://www.youtube.com/watch?v=sg4OGqU85ZQ ; https://events.vtools.ieee.org/m/328764 | anotace |
| 18 | IPW 2026 program | https://dicea.unipd.it/ipw-2026-padova/agenda | úryvek (bio), abstrakt keynote N/A |
| 19 | Profily: MAE Center, CEE, ISE, CIRI UIUC | https://mae.cee.illinois.edu/about/about_leadership.html ; https://cee.illinois.edu/directory/profile/gardoni ; https://ciri.illinois.edu/people/paolo-gardoni | úryvky |

**Neověřeno kvůli vyčerpání vyhledávacího rozpočtu:** úplný seznam Gardoniho článků v RESS 241, 247 a 251 (dblp nedostupné), Gardoniho práce o klimatické změně a větru, abstrakt keynote IPW 2026, obsah knihy *Risk Analysis of Natural Hazards* (Springer 2016).
