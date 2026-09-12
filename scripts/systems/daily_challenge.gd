extends Node

func date_key() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d.year, d.month, d.day]

func build_today() -> Dictionary:
	var key := date_key()
	var seed_value := int(key.replace("-", ""))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var base_level := 51 + rng.randi_range(0, 9)
	var data := CampaignGenerator.generate(base_level)
	data["id"] = -1
	data["daily"] = true
	data["daily_key"] = key
	data["par_moves"] = int(data.get("par_moves", 8)) + rng.randi_range(0, 2)
	data["rescue_id"] = ["chick", "puppy", "kitten", "robot", "panda", "fox", "alien"][rng.randi_range(0, 6)]
	return data

func is_completed_today() -> bool:
	return date_key() in SaveManager.data.daily_completed

func reward_text() -> String:
	return "COMPLETED" if is_completed_today() else "+100 COINS"
