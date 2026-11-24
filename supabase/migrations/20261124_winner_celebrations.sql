create or replace function public.op_get_state(p_code text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_room public.op_rooms; v_me public.op_players; v_round public.op_rounds; v_submissions jsonb; v_hand jsonb; v_players jsonb; v_winner jsonb;
begin
 select * into v_room from public.op_rooms where code=upper(trim(p_code));
 if not found then raise exception 'Room not found'; end if;
 select * into v_me from public.op_players where room_id=v_room.id and user_id=auth.uid();
 if not found then raise exception 'You are not in this room'; end if;
 select * into v_round from public.op_rounds where id=v_room.current_round_id;
 select coalesce(jsonb_agg(jsonb_build_object('id',p.id,'name',p.display_name,'score',p.score,'seat',p.seat,'host',p.user_id=v_room.host_id) order by p.seat),'[]'::jsonb) into v_players from public.op_players p where p.room_id=v_room.id;
 select coalesce(jsonb_agg(jsonb_build_object('id',a.id,'body',a.body) order by h.dealt_order),'[]'::jsonb) into v_hand from public.op_hands h join public.op_answers a on a.id=h.card_id where h.player_id=v_me.id;
 if v_round.status in ('judging','complete') then
  select coalesce(jsonb_agg(jsonb_build_object('id',s.id,'body',s.card_text) order by s.created_at),'[]'::jsonb) into v_submissions from public.op_submissions s where s.round_id=v_round.id;
 else v_submissions='[]'::jsonb; end if;
 select jsonb_build_object('name',p.display_name,'score',p.score,'card',(select s.card_text from public.op_submissions s where s.id=w.submission_id))
 into v_winner
 from public.op_winners w join public.op_players p on p.id=w.player_id where w.round_id=v_round.id;
 return jsonb_build_object('code',v_room.code,'status',v_room.status,'round_number',v_room.round_number,'me',jsonb_build_object('id',v_me.id,'name',v_me.display_name,'host',v_me.user_id=v_room.host_id),'players',v_players,'judge_player_id',v_round.judge_player_id,'prompt',v_round.prompt,'round_status',v_round.status,'hand',v_hand,'submissions',v_submissions,'winner',v_winner,
  'has_submitted',exists(select 1 from public.op_submissions s where s.round_id=v_round.id and s.player_id=v_me.id),
  'submitted_count',(select count(*) from public.op_submissions s where s.round_id=v_round.id),
  'expected_submissions',(select count(*)-1 from public.op_players p where p.room_id=v_room.id));
end $$;
grant execute on function public.op_get_state(text) to anon,authenticated;