# MC cross-check of `beta_sys` — Warren X-brace truss

Run package for `MC_NEPTUN_BRIEF.md` (NNM 2026 / Acta Polytechnica).
Produces an approximation-free Monte Carlo estimate of `Pf_sys` using the
progressive-collapse oracle `tests/progressiveCollapseMCFn.m`.

## Run it on neptun01

Environment per `StableTrussOpt-MATLAB/spatial_boom_X_ext_true/NEPTUN_NAVOD.md`:
PuTTY/WinSCP over VPN, user `sglanc`, MATLAB at
`/home/tyburec/MATLAB/R2023a/bin/matlab`, 32 cores / 126 GB shared → use 28
workers.

**What to transfer.** Only these four directories are needed; keep the
layout, because `mcNeptunSetup` resolves the repo root three levels above
itself:

```
~/MatLab/system-reliability-truss-matlab/src/*.m                    (11)
~/MatLab/system-reliability-truss-matlab/tests/progressiveCollapseMCFn.m
~/MatLab/system-reliability-truss-matlab/tests/mc_neptun/*           (9)
~/MatLab/fem-2d-truss-matlab/src/*.m                                 (8)
```

No `.mat` data files, no `examples/`, no OOFEM binaries.

**Step 1 — preflight (~1 min).** Checks release, toolbox licences, path,
the deterministic asserts, and extrapolates wall time:

```bash
/home/tyburec/MATLAB/R2023a/bin/matlab -batch \
  "run('/home/sglanc/MatLab/system-reliability-truss-matlab/tests/mc_neptun/mcNeptunPreflight.m')"
```

Must end with `PREFLIGHT PASSED`. If the Statistics and Machine Learning
licence is missing, stop — `normcdf`/`norminv` are used by
`progressiveCollapseMCFn` and `componentReliabilityFn`, and the fix means
patching repo code.

**Step 2 — check the machine is free**, since it is shared: `htop`.

**Step 3 — launch (~1 h at 1e8).**

```bash
nohup /home/tyburec/MATLAB/R2023a/bin/matlab -batch \
  "run('/home/sglanc/MatLab/system-reliability-truss-matlab/tests/mc_neptun/run_mc.m')" \
  > /tmp/mc_out.log 2>&1 &
echo "PID: $!"
```

`run_mc.m` sets 1e8 samples / 28 chunks / 28 workers, writes a diary, and
sends an ntfy notification to `hexic-notifications-matlab` on both success
and failure.

**Monitor** (progress line with ETA every sub-batch):

```bash
tail -f /home/sglanc/MatLab/system-reliability-truss-matlab/tests/mc_neptun/mc_neptun.log
```

**Results to download:** `mc_neptun_report_<timestamp>.txt` (the seven items
of brief §7), `mc_neptun_result.mat`, `mc_neptun.log`.

Smaller run, if you want the brief's original 3.0 % CoV target instead:

```matlab
o.nTargetTotal = 1e7; runMcNeptun(o);
```

Defaults are **1e8 samples**, 28 chunks × 3 571 429, seeds 1001–1028
(`nTotal = 100 000 012` — the chunk size is rounded up, which is harmless
because the estimator pools raw counts).

## Note on MATLAB R2023a

neptun01 runs R2023a, this was developed on R2026a. Checked for it:
`parcluster('local')` is the correct profile name in R2023a (renamed to
`Processes` only in R2023b, and the old name still resolves);
`parallel.pool.DataQueue`/`afterEach` date from R2017a; no `arguments`
blocks or other recent syntax is used; and `runMcNeptun` deliberately
contains **no nested functions**, so nothing can interact badly with its
`parfor` on an older release. `rng`/`randn` streams are stable across
releases, so the seeds reproduce.

## Without the Parallel Computing Toolbox

```bash
for w in $(seq 1 28); do matlab -batch "runMcChunk($w)" > chunk_$w.log 2>&1 & done
wait
matlab -batch "poolMcChunks"
```

Identical numbers — both paths call the same `mcRunChunk`.

## Files

| file | role |
|---|---|
| `mcNeptunSetup.m` | Verbatim setup from brief §5. **Asserts** the FSD areas and `beta_min`; errors out on mismatch so a long job cannot start on a wrong model. |
| `runMcNeptun.m` | Main driver: parpool, 28 seeded chunks, progress/ETA, pooling. |
| `mcRunChunk.m` | One chunk. Shared by both execution paths. |
| `runMcChunk.m` | `matlab -batch` entry point for the no-PCT fallback. |
| `poolMcChunks.m` | Pools `mc_chunk_*.mat` from the fallback. |
| `mcNeptunReport.m` | Formats brief §7 items 1–6 to stdout + text file. |

