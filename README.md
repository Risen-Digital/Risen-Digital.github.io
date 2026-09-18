# Risen-Digital.github.io — prospect asset set hosting

**Purpose:** serve per-prospect "asset sets" (pitch page + working rebuild of
the prospect's own homepage) at a public, unauthenticated URL, so outbound
emails can link to something a prospect can actually open. This exists to
close item 3 of the outbound-freeze lift gate (decision #8903, commitment
#8906): the asset sets were previously only reachable at a `.ts.net`
Tailscale address, which is unreachable from outside the company network.

## URL template

```
https://risen-digital.github.io/see/{slug}/
```

`{slug}` is a lowercase, hyphenated identifier for the prospect (e.g.
`augusta-downtown-alliance`). This is the exact path shape
(`/see/{slug}`) already used by RisenDigitalSite's own Laravel
`PitchPageController` (`routes/web.php`, `App\Models\PitchPage`) — so when
real production hosting exists for that app, prospect links do not need to
change, only the domain a link resolves to.

## Why this repo and not RisenDigitalSite (project 241) directly

RisenDigitalSite is a full Laravel app (Postgres, Horizon queues, Inertia
build step, AI generation pipeline) and **has no production deployment
today** — no Forge site, no deploy workflow, no environment. Standing that
up was explicitly deferred by the operator on 2026-09-13 (commitment
#6935: "stand up Forge now" vs. "defer" — operator chose defer). It also
needs infrastructure credentials (a hosting platform, DNS on a real
domain) that an engineering session does not hold.

This repo is the smallest thing that satisfies the actual requirement —
serving a static page we already have, at a stable public URL, with no new
infra spend and no new credentials — using GitHub Pages on a repo the
`Risen-Digital` GitHub org already owns and controls. It is an interim
bridge, not a replacement for the real app: it does not carry the AI chat
widget, engagement analytics, or video player that PitchPage.tsx renders
for AI-generated pages. It carries exactly what today's hand-authored
asset sets need: two static HTML sections (pitch letter + homepage
rebuild) with no server logic.

**Decoupling note for the generation pipeline:** the block on
`risensite-ai-pipeline-keys` (ANTHROPIC_API_KEY, ELEVENLABS_API_KEY) is a
*generation* blocker, not a hosting blocker — this repo proves generation
and hosting were never actually coupled. Once those keys unblock the AI
pipeline, its HTML output can be published through the exact same
`scripts/publish-asset-set.sh`, or piped straight into RisenDigitalSite
once that app has a production home.

## Publishing a new asset set

```
scripts/publish-asset-set.sh <slug> <path-to-html-file> --push
```

This drops the file at `see/<slug>/index.html`, injects the
`noindex, nofollow, noarchive, nosnippet` robots meta tag automatically if
the source doesn't already carry one, commits, and pushes. GitHub Pages
rebuilds within roughly a minute of the push (no GitHub Actions billing
dependency — this repo uses the classic "deploy from branch" Pages source,
not an Actions workflow).

## noindex / crawler exclusion

Two independent mechanisms, both applied to every published page:

1. `<meta name="robots" content="noindex, nofollow, noarchive, nosnippet">`
   in every page's `<head>` — enforced by the publish script even for
   hand-edited source files.
2. `/robots.txt` at the repo root disallows `/see/` entirely, as a second
   layer in case a crawler ignores per-page meta (some do for `noarchive`
   caches, none should for `noindex`).

These pages are for one named recipient each, not for search engines.

## What's live today

- `see/augusta-downtown-alliance/index.html` — Augusta Downtown Alliance,
  the reference asset set (same content as agentful-artifact
  `prospect-asset-set-v1`, republished here with the noindex tag added).
