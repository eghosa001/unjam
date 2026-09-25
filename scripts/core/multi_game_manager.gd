extends Node

const WaterSortProgression = preload("res://scripts/core/water_sort_progression.gd")
const BlockPuzzleProgression = preload("res://scripts/core/block_puzzle_progression.gd")

const CAMPAIGN_LEVELS := 10000
const LEVELS_PER_WORLD := 100
const WORLD_COUNT := 100
const GAME_IDS := ["rescue_rush", "water_sort", "block_puzzle"]
const GAME_NAMES := {"rescue_rush":"RESCUE RUSH","water_sort":"WATER SORT","block_puzzle":"BLOCK PUZZLE"}
const DAILY_HISTORY_LIMIT := 45
const WATER_WORLD_BADGE_SPAN_VERSION := 2
const BLOCK_WORLD_BADGE_SPAN_VERSION := 2
const CHECKPOINT_HISTORY_LIMIT := 24

var _state_initialized := false
var _total_stars_cache: Dictionary = {}

func _ready()->void: ensure_state()

func _state_containers_present()->bool:
 return (
  SaveManager.data.get("game_progress",{}) is Dictionary
  and SaveManager.data.get("multi_active_runs",{}) is Dictionary
  and SaveManager.data.get("daily_game_choices",{}) is Dictionary
 )

func _world_badge_migrations_current()->bool:
 var all = SaveManager.data.get("game_progress", {})
 if not all is Dictionary:
  return false
 for id in ["water_sort", "block_puzzle"]:
  var raw = (all as Dictionary).get(id, {})
  if not raw is Dictionary:
   return false
  var required_version := WATER_WORLD_BADGE_SPAN_VERSION if id == "water_sort" else BLOCK_WORLD_BADGE_SPAN_VERSION
  if int((raw as Dictionary).get("world_badge_span_version", 0)) < required_version:
   return false
 return true

func ensure_state()->void:
 if _state_initialized and _state_containers_present() and _world_badge_migrations_current():return
 _total_stars_cache.clear()
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
  if id=="water_sort":g=_migrate_water_sort_world_badges(g)
  elif id=="block_puzzle":g=_migrate_block_puzzle_world_badges(g)
  g["daily_last_date"]=String(g.get("daily_last_date","")); all[id]=g
 SaveManager.data["game_progress"]=all
 if not SaveManager.data.get("multi_active_runs",{}) is Dictionary:SaveManager.data["multi_active_runs"]={}
 if not SaveManager.data.get("daily_game_choices",{}) is Dictionary:SaveManager.data["daily_game_choices"]={}
 _prune_daily_game_choices()
 _state_initialized=true


func _migrate_water_sort_world_badges(g:Dictionary)->Dictionary:
 if int(g.get("world_badge_span_version",0))>=WATER_WORLD_BADGE_SPAN_VERSION:return g
 var highest:=clampi(int(g.get("highest_level",1)),1,CAMPAIGN_LEVELS+1)
 var completed_level:=clampi(highest-1,0,CAMPAIGN_LEVELS)
 var earned_worlds:=clampi(int(completed_level/WaterSortProgression.WORLD_SIZE),0,WaterSortProgression.WORLD_COUNT)
 var migrated:Array=[]
 for world in range(1,earned_worlds+1):migrated.append(str(world))
 g["world_badges"]=migrated
 g["world_badge_span_version"]=WATER_WORLD_BADGE_SPAN_VERSION
 return g

func _migrate_block_puzzle_world_badges(g:Dictionary)->Dictionary:
 if int(g.get("world_badge_span_version",0))>=BLOCK_WORLD_BADGE_SPAN_VERSION:return g
 var highest:=clampi(int(g.get("highest_level",1)),1,CAMPAIGN_LEVELS+1)
 var completed_level:=clampi(highest-1,0,CAMPAIGN_LEVELS)
 var earned_worlds:=clampi(int(completed_level/BlockPuzzleProgression.WORLD_SIZE),0,BlockPuzzleProgression.WORLD_COUNT)
 var migrated:Array=[]
 for world in range(1,earned_worlds+1):migrated.append(str(world))
 g["world_badges"]=migrated
 g["world_badge_span_version"]=BLOCK_WORLD_BADGE_SPAN_VERSION
 return g

func display_name(id:String)->String:return String(GAME_NAMES.get(id,id.to_upper()))
func progression_scope_label(id:String)->String:return "ZONE" if id=="rescue_rush" else "WORLD"

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

