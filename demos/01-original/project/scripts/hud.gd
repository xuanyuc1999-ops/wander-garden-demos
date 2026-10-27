extends CanvasLayer
var game: Node
var region_label: Label
var area_en: Label
var prompt_label: Label
var toast_label: Label
var seed_label: Label
var detail_label: Label
var help_label: Label
var region_row: Label
var panel: PanelContainer
var panel_text: Label
var start_screen: Control
var main: Control
var toast_time=0.0
var kind=""

func style(bg: Color, radius: int=14) -> StyleBoxFlat:
	var s=StyleBoxFlat.new()
	s.bg_color=bg
	s.corner_radius_top_left=radius
	s.corner_radius_top_right=radius
	s.corner_radius_bottom_left=radius
	s.corner_radius_bottom_right=radius
	s.content_margin_left=22
	s.content_margin_right=22
	s.content_margin_top=16
	s.content_margin_bottom=16
	return s

func label(parent: Node,text: String,size: int,color: Color=Color("#f6f0df")) -> Label:
	var l=Label.new()
	l.text=text
	l.add_theme_font_size_override("font_size",size)
	l.add_theme_color_override("font_color",color)
	parent.add_child(l)
	return l

func _ready() -> void:
	var theme=Theme.new()
	theme.default_font=load("res://assets/fonts/NotoSansCJKsc-Regular.otf")
	theme.default_font_size=18
	main=Control.new()
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main.mouse_filter=Control.MOUSE_FILTER_IGNORE
	main.theme=theme
	add_child(main)
	var top=VBoxContainer.new()
	top.position=Vector2(42,31)
	main.add_child(top)
	label(top,"W A N D E R   G A R D E N",14,Color("#e7e8cb"))
	region_label=label(top,"起始田园谷地",28)
	area_en=label(top,"THE MEADOW",12,Color("#e2dfc9"))
	region_row=label(main,"",17)
	region_row.position=Vector2(920,34)
	var bottom=PanelContainer.new()
	bottom.position=Vector2(36,760)
	bottom.size=Vector2(420,108)
	bottom.add_theme_stylebox_override("panel",style(Color(0.12,0.20,0.17,0.90)))
	main.add_child(bottom)
	var vb=VBoxContainer.new()
	bottom.add_child(vb)
	seed_label=label(vb,"",18)
	detail_label=label(vb,"",13,Color("#d6dcc2"))
	help_label=label(main,"WASD 漫游   Shift 轻跑   右键拖动看风景   滚轮远近\nF 开垦   E 互动   Q 换种子   B 行囊   J 图鉴   Esc 休息",15)
	help_label.position=Vector2(710,806)
	help_label.add_theme_color_override("font_shadow_color",Color("#253c37"))
	help_label.add_theme_constant_override("shadow_offset_x",1)
	help_label.add_theme_constant_override("shadow_offset_y",2)
	for text_node in [region_label,area_en,region_row]:
		text_node.add_theme_color_override("font_shadow_color",Color("#253c37"))
		text_node.add_theme_constant_override("shadow_offset_y",2)
	prompt_label=label(main,"",20)
	prompt_label.position=Vector2(420,685)
	prompt_label.size=Vector2(600,50)
	prompt_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_color_override("font_shadow_color",Color("#253c37"))
	prompt_label.add_theme_constant_override("shadow_offset_x",2)
	prompt_label.add_theme_constant_override("shadow_offset_y",2)
	toast_label=label(main,"",19)
	toast_label.position=Vector2(300,138)
	toast_label.size=Vector2(840,80)
	toast_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_color_override("font_shadow_color",Color("#273d35"))
	toast_label.add_theme_constant_override("shadow_offset_y",2)
	panel=PanelContainer.new()
	panel.position=Vector2(330,190)
	panel.size=Vector2(780,470)
	panel.add_theme_stylebox_override("panel",style(Color(0.11,0.18,0.16,0.96),20))
	main.add_child(panel)
	panel_text=label(panel,"",21)
	panel_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	panel.visible=false
	start_screen=Control.new()
	start_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	start_screen.theme=theme
	add_child(start_screen)
	var veil=ColorRect.new()
	veil.color=Color(0.08,0.16,0.13,0.38)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	start_screen.add_child(veil)
	var intro=VBoxContainer.new()
	intro.position=Vector2(100,190)
	intro.add_theme_constant_override("separation",18)
	start_screen.add_child(intro)
	label(intro,"A LITTLE PLACE TO BELONG",15,Color("#e7debd"))
	label(intro,"漫野田园",76)
	label(intro,"W A N D E R   G A R D E N",23)
	label(intro,"\n在破碎相连的梦境原野，\n种一片只属于你的漫野田园。\n",22)
	var button=Button.new()
	button.text="继续漫游" if FileAccess.file_exists("user://garden.json") else "走进原野"
	button.custom_minimum_size=Vector2(300,65)
	button.add_theme_stylebox_override("normal",style(Color("#e1d4ac"),30))
	button.add_theme_stylebox_override("hover",style(Color("#f0e2bc"),30))
	button.add_theme_color_override("font_color",Color("#33493b"))
	button.add_theme_color_override("font_hover_color",Color("#33493b"))
	button.pressed.connect(game.begin)
	intro.add_child(button)
	label(intro,"没有必须完成的事。按 Enter 也可以启程。",15,Color("#e0dfc9"))
	var build_label=label(start_screen,"五场景玩法灰盒 · 实时区块与配色预览  /  v0.2",14)
	build_label.position=Vector2(42,850)
	main.visible=false

