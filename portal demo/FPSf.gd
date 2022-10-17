extends KinematicBody

export var speed = 7
const ACCEL_DEFAULT = 7
const ACCEL_AIR = 1

onready var accel = ACCEL_DEFAULT
export var gravity = 9.8
export var jump = 5
export var platform_jump_multiply = 15
export var cam_accel = 40
export var mouse_sense = 0.1
var snap

var direction = Vector3()
var velocity = Vector3()
var gravity_vec = Vector3()
var movement = Vector3()

onready var head = $Head
onready var camera = $Head/Camera
onready var w1 = $"../World1"
onready var w2 = $"../World2"
onready var tcam = $"../World1/Gate/Viewport/Cameras/TCAM"
onready var tcam2 = $"../World2/Gate/Viewport/Cameras/TCAM2"

func _ready():
	#hides the cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	#get mouse input for camera rotation
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * mouse_sense))
		head.rotate_x(deg2rad(-event.relative.y * mouse_sense))
		head.rotation.x = clamp(head.rotation.x, deg2rad(-89), deg2rad(89))
func _process(delta):
	#camera physics interpolation to reduce physics jitter on high refresh-rate monitors
	if Engine.get_frames_per_second() > Engine.iterations_per_second:
		camera.set_as_toplevel(true)
		camera.global_transform.origin = camera.global_transform.origin.linear_interpolate(head.global_transform.origin, 1)
		camera.rotation.y = rotation.y
		camera.rotation.x = head.rotation.x
		
	else:
		camera.set_as_toplevel(false)
		camera.global_transform = head.global_transform
		
	
	
		
func _physics_process(delta):
	#Magick
	#for cam one
	var playerOffset:Vector3 = translation + w2.translation
	tcam.translation = w1.translation + playerOffset + head.translation
	tcam.rotation_degrees = head.rotation_degrees + self.rotation_degrees
	#for cam two
	playerOffset = translation - w1.translation
	tcam2.translation = (w2.translation - playerOffset - head.translation) * -1
	tcam2.rotation_degrees = head.rotation_degrees + self.rotation_degrees
	
	#get keyboard input
	direction = Vector3.ZERO
	var h_rot = global_transform.basis.get_euler().y
	var f_input = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	var h_input = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	direction = Vector3(h_input, 0, f_input).rotated(Vector3.UP, h_rot).normalized()
	
	#jumping and gravity
	if is_on_floor():
		snap = -get_floor_normal()
		accel = ACCEL_DEFAULT
		gravity_vec = Vector3.ZERO
	else:
		snap = Vector3.DOWN
		accel = ACCEL_AIR
		gravity_vec += Vector3.DOWN * gravity * delta
		
	if Input.is_action_just_pressed("jump") and is_on_floor():
		snap = Vector3.ZERO
		gravity_vec = Vector3.UP * jump
	
	#make it move
	velocity = velocity.linear_interpolate(direction * speed, accel * delta)
	movement = velocity + gravity_vec
	
	move_and_slide_with_snap(movement, snap, Vector3.UP)
	
	
	




func _on_Area_body_entered(body):
	if is_on_floor():
		snap = -get_floor_normal()
		accel = ACCEL_DEFAULT
		gravity_vec = Vector3.ZERO
	elif is_on_floor() == false && body.is_in_group("player"):
		snap = Vector3.ZERO
		gravity_vec = (Vector3.UP + Vector3.BACK) * platform_jump_multiply
		move_and_slide_with_snap(movement, snap, Vector3.UP)

