extends CharacterBody3D

@export var walk_speed: float = 1.0
@export var run_speed: float = 4.0
@export var gravity: float = 20.0
@export var jump_velocity: float = 7.0
@export var mouse_sensitivity: float = 0.003
@export var min_camera_angle: float = -60.0
@export var max_camera_angle: float = 30.0
@export var turn_speed: float = 5.0
@export var animation_controller: Node

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/MainCamera
@onready var body_mesh: MeshInstance3D = $BodyMesh
@onready var visual_pivot = $VisualPivot
@onready var anim_player = $AnimationPlayer

var camera_pitch: float = 0.0
var is_running: bool = false
var current_speed: float = walk_speed
var landing_locked: bool = false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED	
	current_speed = walk_speed
	landing_locked = false

func _unhandled_input(event: InputEvent) -> void:
	
	if event is InputEventMouseMotion:
		camera_pivot.rotate_y(
			-event.relative.x * mouse_sensitivity
		)		
		camera_pitch -= event.relative.y * mouse_sensitivity
		camera_pitch = clamp(
			camera_pitch,
			deg_to_rad(min_camera_angle),
			deg_to_rad(max_camera_angle)
		)
		camera.rotation.x = camera_pitch

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
func _physics_process(delta: float) -> void:
	var moving_forward := Input.is_key_pressed(KEY_W);
	var moving_left := Input.is_key_pressed(KEY_A);
	var moving_back := Input.is_key_pressed(KEY_S);
	var moving_right := Input.is_key_pressed(KEY_D);
	var running := Input.is_key_pressed(KEY_SHIFT);
	#update speed continuously, even while W is hold
	if moving_forward or moving_back or moving_left or moving_right:
		current_speed = run_speed if running else walk_speed
	
	# Read WASD input.
	var input_dir := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_back"
	)
		
	# Get the camera's horizontal forward and right directions.
	var forward := -camera_pivot.global_basis.z
	var right := camera_pivot.global_basis.x

	forward.y = 0.0
	right.y = 0.0

	forward = forward.normalized()
	right = right.normalized()

	# Convert input into camera-relative movement.	
	var direction := right * input_dir.x - forward * input_dir.y
	direction = direction.normalized()

	# Set horizontal movement.	
		
	# Lock horizontal movement only during Jump_Land.
	if landing_locked:
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	
		# Turn smoothly toward the direction of movement.
	if direction.length() > 0.01:
		var target_angle: float = atan2(
			direction.x,
			direction.z
		)

		anim_player.rotation.y = lerp_angle(
			anim_player.rotation.y,
			target_angle,
			min(turn_speed * delta, 1.0)
		)
	
	# Apply gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
		else:
			velocity.y = 0.0

	# Move the character and handle collisions.
	move_and_slide()
	
func unlock_after_landing() -> void:
	landing_locked = false

func lock_for_landing() -> void:
	landing_locked = true
	velocity.x = 0.0
	velocity.z = 0.0
