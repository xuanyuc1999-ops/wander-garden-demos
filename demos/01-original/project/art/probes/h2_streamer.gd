extends "res://scripts/chunk_streamer.gd"
# Proposal-only avoidance area. The old cottage lawn stays clear for cultivation.
func reserved(pos: Vector3) -> bool:
	if Data.region_at(pos)==0 and pos.x> -17 and pos.x< -5 and pos.z> -25 and pos.z< -13:
		return true
	return super.reserved(pos)
