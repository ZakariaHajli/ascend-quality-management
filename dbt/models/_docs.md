{% docs first_pass_yield %}
**First Pass Yield (FPY)** — accepted inspection lots divided by decided lots, per material.
The canonical definition; also expressed as a MetricFlow ratio metric so every consumer computes
it identically (no metric drift). Range 0–1.
{% enddocs %}

{% docs defect_ppm %}
**Defect PPM** — defect quantity per million inspected units (`defects / inspected_qty × 1e6`),
computed via the shared `ppm()` macro.
{% enddocs %}

{% docs bi_temporal_in_spec %}
**Bi-temporal in-spec** — conformance evaluated against the characteristic spec that was valid
**at the inspection date** (ASOF join to the Type-2 spec history), not today's spec. `verdict_differs`
flags rows whose pass/fail changed because the spec was later revised.
{% enddocs %}
