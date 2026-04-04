# Postup posudku příhradového vazníku průmyslové haly

**Dle:** Jandera — Ocelové konstrukce 01 (OK-01), kap. 1.4 a 3
**Normy:** EN 1990, EN 1991-1-1, EN 1991-1-3, EN 1991-1-4, EN 1993-1-1
**Materiál:** ocel S355 (f_y = 355 MPa), průřezy CHS (trubky)

---

## 1. Geometrie haly

| Parametr | Označení | Příklad |
|----------|----------|---------|
| Rozpětí vazníku | L | 30 m |
| Vzdálenost vazníků (rozpon příčné vazby) | b | 6 m |
| Délka haly | d | n × b |
| Výška vazníku v uložení | h_s | 2,5 m |
| Sklon střechy | α (%) | 5 % |
| Max. výška vazníku (uprostřed) | h_max = h_s + α·L/2 | 3,25 m |
| Výška haly ke koruně stěny | H | h_stojky + h_s |
| Rozteč vaznic | a | 3 m |
| Topologie příhrady | — | Pratt |

**Výška haly pro výpočet větru:**
`h = H + h_max` ... výška hřebene od terénu

---

## 2. Zatěžovací stavy (ZS)

### ZS1 — Stálé zatížení G

Charakteristická hodnota stálého zatížení:

```
g_k = g_plášť + g_vazník_vlastní
```

**Plášť:**
`g_plášť` ... zadáno dle použitého střešního pláště [kN/m²], typicky 0,15–0,50 kN/m²

**Vlastní tíha vazníku** (Jandera, kap. 1.4.4 — empirický vzorec):

```
g_vaz = L / 76 · sqrt((g_plášť + s_k) · b)     [kN/m²]
```

kde:
- L ... rozpětí vazníku [m]
- s_k ... char. hodnota zatížení sněhem [kN/m²]
- b ... vzdálenost vazníků [m]

Výsledné stálé zatížení: `g_total = g_plášť + g_vaz`
Minimální stálé zatížení (pro uplift): `g_min = g_plášť + 0,5 · g_vaz`

### ZS2 — Sníh S (EN 1991-1-3)

```
s = μ₁ · C_e · C_t · s_k
```

| Parametr | Hodnota |
|----------|---------|
| Tvarový součinitel μ₁ | **0,8** (sedlová střecha, α ≤ 30°) |
| Součinitel expozice C_e | 1,0 (normální terén) |
| Tepelný součinitel C_t | 1,0 (standard) |
| s_k | dle sněhové mapy ČR [kN/m²] |

> **Pozor:** μ₁ = 0,8, nikoliv 1,0 — jde o rovnoměrné zatížení sněhem dle Tab. 5.2 EN 1991-1-3.

### ZS3 — Příčný vítr W_t (EN 1991-1-4)

**Základní tlak větru:**
```
q_b = 0,5 · ρ · v_b²      [Pa]
```
kde ρ = 1,25 kg/m³, v_b = v_b,0 · c_dir · c_season.

**Součinitel expozice:**
```
c_e(z) = c_r(z)² · c_o(z)²   nebo z tabulky/grafu dle EN 1991-1-4
```

Vrcholový tlak větru: `q_p(z) = c_e(z) · q_b`

**Zóny střechy (příčný vítr — vítr kolmo na hřeben):**

Referenční délka: `e = min(b, 2h)`, kde b = šířka haly, h = výška hřebene

| Zóna | Poloha v ose Y (od návětrné stěny) | Poloha v ose X (od okapu) |
|------|--------------------------------------|--------------------------|
| F | 0 … e/4 | 0 … e/10 |
| G | e/4 … e/2 | 0 … e/10 |
| H | e/2 … L | 0 … e/10 |
| I | celá délka | e/10 … L/2 (závětrná polovina) |
| J | 0 … e/2 | Závětrný okap (bodová zóna) |

Součinitele c_pe,10 pro jednotlivé zóny viz Tab. 7.4a/b EN 1991-1-4 (závisí na sklonu α a poměru h/d).

**Tlak/sání na střechu:**
```
w_e = q_p(z_e) · c_pe     [kN/m²]
```
- Záporné w_e = sání (odtahuje střechu nahoru)
- Kladné w_e = tlak

**Převod na uzlové síly (metoda příspěvných ploch):**

Pro každý uzel horního pásu:
```
F_z,i = w_e,i · b · trib_i · 1000     [N]
```
kde `trib_i` je příspěvná délka uzlu podél vazníku [m].

