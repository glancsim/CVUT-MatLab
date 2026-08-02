# Journal — system-reliability-truss-matlab

Running record of what changed in this module and **why**. The git log says
what; this says why, and records the things that are not visible in a diff:
false starts, numbers that turned out to be wrong, traps worth not stepping in
twice.

Newest entry first. Dates are absolute. When an entry concerns the NNM 2026 /
Acta Polytechnica paper, the corresponding brief and report live in
`C:\GitHub\ctu-nnm-2026\`.

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