func _progress_ref(id:String)->Dictionary:
 ensure_state()
 if id=="rescue_rush":
  return {"highest_level":int(SaveManager.data.get("highest_level",1)),"stars":SaveManager.data.get("stars",{}),"levels_completed":int(SaveManager.data.get("total_levels_completed",0)),"perfect_clears":int(SaveManager.data.get("perfect_clears",0)),"perfect_streak":int(SaveManager.data.get("perfect_streak",0)),"best_perfect_streak":int(SaveManager.data.get("best_perfect_streak",0)),"milestone_chests":SaveManager.data.get("milestone_chests",[]),"world_badges":SaveManager.data.get("world_badges",[]),"daily_streak":int(SaveManager.data.get("daily_streak",0)),"daily_best_streak":int(SaveManager.data.get("daily_best_streak",0)),"achievements":_rescue_achievements()}
 var all=SaveManager.data.get("game_progress",{})
 if not all is Dictionary:return {}
 var raw=(all as Dictionary).get(id,{})
 return raw if raw is Dictionary else {}

func progress_for(id:String)->Dictionary:
 return _progress_ref(id).duplicate(true)

func highest_level(id:String)->int:return clampi(int(_progress_ref(id).get("highest_level",1)),1,CAMPAIGN_LEVELS+1)
func get_stars(id:String,n:int)->int:return int((_progress_ref(id).get("stars",{}) as Dictionary).get(str(n),0))
func levels_completed(id:String)->int:return int(_progress_ref(id).get("levels_completed",0))
func perfect_clears(id:String)->int:return int(_progress_ref(id).get("perfect_clears",0))
func world_badge_count(id:String)->int:
 var badges=_progress_ref(id).get("world_badges",[])
 return (badges as Array).size() if badges is Array else 0
func total_stars(id:String)->int:
 if _total_stars_cache.has(id):return int(_total_stars_cache[id])
 var total:=0
 var stars=_progress_ref(id).get("stars",{})
 if not stars is Dictionary:return 0
 for v in (stars as Dictionary).values():total+=int(v)
 _total_stars_cache[id]=total
 return total
func is_level_unlocked(id:String,n:int)->bool:return n<=highest_level(id)
func world_for_level(n:int)->int:return clampi(int((maxi(1,n)-1)/LEVELS_PER_WORLD)+1,1,WORLD_COUNT)
func first_level_in_world(w:int)->int:return (clampi(w,1,WORLD_COUNT)-1)*LEVELS_PER_WORLD+1
func last_level_in_world(w:int)->int:return mini(first_level_in_world(w)+LEVELS_PER_WORLD-1,CAMPAIGN_LEVELS)
func highest_unlocked_world(id:String)->int:return world_for_level(highest_level(id))
func world_count_for(id:String)->int:return WaterSortProgression.WORLD_COUNT if id=="water_sort" else (BlockPuzzleProgression.WORLD_COUNT if id=="block_puzzle" else WORLD_COUNT)
func world_for_game_level(id:String,n:int)->int:return int(WaterSortProgression.profile(n).get("world",1)) if id=="water_sort" else (int(BlockPuzzleProgression.profile(n).get("world",1)) if id=="block_puzzle" else world_for_level(n))
func first_level_in_game_world(id:String,w:int)->int:
 if id=="water_sort":return (clampi(w,1,WaterSortProgression.WORLD_COUNT)-1)*WaterSortProgression.WORLD_SIZE+1
 if id=="block_puzzle":return (clampi(w,1,BlockPuzzleProgression.WORLD_COUNT)-1)*BlockPuzzleProgression.WORLD_SIZE+1
 return first_level_in_world(w)
func last_level_in_game_world(id:String,w:int)->int:
 if id=="water_sort":return mini(first_level_in_game_world(id,w)+WaterSortProgression.WORLD_SIZE-1,CAMPAIGN_LEVELS)
 if id=="block_puzzle":return mini(first_level_in_game_world(id,w)+BlockPuzzleProgression.WORLD_SIZE-1,CAMPAIGN_LEVELS)
 return last_level_in_world(w)
func highest_unlocked_game_world(id:String)->int:return world_for_game_level(id,highest_level(id))
func difficulty_for_game(id:String,n:int)->String:return String(WaterSortProgression.profile(n).get("difficulty_label","normal-hard")) if id=="water_sort" else (String(BlockPuzzleProgression.profile(n).get("difficulty_class","normal")) if id=="block_puzzle" else difficulty_for_level(n))
func world_name(id:String,w:int)->String:
 var themes={
  "rescue_rush":["Garden Escape","Locks & Keys","Chain Reaction","Blast Lab","Linked Zone","Chaos Rescue","Portal Works","Crystal Circuit","Neon Factory","Rescue Nexus"],
  "water_sort":["Color Springs","Glass Garden","Prism Bay","Liquid Lab","Neon Pour","Spectrum Works","Crystal Flow","Chromatic Vault","Aurora Mix","Master Distillery"],
  "block_puzzle":["Starter Grid","Brick Yard","Shape Works","Line Factory","Pattern City","Block Forge","Grid Nexus","Combo Circuit","Crate Quarter","Ice Foundry","Lockworks","Steel District","Constraint Core","Vector Vault","Pressure Matrix","Expert Grid","Grandmaster Forge","Master Nexus","Final Matrix","Infinite Board"]
 }
 var set:Array=themes[id]
 if id=="block_puzzle":return String(set[clampi(w,1,set.size())-1])
 var base:=String(set[(w-1)%set.size()]);var chapter:=int((w-1)/set.size())+1;return "%s %d"%[base,chapter] if chapter>1 else base
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