func _process(delta: float) -> void:
	if not game.world_ready:
		return
	toast_time=maxf(0,toast_time-delta)
	toast_label.modulate.a=minf(1.0,toast_time)
	var r=game.region
	region_label.text=game.data.REGIONS[r].name
	area_en.text=game.data.REGIONS[r].en
	var dots=""
	for i in range(5):
		dots+=("●" if i<=game.unlocked else "○")+"  "
	region_row.text=dots+"    "+("星光夜" if r==4 else "薄雾" if r==1 else "晴光")
	seed_label.text="Q  "+game.data.REGIONS[game.selected_seed].crop+"种子  × "+str(game.seeds[game.selected_seed])
	detail_label.text="G "+("网格吸附" if game.grid else "自由开垦")+"   ·   T "+game.data.SPEED_NAMES[game.speed_index]
	if not panel.visible:
		prompt_label.text=game.target_prompt()
	else:
		prompt_label.text=""
	if panel.visible and kind in ["bag","journal"]:
		update_panel()

func toast(text: String) -> void:
	toast_label.text=text
	toast_time=5.5

func toggle(which: String) -> void:
	if panel.visible and kind==which:
		close()
		return
	kind=which
	panel.visible=true
	update_panel()
	game.player.enabled=false

func close() -> void:
	panel.visible=false
	kind=""
	game.paused=false
	game.player.enabled=true

func update_panel() -> void:
	var text=""
	if kind=="bag":
		text="行 囊   /   POCKETS\n\n"
		for i in range(5):
			text+="%-8s      种子 %d        收成 %d\n" % [game.data.REGIONS[i].crop,game.seeds[i],game.harvest[i]]
		text+="\nQ 切换播种种类 · E 靠近动物投喂\n收获返还种子，篮子里的种子也会慢慢补满。\n\nB / Esc 收起"
	elif kind=="journal":
		text="沿 途 所 遇   /   FIELD NOTES\n\n"
		for i in range(5):
			text+=("%s   %s   ·   %s\n" % [game.data.REGIONS[i].name,game.data.REGIONS[i].crop if game.discovered_crops[i] else "未收获的种子",game.data.REGIONS[i].pet if game.discovered_pets[i] else "还未认识的小生灵"])
		text+="\n风物记录："+str(game.read_signs.size())+" / 10\n没有收集奖励，也没有必须填满的空格。\n\nJ / Esc 收起"
	elif kind=="pause":
		text="在 这 里 休 息 一 会 儿\n\n作物和时光都已暂停。\n\nT 生长速度： "+game.data.SPEED_NAMES[game.speed_index]+"\nG 自由开垦 / 网格吸附\nM 音乐开关   ·   P 拍照模式\nR 让伙伴留下 / 邀请附近伙伴跟随\nH 显示或隐藏操作提示\n\nEsc 继续漫游 · F5 保存\n存档只记录游玩时间，离线不会有任何损失。"
	panel_text.text=text

func story(text: String) -> void:
	kind="story"
	panel.visible=true
	panel_text.text="风 物 笺\n\n\n"+text+"\n\n\nEsc 收起"
	game.player.enabled=false

