extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@export var move_speed: float = 5.0
@export var gravity: float = 20.0
@export var mouse_sensitiveity: float = 0.003
@export var min_camera_angle: float = -60
@export var max_camera_angle: float = 30

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D  = $CameraPivot/MainCamera

var camera_pitch: float = 0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		camera_pivot.rotate_y(-event.relative.x * mouse_sensitiveity)
		camera_pitch -= event.relative.y * mouse_sensitiveity
	camera_pitch = clamp(
			camera_pitch,
			deg_to_rad(min_camera_angle),
			deg_to_rad(max_camera_angle)
		)

	camera.rotation.x = camera_pitch

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_back"
		)
	
	var forward := -camera_pivot.global_basis.z
	var right := camera_pivot.global_basis.x

#	keep movement in the ground, ignoring camera up/down title.
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()
	
	var direction := right * input_dir.x + forward * -input_dir.y
	direction = direction.normalized()
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
		
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
	#var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	#var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