> Při výpočtu je třeba rozlišit, do které zóny (F, G, H, I) příspěvná plocha každého uzlu spadá, a aplikovat příslušné c_pe.

### ZS4 — Podélný vítr W_l (EN 1991-1-4)

Vítr rovnoběžný s hřebenem. Obvykle způsobuje sání na celé střeše (zóna G/H/I).
Pro posudek vazníku je zpravidla méně nepříznivý než příčný vítr.

Součinitele c_pe se určí stejným postupem jako pro ZS3, ale pro θ = 0° (vítr podél hřebene).

---

## 3. Kombinace zatěžovacích stavů (KZS) — EN 1990

Kombinace pro **mezní stav únosnosti (MSÚ)** dle EN 1990, rovnice 6.10:

```
E_d = Σ γ_G,j · G_k,j  +  γ_Q,1 · Q_k,1  +  Σ γ_Q,i · ψ_0,i · Q_k,i
```

### Tabulka kombinací

| KZS | Popis | Vzorec | Rozhodující pro |
|-----|-------|--------|----------------|
| **1** | Stálé + sníh | 1,35·G + 1,5·S | Max. tlak v horním pásu |
| **2** | Stálé + sníh + vítr příčný | 1,35·G + 1,5·S + 0,9·W_t | Kombinovaný účinek |
| **3** | Stálé + vítr příčný + sníh | 1,35·G + 1,5·W_t + 0,75·S | Sání + tíha, uplift hrozí |
| **4** | Min. stálé + vítr příčný | 1,0·G_min + 1,5·W_t | Uplift — tlak v dolním pásu |
| **5** | Min. stálé + vítr podélný | 1,0·G_min + 1,5·W_l | Uplift — tlak v dolním pásu |

Kombinační součinitel sněhu: ψ_0,S = 0,5
Kombinační součinitel větru: ψ_0,W = 0,6

> **KZS 1** rozhoduje pro návrh horního pásu (max. tlak → vzpěr).
> **KZS 4/5** rozhodují pro návrh dolního pásu při dominantním sání větru (uplift).

---

## 4. FEM model

### Typ modelu

**2D příhradový vazník** — pin-jointed, pouze osové síly:
- Každý prut = 1 element (tah/tlak)
- Uzly = klouby (bez přenosu momentů)
- Solver: `linearSolverFn` z modulu `fem-2d-truss-matlab`

> Alternativně lze použít 3D rámový model (`fem-3d-frame-matlab`) s kloubovými uvolněními
> (`beams.releases`) na výplňových prutech — umožňuje zahrnutí sloupů do téhož modelu.

### Podpory

| Uzel | Poloha | Typ |
|------|--------|-----|
| Levý | x = 0 | Kloubová (ux + uz fixovány) |
| Pravý | x = L | Pojezdová (uz fixován) |

### Zatěžovací uzly

Zatížení se přikládá **do uzlů horního pásu** jako svislé uzlové síly.
Příspěvná délka `trib_i` = polovina vzdálenosti k sousedním uzlům podél horního pásu.

---

## 5. Klasifikace prutů

| Typ prutu | Kritérium | Skupina průřezů |
|-----------|-----------|-----------------|
| Horní pás | Sekvence v pásu, sekce 1 | 1 |
| Dolní pás | Sekvence v pásu, sekce 2 | 2 |
| Diagonála | Úhel 15°–75° od vodorovné | 3 |
| Svislice | Úhel > 75° od vodorovné | 3 |

---

## 6. Vzpěrné délky L_cr (Jandera, Tab. 1.29 — trubkový vazník)

| Typ prutu | L_cr v rovině | L_cr z roviny |
|-----------|--------------|---------------|
| Horní pás | L_sys (vzdálenost uzlů pásu) | 0,9 · a (rozteč vaznic) |
| Dolní pás | L_sys | b (vzdálenost vazníků / zavětrování) |
| Diagonála | 0,9 · L_sys | 0,75 · L_sys |
| Svislice | 0,9 · L_sys | 0,75 · L_sys |

Rozhodující vzpěrná délka: `L_cr = max(L_cr,in, L_cr,out)`
Pro CHS platí: I_y = I_z → stačí jedna hodnota L_cr.

---

## 7. Posudek průřezu a stability (EN 1993-1-1)

### 7.1 Třída průřezu CHS (Tab. 5.2)

