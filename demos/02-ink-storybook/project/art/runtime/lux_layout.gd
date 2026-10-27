extends "res://art/probes/h2_test.gd"
func walk(destination: Vector3,tolerance: float=.3,budget: float=35.0) -> bool:
	var distance=Vector2(destination.x-game.player.position.x,destination.z-game.player.position.z).length()
	return await super.walk(destination,tolerance,maxf(budget,distance/game.player.run_speed*2.0+10))
