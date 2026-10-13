extends CharacterBody3D

@export var walk_speed: float = 5.0
@export var run_speed: float = 8.0
@export var gravity: float = 20.0
@export var jump_velocity: float = 7.0
@export var mouse_sensitivity: float = 0.003
@export var min_camera_angle: float = -60.0
@export var max_camera_angle: float = 30.0
@export var turn_speed: float = 5.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/MainCamera
@onready var body_mesh: MeshInstance3D = $BodyMesh
@onready var visual_pivot = $VisualPivot
@onready var anim_player = $AnimationPlayer

var camera_pitch: float = 0.0
var current_speed = walk_speed

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED	

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
	if Input.is_action_pressed("run"):
		current_speed = run_speed

func _physics_process(delta: float) -> void:
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
	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed

	# Turn smoothly toward the direction of movement.
	if direction.length() > 0.01:
		var target_angle: float = atan2(
			-forward.x,
			-forward.z
		)

		anim_player.rotation.y = lerp_angle(
			anim_player.rotation.y,
			target_angle+135,
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