## Results in this directory

The run has been executed. Findings are written up in
`ctu-nnm-2026/MC_NEPTUN_FINDINGS.md`; the headline is
`Pf_MC = 1.88199977e-04` (1e8 samples, 18 820 failures, CoV 0.73 %), which
is **1.68× above** the analytical `Pf_sys` — i.e. PNET at `rho0 = 0.7`
under-estimates, the opposite of the direction the brief assumed.

| file | tracked | what it is |
|---|---|---|
| `mc_neptun_report_20260801_191214.txt` | yes | the 1e8 run — the result of record |
| `mc_neptun_report_20260801_142329.txt` | yes | earlier 1e7 validation run |
| `mc_neptun.log` | yes | diary of the 1e8 run |
| `mc_neptun_result.mat` | **no** (`.gitignore`) | ~7 MB raw output incl. all 18 820 failure sequences; regenerate with a ~2 h run |

The two runs used the same seeds, so the 1e7 samples are a **subset** of the
1e8 samples. They are not independent and must not be pooled — the 1e8 run
supersedes.

## Diagnostics

`diagnostics/` reproduces every claim in `MC_NEPTUN_FINDINGS.md`. Run any of
them directly; they resolve their own paths.

| script | produces |
|---|---|
| `cutset_rank.m` | all 91 cut-sets ranked by `betaPerCutSet`, plus PNET groups |
| `group_membership.m` | §2 — MC modes mapped onto PNET groups |
| `mode_stats.m` | §3 and §6 — all observed mechanisms, size distribution, cut-set-enumeration completeness check |
| `rho_sweep.m` | §5 — `rho0` sweep, plus the tie-break fix that does not work |
| `seq_diff.m` | `repSequence` stability across RNG seeds |
| `final_cause.m` | §4 — the `{4,8,9,16}` correlation flip that causes the bimodality |
| `pnetTieBreakFn.m` | deterministic-tie-break variant of `pnetSystemReliabilityFn` |

`group_membership.m` and `mode_stats.m` read `mc_neptun_result.mat`, so they
need a completed run present; the others recompute the analytical side only
and work from a clean checkout.

## Design notes

**Chunks are decoupled from cores.** Pooling raw counts
(`sum(nFail)/sum(nSamples)`) is exact regardless of concurrency, so 28
chunks give the same answer on 28 cores as on 16. Seeds stay 1001–1028 so a
run on any machine is comparable with a neptun run.

**`beta` is never averaged.** It is non-linear in `Pf`, and a chunk with
`nFail == 0` would give `Inf` (brief §3).

**`progressiveCollapseMCFn` is left serial.** Not rewritten into `parfor`
(brief §3).

**Sub-batching (`opts.subBatch`, default 5e5).** `progressiveCollapseMCFn`
pre-allocates `randn(nSamples, nGroups)` up front, so a monolithic
3.57e6-sample call costs ~340 MB per worker — ~10 GB across 28 workers,
plus worker baselines. Sub-batching caps this at ~48 MB per worker. The
seed is set **once per chunk** and the RNG stream then continues across
sub-batches (`progressiveCollapseMCFn` only calls `rng` when `opts.seed` is
present), so the brief's "one seed per chunk" contract holds and the run is
reproducible. It is not bit-identical to a monolithic call, because the
`randn(n,4)` / `randn(n,2)` draws interleave differently.

## Two caveats on the brief

**Seed independence.** `rng(1000+w)` on the default Mersenne Twister gives
different but not formally independent streams. At 6 random variables and
~3.6e6 draws per chunk the overlap risk is negligible; the rigorous
alternative (`mrg32k3a` substreams) would require changing
`progressiveCollapseMCFn`'s signature, so it was left as the brief
specifies.

**The §6(b) lower bound is not strictly binding on this oracle.**
`Pf_sys >= Pf({11,14}) == Pf_min` follows from the union-of-cut-sets
formulation. The oracle, however, is *path-dependent*: it removes only the
single `min g` member per step and re-solves. `R_4 <= |N_11|` on the intact
structure therefore does not imply system failure — a different member can
fail first, and with `gH = 3` the truss can shed up to three members and
remain stable (13 members + 3 reactions = 16 = statically determinate). A
small shortfall below `Pf_min` would consequently not be proof of a setup
error. `mcNeptunSetup`'s asserts rule a setup mismatch out independently.
