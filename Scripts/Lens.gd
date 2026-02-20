extends StaticBody3D
class_name SirajLens

enum LensType { CONVEX, CONCAVE, PRISM }

@export var type: LensType = LensType.CONVEX
@export var refraction_angle: float = 30.0 # Used for PRISM or custom bending
@export var tint_color: Color = Color(0.1, 0.8, 0.9, 1.0) # Adds a neon art feel to the light

@onready var mesh_instance = $MeshInstance3D

func _ready() -> void:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = tint_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.5
	mat.emission_enabled = true
	mat.emission = tint_color * 0.5
	mesh_instance.material_override = mat

# Returns the new refracted direction of the light
func get_refracted_direction(incident_dir: Vector3, hit_normal: Vector3) -> Vector3:
	var new_dir = incident_dir
	
	match type:
		LensType.CONVEX:
			# Bends towards the normal (simplified for puzzle logic)
			new_dir = incident_dir.lerp(-hit_normal, 0.2).normalized()
		LensType.CONCAVE:
			# Bends away from the normal
			new_dir = incident_dir.lerp(hit_normal, 0.2).normalized()
		LensType.PRISM:
			# Bends at a specific sharp angle around the Y axis (example)
			var angle_rad = deg_to_rad(refraction_angle)
			new_dir = incident_dir.rotated(Vector3.UP, angle_rad).normalized()
			
	return new_dir

func get_tint() -> Color:
	return tint_color
