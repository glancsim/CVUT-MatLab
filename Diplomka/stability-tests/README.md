# Stability Tests - Automatizované spouštění

## 📋 Popis

Tento projekt obsahuje 9 stability testů pro porovnání výsledků MATLAB implementace s programem OOFEM. Každý test provádí:
1. **Lineární analýzu** (klasická MKP)
2. **Nelineární analýzu** (geometrická nelinearita)
3. **Porovnání s OOFEM** (výpočet procentuálních chyb)

## 🚀 Rychlý start

### Spuštění všech testů najednou:

```matlab
cd('C:\GitHub\MatLab\Diplomka\stability-tests')
run_all_stability_tests
```

### Spuštění jednotlivého testu:

```matlab
cd('C:\GitHub\MatLab\Diplomka\stability-tests\Test 1')
run('test.mlx')
```

## 📁 Struktura projektu

```
stability-tests/
├── run_all_stability_tests.m    # Hlavní skript pro všechny testy
├── results/                      # Výsledky (generuje se automaticky)
│   ├── errors_table.xlsx        # Excel tabulka s chybami
│   ├── all_tests_results.mat    # MATLAB data
│   ├── errors_summary.txt       # Textový report
│   └── *.png                    # Grafy
├── Test 1/
│   ├── test.mlx                 # Hlavní test
│   ├── oofem                    # OOFEM executable/cmd
│   ├── sectionsSet.mat          # Průřezy
│   └── [generované soubory]     # input.mat, eigen.mat, test.out, ...
├── Test 2/
│   └── ...
└── Test 9/
    └── ...
```

## 📊 Výstupy

Po spuštění `run_all_stability_tests.m` se vytvoří:

1. **Excel tabulka** (`results/errors_table.xlsx`)
   - Řádky = testy (Test 1-9)
   - Sloupce = chyby jednotlivých vlastních čísel
   - Statistiky: průměr, max, min

2. **MATLAB data** (`results/all_tests_results.mat`)
   - `resultsTable` - matice chyb
   - `testNames` - názvy testů
   - `testStatus` - stav testů (OK/ERROR)
   - `executionTimes` - časy běhu

3. **Textový report** (`results/errors_summary.txt`)
   - Souhrn všech testů
   - Celkové statistiky

4. **Grafy** (PNG formát)
   - Heatmapa všech chyb
   - Box plot distribucí
   - Sloupcový graf průměrných chyb

## ⚙️ Konfigurace

V souboru `run_all_stability_tests.m` můžeš upravit:

```matlab
%% KONFIGURACE
addpath('C:\GitHub\MatLab\Diplomka\Resources');  % Cesta k funkcím
baseDir = pwd;                                    % Složka s testy

numTests = 9;                  % Počet testů
numEigenvalues = 10;          % Počet vlastních čísel

saveGraphs = false;            % Ukládat grafy z každého testu?
closeGraphs = true;            # Zavírat grafy po testu?
```

## 🔧 Požadavky

- **MATLAB** R2019b nebo novější
- **Live Script** podpora (.mlx soubory)
- **OOFEM** nainstalovaný a dostupný v PATH
- **Závislosti:**
  - `Resources/` složka s funkcemi:
    - `stiffnessMatrixFn.m`
    - `geometricMoofemFn.m`
    - `oofemTestFn.m`
    - `oofemInputFn.m`
    - a další...

## 📝 Jak přidat nový test

1. Vytvoř novou složku `Test X/`
2. Zkopíruj strukturu z existujícího testu
3. Uprav `test.mlx` podle potřeby
4. Uprav `numTests` v `run_all_stability_tests.m`

## 🐛 Řešení problémů

### Test selhává s chybou

- Zkontroluj že OOFEM je v PATH
- Ověř že `oofem` nebo `oofem.cmd` existuje ve složce testu
- Zkontroluj že všechny funkce v `Resources/` jsou dostupné

### Excel export nefunguje

- Je potřeba mít nainstalovaný Excel
- Nebo můžeš použít jen MAT soubory a textový report

### Chybí proměnná 'errors'

- Ověř že test.mlx správně běží samostatně
- Zkontroluj že `oofemTestFn` vrací `errors` do workspace

## 📚 Reference

- **OOFEM**: Object Oriented Finite Element Method
- **Projekt**: CVUT-MatLab / Diplomka
- **Autor**: glancsim
- **Datum**: 2026-01-13

## 📞 Kontakt

Pro otázky nebo problémy:
- GitHub: https://github.com/glancsim/CVUT-MatLab
- Issues: https://github.com/glancsim/CVUT-MatLab/issues

---

**Happy testing! 🎉**
