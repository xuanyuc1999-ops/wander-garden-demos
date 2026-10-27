extends RefCounted

const REGIONS = [
	{"id":"meadow", "name":"起始田园谷地", "en":"THE MEADOW", "crop":"胡萝卜", "pet":"软毛小兔", "ground":"368e6d", "leaf":"4aaf75", "accent":"f2bd65", "sky":"79bed2", "line":"土地从不催促生长。你也可以。", "signs":["把第一颗种子留给今天，\n把收成留给某个心情好的明天。","沿微光走走吧。\n风会记得你回家的路。"]},
	{"id":"forest", "name":"晨雾苔藓森林", "en":"MISTWOOD", "crop":"苔藓菌菇", "pet":"红毛小狐狸", "ground":"236966", "leaf":"308d83", "accent":"e7bc6c", "sky":"689faa", "line":"雾替森林保管着没说完的话。", "signs":["昨夜有狐狸经过。\n它没有带走什么，只留下几枚脚印。","苔藓长得很慢，\n却已经把石头抱了很久。"]},
	{"id":"salt", "name":"金沙盐湖滩", "en":"THE SALT MIRROR", "crop":"晶花", "pet":"小水獭", "ground":"d3ba73", "leaf":"63b7ab", "accent":"70d8de", "sky":"75c5d1", "line":"天空落在水里，风把它轻轻铺平。", "signs":["湖里的云不必去远方。\n你也是。","晶花把盐变成了光。\n每一片土地都有自己的温柔。"]},
	{"id":"autumn", "name":"枫红秋谷", "en":"AMBER HOLLOW", "crop":"秋梨", "pet":"大尾松鼠", "ground":"ba783d", "leaf":"e65b3c", "accent":"f2c25a", "sky":"c5a3a5", "line":"落叶没有迟到，它只是选了自己的季节。", "signs":["松鼠埋下的，不全是粮食。\n也有下一个春天。","如果想念夏天，\n就靠着这棵枫树坐一会儿。"]},
	{"id":"stars", "name":"星光花谷", "en":"THE STAR GARDEN", "crop":"荧光花", "pet":"萤火虫兽", "ground":"2b3468", "leaf":"8878c2", "accent":"71e4ee", "sky":"182b62", "line":"这里的夜很长，足够安放所有小小的愿望。", "signs":["没有人规定星星必须挂在天上。","走到这里也不是终点。\n你喜欢的地方，就是家。"]}
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