func _prune_daily_game_choices()->void:
 var choices:Dictionary=SaveManager.data.get("daily_game_choices",{})
 var keys:Array=choices.keys()
 keys.sort()
 while keys.size()>DAILY_HISTORY_LIMIT:
  choices.erase(String(keys.pop_front()))
 SaveManager.data["daily_game_choices"]=choices

func daily_started_games()->Array[String]:
 ensure_state()
 var choices:Dictionary=SaveManager.data.get("daily_game_choices",{})
 var key:=date_key()
 var raw=choices.get(key,[])
 var started:Array[String]=[]
 if raw is Array:
  for value in raw:
   var id:=String(value)
   if id in GAME_IDS and id not in started:started.append(id)
 else:
  # Migrate the former one-choice-per-day string format without losing history.
  var legacy:=String(raw)
  if legacy in GAME_IDS:started.append(legacy)
  choices[key]=started.duplicate()
  SaveManager.data["daily_game_choices"]=choices
 return started

func daily_selected_game()->String:
 # Compatibility helper for older callers. Daily play is no longer exclusive;
 # return the most recently started game only as a descriptive value.
 var started:=daily_started_games()
 return started.back() if not started.is_empty() else ""

func claim_daily_game(id:String)->bool:
 if id not in GAME_IDS:return false
 ensure_state()
 var key:=date_key()
 var choices:Dictionary=SaveManager.data.get("daily_game_choices",{})
 var started:=daily_started_games()
 if id not in started:started.append(id)
 choices[key]=started
 SaveManager.data["daily_game_choices"]=choices
 _prune_daily_game_choices()
 SaveManager.save()
 return true

func daily_level(id:String)->int:
 var d:=Time.get_date_dict_from_system();return posmod(int(d.year)*372+int(d.month)*31+int(d.day)+GAME_IDS.find(id)*997,CAMPAIGN_LEVELS)+1
func is_daily_completed(id:String)->bool:
 if id=="rescue_rush":return DailyChallenge.is_completed_today()
 return date_key() in _progress_ref(id).get("daily_completed",[])

func achievement_definitions(id:String)->Array:return [{"id":"first","title":"First Victory","need":1},{"id":"century","title":"Century Club","need":100},{"id":"perfect25","title":"Perfectionist","need":25},{"id":"world10","title":"World Traveller","need":10},{"id":"master","title":"10K Master","need":10000}]
func unlocked_achievements(id:String)->Array:
 var p:=_progress_ref(id);var out:Array=[]
 for a in achievement_definitions(id):
  var ok:=int(p.get("levels_completed",0))>=int(a.need) if String(a.id) in ["first","century","master"] else (int(p.get("perfect_clears",0))>=25 if String(a.id)=="perfect25" else (p.get("world_badges",[]) as Array).size()>=10)
  if ok:out.append(String(a.id))
 return out
func complete_daily(id:String,reward:=100)->bool:
 if id=="rescue_rush":return SaveManager.complete_daily(date_key(),reward)
 ensure_state();var all:Dictionary=SaveManager.data.get("game_progress",{});var g:Dictionary=all.get(id,{});var key:=date_key();var done:Array=g.get("daily_completed",[]);var previous:=String(g.get("daily_last_date",""))
 if key in done or previous==key:return false
 g["daily_streak"]=int(g.get("daily_streak",0))+1 if _is_previous_calendar_day(previous,key) else 1;g["daily_best_streak"]=maxi(int(g.get("daily_best_streak",0)),int(g.get("daily_streak",0)));g["daily_last_date"]=key;done.append(key);g["daily_completed"]=_bounded_date_history(done);all[id]=g;SaveManager.data["game_progress"]=all;SaveManager.data["coins"]=int(SaveManager.data.get("coins",0))+reward;SaveManager.save();return true
