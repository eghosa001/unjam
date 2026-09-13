extends Node

const CAMPAIGN_LEVELS := 10000
const LEVELS_PER_WORLD := 100
const WORLD_COUNT := 100
const GAME_IDS := ["rescue_rush", "water_sort", "block_puzzle"]
const GAME_NAMES := {"rescue_rush":"RESCUE RUSH","water_sort":"WATER SORT","block_puzzle":"BLOCK PUZZLE"}
const TASK_REWARD := 75

func _ready()->void: ensure_state()
func ensure_state()->void:
 if not SaveManager.data.get("game_progress",{}) is Dictionary: SaveManager.data["game_progress"]={}
 var all:Dictionary=SaveManager.data.get("game_progress",{})
 for id in GAME_IDS:
  if id=="rescue_rush": continue
  var g:Dictionary=all.get(id,{}) if all.get(id,{}) is Dictionary else {}
  g["highest_level"]=clampi(int(g.get("highest_level",1)),1,CAMPAIGN_LEVELS+1)
  if not g.get("stars",{}) is Dictionary:g["stars"]={}
  for k in ["levels_completed","perfect_clears","perfect_streak","best_perfect_streak","daily_streak","daily_best_streak"]: g[k]=maxi(0,int(g.get(k,0)))
  for k in ["milestone_chests","world_badges","daily_completed","achievements"]:
   if not g.get(k,[]) is Array:g[k]=[]
  g["daily_last_date"]=String(g.get("daily_last_date","")); all[id]=g
 SaveManager.data["game_progress"]=all
 if not SaveManager.data.get("multi_active_runs",{}) is Dictionary:SaveManager.data["multi_active_runs"]={}
 if not SaveManager.data.get("daily_tasks",{}) is Dictionary:SaveManager.data["daily_tasks"]={}

func display_name(id:String)->String:return String(GAME_NAMES.get(id,id.to_upper()))
func progress_for(id:String)->Dictionary:
 ensure_state()
 if id=="rescue_rush": return {"highest_level":int(SaveManager.data.get("highest_level",1)),"stars":SaveManager.data.get("stars",{}),"levels_completed":int(SaveManager.data.get("total_levels_completed",0)),"perfect_clears":int(SaveManager.data.get("perfect_clears",0)),"perfect_streak":int(SaveManager.data.get("perfect_streak",0)),"best_perfect_streak":int(SaveManager.data.get("best_perfect_streak",0)),"milestone_chests":SaveManager.data.get("milestone_chests",[]),"world_badges":SaveManager.data.get("world_badges",[]),"daily_streak":int(SaveManager.data.get("daily_streak",0)),"daily_best_streak":int(SaveManager.data.get("daily_best_streak",0)),"achievements":SaveManager.data.get("rescue_achievements",[])}
 return (SaveManager.data.get("game_progress",{}) as Dictionary).get(id,{}).duplicate(true)
func highest_level(id:String)->int:return clampi(int(progress_for(id).get("highest_level",1)),1,CAMPAIGN_LEVELS+1)
func get_stars(id:String,n:int)->int:return int((progress_for(id).get("stars",{}) as Dictionary).get(str(n),0))
func total_stars(id:String)->int:
 var total:=0
 for v in (progress_for(id).get("stars",{}) as Dictionary).values():total+=int(v)
 return total
