
-- OUT OF POCKET multiplayer schema
-- Run this entire file in Supabase SQL Editor after enabling Anonymous Sign-Ins.
create extension if not exists pgcrypto;

create table if not exists public.op_rooms (
 id uuid primary key default gen_random_uuid(),
 code text not null unique,
 host_id uuid not null,
 status text not null default 'lobby' check(status in ('lobby','playing','finished')),
 round_number integer not null default 0,
 judge_player_id uuid,
 current_round_id uuid,
 created_at timestamptz not null default now()
);
create table if not exists public.op_players (
 id uuid primary key default gen_random_uuid(),
 room_id uuid not null references public.op_rooms(id) on delete cascade,
 user_id uuid not null,
 display_name text not null check(char_length(display_name) between 1 and 18),
 score integer not null default 0,
 seat integer not null,
 joined_at timestamptz not null default now(),
 unique(room_id,user_id),
 unique(room_id,seat)
);
create table if not exists public.op_prompts (
 id bigserial primary key,
 body text not null unique
);
create table if not exists public.op_answers (
 id bigserial primary key,
 body text not null unique
);
create table if not exists public.op_rounds (
 id uuid primary key default gen_random_uuid(),
 room_id uuid not null references public.op_rooms(id) on delete cascade,
 prompt text not null,
 judge_player_id uuid not null references public.op_players(id),
 status text not null default 'submitting' check(status in ('submitting','judging','complete')),
 created_at timestamptz not null default now()
);
alter table public.op_rooms drop constraint if exists op_rooms_current_round_id_fkey;
alter table public.op_rooms add constraint op_rooms_current_round_id_fkey foreign key(current_round_id) references public.op_rounds(id) on delete set null;
create table if not exists public.op_hands (
 player_id uuid not null references public.op_players(id) on delete cascade,
 card_id bigint not null references public.op_answers(id),
 primary key(player_id,card_id)
);
create table if not exists public.op_submissions (
 id uuid primary key default gen_random_uuid(),
 round_id uuid not null references public.op_rounds(id) on delete cascade,
 player_id uuid not null references public.op_players(id),
 card_text text not null,
 created_at timestamptz not null default now(),
 unique(round_id,player_id)
);
create table if not exists public.op_winners (
 round_id uuid primary key references public.op_rounds(id) on delete cascade,
 submission_id uuid not null references public.op_submissions(id),
 player_id uuid not null references public.op_players(id)
);