func complete_level(id:String,n:int,stars:int,coin_reward:=25,context:Dictionary={})->Dictionary:
 if id=="rescue_rush":
  _total_stars_cache.erase(id)
  var rescue_id:=String(context.get("rescue_id",""))
  var rewards:=SaveManager.complete_level(n,stars,rescue_id,coin_reward)
  var difficulty:=String(context.get("difficulty",difficulty_for_game(id,n)))
  AnalyticsManager.track("multi_game_level_complete",{"game":id,"level":n,"stars":stars,"difficulty":difficulty})
  return rewards
 ensure_state();n=clampi(n,1,CAMPAIGN_LEVELS);stars=clampi(stars,1,3);var all:Dictionary=SaveManager.data.get("game_progress",{});var g:Dictionary=all.get(id,{});var sm:Dictionary=g.get("stars",{});var key:=str(n);var previous:=int(sm.get(key,0));var first:=previous==0;var rewards={"first_clear":first,"improved":stars>previous,"perfect":stars==3 and previous<3,"milestone":false,"world_badge":false,"bonus_coins":0,"prestige":0};sm[key]=maxi(previous,stars);g["stars"]=sm;g["highest_level"]=maxi(int(g.get("highest_level",1)),mini(CAMPAIGN_LEVELS+1,n+1))
 if first:g["levels_completed"]=mini(CAMPAIGN_LEVELS,int(g.get("levels_completed",0))+1);SaveManager.data["coins"]=int(SaveManager.data.get("coins",0))+coin_reward
 if stars==3 and previous<3:g["perfect_clears"]=int(g.get("perfect_clears",0))+1;g["perfect_streak"]=int(g.get("perfect_streak",0))+1;g["best_perfect_streak"]=maxi(int(g.get("best_perfect_streak",0)),int(g.get("perfect_streak",0)))
 elif first:g["perfect_streak"]=0
 if first and n%10==0:var c:Array=g.get("milestone_chests",[]);c.append(key);g["milestone_chests"]=c;rewards.milestone=true;SaveManager.data["coins"]=int(SaveManager.data.get("coins",0))+100
 var badge_span:=WaterSortProgression.WORLD_SIZE if id=="water_sort" else (BlockPuzzleProgression.WORLD_SIZE if id=="block_puzzle" else LEVELS_PER_WORLD)
 if first and n%badge_span==0:
  var wk:=str(int(n/badge_span));var b:Array=g.get("world_badges",[])
  if wk not in b:b.append(wk);g["world_badges"]=b;rewards.world_badge=true;SaveManager.data["coins"]=int(SaveManager.data.get("coins",0))+250;SaveManager.data["prestige_points"]=int(SaveManager.data.get("prestige_points",0))+5
 all[id]=g
 SaveManager.data["game_progress"]=all
 if _total_stars_cache.has(id):_total_stars_cache[id]=int(_total_stars_cache[id])+maxi(0,stars-previous)
 SaveManager.save()
 var difficulty:=difficulty_for_game(id,n)
 AnalyticsManager.track("multi_game_level_complete",{"game":id,"level":n,"stars":stars,"difficulty":difficulty})
 return rewards
func _persist_checkpoint_deferred()->void:
 if SaveManager.has_method("save_deferred"):SaveManager.call("save_deferred")
 else:SaveManager.save()

func _checkpoint_payload_matches(existing:Dictionary,payload:Dictionary)->bool:
 # Ignore only the generated timestamp. Compare nested values directly so an
 # unchanged move checkpoint does not recursively duplicate the whole run.
 for key in payload:
  if not existing.has(key) or existing[key]!=payload[key]:return false
 for key in existing:
  if key!="saved_at" and not payload.has(key):return false
 return true

func save_checkpoint(id:String,data:Dictionary)->void:
 ensure_state()
 var runs:Dictionary=SaveManager.data.get("multi_active_runs",{})
 # Gameplay callers already pass detached checkpoint arrays/dictionaries.
 # A second recursive duplicate here doubled per-move allocation cost; keep only
 # a shallow top-level copy while checkpoint() still deep-copies on read.
 var payload:=data.duplicate(false)
 var raw_history=payload.get("history",[])
 if raw_history is Array and (raw_history as Array).size()>CHECKPOINT_HISTORY_LIMIT:
  payload["history"]=(raw_history as Array).slice((raw_history as Array).size()-CHECKPOINT_HISTORY_LIMIT)
 payload["game"]=id
 var existing=runs.get(id,{})
 if existing is Dictionary and _checkpoint_payload_matches(existing as Dictionary,payload):return
 payload["saved_at"]=int(Time.get_unix_time_from_system())
 runs[id]=payload
 SaveManager.data["multi_active_runs"]=runs
 _persist_checkpoint_deferred()
func checkpoint(id:String)->Dictionary:
 ensure_state();var runs:Dictionary=SaveManager.data.get("multi_active_runs",{});var raw=runs.get(id,{});return raw.duplicate(true) if raw is Dictionary else {}
func clear_checkpoint(id:String)->void:
 ensure_state()
 var runs:Dictionary=SaveManager.data.get("multi_active_runs",{})
 if not runs.has(id):return
 runs.erase(id)
 SaveManager.data["multi_active_runs"]=runs
 _persist_checkpoint_deferred()