func is_level_unlocked(id:String,n:int)->bool:return n<=highest_level(id)
func world_for_level(n:int)->int:return clampi(int((maxi(1,n)-1)/LEVELS_PER_WORLD)+1,1,WORLD_COUNT)
func first_level_in_world(w:int)->int:return (clampi(w,1,WORLD_COUNT)-1)*LEVELS_PER_WORLD+1
func last_level_in_world(w:int)->int:return mini(first_level_in_world(w)+LEVELS_PER_WORLD-1,CAMPAIGN_LEVELS)
func highest_unlocked_world(id:String)->int:return world_for_level(highest_level(id))
func world_name(id:String,w:int)->String:
 var themes={"rescue_rush":["Garden Escape","Locks & Keys","Chain Reaction","Blast Lab","Linked Zone","Chaos Rescue","Portal Works","Crystal Circuit","Neon Factory","Rescue Nexus"],"water_sort":["Color Springs","Glass Garden","Prism Bay","Liquid Lab","Neon Pour","Spectrum Works","Crystal Flow","Chromatic Vault","Aurora Mix","Master Distillery"],"block_puzzle":["Starter Grid","Brick Yard","Shape Works","Line Factory","Pattern City","Block Forge","Grid Nexus","Combo Circuit","Master Matrix","Infinite Board"]}
 var set:Array=themes[id];var base:=String(set[(w-1)%set.size()]);var chapter:=int((w-1)/set.size())+1;return "%s %d"%[base,chapter] if chapter>1 else base
func difficulty_for_level(n:int)->String:
 if n%100==0:return "boss"
 if n%25==0:return "milestone"
 var s:=posmod(n-1,25)+1
 if s<=5:return "easy"
 if s<=15:return "easy" if s%4==0 else "medium"
 return "medium" if s%3==0 else "hard"
func date_key()->String:
 var d:=Time.get_date_dict_from_system();return "%04d-%02d-%02d"%[d.year,d.month,d.day]
func daily_level(id:String)->int:
 var d:=Time.get_date_dict_from_system();return posmod(int(d.year)*372+int(d.month)*31+int(d.day)+GAME_IDS.find(id)*997,CAMPAIGN_LEVELS)+1
func is_daily_completed(id:String)->bool:
 if id=="rescue_rush":return DailyChallenge.is_completed_today()
 return date_key() in progress_for(id).get("daily_completed",[])

func daily_tasks(id:String)->Array:
 ensure_state();var key:=date_key()+":"+id;var store:Dictionary=SaveManager.data.get("daily_tasks",{})
 if not store.get(key,[]) is Array:
  store[key]=[{"id":"play3","title":"Complete 3 levels","target":3,"progress":0,"claimed":false},{"id":"stars6","title":"Earn 6 stars","target":6,"progress":0,"claimed":false},{"id":"perfect1","title":"Get a perfect clear","target":1,"progress":0,"claimed":false}];SaveManager.data["daily_tasks"]=store;SaveManager.save()
 return (store.get(key,[]) as Array).duplicate(true)
func _advance_tasks(id:String,stars:int)->void:
 var key:=date_key()+":"+id;daily_tasks(id);var store:Dictionary=SaveManager.data.get("daily_tasks",{});var tasks:Array=store[key]
 for t in tasks:
  match String(t.get("id","")):
   "play3":t["progress"]=mini(int(t.target),int(t.progress)+1)
   "stars6":t["progress"]=mini(int(t.target),int(t.progress)+stars)
   "perfect1":
    if stars==3:t["progress"]=1
 store[key]=tasks;SaveManager.data["daily_tasks"]=store
func claim_daily_task(id:String,task_id:String)->bool:
 var key:=date_key()+":"+id;daily_tasks(id);var store:Dictionary=SaveManager.data.get("daily_tasks",{});var tasks:Array=store[key]
 for t in tasks:
  if String(t.id)==task_id and int(t.progress)>=int(t.target) and not bool(t.claimed):t["claimed"]=true;SaveManager.data["coins"]=int(SaveManager.data.get("coins",0))+TASK_REWARD;SaveManager.data["achievement_points"]=int(SaveManager.data.get("achievement_points",0))+10;store[key]=tasks;SaveManager.data["daily_tasks"]=store;SaveManager.save();return true
 return false
func achievement_definitions(id:String)->Array:return [{"id":"first","title":"First Victory","need":1},{"id":"century","title":"Century Club","need":100},{"id":"perfect25","title":"Perfectionist","need":25},{"id":"world10","title":"World Traveller","need":10},{"id":"master","title":"10K Master","need":10000}]
func unlocked_achievements(id:String)->Array:
 var p:=progress_for(id);var out:Array=[]
 for a in achievement_definitions(id):
  var ok:=int(p.get("levels_completed",0))>=int(a.need) if String(a.id) in ["first","century","master"] else (int(p.get("perfect_clears",0))>=25 if String(a.id)=="perfect25" else (p.get("world_badges",[]) as Array).size()>=10)
  if ok:out.append(String(a.id))
 return out
