extends Node3D
class_name LightEmitter

@export var max_bounces: int = 5
@export var max_distance: float = 100.0
@export var beam_color: Color = Color(1.0, 0.9, 0.2, 0.8)

var raycasts: Array[RayCast3D] = []
var beam_meshes: Array[MeshInstance3D] = []

func _ready() -> void:
	pass

func _physics_process(_delta: float) -> void:
	_update_beams()

func _create_beam_segment(_index: int) -> void:
	var ray = RayCast3D.new()
	add_child(ray)
	raycasts.append(ray)
	ray.enabled = false # we manually update it
	
	var mesh_inst = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.05
	cylinder.bottom_radius = 0.05
	cylinder.height = 1.0 # default
	mesh_inst.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = beam_color
	mat.emission_enabled = true
	mat.emission = beam_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_inst.material_override = mat
	
	add_child(mesh_inst)
	beam_meshes.append(mesh_inst)

func _update_beams() -> void:
	var current_origin = global_position
	var current_dir = -global_transform.basis.z.normalized()
	var current_color = beam_color
	
	var ignored_bodies = []
	
	for i in range(max_bounces):
		if i >= raycasts.size():
			_create_beam_segment(i)
		
		var ray = raycasts[i]
		var mesh = beam_meshes[i]
		
		ray.clear_exceptions()
		for body in ignored_bodies:
			ray.add_exception(body)
			
		# set global ray position, calculate local target
		ray.global_position = current_origin
		ray.target_position = ray.to_local(current_origin + current_dir * max_distance)
		ray.hit_from_inside = true
		ray.collision_mask = 0xFFFFFFFF # Collide with everything
		ray.force_raycast_update()
		
		var hit_point = current_origin + current_dir * max_distance
		var is_hit = ray.is_colliding()
		
		if is_hit:
			hit_point = ray.get_collision_point()
			
		var distance = current_origin.distance_to(hit_point)
		
		if distance > 0.01:
			mesh.visible = true
			var mid_point = current_origin + current_dir * (distance / 2.0)
			
			# Orient cylinder mesh along beam
			mesh.global_position = mid_point
			# default cylinder is Y-up, look_at makes -Z point to target
			mesh.look_at(hit_point, Vector3.UP if abs(current_dir.y) < 0.99 else Vector3.RIGHT)
			mesh.rotate_object_local(Vector3.RIGHT, PI / 2.0)
			mesh.scale = Vector3(1, distance, 1)
			
			# apply current color
			if mesh.material_override:
				mesh.material_override.albedo_color = current_color
				mesh.material_override.emission = current_color
		else:
			mesh.visible = false
			
		if is_hit:
			var collider = ray.get_collider()
			if collider and collider.is_in_group("Reflectors"):
				var normal = ray.get_collision_normal()
				current_dir = current_dir.bounce(normal)
				current_origin = hit_point + current_dir * 0.01 # offset to avoid getting stuck
			elif collider and collider.is_in_group("Lenses") and collider.has_method("get_refracted_direction"):
				# Refract through lens
				var normal = ray.get_collision_normal()
				current_dir = collider.get_refracted_direction(current_dir, normal)
				current_origin = hit_point # the new ray will start here and ignore this lens
				ignored_bodies.append(collider)
				# Mix colors for neon effect
				var tint = collider.get_tint()
				current_color = current_color.lerp(tint, 0.8)
			elif collider and collider.has_method("receive_light"):
				collider.receive_light()
				_hide_remaining_segments(i + 1)
				break
			else:
				_hide_remaining_segments(i + 1)
				break
		else:
			_hide_remaining_segments(i + 1)
			break

func _hide_remaining_segments(start_idx: int) -> void:
	for i in range(start_idx, raycasts.size()):
		beam_meshes[i].visible = false