insert into public.op_prompts(body) values
('My FBI agent finally quit after witnessing ______.'),
('The worst thing to find in your date''s search history is ______.'),
('My villain origin story began with ______.'),
('Nothing ruins a first date faster than ______.'),
('The new Olympic sport is ______.'),
('My therapist''s therapist is going to need therapy after hearing about ______.'),
('The reason my DoorDash driver blocked me was ______.'),
('The group chat has officially been shut down because of ______.'),
('The real reason the Wi-Fi is slow is ______.'),
('My last brain cell is currently busy dealing with ______.'),
('The only thing standing between me and financial stability is ______.'),
('The worst possible thing to hear from your pilot is ______.'),
('My parents said I could be anything, so naturally I became ______.'),
('The next season of reality TV will feature ______.'),
('The secret ingredient in every family argument is ______.'),
('The government is hiding ______ from us.'),
('My dating profile was rejected for containing ______.'),
('The new employee orientation was interrupted by ______.'),
('The apocalypse could have been prevented if not for ______.'),
('The most embarrassing thing to say during a job interview is ______.'),
('My search history looks like it was written by ______.'),
('The only thing worse than a situationship is ______.'),
('I knew the family reunion was going downhill when ______.'),
('The CEO''s emergency meeting was called because of ______.'),
('My sleep paralysis demon has a side hustle selling ______.'),
('The internet collectively agreed to cancel ______.'),
('The worst thing to accidentally send to the family group chat is ______.'),
('My toxic trait is believing I can fix ______.'),
('The new school rule bans ______.'),
('The reason aliens refuse to visit Earth is ______.')
on conflict(body) do nothing;
insert into public.op_answers(body) values
('A man whose entire personality is his truck.'),
('A 12-year-old explaining cryptocurrency.'),
('The emotional intelligence of a wet sock.'),
('A 3 AM text that should''ve stayed in drafts.'),
('A suspiciously confident raccoon.'),
('A podcast with three male hosts and zero qualifications.'),
('Being financially dependent on a situationship.'),
('A 2009 Facebook status coming back to haunt me.'),
('A 47-minute bathroom break at Target.'),
('The audacity of someone who owes me $37.'),
('A family-sized bag of shredded cheese eaten in the dark.'),
('A LinkedIn motivational post written during a breakdown.'),
('A situationship with more plot holes than a Marvel movie.'),
('Asking ChatGPT to write an apology I don''t mean.'),
('A vape with the battery percentage of my will to live.'),
('A ring light and absolutely no self-awareness.'),
('A man who says ''I''m an empath'' before ruining your week.'),
('The Duolingo owl holding my loved ones hostage.'),
('A live laugh love sign in a divorce lawyer''s office.'),
('A raccoon with a criminal record.'),
('A 14-part TikTok storytime with no conclusion.'),
('An expired coupon and a dream.'),
('The confidence of a mediocre man with a podcast.'),
('A family group chat that should be evidence in court.'),
('A situationship soft launch that needs a federal investigation.'),
('A Stanley cup full of unresolved trauma.'),
('A printer that senses fear.'),
('A public apology filmed in the front seat of a car.'),
('A man whose bed frame is still on back order.'),
('A suspicious amount of enthusiasm for team-building exercises.'),
('A screenshot with 900 pixels of context missing.'),
('A corporate email that starts with ''per my last email.'''),
('A vape break during a fire drill.'),
('A 40-year-old man calling himself an alpha.'),
('A ghost with terrible communication skills.'),
('A chicken nugget found in the washing machine.'),
('A motivational quote over a photo of a rented Lamborghini.'),
('A group project where one person has done literally everything.'),
('A 6''4 man with the emotional range of a teaspoon.'),
('A full moon and one bad decision.'),
('A Venmo request for emotional damages.'),
('A family secret revealed by the aunt who had two margaritas.'),
('A FaceTime call from someone who could have texted.'),
('A dating app bio that says ''fluent in sarcasm.'''),
('A landlord who thinks exposed brick is a personality.'),
('A 3-page notes app apology.'),
('A Roomba with a personal vendetta.'),
('A podcast clip that begins with ''women these days.'''),
('A suspiciously specific Google search.'),
('The audacity to say ''calm down'' to someone who is calm.'),
('A situationship sponsored by mixed signals.'),
('A LinkedIn connection request from my ex.'),
('A gas station sushi incident.'),
('An AI-generated apology with the wrong name in it.'),
('A 900-day Snapchat streak and no actual conversation.'),
('A man who claps when the plane lands.'),
('The last functioning brain cell in the group chat.'),
('A work email sent at 11:58 PM that says ''quick question.'''),
('A 2016 Instagram caption resurfacing at the worst time.'),
('A family-size bag of emotional support fries.'),
('A fake birthday to get free dessert.'),
('A situationship that needs a project manager.'),
('A suspiciously wet bathroom floor.'),
('A motivational podcast recorded in a leased car.'),
('A pigeon with a side quest.'),
('A 5-minute voice note that could have been seven words.'),
('A man who says ''I hate drama'' and is the drama.'),
('An Uber driver who knows too much.'),
('A haunted Stanley cup.'),
('A resignation letter written in the Taco Bell parking lot.')
on conflict(body) do nothing;

alter table public.op_rooms enable row level security;
alter table public.op_players enable row level security;
alter table public.op_rounds enable row level security;
alter table public.op_hands enable row level security;
alter table public.op_submissions enable row level security;
alter table public.op_winners enable row level security;
alter table public.op_prompts enable row level security;
alter table public.op_answers enable row level security;
-- All game reads/writes go through security-definer RPCs to keep hands and unrevealed cards private.
revoke all on public.op_rooms,public.op_players,public.op_rounds,public.op_hands,public.op_submissions,public.op_winners,public.op_prompts,public.op_answers from anon,authenticated;

