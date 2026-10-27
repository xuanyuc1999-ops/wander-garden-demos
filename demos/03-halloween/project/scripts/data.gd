extends RefCounted

const REGIONS = [
	{"id":"meadow", "name":"南瓜田园谷地", "en":"THE MEADOW", "crop":"胡萝卜", "pet":"软毛小兔", "ground":"765467", "leaf":"ca8b52", "accent":"f2bd65", "sky":"79bed2", "line":"南瓜灯替你留着一条暖暖的回家路。", "signs":["把第一颗种子留给今天，\n把收成留给某个心情好的明天。","沿微光走走吧。\n风会记得你回家的路。"]},
	{"id":"forest", "name":"幽雾苔藓森林", "en":"MISTWOOD", "crop":"苔藓菌菇", "pet":"红毛小狐狸", "ground":"484663", "leaf":"8263ad", "accent":"e7bc6c", "sky":"689faa", "line":"雾里的小幽灵，只想陪你散一会儿步。", "signs":["昨夜有狐狸经过。\n它没有带走什么，只留下几枚脚印。","苔藓长得很慢，\n却已经把石头抱了很久。"]},
	{"id":"salt", "name":"月镜盐湖滩", "en":"THE SALT MIRROR", "crop":"晶花", "pet":"小水獭", "ground":"9ca6bb", "leaf":"63b7ab", "accent":"70d8de", "sky":"75c5d1", "line":"月亮把银色糖纸，轻轻铺在湖面上。", "signs":["湖里的云不必去远方。\n你也是。","晶花把盐变成了光。\n每一片土地都有自己的温柔。"]},
	{"id":"autumn", "name":"南瓜枫红秋谷", "en":"AMBER HOLLOW", "crop":"秋梨", "pet":"大尾松鼠", "ground":"a6684e", "leaf":"e65b3c", "accent":"f2c25a", "sky":"c5a3a5", "line":"枫叶和南瓜，都穿好了秋天的节日盛装。", "signs":["松鼠埋下的，不全是粮食。\n也有下一个春天。","如果想念夏天，\n就靠着这棵枫树坐一会儿。"]},
	{"id":"stars", "name":"幽光星花谷", "en":"THE STAR GARDEN", "crop":"荧光花", "pet":"萤火虫兽", "ground":"51416b", "leaf":"8878c2", "accent":"71e4ee", "sky":"182b62", "line":"今晚的星星，是小骷髅悄悄撒下的糖。", "signs":["没有人规定星星必须挂在天上。","走到这里也不是终点。\n你喜欢的地方，就是家。"]}
]
const SPACING = 72.0
const GROW_SECONDS = [12.0, 35.0, 65.0]
const SPEED_NAMES = ["快 · 12 秒", "正常 · 35 秒", "慢 · 65 秒"]

static func center(index: int) -> Vector3:
	return Vector3(0, 0, -SPACING * index)

static func region_at(pos: Vector3) -> int:
	return clampi(roundi(-pos.z / SPACING), 0, 4)

static func gate_pos(index: int) -> Vector3:
	return Vector3(0, 0, -36.0 - SPACING * index)
