extends Node

const WaterSortProgression = preload("res://scripts/core/water_sort_progression.gd")

const CAMPAIGN_LEVELS := 10000
const LEVELS_PER_WORLD := 100
const WORLD_COUNT := 100
const GAME_IDS := ["rescue_rush", "water_sort", "block_puzzle"]
const GAME_NAMES := {"rescue_rush":"RESCUE RUSH","water_sort":"WATER SORT","block_puzzle":"BLOCK PUZZLE"}
const TASK_REWARD := 75
const DAILY_HISTORY_LIMIT := 45

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
  g["daily_completed"]=_bounded_date_history(g.get("daily_completed",[]) as Array)
  g["daily_last_date"]=String(g.get("daily_last_date","")); all[id]=g
 SaveManager.data["game_progress"]=all
 if not SaveManager.data.get("multi_active_runs",{}) is Dictionary:SaveManager.data["multi_active_runs"]={}
 if not SaveManager.data.get("daily_tasks",{}) is Dictionary:SaveManager.data["daily_tasks"]={}
 var task_store:Dictionary=SaveManager.data.get("daily_tasks",{})
 _prune_daily_task_history(task_store)
 SaveManager.data["daily_tasks"]=task_store

func display_name(id:String)->String:return String(GAME_NAMES.get(id,id.to_upper()))

func _rescue_achievements()->Array:
 var out:Array=[]
 var canonical=SaveManager.data.get("achievements",[])
 if canonical is Array:
  for value in canonical:
   if value not in out:out.append(value)
 var legacy=SaveManager.data.get("rescue_achievements",[])
 if legacy is Array:
  for value in legacy:
   if value not in out:out.append(value)
 return out

func progress_for(id:String)->Dictionary:
 ensure_state()
 if id=="rescue_rush": return {"highest_level":int(SaveManager.data.get("highest_level",1)),"stars":SaveManager.data.get("stars",{}),"levels_completed":int(SaveManager.data.get("total_levels_completed",0)),"perfect_clears":int(SaveManager.data.get("perfect_clears",0)),"perfect_streak":int(SaveManager.data.get("perfect_streak",0)),"best_perfect_streak":int(SaveManager.data.get("best_perfect_streak",0)),"milestone_chests":SaveManager.data.get("milestone_chests",[]),"world_badges":SaveManager.data.get("world_badges",[]),"daily_streak":int(SaveManager.data.get("daily_streak",0)),"daily_best_streak":int(SaveManager.data.get("daily_best_streak",0)),"achievements":_rescue_achievements()}
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
func world_count_for(id:String)->int:return WaterSortProgression.WORLD_COUNT if id=="water_sort" else WORLD_COUNT
func world_for_game_level(id:String,n:int)->int:return int(WaterSortProgression.profile(n).get("world",1)) if id=="water_sort" else world_for_level(n)
func first_level_in_game_world(id:String,w:int)->int:
 if id=="water_sort":return (clampi(w,1,WaterSortProgression.WORLD_COUNT)-1)*WaterSortProgression.WORLD_SIZE+1
 return first_level_in_world(w)
func last_level_in_game_world(id:String,w:int)->int:
 if id=="water_sort":return mini(first_level_in_game_world(id,w)+WaterSortProgression.WORLD_SIZE-1,CAMPAIGN_LEVELS)
 return last_level_in_world(w)
func highest_unlocked_game_world(id:String)->int:return world_for_game_level(id,highest_level(id))
func difficulty_for_game(id:String,n:int)->String:return String(WaterSortProgression.profile(n).get("difficulty_label","normal-hard")) if id=="water_sort" else difficulty_for_level(n)
func world_name(id:String,w:int)->String:
 var themes={"rescue_rush":["Garden Escape","Locks & Keys","Chain Reaction","Blast Lab","Linked Zone","Chaos Rescue","Portal Works","Crystal Circuit","Neon Factory","Rescue Nexus"],"water_sort":["Color Springs","Glass Garden","Prism Bay","Liquid Lab","Neon Pour","Spectrum Works","Crystal Flow","Chromatic Vault","Aurora Mix","Master Distillery"],"block_puzzle":["Starter Grid","Brick Yard","Shape Works","Line Factory","Pattern City","Block Forge","Grid Nexus","Combo Circuit","Master Matrix","Infinite Board"]}
 var set:Array=themes[id];var base:=String(set[(w-1)%set.size()]);var chapter:=int((w-1)/set.size())+1;return "%s %d"%[base,chapter] if chapter>1 else base
