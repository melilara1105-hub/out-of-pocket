# OUT OF POCKET

An original 18+ party card game for 3–10 players. First to 10 points wins. The judge rotates every round and answers stay anonymous until all players have submitted.

## What's built

- Responsive landing page, lobby, join flow, game table and rules dialog.
- Supabase-backed room creation and six-character room codes.
- Anonymous sign-in, shared player list and synchronized game state (polling).
- Server-validated 10-card hands, one submission per player, anonymous reveal, judge-only winner selection and rotating judge.
- Seeded starter deck: 30 prompts and 70 answers.

## Connect the multiplayer backend (required once)

1. Create a free project at [Supabase](https://supabase.com/).
2. In the Supabase dashboard, open **Authentication → Sign-In / Providers** and enable **Anonymous Sign-Ins**.
3. Open **SQL Editor → New query**. Copy the entire contents of [supabase/schema.sql](supabase/schema.sql), paste it, and run it. This creates the database tables, private game RPCs and starter deck.
4. In **Project Settings → API**, copy the **Project URL** and the **anon/public key**.
5. In this repository, create a file named `config.js` (copy the shape from `config.example.js`) and replace the two placeholder values. The anon/public key is intended for browser use. **Never use the service_role key in this site.**
6. Enable GitHub Pages under **Settings → Pages → Deploy from a branch → main → /(root)**.

After GitHub Pages publishes, open the site in two or more browsers/devices. Create a room on one device and join with its code on the others. At least 3 players are required to start.

## Game rules

- 3–10 players; 10 answer cards per hand.
- One judge per round; judge rotates clockwise.
- Everyone except the judge submits one answer.
- Submissions remain hidden until every eligible player submits.
- The judge picks the winner; winner receives one point.
- First to 10 points wins.

## Security notes

- The browser uses Supabase anonymous authentication and the public anon key.
- Game tables have RLS enabled and direct table access revoked; all actions/state reads go through security-definer RPCs.
- The database validates room membership, player hands, judge permissions, submissions and scoring.
- Anonymous submissions are not returned to clients until the round enters judging.
- This project currently polls game state every ~1.8 seconds for reliability and simplicity.

## Current limitations / next improvements

- Add reconnect-friendly player identity and an explicit leave/kick flow.
- Add a host start confirmation and better handling for players who disconnect mid-round.
- Replace polling with Supabase Realtime once the room event model is ready.
- Expand the deck and introduce special cards / double-card prompts.
- Add a proper winner screen, sound and reveal animations.

OUT OF POCKET is an independent original party game project and is not affiliated with Cards Against Humanity.
