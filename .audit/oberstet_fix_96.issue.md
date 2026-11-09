Issue:    wamp-proto/wamp-cicd#96
Title:    Bump the GitHub Actions used inside wamp-cicd (checkout, upload-artifact) to Node 24 versions, pinned by SHA
URL:      https://github.com/wamp-proto/wamp-cicd/issues/96
State:    OPEN at freeze
Author:   @oberstet
Updated:  2026-11-09T16:18:20Z
Comments: 0
Frozen:   2026-11-09T16:20:10Z by `just new-branch`
SHA-256:  a79a9fee090d43fb53233cd719c48ba9f02e709d11d270184038bdd208cdf3fe (of everything below the line)

---

## Problem

Every job in the WAMP repos that uses wamp-cicd now shows this warning (seen on crossbario/wamp-xbr PR #221, 2026-11-09):

> Node.js 20 is deprecated. The following actions target Node.js 20 but are being forced to run on Node.js 24: actions/checkout@v4, astral-sh/setup-uv@v6, extractions/setup-crate@…

Part of that comes from wamp-cicd itself. All seven consuming repos (autobahn-python, crossbar, txaio, zlmdb, cfxdb, wamp-xbr, autobahn-js) call wamp-cicd's reusable workflow and actions **`@main`**, so these lines run in every one of them:

| File (wamp-cicd `main` at `79d4c1d`) | Line | Uses | Latest |
|---|---|---|---|
| `.github/workflows/identifiers.yml` | 104 | `actions/checkout@v4` | v7.0.1 |
| `actions/upload-artifact-verified/action.yml` | 142 | `actions/upload-artifact@v4` | v7.0.2 |
| `.github/workflows/test.yml` | 28 | `actions/checkout@11bd719… # v4.2.2` | v7.0.1 |
| `.github/workflows/check-aspect.yml` | 34 | `actions/checkout@11bd719… # v4.2.2` | v7.0.1 |

The consumers use these wamp-cicd pieces this many times: `identifiers.yml` 23, `upload-artifact-verified` 33, `download-artifact-verified` 126.

`actions/download-artifact-verified` does **not** use `actions/download-artifact`: it fetches through `gh api …/actions/runs/<id>/artifacts`. So nothing in wamp-cicd has to move in step with `upload-artifact`. But wamp-xbr's `main.yml` (line 258, the verify job) uses `actions/download-artifact@v4` directly on artifacts that `upload-artifact-verified` produced. That consumer has to keep working after the bump.

## The change

1. Pin third-party actions by full commit SHA with an exact-version comment. This is the form the two test workflows already use:
   - `actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1` in `identifiers.yml`, `test.yml` and `check-aspect.yml`.
   - `actions/upload-artifact@cf430e030ddbb5b0abf93d22962f4752f3646cd9 # v7.0.2` in `upload-artifact-verified`.

   Re-resolve both SHAs from the tags when implementing.
2. Before bumping, read the release notes for these majors:
   - **upload-artifact v5**: Node 24 support, `@actions/artifact` v4.
   - **upload-artifact v6**: runs on Node 24 and needs runner ≥ 2.327.1.
   - **upload-artifact v7**: ESM, and a new `archive` input that defaults to zipping, so behaviour is unchanged. Also check that `include-hidden-files` (which the action sets, see the comment at line 146) and `retention-days` keep their meaning.
   - **checkout v6**: persisted credentials are written to a separate file (actions/checkout#2286). `identifiers.yml` checks out with `submodules: recursive` and `fetch-depth: 0`, so the test run must show that submodules and tags still arrive.
   - **checkout v7**: refuses to check out a fork PR under `pull_request_target` and `workflow_run`. `identifiers.yml` checks out with no `ref:`, so this should not apply, but the reusable workflow is called from `workflow_run` (release-post-comment) in several repos.
3. Keep uploads zipped, and set it explicitly. `download-artifact-verified` downloads through the `…/artifacts/<id>/zip` endpoint, so it depends on every artifact being a zip. v7's `archive` defaults to `true`, but `archive: false` anywhere would break every verified download in all seven repos. Set `archive: true` explicitly in `upload-artifact-verified`, with a comment naming that dependency.

## Verifying before it reaches `main`

A change here reaches all seven repos at once. So test it first from a branch. Push `fix_<N>` to `wamp-proto/wamp-cicd` on GitHub temporarily, because a `uses:` ref only resolves against GitHub. In a throwaway PR, point one consumer's workflows at it (`wamp-proto/wamp-cicd/…@fix_<N>` instead of `@main`), and check that these pass on a real GitHub run:

- identifiers, with submodules and tags checked out (`git submodule status`, `git tag` non-empty);
- an upload-artifact-verified → download-artifact-verified round trip;
- wamp-xbr's direct `actions/download-artifact@v4` on a verified artifact.

## Done when

- None of the four lines above appear in the Node 20 deprecation warning.
- One consumer's real GitHub run from the branch passes the checks above, before the change lands on `main`.

## Related

- The other actions in the warning (`setup-uv`, `setup-just` → `setup-crate`) and the rest of the third-party actions live in the consuming repos. They are tracked in crossbario/autobahn-crossbar-ai (the new `workflow-actions` aspect; that issue links back here). The Node 20 warning is fully gone only when both issues have landed.
- Out of scope, recorded for a separate decision: consumers call wamp-cicd `@main`, so a wamp-cicd change reaches every repo at once, with no rollout or provenance.

---

## Comments at freeze (0)

