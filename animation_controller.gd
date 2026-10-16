extends Node3D

@export var character: CharacterBody3D
@export var animation_player: AnimationPlayer

@export var idle_animation: StringName = &"Idle"
@export var walk_animation: StringName = &"Walk"
@export var run_animation: StringName = &"Sprint"
@export var jump_start_animation: StringName = &"Jump_Start"
@export var jump_animation: StringName = &"Jump"
@export var jump_land_animation: StringName = &"Jump_Land"
@export var run_threshold: float = 6.5
@export var walk_speed: float = 5.0
@export var run_speed: float = 8.0

var current_animation: StringName = &""
var jump_state: StringName = &""
var was_on_floor: bool = true
var is_landing: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if animation_player != null:
		animation_player.animation_finished.connect(
			_on_animation_finished
		)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if character == null or animation_player == null:
		return
	var on_floor := character.is_on_floor()
	var speed := Vector2(
		character.velocity.x,
		character.velocity.z
	).length()	

	
	
	var next_animation: StringName
	
	# Detect takeoff.
	if was_on_floor and not on_floor:
		jump_state = &"start"
		play_animation(jump_start_animation)

	var moving_forward := Input.is_key_pressed(KEY_W);
	var moving_left := Input.is_key_pressed(KEY_A);
	var moving_back := Input.is_key_pressed(KEY_S);
	var moving_right := Input.is_key_pressed(KEY_D);
	var running := Input.is_key_pressed(KEY_SHIFT);
	
	var just_landed := on_floor and not was_on_floor
	
	if just_landed:
		is_landing = true
		jump_state = &"land"

		if character != null and character.has_method("lock_for_landing"):
			character.lock_for_landing()
		play_animation(jump_land_animation)
		
	was_on_floor = on_floor
	
	if is_landing:
		return
	# Handle airborne animation.
	if not on_floor:
		if jump_state == &"":
			jump_state = &"start"
			play_animation(jump_start_animation)

		elif jump_state == &"land":
			jump_state = &"loop"
			play_animation(jump_animation)

	# Detect landing.
	
	
	# Normal ground movement.
	elif jump_state == &"":
		if speed < 0.1:
			play_animation(idle_animation)
		elif moving_forward or moving_back or moving_left or moving_right:
			if running:
				if current_animation !=  run_animation:
					play_animation(run_animation)
			else:
				if current_animation !=walk_animation:
					play_animation(walk_animation)
		else:
			play_animation(walk_animation)

func play_animation(animation_name: StringName) -> void:
	if current_animation == animation_name:
		return

	if not animation_player.has_animation(animation_name):
		push_warning(
			"Animation not found: " + str(animation_name)
		)
		return

	print("Playing animation: ", animation_name)
	animation_player.play(animation_name)
	current_animation = animation_name

func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name == jump_start_animation:
		if character != null and not character.is_on_floor():
			jump_state = &"jump"
			play_animation(jump_animation)
		elif character != null:
			jump_state = &"land"
			play_animation(jump_land_animation)

	elif animation_name == jump_animation:
		if character != null and not character.is_on_floor():
			# Repeat the airborne animation if it isn't set to loop.
			current_animation = &""
			play_animation(jump_animation)

	elif animation_name == jump_land_animation:
		jump_state = &""
		current_animation = &""
		is_landing = false
		
		if character != null:
			character.unlock_after_landing()
		
		resume_ground_animation()
		
func resume_ground_animation() -> void:
	if character == null:
		return

	var speed := Vector2(
		character.velocity.x,
		character.velocity.z
	).length()

	if speed < 0.1:
		play_animation(idle_animation)
	elif speed >= run_threshold:
		play_animation(run_animation)
	else:
		play_animation(walk_animation)
