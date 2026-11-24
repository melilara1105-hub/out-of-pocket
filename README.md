# OUT OF POCKET

An 18+ multiplayer party card game for 3–10 players. First to 10 points wins. The judge rotates every round and submissions are anonymous until reveal.

## Current status

This repository contains the first front-end prototype:
- Landing page, lobby, join screen, game screen and rules dialog
- Original starter prompt and answer deck
- Basic hand selection, reveal, judging and scoring UI

**Important:** This first version is a local prototype, not yet a fully synchronized online multiplayer game. Online rooms require a Supabase project, database schema, row-level security policies and server-side game actions. Do not put a Supabase service-role key in browser code.

## Run locally

Open `index.html` in a browser, or use GitHub Pages to host the static prototype.

## Publish with GitHub Pages

1. Open the repository's **Settings → Pages**.
2. Under **Build and deployment**, choose **Deploy from a branch**.
3. Select `main` and `/ (root)`, then save.
4. Wait for GitHub Pages to publish the site.

## Game rules

- 3–10 players
- 10 answer cards per hand
- One rotating judge per round
- One anonymous answer submission per non-judge
- Judge selects the winning answer
- Winner receives one point
- First to 10 points wins

## Planned next steps

1. Connect real multiplayer rooms and presence with Supabase.
2. Enforce anonymous submissions and judging on the server.
3. Add reconnect handling, turn validation and full deck rotation.
4. Expand the original card library and add optional special cards.

OUT OF POCKET is an independent original party game project and is not affiliated with Cards Against Humanity.
