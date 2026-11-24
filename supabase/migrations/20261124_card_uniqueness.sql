-- OUT OF POCKET card uniqueness and prompt shuffle migration
-- Safe to run on an existing project. Does not delete game records or seed cards.

alter table public.op_hands
  add column if not exists dealt_order bigserial;

create table if not exists public.op_used_answers (
  room_id uuid not null references public.op_rooms(id) on delete cascade,
  card_id bigint not null references public.op_answers(id),
  used_at timestamptz not null default now(),
  primary key (room_id, card_id)
);

alter table public.op_used_answers enable row level security;
revoke all on public.op_used_answers from anon, authenticated;

-- Deal a shuffled, non-overlapping hand to each player in the room.
create or replace function public.op_start_game(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_room op_rooms;
  v_judge op_players;
  v_round op_rounds;
  v_count integer;
  v_player op_players;
  v_prompt text;
begin
  select * into v_room
  from op_rooms
  where code = upper(trim(p_code))
  for update;

  if not found or v_room.host_id <> auth.uid() then
    raise exception 'Only the host can start this room';
  end if;

  select count(*) into v_count
  from op_players
  where room_id = v_room.id;

  if v_count < 3 then
    raise exception 'At least 3 players are required';
  end if;

  if v_room.status <> 'lobby' then
    raise exception 'Game already started';
  end if;

  select * into v_judge
  from op_players
  where room_id = v_room.id
  order by seat
  limit 1;

  select p.body into v_prompt
  from op_prompts p
  where not exists (
    select 1 from op_rounds r
    where r.room_id = v_room.id and r.prompt = p.body
  )
  order by random()
  limit 1;

  if v_prompt is null then
    raise exception 'This room has used every prompt card. Start a new room for a fresh deck.';
  end if;

  update op_rooms
  set status = 'playing', round_number = 1, judge_player_id = v_judge.id
  where id = v_room.id;

  insert into op_rounds(room_id, prompt, judge_player_id)
  values (v_room.id, v_prompt, v_judge.id)
  returning * into v_round;

  update op_rooms
  set current_round_id = v_round.id
  where id = v_room.id;

  -- Deal 10 different cards per player, with no card shared in this room.
  for v_player in
    select * from op_players
    where room_id = v_room.id
    order by seat
  loop
    insert into op_hands(player_id, card_id)
    select v_player.id, a.id
    from op_answers a
    where not exists (
      select 1
      from op_hands h
      join op_players hp on hp.id = h.player_id
      where hp.room_id = v_room.id
        and h.card_id = a.id
    )
    order by random()
    limit 10;

    if (select count(*) from op_hands where player_id = v_player.id) < 10 then
      raise exception 'Not enough unique answer cards for everyone. Add more answer cards before starting a room with this many players.';
    end if;
  end loop;

  return public.op_get_state(p_code);
end;
$$;

-- Retire a played answer for the entire room and draw a fresh, unused card.
create or replace function public.op_submit_card(p_code text, p_card_id bigint)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_room op_rooms;
  v_round op_rounds;
  v_player op_players;
  v_card text;
  v_total integer;
  v_expected integer;
begin
  select * into v_room
  from op_rooms
  where code = upper(trim(p_code))
  for update;

  if not found then
    raise exception 'Room not found';
  end if;

  select * into v_player
  from op_players
  where room_id = v_room.id and user_id = auth.uid();

  if not found then
    raise exception 'You are not in this room';
  end if;

  select * into v_round
  from op_rounds
  where id = v_room.current_round_id
  for update;

  if v_player.id = v_round.judge_player_id then
    raise exception 'The judge cannot submit';
  end if;

  if v_round.status <> 'submitting' then
    raise exception 'Submissions are closed';
  end if;

  select a.body into v_card
  from op_answers a
  join op_hands h on h.card_id = a.id
  where h.player_id = v_player.id and a.id = p_card_id;

  if v_card is null then
    raise exception 'That card is not in your hand';
  end if;

  insert into op_submissions(round_id, player_id, card_text)
  values (v_round.id, v_player.id, v_card);

  insert into op_used_answers(room_id, card_id)
  values (v_room.id, p_card_id)
  on conflict (room_id, card_id) do nothing;

  delete from op_hands
  where player_id = v_player.id and card_id = p_card_id;

  insert into op_hands(player_id, card_id)
  select v_player.id, a.id
  from op_answers a
  where not exists (
    select 1 from op_used_answers u
    where u.room_id = v_room.id and u.card_id = a.id
  )
  and not exists (
    select 1
    from op_hands h
    join op_players hp on hp.id = h.player_id
    where hp.room_id = v_room.id and h.card_id = a.id
  )
  order by random()
  limit 1;

  select count(*) into v_total
  from op_submissions
  where round_id = v_round.id;

  select count(*) - 1 into v_expected
  from op_players
  where room_id = v_room.id;

  if v_total >= v_expected then
    update op_rounds set status = 'judging' where id = v_round.id;
  end if;

  return public.op_get_state(p_code);
end;
$$;

-- Pick a prompt that has not appeared earlier in this room.
create or replace function public.op_next_round(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_room op_rooms;
  v_old op_rounds;
  v_judge op_players;
  v_round op_rounds;
  v_prompt text;
begin
  select * into v_room
  from op_rooms
  where code = upper(trim(p_code))
  for update;

  if not found then
    raise exception 'Room not found';
  end if;

  select * into v_old
  from op_rounds
  where id = v_room.current_round_id;

  if v_room.status = 'finished' then
    raise exception 'Game is over';
  end if;

  if v_old.status <> 'complete' then
    raise exception 'This round is not complete';
  end if;

  select * into v_judge
  from op_players
  where room_id = v_room.id
    and seat = (
      select mod(seat, (select count(*) from op_players where room_id = v_room.id)) + 1
      from op_players
      where id = v_old.judge_player_id
    );

  select p.body into v_prompt
  from op_prompts p
  where not exists (
    select 1 from op_rounds r
    where r.room_id = v_room.id and r.prompt = p.body
  )
  order by random()
  limit 1;

  if v_prompt is null then
    raise exception 'This room has used every prompt card. Start a new room for a fresh deck.';
  end if;

  update op_rooms
  set round_number = round_number + 1, judge_player_id = v_judge.id
  where id = v_room.id;

  insert into op_rounds(room_id, prompt, judge_player_id)
  values (v_room.id, v_prompt, v_judge.id)
  returning * into v_round;

  update op_rooms
  set current_round_id = v_round.id
  where id = v_room.id;

  return public.op_get_state(p_code);
end;
$$;

grant execute on function public.op_start_game(text) to anon, authenticated;
grant execute on function public.op_submit_card(text, bigint) to anon, authenticated;
grant execute on function public.op_next_round(text) to anon, authenticated;
