extends Node
# Rendering sample with teleported views. Not evidence of gameplay traversal.
var game: Node
var samples: Array=[]
var collecting=false
var last_frame_us=0
func _process(_delta: float) -> void:
	var now=Time.get_ticks_usec()
	if collecting:
		samples.append((now-last_frame_us)/1000.0)
	last_frame_us=now
func _ready() -> void:
	get_window().borderless=true
	get_window().size=Vector2i(1920,1080)
	get_window().position=Vector2i.ZERO
	game.begin()
	var results=[]
	for i in range(5):
		game.player.position=game.data.center(i)+Vector3(0,0.1,9)
		await get_tree().create_timer(2.0).timeout
		samples=[]
		collecting=true
		await get_tree().create_timer(6.0).timeout
		collecting=false
		samples.sort()
		var total=0.0
		for value in samples:
			total+=value
		results.append({"region":i,"frames":samples.size(),"average_fps":samples.size()*1000.0/total,"p95_ms":samples[int(samples.size()*0.95)],"p99_ms":samples[int(samples.size()*0.99)],"max_ms":samples.back(),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})
		print("BENCH_REGION ",JSON.stringify(results.back()))
	game.player.position=Vector3(48,0.5,-10)
	game.player.pivot.rotation.y=0
	await get_tree().create_timer(2.0).timeout
	samples=[]
	collecting=true
	Input.action_press("right")
	Input.action_press("run")
	await get_tree().create_timer(18.0).timeout
	Input.action_release("right")
	Input.action_release("run")
	collecting=false
	samples.sort()
	var stream_total=0.0
	for value in samples:
		stream_total+=value
	var traversal={"frames":samples.size(),"average_fps":samples.size()*1000.0/stream_total,"p95_ms":samples[int(samples.size()*0.95)],"p99_ms":samples[int(samples.size()*0.99)],"max_ms":samples.back(),"end_position":str(game.player.position),"chunks":game.streamer.stats()}
	var path="user://benchmark.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--benchmark-report="):
			path=arg.trim_prefix("--benchmark-report=")
	var f=FileAccess.open(path,FileAccess.WRITE)
	f.store_string(JSON.stringify({"gpu":RenderingServer.get_video_adapter_name(),"logical_viewport":str(get_viewport().get_visible_rect().size),"framebuffer":str(get_viewport().get_texture().get_size()),"window":str(DisplayServer.window_get_size()),"engine":Engine.get_version_info(),"method":"monotonic wall-clock intervals; five fixed native views, 2s warmup + 6s measured each; 18s input-driven peripheral chunk traversal after positional setup","regions":results,"stream_traversal":traversal},"\t"))
	f.close()
	get_tree().quit()