create or replace function public.op_create_room(p_name text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_room op_rooms; v_player op_players;
begin
 if auth.uid() is null then raise exception 'Sign in required'; end if;
 if char_length(trim(p_name)) not between 1 and 18 then raise exception 'Name must be 1–18 characters'; end if;
 insert into op_rooms(code,host_id) values(upper(substr(encode(gen_random_bytes(5),'hex'),1,6)),auth.uid()) returning * into v_room;
 insert into op_players(room_id,user_id,display_name,seat) values(v_room.id,auth.uid(),trim(p_name),1) returning * into v_player;
 return jsonb_build_object('code',v_room.code,'player_id',v_player.id);
end $$;

create or replace function public.op_join_room(p_code text,p_name text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_room op_rooms; v_player op_players; v_count int;
begin
 if auth.uid() is null then raise exception 'Sign in required'; end if;
 select * into v_room from op_rooms where code=upper(trim(p_code)) for update;
 if not found then raise exception 'Room not found'; end if;
 if v_room.status<>'lobby' then raise exception 'This game has already started'; end if;
 select * into v_player from op_players where room_id=v_room.id and user_id=auth.uid();
 if found then return jsonb_build_object('code',v_room.code,'player_id',v_player.id); end if;
 select count(*) into v_count from op_players where room_id=v_room.id;
 if v_count>=10 then raise exception 'Room is full'; end if;
 if char_length(trim(p_name)) not between 1 and 18 then raise exception 'Name must be 1–18 characters'; end if;
 insert into op_players(room_id,user_id,display_name,seat) values(v_room.id,auth.uid(),trim(p_name),v_count+1) returning * into v_player;
 return jsonb_build_object('code',v_room.code,'player_id',v_player.id);
end $$;

create or replace function public.op_start_game(p_code text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_room op_rooms; v_judge op_players; v_round op_rounds; v_count int; v_player op_players; v_prompt text;
begin
 select * into v_room from op_rooms where code=upper(trim(p_code)) for update;
 if not found or v_room.host_id<>auth.uid() then raise exception 'Only the host can start this room'; end if;
 select count(*) into v_count from op_players where room_id=v_room.id;
 if v_count<3 then raise exception 'At least 3 players are required'; end if;
 if v_room.status<>'lobby' then raise exception 'Game already started'; end if;
 select * into v_judge from op_players where room_id=v_room.id order by seat limit 1;
 select body into v_prompt from op_prompts order by random() limit 1;
 update op_rooms set status='playing',round_number=1,judge_player_id=v_judge.id where id=v_room.id;
 insert into op_rounds(room_id,prompt,judge_player_id) values(v_room.id,v_prompt,v_judge.id) returning * into v_round;
 update op_rooms set current_round_id=v_round.id where id=v_room.id;
 for v_player in select * from op_players where room_id=v_room.id loop
  insert into op_hands(player_id,card_id)
  select v_player.id,id from op_answers order by random() limit 10;
 end loop;
 return public.op_get_state(p_code);
end $$;

create or replace function public.op_submit_card(p_code text,p_card_id bigint)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_room op_rooms; v_round op_rounds; v_player op_players; v_card text; v_total int; v_expected int;
begin
 select * into v_room from op_rooms where code=upper(trim(p_code)) for update;
 select * into v_player from op_players where room_id=v_room.id and user_id=auth.uid();
 if not found then raise exception 'You are not in this room'; end if;
 select * into v_round from op_rounds where id=v_room.current_round_id for update;
 if v_player.id=v_round.judge_player_id then raise exception 'The judge cannot submit'; end if;
 if v_round.status<>'submitting' then raise exception 'Submissions are closed'; end if;
 select body into v_card from op_answers a join op_hands h on h.card_id=a.id where h.player_id=v_player.id and a.id=p_card_id;
 if v_card is null then raise exception 'That card is not in your hand'; end if;
 insert into op_submissions(round_id,player_id,card_text) values(v_round.id,v_player.id,v_card);
 delete from op_hands where player_id=v_player.id and card_id=p_card_id;
 insert into op_hands(player_id,card_id) select v_player.id,id from op_answers a where not exists(select 1 from op_hands h where h.player_id=v_player.id and h.card_id=a.id) order by random() limit 1;
 select count(*) into v_total from op_submissions where round_id=v_round.id;
 select count(*)-1 into v_expected from op_players where room_id=v_room.id;
 if v_total>=v_expected then update op_rounds set status='judging' where id=v_round.id; end if;
 return public.op_get_state(p_code);
end $$;

create or replace function public.op_choose_winner(p_code text,p_submission_id uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_room op_rooms; v_round op_rounds; v_sub op_submissions; v_player op_players;
begin
 select * into v_room from op_rooms where code=upper(trim(p_code)) for update;
 select * into v_round from op_rounds where id=v_room.current_round_id for update;
 select * into v_player from op_players where room_id=v_room.id and user_id=auth.uid();
 if v_player.id is distinct from v_round.judge_player_id then raise exception 'Only the judge can choose'; end if;
 if v_round.status<>'judging' then raise exception 'Wait for all answers before judging'; end if;
 select * into v_sub from op_submissions where id=p_submission_id and round_id=v_round.id;
 if not found then raise exception 'Submission not found'; end if;
 insert into op_winners(round_id,submission_id,player_id) values(v_round.id,v_sub.id,v_sub.player_id);
 update op_players set score=score+1 where id=v_sub.player_id;
 update op_rounds set status='complete' where id=v_round.id;
 if (select score from op_players where id=v_sub.player_id)>=10 then update op_rooms set status='finished' where id=v_room.id; end if;
 return public.op_get_state(p_code);
end $$;

create or replace function public.op_next_round(p_code text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_room op_rooms; v_old op_rounds; v_judge op_players; v_round op_rounds; v_prompt text;
begin
 select * into v_room from op_rooms where code=upper(trim(p_code)) for update;
 if not found then raise exception 'Room not found'; end if;
 select * into v_old from op_rounds where id=v_room.current_round_id;
 if v_room.status='finished' then raise exception 'Game is over'; end if;
 if v_old.status<>'complete' then raise exception 'This round is not complete'; end if;
 select * into v_judge from op_players where room_id=v_room.id and seat=(select mod(seat,(select count(*) from op_players where room_id=v_room.id))+1 from op_players where id=v_old.judge_player_id);
 select body into v_prompt from op_prompts order by random() limit 1;
 update op_rooms set round_number=round_number+1,judge_player_id=v_judge.id where id=v_room.id;
 insert into op_rounds(room_id,prompt,judge_player_id) values(v_room.id,v_prompt,v_judge.id) returning * into v_round;
 update op_rooms set current_round_id=v_round.id where id=v_room.id;
 return public.op_get_state(p_code);
end $$;

create or replace function public.op_get_state(p_code text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_room op_rooms; v_me op_players; v_round op_rounds; v_submissions jsonb; v_hand jsonb; v_players jsonb; v_winner jsonb;
begin
 select * into v_room from op_rooms where code=upper(trim(p_code));
 if not found then raise exception 'Room not found'; end if;
 select * into v_me from op_players where room_id=v_room.id and user_id=auth.uid();
 if not found then raise exception 'You are not in this room'; end if;
 select * into v_round from op_rounds where id=v_room.current_round_id;
 select coalesce(jsonb_agg(jsonb_build_object('id',p.id,'name',p.display_name,'score',p.score,'seat',p.seat,'host',p.user_id=v_room.host_id) order by p.seat),'[]'::jsonb) into v_players from op_players p where p.room_id=v_room.id;
 select coalesce(jsonb_agg(jsonb_build_object('id',a.id,'body',a.body)),'[]'::jsonb) into v_hand from op_hands h join op_answers a on a.id=h.card_id where h.player_id=v_me.id;
 if v_round.status in ('judging','complete') then
  select coalesce(jsonb_agg(jsonb_build_object('id',s.id,'body',s.card_text) order by s.created_at),'[]'::jsonb) into v_submissions from op_submissions s where s.round_id=v_round.id;
 else v_submissions='[]'::jsonb; end if;
 select jsonb_build_object('name',p.display_name,'score',p.score) into v_winner from op_winners w join op_players p on p.id=w.player_id where w.round_id=v_round.id;
 return jsonb_build_object('code',v_room.code,'status',v_room.status,'round_number',v_room.round_number,'me',jsonb_build_object('id',v_me.id,'name',v_me.display_name,'host',v_me.user_id=v_room.host_id),'players',v_players,'judge_player_id',v_round.judge_player_id,'prompt',v_round.prompt,'round_status',v_round.status,'hand',v_hand,'submissions',v_submissions,'winner',v_winner,
  'has_submitted',exists(select 1 from op_submissions s where s.round_id=v_round.id and s.player_id=v_me.id),
  'submitted_count',(select count(*) from op_submissions s where s.round_id=v_round.id),
  'expected_submissions',(select count(*)-1 from op_players p where p.room_id=v_room.id));
end $$;

grant execute on function public.op_create_room(text),public.op_join_room(text,text),public.op_start_game(text),public.op_submit_card(text,bigint),public.op_choose_winner(text,uuid),public.op_next_round(text),public.op_get_state(text) to anon,authenticated;
