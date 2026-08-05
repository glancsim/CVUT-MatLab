# Journal — system-reliability-truss-matlab

Running record of what changed in this module and **why**. The git log says
what; this says why, and records the things that are not visible in a diff:
false starts, numbers that turned out to be wrong, traps worth not stepping in
twice.

Newest entry first. Dates are absolute. When an entry concerns the NNM 2026 /
Acta Polytechnica paper, the corresponding brief and report live in
`C:\GitHub\ctu-nnm-2026\`.

---

## 2026-08-05 — in-figure ratio labels rounded to two significant figures

**Driver:** `FIGURES_ROUND5_BRIEF.md`, itself downstream of M. Sýkora's
co-author review (paper tag `feedback-1`): stop printing more precision than
the numbers carry. `paper.tex` had already been rounded; the figures had not,
so `fig_accumulation` said `4.07x` next to body text saying `4.1`.

Formatting only — four `sprintf` format strings in `make_paper_figures.m`,
`%.2f` → `%.1f`. Every ratio the labels print lies in [1, 10), so `%.1f` *is*
two significant figures here; nothing was recomputed and no layout moved. The
underlying values were captured at ten digits before and after and are
identical (`Pf_MC/Pf_min = 4.0677737849`, `Pf_MC/Pf_sys = 1.6816305849`,
group ratios `2.8199917413` / `1.9356557464` / `0.0257316973`,
`sweepRatio(0.7) = 2.4189461237`).

`1.68x` in `fig_accumulation` deliberately keeps two decimals and now carries a
comment saying so. It is the graphical form of the `68 %` underestimate quoted
verbatim in the abstract, §3.3, §4 and the conclusions; at `%.1f` it prints
`1.7`, which reads as 70 % and contradicts all four. The rule is *two
significant figures on every ratio label, except where the label is the
graphical form of a percentage quoted in the text* — and it does not extend
further than that.

### The `-batch` graphics blocker has a workaround: the COM automation server

The entry below records that MATLAB graphics never initialise under `-batch` or
`-nodesktop` on these machines and that figures "have to be rendered from an
interactive desktop". Two launch mechanisms were tried again here and both
failed, in two *different* ways worth telling apart:

- `matlab -batch` — hangs exactly as documented, at the first `axes()` inside
  `figAccumulationFn`. Killed after 600 s, nothing written.
- `matlab -wait -sd ... -r` (a real desktop, spawned from a shell) — the
  process *dies silently* mid-figure instead of hanging: launcher exits 0, no
  crash dump, no error, the `try/catch` never reached, nothing written. Also
  note plain `matlab -r` without `-wait` returns immediately on Windows
  (`matlab.exe` is only a launcher), so anything reading a log after it sees a
  mid-run snapshot and the session gets reaped with the shell's process tree.

What **does** work, and is not in the ruled-out list: the **COM automation
server**. From PowerShell,

    $ml = New-Object -ComObject Matlab.Application
    $ml.Execute("run('<driver>.m')")
    $ml.Quit()

`figure()` and `axes()` both return, all three figures exported first try, and
`Execute` hands back the command-window output as a string so the console
diagnostics survive without a `diary`. A `diary` inside a COM session came back
empty, so rely on the returned string. This makes headless figure regeneration
possible again — worth trying before anything else next time.

---

## 2026-08-02 — per-member resistances strengthen the effect, and relocate the bound

**Driver:** `RESISTANCE_MODEL_BRIEF.md`. Report:
`ctu-nnm-2026/RESISTANCE_MODEL_REPORT.md`. New scripts:
`tests/mc_neptun/diagnostics/resistance_model_{compare,mc,detail}.m`.

Robustness check ahead of review: the paper gives 16 members only 4 resistance
variables, and three of its claims lean on that. Changing **only**
`rvSpec.resGroup/resMean/resStd` to one variable per member — areas and
`members.sections` untouched, so the structure is physically identical — gives
`beta_sys` 3.690481 → **3.613315** against an unchanged `beta_min = 3.909383`.
The effect does not merely survive, it grows: `Pf_sys/Pf_min` 2.4189 → 3.2670,
and the simulation moves the same way, `Pf_MC` 1.882e-04 → 2.290e-04
(10⁶ samples, 229 events; `1.22x`, CI [1.07, 1.39] against the 10⁸ run of
record).

### The Limitations hedge was wrong, and in the safe direction

`paper.tex` currently says per-member scatter "would weaken the bound to a
numerical statement rather than an identity". `beta_p({11,14})` does move off
`beta_min` (+1.070e-03) — but `{7,11}` and `{10,16}` **inherit** the bound at
`min_p beta_p - beta_min = +9.021e-10`. The reason is physical, not
probabilistic: losing end-panel diagonal 11 puts the support vertical 7 at
utilisation **1.427** (75.0 kN demand against 52.6 kN mean resistance, 5.3σ),
so it fails with conditional probability `1 - 3.7e-09` under any resistance
model. The bound is a property of the *set* of cut-sets; reasoning about one
member of it is what produced the wrong hedge.

### Why the union beats the intersection

Both effects were measured rather than argued. The intersection effect is
**nil**: `Pf({11,14})` falls by 0.4 %, and the `beta_p` distribution over all 91
cut-sets barely moves (median 7.0833 and max 16.1378 identical). Cut-set
probabilities here are load-driven — conditioning on member 11 failing
conditions on a high load, which drags member 14's demand up with it, so
de-correlating resistances cannot break a dependence running through the loads.
At `COV(P)=0.15` vs `COV(R)=0.08` that is the expected regime.

The union effect is large and localised: the grouped model's leading group
absorbs 26 cut-sets and counts `Pf = 4.6266e-05` **once**; per-member it splits
into `{7,11}` and `{10,16}`, each carrying the same probability, so the
dominant term is counted **twice**. That one regrouping is ~85 % of the total
`Pf_sys` increase. Consistent with the `PREEMPTION_CHECK` entry below, which
finds all of the shortfall in that same group.

### The correlation collapse is real but does not close the gap

Among the 8 leading cut-sets, pairs above `rho0` fall 28/28 → 12/28
(mean 0.939 → 0.605) and PNET groups go 18 → 36. Yet the shortfall only shrinks
68 % → 51 %, and the six pairwise correlations among the four leading simulated
mechanisms show exactly why:

| pair | grouped | per-member |
|---|---|---|
| `{11,14}`–`{7,11}` (sequences `[11 14]`, `[11 7]`) | 1.0000 | **1.0000** |
| `{13,16}`–`{10,16}` (sequences `[16 13]`, `[16 10]`) | 1.0000 | **1.0000** |
| the four cross-panel pairs | 0.8940 | 0.3077–0.3095 |

Two sequences that **open on the same member** have identical equivalent planes
whatever the resistance model, because `equivalentPlaneFn` reduces a sequence to
one plane dominated by its first limit state. Shared resistance explains the
four pairs that collapse; the one-plane-per-cut-set reduction explains the two
that do not. The paper attributes all of it to the shared resistance.

### Three brief predictions that did not hold

- The 68 % shortfall would "shrink or disappear" — it shrank to 51 % and
  structurally cannot close (above).
- The bound "stops being an identity" — only for `{11,14}`; the bound itself
  holds to 9e-10.
- The seed scatter "may well come out deterministic" once the shared-`R_4` tie
  is gone — it does not. **18 distinct `beta_sys` values in 20 seeds** against
  the grouped model's 13, group count 37–42 against 13–20. The std is smaller
  (0.006955 vs 0.008306) only because the range is narrower. The paper's
  "not diffuse but a single grouping decision flipping" is a grouped-model
  statement and must not be generalised.

### Two errors found in `paper.tex` in passing

- Line 667 calls `{11,14}` "the two diagonals of the **central** panel". Member
  11 is node 1 `(0,0)`→node 6 `(4,2)` and member 14 is node 2 `(4,0)`→node 5
  `(0,2)`: they cross in `x ∈ [0,4]`, the **end** panel at the pinned support.
  The central panel's X is `{12,15}`, the two *least* critical members
  (`beta = 10.2966`). The sentence sits inside the bound argument, where the
  end-panel location is exactly the point.
- Lines 721–724 quote the representative correlations as "mean of 0.020" while
  citing the 8-representative figure. `0.020` is the mean over **ten** (45
  pairs); over the eight plotted (28 pairs) it is `0.057`. Min and max coincide
  at both `n`, so only the mean is affected.

### Notes for anyone repeating this

`equivalentPlaneFn` costs `2n` `cornellIndexFn` calls per cut-set, so tripling
`nU` from 6 to 18 looked like it would triple runtime. It did not — measured
slowdown **1.10x**, because the FEM solves in `mostProbableSequenceFn` dominate.
52 pipeline runs took 12.7 min.

The two MC variants share chunk seeds but are **not** paired and the grouped
10⁶ run is **not** a subset of the published 10⁸: `progressiveCollapseMCFn`
allocates `randn(nSamples, nGroups)` column-major, so both a different
`nGroups` (4 vs 16) and a different `nSamples` per chunk (62 500 vs 3 571 429)
reshuffle the stream entirely. Agreement with the published number is a wiring
check, not a second estimate.

Nothing committed, no figure regenerated, `paper.tex` untouched. The concurrent
`preemption_check.m` job and the modified `make_paper_figures.m` were left
alone.

---

## 2026-08-02 — the per-group "overcount" was never an overcount

**Driver:** `PREEMPTION_CHECK_BRIEF.md`. Report:
`ctu-nnm-2026/PREEMPTION_CHECK_REPORT.md`. New script:
`tests/mc_neptun/diagnostics/preemption_check.m`.

The entry above attributes the whole PNET discrepancy to the grouping step and
reads figure `fig_pnet_vs_mc` row by row: two groups undercounted, two
overcounted, errors nearly cancelling. **The two "overcounted" rows were being
read wrong**, and the reason is that the figure puts two different quantities
side by side — an analytical probability of an event that *overlaps* its
neighbours, against a simulated count that is a *disjoint partition* of
observed collapses.

Measured over all 10⁸ samples, every analytical cut-set probability is right:

| representative | predicted | observed | z |
|---|---|---|---|
| `{11,14}` | 4626.6 | 4609 | −0.26 |
| `{1,2,8}` | 2943.2 | 2861 | −1.52 |
| `{5,12}` | 2914.7 | 2930 | +0.28 |
| `{4,8,9,16}` | 707.4 | 702 | −0.20 |

`{5,12}` is violated 2 930 times and completes the collapse 31 times, because
in 97 % of those samples the structure has already failed as `{2,5}`.
`{4,8,9,16}` is violated 754 times and completes 0 times — `{13,16}` gets there
first in 91 %. Pre-emption, not overestimation.

**The sharp version.** 2 929 of `{5,12}`'s 2 930 samples are *the same samples*
the simulation books as `{2,5}`. The two cut-sets are one event reached in
opposite orders: `mostProbableSequenceFn` prices only the single most probable
ordering of each cut-set (`min beta_p` over `perms`), so the member-2-first
order is filed under `{2,5}` in group 2 and the member-5-first order under
`{5,12}`/`{5,15}` in group 3. Re-pair the groups and the discrepancy vanishes:
groups 2+3 give `5.8579e-05` against a simulated `5.7720e-05` (0.99), while
groups 1+4 stay 2.45× short. **All of the 7.63e-05 system shortfall is in the
`{11,14}` group** — so "concentrated in the grouping step" is now literally
true, rather than four errors that happen to sum correctly.

### Two traps worth not stepping in twice

**The stored `.mat` cannot answer this question.** `failSequences` holds only
*failed* samples and each sequence stops at the first mechanism, so "all members
of the cut-set failed" collapses into "the cut-set *was* the mechanism". The way
round it, without a second 2 h run: **deterministic replay**. For a fixed set of
surviving members the axial forces are linear in the two load multipliers, so
one pair of unit-load FEM solves per structural state (18 states, memoised)
reproduces every sample's outcome exactly — 10⁸ samples in 91 s instead of 2 h,
gated on reproducing all 28 per-chunk failure counts and all 12 mechanism counts
bit-for-bit.

**`rng(seed)` does not set the generator, only the seed.** The run of record is
reproducible only under **Threefry**, because a parpool worker's default
generator is Threefry while the client's is Mersenne Twister. `runMcChunk.m`
(the no-PCT fallback) is seeded identically and will *not* reproduce the numbers
of record. Under `'twister'` the same seeds give `nFail = 18 799` instead of
`18 820`. Documented in `tests/mc_neptun/README.md`.

Also found: `MC_NEPTUN_FINDINGS.md` §2 states group 3 is "33× over". The ratio
is `2.9147e-05 / 7.500e-07 = 38.9`; the paper's 39 is the correct one.

Nothing was committed, no figure regenerated and `paper.tex` untouched — the
report proposes the wording changes for §3.3 and leaves the decision open.

---

## 2026-08-02 — Monte Carlo cross-check lands, and it overturns the headline

**Driver:** `FIGURES_ADDENDUM_MC.md`. The 10⁸-sample progressive-collapse run
finished on neptun and disagreed with the analytical result *in the direction
nobody expected*.

| | |
|---|---|
| `Pf_min` (component, exact) | `4.62660874e-05` |
| `Pf_sys` (PNET, `rho0=0.7`, `rng(42)`) | `1.11915173e-04` |
| `Pf_MC` (10⁸ samples) | `1.88199977e-04` |
| `Pf_MC / Pf_sys` | `1.68` — PNET is **68 % low**, 61 sigma |

The prior assumption was that PNET over-estimates the union. It under-estimates
it here, so the paper's headline number is now the simulation, not the
cut-set analysis. Figures 3, 4 and 6 were rebuilt around that and figure 7 is new.

### Why the analytical method is wrong here

Not in the combination step — in the **grouping** step. Figure 5 is the
diagnostic: among the ten most critical *cut-sets*, all 45 off-diagonal
correlations sit at 0.894 or 1.000, so PNET folds all of them into one group.
Four of those cut-sets — `{11,14}`, `{13,16}`, `{7,11}`, `{10,16}` — are the
four leading mechanisms the simulation actually observes, in 3822, 3831, 2659
and 2650 **mutually exclusive** samples. The linearisation calls them one
event; they are not. Among the surviving *representatives* the correlations are
fine (0 of 45 above `rho0`, mean 0.02), which is why the figure now shows both
matrices side by side rather than only the flattering one.

### `pnetSystemReliabilityFn` could hang, and now cannot

Found while computing a `rho0 -> 1` reference point. The grouping loop absorbs
every cut-set `k` with `rho_1k >= rho0`. At `rho0 > 1` it absorbs nothing — not
even the representative against itself — so `remaining` never shrinks, `groups`
grows without bound, and MATLAB spins until it dies. `rho0 == 1` exactly is
unsafe for a subtler reason: the `alphaTilde` rows are unit-norm only to
floating-point accuracy, and **32 of the 91 self-correlations evaluate just
below 1**, so whether a representative absorbs itself depends on rounding.

Fixed in `src/pnetSystemReliabilityFn.m` (not by me — landed separately while
this work was in flight) by rejecting `rho0 > 1` outright and asserting
`rho1k(1) = 1`, which makes termination structural rather than numerical.
Verified afterwards that every published number is unchanged: the whole `rho0`
sweep, `beta_sys`, `Pf_sys` and the group count all reproduce exactly, because
the assertion only forces something that was already true at every `rho0` we
actually use.

### The `rho0 -> 1` point in the addendum was wrong twice

It was given as `6.78`, described as the fully-independent limit. Measured:

```
1-eps    1e-2   1e-3   1e-4   1e-5   1e-6   1e-9   1e-12  1e-15
ratio    6.78   6.78   6.78   7.41   8.67  11.04   13.04  14.31
groups     62     66     66     69     71     75      79     81
```

and treating all 91 cut-sets as independent gives **21.21**. So `6.78` is just
the value at `rho0 ~ 0.999`, the end of a plateau at 66 groups, and the
sequence keeps climbing with no limit worth plotting. Figure 6 carries 0.999 as
an ordinary measured point and stops; the shaded "unstable" region past 0.95
makes the argument better than a fabricated limit marker would, because the
6.78 → 14.31 spread *is* the instability.

### Files

- `examples/make_paper_figures.m` — figures 3, 4, 6 rebuilt; figure 7 added;
  figure 5 became two panels. Gained an optional second argument
  (`make_paper_figures([], 3)`) so one figure can be re-exported while
  iterating on its layout. Reads `tests/mc_neptun/mc_neptun_result.mat` and
  derives the mechanism tally and per-group MC probabilities from
  `out.failSequences` rather than transcribing them, so they track the raw data.
- `examples/example_warren_xbrace_paper.m` — `rho0` sweep extended to 0.98 and
  0.999 (now 10 points, 31 pipeline runs).

### Two things about the truss that the figures made visible

The five dominant simulated mechanisms are **not** in five different parts of
the structure, which is what the prose claimed. `{11,14}` and `{7,11}` are both
in the left panel; `{13,16}` and `{10,16}` are both in the right. Three
mechanism types in three regions, two of them mirrored — which is forced, since
the truss is symmetric. The argument still holds (all five are two-member
mechanisms within a factor of 2.2 of each other) but the wording needed fixing.

One observed mechanism, `{7,10,16}` (one sample in 10⁸), matches no minimal
cut-set and therefore belongs to no PNET group. The per-group probabilities sum
to `1.88190e-04` against `Pf_MC = 1.88200e-04`; the difference is exactly that
one sample.

---

## 2026-08-01/02 — reproducibility, and the first set of paper figures

**Driver:** `REPRO_AND_FIGURES_BRIEF.md`.

### The module was not deterministic and did not say so

`cornellIndexFn` evaluates `mvncdf` for cut-sets of four or more members, and
MATLAB switches to randomised quasi-Monte Carlo quadrature at dimension 4. Over
20 seeds with identical inputs: `beta_sys = 3.6971 ± 0.0083`, group count
wandering between 13 and 20 as borderline correlations cross `rho0`. A bare
four-decimal `beta_sys` was therefore not reproducible.

Fixed by documenting it at the source (`src/cornellIndexFn.m` header, with the
measured scatter and an explicit "do not tighten the mvncdf tolerances — that
changes the answer rather than stabilising it"), cross-referencing it from
`src/systemReliabilityFn.m` so a caller finds it without reading the whole
chain, and seeding the example. Deliberately *not* fixed by rewriting the
integration: a seed is the honest fix.

### Model setup factored out

`examples/warrenXbraceModelFn.m` is new and now owns the geometry, boundary
conditions, RV spec and FSD sizing. `example_warren_xbrace.m`,
`example_warren_xbrace_paper.m` and `make_paper_figures.m` all call it, so the
demo, the published numbers and the figures cannot drift apart. It draws no
random numbers, so it is safe to call before or after `rng()`.

Two stale comments went with it: the header claimed 50 kN loads where the code
uses 75 kN, and a note claimed 75 kN gives "~1–2 % MC failures" when the real
system failure probability is `1.1e-04`, i.e. 0.011 % — a hundred times
smaller. The corrected note now says what a meaningful MC check would cost
(~10⁷ samples), which is what eventually justified the neptun run.

### Everything the paper quotes is regenerated by one script

`examples/example_warren_xbrace_paper.m`. All fourteen acceptance values
reproduced exactly on the first run, including the 20-seed noise statistics.

Runtime is honest rather than optimistic: 31 full `systemReliabilityFn` calls,
measured anywhere between 7.4 s and 26 s each depending on the machine's
thermal state — the run that produced the published numbers wall-clocked 134
minutes on a throttled machine. The `rho0` sweep is deliberately *not*
shortcut through `pnetSystemReliabilityFn`, even though `rho0` only enters the
final step and the shortcut is provably identical, so the sweep makes no
correctness claim the reader has to take on trust. (`make_paper_figures` does
take the shortcut, and says so — it is redrawing, not publishing.)

### Traps worth not stepping in twice

**R2026a's web renderer fails silently on degenerate patches.** It throws
`Cannot read properties of null (reading 'lineWidth')` and then exports the
figure with *nothing in it but the legend* — no error, a plausible-looking PDF,
just empty. Off-screen legend keys must be real quads with area: `NaN` vertices
fail, and so does a three-vertex patch whose x coordinates are all identical.
Figure 2 shipped blank once because of this.

**`ItemTokenSize`** is no longer accepted as a `legend()` construction argument
in R2026a ("Unknown property") but still works through `set()` afterwards.

**`exportgraphics(..., 'ContentType', 'vector')` rasterises the whole figure**
if anything in it uses `FaceAlpha`. Figure 6's confidence band is a solid grey
for that reason.

**MATLAB graphics will not initialise under `-batch` or `-nodesktop`** on either
machine here — `figure()` succeeds, `axes()` never returns. Ruled out: renderer
flags, `-nojvm`, fresh prefdir, GPU env vars, function shadowing, orphaned
helper processes, session isolation. Compute is unaffected. Figures have to be
rendered from an interactive desktop.

**`plotTrussFn` cannot label an X-braced truss.** Its `'Labels', true` mode puts
each member number at the member midpoint, and both diagonals of an X-braced
panel share the same midpoint — so members 11/14, 12/15 and 13/16 are drawn
exactly on top of each other. `fig_geometry` places diagonal labels at 30 % along
the member instead. The underlying bug in
`fem-2d-truss-matlab/src/plotTrussFn.m` is untouched and still there for any
X-braced truss.

---

## Conventions

- Absolute dates, newest first.
- Record the *reason*, and record what was tried and rejected — a diff already
  shows what changed.
- When a number in a brief turns out to be wrong, write down both the claimed
  and the measured value.
- Findings that belong to another module (`fem-2d-truss-matlab`, etc.) are
  noted here but fixed there, separately.