func difficulty_for_level(n:int)->String:
 if n%100==0:return "boss"
 if n%25==0:return "milestone"
 if n<=10:return "easy"
 if n<=20:return "medium"
 var phase:=posmod(n-1,25)+1
 var world:=world_for_level(n)
 var score:=0 if phase<=5 else (1 if phase<=15 else 2)
 if phase in [4,12,20]: score-=1
 if world>=11:score+=1
 if world>=41:score+=1
 if world>=76 and phase>8:score+=1
 score=clampi(score,0,2)
 return ["easy","medium","hard"][score]
func date_key()->String:
 var d:=Time.get_date_dict_from_system();return "%04d-%02d-%02d"%[d.year,d.month,d.day]

func _date_dict(value:String)->Dictionary:
 var parts:=value.split("-")
 if parts.size()!=3:return {}
 var year:=int(parts[0]);var month:=int(parts[1]);var day:=int(parts[2])
 if year<1 or month<1 or month>12 or day<1 or day>31:return {}
 return {"year":year,"month":month,"day":day,"hour":0,"minute":0,"second":0}

func _is_previous_calendar_day(previous_date:String,current_date:String)->bool:
 var previous:=_date_dict(previous_date);var current:=_date_dict(current_date)
 if previous.is_empty() or current.is_empty():return false
 var previous_unix:=int(Time.get_unix_time_from_datetime_dict(previous))
 var current_unix:=int(Time.get_unix_time_from_datetime_dict(current))
 return current_unix-previous_unix==86400

func _bounded_date_history(values:Array)->Array:
 var out:Array=[]
 for value in values:
  var key:=String(value)
  if key.is_empty() or key in out:continue
  out.append(key)
 if out.size()>DAILY_HISTORY_LIMIT:out=out.slice(out.size()-DAILY_HISTORY_LIMIT)
 return out

func _prune_daily_task_history(store:Dictionary)->void:
 var dates:Array=[]
 for raw_key in store.keys():
  var date:=String(raw_key).get_slice(":",0)
  if date.length()==10 and date not in dates:dates.append(date)
 dates.sort()
 while dates.size()>DAILY_HISTORY_LIMIT:
  var expired:=String(dates.pop_front())
  for raw_key in store.keys():
   if String(raw_key).begins_with(expired+":"):store.erase(raw_key)

func daily_level(id:String)->int:
 var d:=Time.get_date_dict_from_system();return posmod(int(d.year)*372+int(d.month)*31+int(d.day)+GAME_IDS.find(id)*997,CAMPAIGN_LEVELS)+1
func is_daily_completed(id:String)->bool:
 if id=="rescue_rush":return DailyChallenge.is_completed_today()
 return date_key() in progress_for(id).get("daily_completed",[])

func daily_tasks(id:String)->Array:
 ensure_state();var key:=date_key()+":"+id;var store:Dictionary=SaveManager.data.get("daily_tasks",{});var changed:=false
 if not store.has(key) or not store.get(key) is Array:
  store[key]=[{"id":"play3","title":"Complete 3 levels","target":3,"progress":0,"claimed":false},{"id":"stars6","title":"Earn 6 stars","target":6,"progress":0,"claimed":false},{"id":"perfect1","title":"Get a perfect clear","target":1,"progress":0,"claimed":false}];changed=true
 var before:=store.size();_prune_daily_task_history(store);changed=changed or store.size()!=before;SaveManager.data["daily_tasks"]=store
 if changed:SaveManager.save()
 return (store.get(key,[]) as Array).duplicate(true)
func _advance_tasks(id:String,stars:int)->void:
 var key:=date_key()+":"+id;daily_tasks(id);var store:Dictionary=SaveManager.data.get("daily_tasks",{});var tasks:Array=(store.get(key,[]) as Array)
 for t in tasks:
  match String(t.get("id","")):
   "play3":t["progress"]=mini(int(t.target),int(t.progress)+1)
   "stars6":t["progress"]=mini(int(t.target),int(t.progress)+stars)
   "perfect1":
    if stars==3:t["progress"]=1
 store[key]=tasks;SaveManager.data["daily_tasks"]=store