```
ε = sqrt(235 / f_y)

Třída 1:  D/t ≤ 50 · ε²
Třída 2:  D/t ≤ 70 · ε²
Třída 3:  D/t ≤ 90 · ε²
```

Pro CHS třídy 1–3 je N_pl,Rd = A · f_y / γ_M0.

### 7.2 Tah — Cl. 6.2.3

```
N_pl,Rd = A · f_y / γ_M0

Podmínka:  N_Ed / N_pl,Rd ≤ 1,0
```

### 7.3 Tlak a vzpěr — Cl. 6.3.1

**Štíhlost:**
```
λ̄ = (L_cr / i) / λ_1

kde  λ_1 = π · sqrt(E / f_y)
     i   = sqrt(I / A)
```

**Součinitel imperfekce α** (Tab. 6.1):

| Křivka | α |
|--------|---|
| a | 0,21 |
| b | 0,34 |
| c | 0,49 |
| d | 0,76 |

Pro CHS válcované za tepla → **křivka a** (α = 0,21).

**Součinitel vzpěrnosti χ:**
```
Φ = 0,5 · [1 + α · (λ̄ − 0,2) + λ̄²]

χ = min( 1 / (Φ + sqrt(Φ² − λ̄²)),  1,0 )
```

**Únosnost ve vzpěru:**
```
N_b,Rd = χ · A · f_y / γ_M1

Podmínka:  |N_Ed| / N_b,Rd ≤ 1,0
```

Součinitele: γ_M0 = 1,0, γ_M1 = 1,0 (dle národní přílohy ČR).

---

## 8. Postup výpočtu — krok za krokem

```
1.  Zadat geometrii haly (L, α, h_s, b, a)
2.  Zadat průřezy (D, t pro každou skupinu), ocel S355
3.  Vypočítat A, I, i pro každý průřez (vzorce pro CHS)
4.  Stanovit zatížení:
        g_total = g_plášť + g_vaz      [kN/m²]
        s       = μ₁ · s_k = 0,8 · s_k [kN/m²]
        w_e     = q_p(z) · c_pe        [kN/m²] (po zónách F/G/H/I)
5.  Sestavit FEM model (uzly, pruty, podpory)
6.  Pro každé KZS (1–5):
        a. Vypočítat uzlové síly (g nebo s nebo w_e) × b × trib_i
        b. Spustit FEM → N_Ed pro každý prut
7.  Klasifikovat pruty (horní/dolní pás, diagonály, svislice)
8.  Stanovit vzpěrné délky L_cr (Tab. 1.29)
9.  Pro každý prut a každé KZS:
        a. Ověřit třídu průřezu (D/t ≤ 50ε²)
        b. Tah:  util = N_Ed / N_pl,Rd
           Tlak: util = |N_Ed| / N_b,Rd
10. Obálka: util_max(p) = max přes všechna KZS
11. Výstup: tabulka využití, status OK/NEVYHOVUJE
```

---

## 9. Orientační hodnoty pro průmyslovou halu L = 30 m

| Veličina | Hodnota | Poznámka |
|----------|---------|----------|
| g_plášť | 0,35 kN/m² | Lehký střešní plášť |
| s_k | 0,70 kN/m² | Sněhová oblast I (Praha) |
| μ₁ · s_k | 0,56 kN/m² | Výpočtové zatížení sněhem |
| q_b | 0,30 kN/m² | v_b = 22 m/s (oblast I) |
| c_e(h) | ~2,0 | pro h ≈ 8 m, terén kat. II |
| q_p | 0,60 kN/m² | |
| w_e (sání, zóna H) | −0,36 kN/m² | c_pe ≈ −0,6 |
| w_e (tlak, čelní stěna) | +0,48 kN/m² | c_pe ≈ +0,8 |
| Horní pás (rozhodující KZS) | KZS 1 | Tlak → vzpěr |
| Dolní pás (rozhodující KZS) | KZS 4/5 | Tlak (sání > tíha) |

---

## 10. Reference

- Jandera, M.: *Ocelové konstrukce 01 — cvičení*, ČVUT 2026, kap. 1.4 a 3
- EN 1990: *Zásady navrhování konstrukcí*
- EN 1991-1-3: *Zatížení sněhem*
- EN 1991-1-4: *Zatížení větrem*
- EN 1993-1-1: *Navrhování ocelových konstrukcí — Obecná pravidla*
