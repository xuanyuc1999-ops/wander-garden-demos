extends Node
var game: Node
var recording=false
var last_draw=0
var samples=[]
func rendered() -> void:
	var now=Time.get_ticks_usec()
	if recording and last_draw>0:samples.append((now-last_draw)/1000.0)
	last_draw=now
func measure() -> Dictionary:
	if samples.is_empty():return {"status":"not_run","reason":"No presented native frames"}
	samples.sort()
	var total=0.0
	for v in samples:total+=v
	return {"status":"measured","frames":samples.size(),"average_fps":samples.size()*1000.0/total,
		"p95_ms":samples[mini(samples.size()-1,int(samples.size()*.95))],
		"p99_ms":samples[mini(samples.size()-1,int(samples.size()*.99))],"maximum_ms":samples.back(),
		"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"rendered_primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)}
func _ready() -> void:
	var path="user://art-benchmark.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--benchmark-report="):path=arg.trim_prefix("--benchmark-report=")
	get_window().content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT
	get_window().content_scale_size=Vector2i(1920,1080)
	get_window().size=Vector2i(1920,1080)
	RenderingServer.frame_post_draw.connect(rendered)
	game.begin()
	var views=[]
	for i in range(5):
		game.player.position=game.data.center(i)+Vector3(0,.1,9)
		await get_tree().create_timer(2).timeout
		samples=[];last_draw=0;recording=true
		await get_tree().create_timer(4).timeout
		recording=false
		var result=measure();result["region"]=i;views.append(result)
		print("ART_BENCH ",JSON.stringify(result))
	game.player.position=Vector3(48,.5,-10)
	await get_tree().create_timer(2).timeout
	samples=[];last_draw=0;recording=true
	Input.action_press("right");Input.action_press("run")
	await get_tree().create_timer(10).timeout
	Input.action_release("right");Input.action_release("run")
	recording=false
	var stream=measure();stream["chunks"]=game.streamer.stats()
	var report={"gpu":RenderingServer.get_video_adapter_name(),"engine":Engine.get_version_info(),
		"framebuffer":str(get_viewport().get_texture().get_size()),"window":str(DisplayServer.window_get_size()),
		"method":"Native frame_post_draw intervals, no fixed FPS acceleration; 2s warmup/4s each fixed view then 10s real input chunk traversal. All five biomes have Halloween art and original gameplay.",
		"views":views,"traversal":stream}
	var f=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"));f.close()
	get_tree().quit()