func claim_daily_task(id:String,task_id:String)->bool:
 var key:=date_key()+":"+id;daily_tasks(id);var store:Dictionary=SaveManager.data.get("daily_tasks",{});var tasks:Array=(store.get(key,[]) as Array)
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
 ensure_state();var all:Dictionary=SaveManager.data.get("game_progress",{});var g:Dictionary=all.get(id,{});var key:=date_key();var done:Array=g.get("daily_completed",[]);var previous:=String(g.get("daily_last_date",""))
 if key in done or previous==key:return false
 g["daily_streak"]=int(g.get("daily_streak",0))+1 if _is_previous_calendar_day(previous,key) else 1;g["daily_best_streak"]=maxi(int(g.get("daily_best_streak",0)),int(g.get("daily_streak",0)));g["daily_last_date"]=key;done.append(key);g["daily_completed"]=_bounded_date_history(done);all[id]=g;SaveManager.data["game_progress"]=all;SaveManager.data["coins"]=int(SaveManager.data.get("coins",0))+reward;SaveManager.save();return true
func complete_level(id:String,n:int,stars:int,coin_reward:=25)->Dictionary:
 if id=="rescue_rush":_advance_tasks(id,stars);return SaveManager.complete_level(n,stars,"",coin_reward)
 ensure_state();n=clampi(n,1,CAMPAIGN_LEVELS);stars=clampi(stars,1,3);var all:Dictionary=SaveManager.data.get("game_progress",{});var g:Dictionary=all.get(id,{});var sm:Dictionary=g.get("stars",{});var key:=str(n);var previous:=int(sm.get(key,0));var first:=previous==0;var rewards={"first_clear":first,"improved":stars>previous,"perfect":stars==3 and previous<3,"milestone":false,"world_badge":false,"bonus_coins":0,"prestige":0};sm[key]=maxi(previous,stars);g["stars"]=sm;g["highest_level"]=maxi(int(g.get("highest_level",1)),mini(CAMPAIGN_LEVELS+1,n+1))
 if first:g["levels_completed"]=mini(CAMPAIGN_LEVELS,int(g.get("levels_completed",0))+1);SaveManager.data["coins"]=int(SaveManager.data.get("coins",0))+coin_reward
 if stars==3 and previous<3:g["perfect_clears"]=int(g.get("perfect_clears",0))+1;g["perfect_streak"]=int(g.get("perfect_streak",0))+1;g["best_perfect_streak"]=maxi(int(g.get("best_perfect_streak",0)),int(g.get("perfect_streak",0)))
 elif first:g["perfect_streak"]=0
 if first and n%10==0:var c:Array=g.get("milestone_chests",[]);c.append(key);g["milestone_chests"]=c;rewards.milestone=true;SaveManager.data["coins"]=int(SaveManager.data.get("coins",0))+100
 var badge_span:=WaterSortProgression.WORLD_SIZE if id=="water_sort" else LEVELS_PER_WORLD
 if first and n%badge_span==0:var wk:=str(int(n/badge_span));var b:Array=g.get("world_badges",[]);b.append(wk);g["world_badges"]=b;rewards.world_badge=true;SaveManager.data["coins"]=int(SaveManager.data.get("coins",0))+250;SaveManager.data["prestige_points"]=int(SaveManager.data.get("prestige_points",0))+5
 all[id]=g;SaveManager.data["game_progress"]=all;_advance_tasks(id,stars);SaveManager.save();var difficulty:=difficulty_for_game(id,n);RetentionManager.record_level_complete(n,stars,0,0,0,"",-1,id,difficulty);AnalyticsManager.track("multi_game_level_complete",{"game":id,"level":n,"stars":stars,"difficulty":difficulty});return rewards
func save_checkpoint(id:String,data:Dictionary)->void:
 ensure_state();var runs:Dictionary=SaveManager.data.get("multi_active_runs",{});var payload:=data.duplicate(true);payload["game"]=id;payload["saved_at"]=int(Time.get_unix_time_from_system());runs[id]=payload;SaveManager.data["multi_active_runs"]=runs;SaveManager.save()
func checkpoint(id:String)->Dictionary:
 ensure_state();var runs:Dictionary=SaveManager.data.get("multi_active_runs",{});var raw=runs.get(id,{});return raw.duplicate(true) if raw is Dictionary else {}
func clear_checkpoint(id:String)->void:
 ensure_state();var runs:Dictionary=SaveManager.data.get("multi_active_runs",{});runs.erase(id);SaveManager.data["multi_active_runs"]=runs;SaveManager.save()
