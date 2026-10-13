extends SceneTree

const Block = preload("res://scripts/core/block_puzzle_authored_catalog.gd")
const Rescue = preload("res://scripts/core/rescue_rush_authored_catalog.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for catalog in [Block, Rescue]:
		catalog.clear_cache()
		for level in [1, 501, 1001, 501, 1501, 9501, 1]:
			var item: Dictionary = catalog.recipe(level)
			if not _check(int(item.get("level", -1)) == level, "Chapter eviction changed the authored puzzle at level %d" % level):return
			if not _check(catalog._chapter_cache.size() <= 2, "Chapter cache grew beyond two 500-level windows"):return
		catalog.clear_cache()
		if not _check(catalog._chapter_cache.is_empty(), "Cache clear failed"):return
	print("CAMPAIGN_CACHE_BOUNDS_OK: bounded memory, correct levels after eviction and reload")
	quit(0)

func _check(ok: bool, message: String) -> bool:
	if ok: return true
	push_error(message)
	quit(1)
	return false
