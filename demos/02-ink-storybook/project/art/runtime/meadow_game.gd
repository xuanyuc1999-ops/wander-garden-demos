extends "res://art/runtime/meadow_sample.gd"
# Playable art preview uses its own save, so it never overwrites the greybox save.
var art_initialized=false
const ART_SAVE="user://wander-garden-art-v03.json"
func _ready() -> void:
	await super._ready()
	var testing=false
	for arg in OS.get_cmdline_user_args():
		if arg in ["--ink-check","--locomotion-check","--meshy-check","--biome-check","--biome-capture","--lux-check","--lux-qa","--qa","--sample-test","--pilot-proof","--sample-capture","--sample-benchmark","--save-smoke","--motion-water-demo","--motion-water-check"]:
			testing=true
	art_initialized=true
	qa=testing
	if not testing:load_game()
	if "--save-smoke" in OS.get_cmdline_user_args():
		var test=load("res://art/runtime/save_smoke.gd").new()
		test.game=self
		add_child(test)

func save_file() -> String:
	return "user://wander-garden-art-save-smoke.json" if "--save-smoke" in OS.get_cmdline_user_args() else ART_SAVE

func load_game() -> void:
	if not art_initialized or not FileAccess.file_exists(save_file()):return
	var file=FileAccess.open(save_file(),FileAccess.READ)
	if file==null:return
	var payload=JSON.parse_string(file.get_as_text())
	file.close()
	if payload is Dictionary and int(payload.get("version",0))==1:
		restore_payload(payload)

func restore_payload(payload: Dictionary) -> void:
	super.restore_payload(payload)
	seeds=seeds.map(func(value):return int(value))
	harvest=harvest.map(func(value):return int(value))
	player.velocity=Vector3.ZERO

func save_game() -> void:
	if not art_initialized or not started:return
	var path=save_file()
	var file=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file!=null:
		file.store_string(JSON.stringify(save_payload()))
		file.close()
		if FileAccess.file_exists(path):
			DirAccess.copy_absolute(ProjectSettings.globalize_path(path),ProjectSettings.globalize_path(path+".backup"))
		DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))
