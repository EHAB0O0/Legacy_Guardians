extends StaticBody3D

@export var activated_color: Color = Color(0.0, 1.0, 0.0)
@export var inactive_color: Color = Color(1.0, 0.0, 0.0)

var is_activated: bool = false
var _hit_this_frame: bool = false

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
var material: StandardMaterial3D

func _ready() -> void:
	material = StandardMaterial3D.new()
	mesh_instance.material_override = material
	_update_color()

func _physics_process(delta: float) -> void:
	if is_activated != _hit_this_frame:
		is_activated = _hit_this_frame
		_update_color()
		if is_activated:
			print("Puzzle Solved: Receiver Activated!")
			
	# Reset for next frame
	_hit_this_frame = false

func receive_light() -> void:
	_hit_this_frame = true

func _update_color() -> void:
	if is_activated:
		material.albedo_color = activated_color
		material.emission_enabled = true
		material.emission = activated_color
	else:
		material.albedo_color = inactive_color
		material.emission_enabled = true
		material.emission = inactive_color * 0.5
