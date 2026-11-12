Issue:    wamp-proto/wamp-cicd#98
Title:    gh-actions rollout 20261112-gh-actions: wamp-cicd
URL:      https://github.com/wamp-proto/wamp-cicd/issues/98
State:    OPEN at freeze
Author:   @oberstet
Updated:  2026-11-12T01:29:51Z
Comments: 0
Frozen:   2026-11-12T01:30:35Z by `just new-branch`
SHA-256:  7f69244b3bd4405d6563b9402521b9d87fdd0d2947d33c5f267422d1970475d1 (of everything below the line)

---


## Why

The `gh-actions` aspect rollout `20261112-gh-actions` brings `wamp-cicd` in line
with its declared aspects. Computed by the aspect's `reconcile.py`
(`wamp-proto/wamp-ai@ff7eb5d8c5fa`) against apex
`5726cf8517eb`, applied mechanically by the fleet driver.

## Changes (2 file(s))

- `aspects.toml`
- `deps.toml`

### `aspects.toml` (membership, rendered from the apex)

```diff
--- a/aspects.toml
+++ b/aspects.toml
@@ -1,7 +1,11 @@
 # Materialized aspect membership for this repository.
 # Rendered from the apex inventory (all.yml); NOT a source of truth.
-aspects = ["way-a"]
+aspects = ["way-a", "gh-actions"]
 
 [provider.way-a]
 repo = "wamp-proto/wamp-ai"
 path = ".deps/wamp-ai"
+
+[provider.gh-actions]
+repo = "wamp-proto/wamp-ai"
+path = ".deps/wamp-ai"
```

## Acceptance

- The branch carries exactly the files above; re-running the aspect reconcile reports 0 changes.
- Tracked in the fleet rollout record `rollouts/20261112-gh-actions/rollout.toml` (wamp-proto/wamp-fleet).

---

## Comments at freeze (0)

