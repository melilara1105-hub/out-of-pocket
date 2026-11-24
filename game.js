/* OUT OF POCKET — Supabase-backed multiplayer client.
   The database enforces room membership, private hands, anonymous reveal and judge-only scoring. */
(() => {
 const $ = id => document.getElementById(id);
 const screens=["home-screen","lobby-screen","join-screen","game-screen"];
 const state={client:null,code:null,me:null,room:null,poll:null,selected:null,lastRoundStatus:null,lastRoundNumber:null,lastWinner:null,lastGameStatus:null};
 const show=id=>screens.forEach(s=>$(s).classList.toggle("active",s===id));
 const esc=s=>String(s??"").replace(/[&<>"']/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
 let toastTimer;
 function toast(msg){const t=$("toast");t.textContent=msg;t.classList.add("show");clearTimeout(toastTimer);toastTimer=setTimeout(()=>t.classList.remove("show"),2600);}
 function configured(){return window.OP_SUPABASE_URL&&window.OP_SUPABASE_ANON_KEY&&!window.OP_SUPABASE_URL.includes("YOUR_")&&!window.OP_SUPABASE_ANON_KEY.includes("YOUR_");}
 async function ensureClient(){
  if(!configured())throw new Error("Supabase isn't configured yet. Follow the setup steps in README.md.");
  if(!state.client)state.client=window.supabase.createClient(window.OP_SUPABASE_URL,window.OP_SUPABASE_ANON_KEY,{auth:{persistSession:true,autoRefreshToken:true}});
  const {data:{session}}=await state.client.auth.getSession();
  if(!session){const {error}=await state.client.auth.signInAnonymously();if(error)throw error;}
  return state.client;
 }
 async function rpc(name,args={}){const c=await ensureClient();const {data,error}=await c.rpc(name,args);if(error)throw error;return data;}
 function err(e){toast(e?.message||"Something went wrong. Please try again.");}
 function setPolling(){clearInterval(state.poll);state.poll=setInterval(async()=>{if(!state.code)return;try{const s=await rpc("op_get_state",{p_code:state.code});render(s);}catch(e){console.error(e);}},1800);}
 async function createRoom(){
  try{const name=($("player-name").value||"Host").trim();const data=await rpc("op_create_room",{p_name:name});state.code=data.code;await refresh();setPolling();show("lobby-screen");}
  catch(e){err(e);}
 }
 async function joinRoom(){
  try{const name=($("join-name").value||"Player").trim();const code=$("join-code").value.trim().toUpperCase();if(code.length!==6)throw new Error("Enter the six-character room code.");const data=await rpc("op_join_room",{p_code:code,p_name:name});state.code=data.code;await refresh();setPolling();show("lobby-screen");}
  catch(e){$("join-message").textContent=e.message||"Couldn't join room."; }
 }
 async function refresh(){const s=await rpc("op_get_state",{p_code:state.code});render(s);}
 async function start(){try{await rpc("op_start_game",{p_code:state.code});await refresh();}catch(e){err(e);}}
 async function submit(){if(!state.selected)return;try{await rpc("op_submit_card",{p_code:state.code,p_card_id:Number(state.selected)});state.selected=null;await refresh();}catch(e){err(e);}}
 async function choose(id){try{await rpc("op_choose_winner",{p_code:state.code,p_submission_id:id});await refresh();}catch(e){err(e);}}
 async function next(){try{await rpc("op_next_round",{p_code:state.code});state.selected=null;await refresh();}catch(e){err(e);}}
 function celebrate(kind, winner, card){
  const layer=$("celebration");
  if(!layer)return;
  layer.className="celebration "+(kind==="game"?"game-victory":"round-victory");
  layer.innerHTML='<div class="celebration-backdrop"></div><div class="celebration-content"><div class="celebration-kicker">'+(kind==="game"?"THE GAME IS OVER":"THE JUDGE HAS SPOKEN")+'</div><div class="celebration-title">'+(kind==="game"?"OUT OF POCKET CHAMPION":"THE WINNING ANSWER")+'</div><div class="celebration-card">'+esc(card||"")+'</div><div class="celebration-winner">'+esc(winner||"Someone")+'</div><div class="celebration-points">'+(kind==="game"?"CLAIMED THE CROWN":"＋1 POINT")+'</div><button class="button button-primary celebration-close">LET'S GO ↗</button></div><div class="confetti" aria-hidden="true">'+Array.from({length:44},(_,i)=>'<i style="--i:'+i+'"></i>').join("")+'</div>';
  layer.classList.remove("hidden");
  layer.querySelector(".celebration-close").addEventListener("click",()=>layer.classList.add("hidden"));
  setTimeout(()=>layer.classList.add("hidden"),kind==="game"?11000:7500);
 }
 function render(s){
  const previousRound=state.lastRoundNumber;
  const previousWinner=state.lastWinner;
  const previousGameStatus=state.lastGameStatus;
  state.room=s;state.me=s.me;
  const winnerChanged=!!s.winner&&(!previousWinner||previousWinner.name!==s.winner.name||previousRound!==s.round_number);
  const gameJustFinished=s.status==="finished"&&previousGameStatus!=="finished";
  state.lastRoundNumber=s.round_number;
  state.lastWinner=s.winner||null;
  state.lastGameStatus=s.status;
  if(gameJustFinished){celebrate("game",s.winner?.name,s.winner?.card||"");}
  else if(winnerChanged){celebrate("round",s.winner.name,s.winner.card||"");}
  $("room-code").textContent=s.code;$("player-count").textContent=s.players.length+"/10";
  $("player-list").innerHTML=s.players.map(p=>'<div class="player-row"><span class="avatar">'+esc(p.name.slice(0,1).toUpperCase())+'</span><span>'+esc(p.name)+'</span>'+(p.host?'<span class="host-tag">HOST</span>':'')+(p.id===s.me.id?'<span class="host-tag">YOU</span>':'')+'</div>').join("");
  $("start-game").classList.toggle("hidden",!s.me.host||s.status!=="lobby");
  $("lobby-message").textContent=s.status==="lobby"?(s.players.length<3?"Waiting for at least 3 players…":"Everyone's here. Host can start the game."):"Game in progress.";
  if(s.status==="lobby"){show("lobby-screen");return;}
  show("game-screen");
  $("round-number").textContent=s.round_number;$("judge-name").textContent=(s.players.find(p=>p.id===s.judge_player_id)||{}).name||"—";
  $("prompt-card").textContent=s.prompt||"Waiting for the next prompt…";
  const isJudge=s.me.id===s.judge_player_id;
  $("score-list").innerHTML=[...s.players].sort((a,b)=>b.score-a.score).map(p=>'<div class="score-item">'+esc(p.name)+' <strong>'+p.score+'</strong></div>').join("");
  $("hand-count").textContent=(s.hand?.length||0)+" CARDS";
  if(s.round_status==="submitting"){
   const hasSubmitted=!!s.has_submitted;
   $("game-status").textContent=isJudge?"You're the judge. Your job is to wait for the anonymous answers.":"Pick the funniest answer and submit it. Your name stays hidden.";
   $("hand").innerHTML=isJudge?"<p class='small-muted'>The judge sits this round out. Wait for submissions.</p>":hasSubmitted?"<p class='small-muted'>Your answer is locked in. Waiting for the others…</p>":(s.hand||[]).map(c=>'<button class="answer-card '+(String(state.selected)===String(c.id)?"selected":"")+'" data-id="'+c.id+'">'+esc(c.body)+'</button>').join("");
   $("hand").querySelectorAll("button[data-id]").forEach(b=>b.addEventListener("click",()=>{state.selected=b.dataset.id;render(s);}));
   $("submit-hint").textContent=isJudge?"You're judging this round.":"Choose one card. It will be anonymous.";
   $("submit-card").classList.toggle("hidden",isJudge||hasSubmitted);$("submit-card").disabled=!state.selected;
   $("waiting-panel").classList.toggle("hidden",isJudge||!hasSubmitted);
   $("waiting-panel").querySelector("p").textContent="Your answer is in. Waiting for the other players…";
   $("reveal-area").classList.add("hidden");
  }else{
   $("hand").innerHTML="";$("submit-card").classList.add("hidden");$("waiting-panel").classList.add("hidden");$("reveal-area").classList.remove("hidden");
   $("game-status").textContent=s.round_status==="judging"?(isJudge?"All answers are in. Pick the winner.":"Answers revealed. The judge is deciding."):(s.winner?s.winner.name+" won this round!":"Round complete.");
   $("submission-count").textContent=(s.submissions||[]).length+" ANSWERS";
   $("submission-grid").innerHTML=(s.submissions||[]).map((sub,i)=>'<div class="submission-card"><p>'+esc(sub.body)+'</p>'+(s.round_status==="judging"&&isJudge?'<button data-sub="'+sub.id+'">PICK THIS WINNER</button>':(s.winner&&s.winner.name?"<span class='small-muted'>ROUND WINNER: "+esc(s.winner.name)+"</span>":"<span class='small-muted'>ANONYMOUS SUBMISSION</span>"))+'</div>').join("");
   $("submission-grid").querySelectorAll("button[data-sub]").forEach(b=>b.addEventListener("click",()=>choose(b.dataset.sub)));
   const nextBtn=$("next-round");nextBtn.classList.toggle("hidden",s.round_status!=="complete"||!isJudge||s.status==="finished");nextBtn.textContent="NEXT ROUND ↗";
   if(s.status==="finished"){$("game-status").textContent=(s.winner?.name||"A player")+" wins OUT OF POCKET! First to 10!";nextBtn.classList.add("hidden");}
  }
 }
 $("create-room").addEventListener("click",createRoom);
 $("join-open").addEventListener("click",()=>show("join-screen"));
 $("join-back").addEventListener("click",()=>show("home-screen"));
 $("leave-lobby").addEventListener("click",()=>{clearInterval(state.poll);state.code=null;show("home-screen");});
 $("start-game").addEventListener("click",start);
 $("submit-card").addEventListener("click",submit);
 $("next-round").addEventListener("click",next);
 $("exit-game").addEventListener("click",()=>{clearInterval(state.poll);state.code=null;show("home-screen");});
 $("join-room").addEventListener("click",joinRoom);
 $("copy-code").addEventListener("click",()=>navigator.clipboard?.writeText(state.code||"").then(()=>toast("Room code copied!")).catch(()=>toast("Room code: "+state.code)));
 $("rules-open").addEventListener("click",()=>$("rules-dialog").showModal());
 $("rules-close").addEventListener("click",()=>$("rules-dialog").close());
 $("join-code").addEventListener("input",e=>e.target.value=e.target.value.toUpperCase().replace(/[^A-Z0-9]/g,""));
 if(!configured()){$("lobby-message").textContent="Connect your Supabase project to enable online rooms. Setup instructions are in README.md.";}
})();