func complete_daily(id:String,reward:=100)->bool:
 if id=="rescue_rush":return SaveManager.complete_daily(date_key(),reward)
 ensure_state();var all:Dictionary=SaveManager.data.game_progress;var g:Dictionary=all[id];var key:=date_key();var done:Array=g.daily_completed
 if key in done:return false
 g.daily_streak=int(g.daily_streak)+1;g.daily_best_streak=maxi(int(g.daily_best_streak),int(g.daily_streak));g.daily_last_date=key;done.append(key);g.daily_completed=done;all[id]=g;SaveManager.data.game_progress=all;SaveManager.data["coins"]=int(SaveManager.data.get("coins",0))+reward;SaveManager.save();return true
func complete_level(id:String,n:int,stars:int,coin_reward:=25)->Dictionary:
 if id=="rescue_rush":_advance_tasks(id,stars);return SaveManager.complete_level(n,stars,"",coin_reward)
 ensure_state();n=clampi(n,1,CAMPAIGN_LEVELS);stars=clampi(stars,1,3);var all:Dictionary=SaveManager.data.game_progress;var g:Dictionary=all[id];var sm:Dictionary=g.stars;var key:=str(n);var previous:=int(sm.get(key,0));var first:=previous==0;var rewards={"first_clear":first,"improved":stars>previous,"perfect":stars==3 and previous<3,"milestone":false,"world_badge":false,"bonus_coins":0,"prestige":0};sm[key]=maxi(previous,stars);g.stars=sm;g.highest_level=maxi(int(g.highest_level),mini(CAMPAIGN_LEVELS+1,n+1))
 if first:g.levels_completed=mini(CAMPAIGN_LEVELS,int(g.levels_completed)+1);SaveManager.data["coins"]=int(SaveManager.data.get("coins",0))+coin_reward
 if stars==3 and previous<3:g.perfect_clears=int(g.perfect_clears)+1;g.perfect_streak=int(g.perfect_streak)+1;g.best_perfect_streak=maxi(int(g.best_perfect_streak),int(g.perfect_streak))
 elif first:g.perfect_streak=0
 if first and n%10==0:var c:Array=g.milestone_chests;c.append(key);g.milestone_chests=c;rewards.milestone=true;SaveManager.data["coins"]=int(SaveManager.data.get("coins",0))+100
 if first and n%100==0:var wk:=str(int(n/100));var b:Array=g.world_badges;b.append(wk);g.world_badges=b;rewards.world_badge=true;SaveManager.data["coins"]=int(SaveManager.data.get("coins",0))+250;SaveManager.data["prestige_points"]=int(SaveManager.data.get("prestige_points",0))+5
 all[id]=g;SaveManager.data.game_progress=all;_advance_tasks(id,stars);SaveManager.save();AnalyticsManager.track("multi_game_level_complete",{"game":id,"level":n,"stars":stars,"difficulty":difficulty_for_level(n)});return rewards
func save_checkpoint(id:String,data:Dictionary)->void:ensure_state();var r:Dictionary=SaveManager.data.multi_active_runs;var p:=data.duplicate(true);p.game=id;p.saved_at=int(Time.get_unix_time_from_system());r[id]=p;SaveManager.data.multi_active_runs=r;SaveManager.save()
func checkpoint(id:String)->Dictionary:ensure_state();var raw=(SaveManager.data.multi_active_runs as Dictionary).get(id,{});return raw.duplicate(true) if raw is Dictionary else {}
func clear_checkpoint(id:String)->void:ensure_state();var r:Dictionary=SaveManager.data.multi_active_runs;r.erase(id);SaveManager.data.multi_active_runs=r;SaveManager.save()
