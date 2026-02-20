extends CharacterBody3D

@export var speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var rotation_speed: float = 10.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var third_person_pivot = $ThirdPersonPivot
@onready var top_down_pivot = $TopDownPivot
@onready var third_person_cam = $ThirdPersonPivot/ThirdPersonCamera
@onready var top_down_cam = $TopDownPivot/TopDownCamera

var is_top_down: bool = false
var _was_c_pressed: bool = false

func _ready() -> void:
	third_person_cam.make_current()

func _physics_process(delta: float) -> void:
	# Toggle Camera logic
	if Input.is_key_pressed(KEY_C):
		if not _was_c_pressed:
			toggle_camera()
			_was_c_pressed = true
	else:
		_was_c_pressed = false
		
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if is_top_down:
		direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	else:
		var cam_basis = third_person_pivot.global_transform.basis
		direction = (cam_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		direction.y = 0

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		
		# Rotate character to face direction of movement
		var target_transform = transform.looking_at(global_position + direction, Vector3.UP)
		transform = transform.interpolate_with(target_transform, rotation_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

func toggle_camera() -> void:
	is_top_down = !is_top_down
	if is_top_down:
		top_down_cam.make_current()
	else:
		third_person_cam.make_current()
