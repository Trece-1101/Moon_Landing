extends Node2D

###### DECLARACIONES ######

#### Componentes => para acceder directamente a propiedades de elementos de la jerarquia
onready var Apollo = get_node("Apollo")
onready var Camera = get_node("Camera2D")
onready var GUI = get_node("GUI")
onready var After_burner = get_node("Flame")
onready var Lateral_burner = get_node("LatFlame")
onready var Asteroid1 = get_node("Meteoros/Meteoro1")
onready var Asteroid2 = get_node("Meteoros/Meteoro2")
onready var Asteroid3 = get_node("Meteoros/Meteoro3")
onready var Asteroid4 = get_node("Meteoros/Meteoro4")
onready var Asteroid5 = get_node("Meteoros/Meteoro5")
onready var Asteroid6 = get_node("Meteoros/Meteoro6")
onready var Burner_sound = get_node("Audio/AudioBurner")
onready var Burner_lat_sound = get_node("Audio/AudioLatBurner")
onready var EndGameCanvas = get_node("EndCanvas/EndGame")
onready var StartGameCanvas = get_node("StartCanvas/StartGame")

#### Parametros => valores para manejar fisica y escalas
var gravity = Vector2(0, -1.6)
## Apollo
var apollo_aceleration = Vector2()
var apollo_position = Vector2()
var apollo_mass = 10000 # [kg]
var apollo_push = 2250
var apollo_fuel = 10000
var apollo_combustion = 0
var apollo_rate_combustion = 200 # [kg * N * sg] por cada newton de empuje por cada segundo quema este valor
export var apollo_velocity = Vector2() # para poder setear la posicion desde el inspector
export var initial_position = Vector2() # para poder setear la posicion desde el inspector

## Meteoritos / asteroides
var asteroids_velocity = [Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0)]
var asteroids_position = [Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0)]
var Asteroids = []

## Velocidad aterrizaje
# 2 m/s => aterrizaje suave
var soft_landing = 2 #[m/s]
# 5 m/s => aterrizaje duro
var hard_landing = 5 #[m/s]
# 8 m/s => golpe brusco
var brutal_landing = 8 #[m/s]
# 12 m/s => estrellado
var crash_landing = 12 #[m/s]

# Parametros de escala (real_size = tamaño fisico en metros) (screen_size = tamaño pantalla en pixeles)
var real_size = Vector2(500, 100) 
var screen_size = Vector2(1366, 750) # 1366 x 760
####

#### Manejo after burners => parametros de la imagen y valores de los quemadores de la nave
# 0 = 0N; 1 = 2250N; 2 = 4500N; 3 = 6750N; 4 = 9000N; 5 = 11250N
# 6 = 13500N; 7 = 15750N; 8 = 18000N; 9 = 20250N; 10 = 22500N
# 11 = 24750N; 12 = 27000N; 13 = 29250N; 14 = 31500N; 15 = 33750N
# 16 = 36000N; 17 = 38250N; 18 = 40500N; 19 = 42750N; 20 = 45000N
# => +2250N por cada nivel
var after_burner_level
var after_burner_newton = Vector2(0, 0)
var after_burner_aceleration = Vector2(0, 0)
var lateral_burner_level
var lateral_burner_aceleration = Vector2(0, 0)
var lateral_burner_newton = Vector2(0, 0)
var total_burner_aceleration = Vector2(0, 0)
# modificadores para el sprite del quemador
var after_burner_scale = Vector2(0.1, 0.1)
var after_burner_scale_modifier = Vector2(0.01, 0.02)
var after_burner_offset = 2

## Aux => valores auxiliares
var floor_position = 672.26
var apollo_floor
var iniciar = false
var distance_to_floor
var timer = 0
var last_velocity = Vector2()
var land = false
var sound_playing = false
var lat_sound_playing = false

############################

###### INICIALIZACION ######

func _ready():	
	#apollo_velocity = Vector2(30, -10) # Apollo incia en vel 0 y quemadores en 0
	EndGameCanvas.visible = false
	StartGameCanvas.visible = true
	GUI.visible = true
	after_burner_level = 0 # quemadores en 0
	lateral_burner_level = 0
	apollo_position = initial_position # le asignamos la posicion [m] a la inicial que pasamos desde el inspector
	Apollo.position = transform_to_real_coordinate(initial_position) # transformamos a coordenadas pixeles
		
	asteroids_position[0] = Vector2(20, 80)
	Asteroid1.position = transform_to_real_coordinate(asteroids_position[0])
	asteroids_velocity[0] = random_var_left_right(Vector2(60, 6))
	Asteroids.append(Asteroid1)
	asteroids_position[1] = Vector2(20, 70)
	Asteroid2.position = transform_to_real_coordinate(asteroids_position[1])
	asteroids_velocity[1] = random_var_left_right(Vector2(30, -4))
	Asteroids.append(Asteroid2)
	asteroids_position[2] = Vector2(510, 80)
	Asteroid3.position = transform_to_real_coordinate(asteroids_position[2])
	asteroids_velocity[2] = random_var_right_left(Vector2(-10, -2))
	Asteroids.append(Asteroid3)
	asteroids_position[3] = Vector2(510, 40)
	Asteroid4.position = transform_to_real_coordinate(asteroids_position[3])
	asteroids_velocity[3] = random_var_right_left(Vector2(-50, 15))
	Asteroids.append(Asteroid4)	
	asteroids_position[4] = Vector2(510, 0)
	Asteroid5.position = transform_to_real_coordinate(asteroids_position[4])
	asteroids_velocity[4] = random_var_right_left(Vector2(-50, 10))
	Asteroids.append(Asteroid5)	
	asteroids_position[5] = Vector2(-10, 0)
	Asteroid6.position = transform_to_real_coordinate(asteroids_position[5])
	asteroids_velocity[5] = random_var_right_left(Vector2(50, 10))
	Asteroids.append(Asteroid6)
	
	
	calculate_apollo_floor() # calculamos donde esta el piso del apollo para poder mostrar al usuario la distancia
	update_gui() # mostramos los datos iniciales al usuario
	
############################

###### CICLO DEL PROGRAMA ######

func _process(delta):
	if iniciar:
		StartGameCanvas.visible = false
		move_apollo(delta) # Funcion que mueve/detiene la nave
		move_asteroids(delta) # Funcion que mueve asteroides
		control_after_burner() # Funcion que controla los quemadores de la nave
		update_gui() # Funcion que controla la interfaz de usuario
		control_cam() # Funcion que controla la camara (zoom y posicion de la GUI)
		#check_colission()

################################

###### INPUT DE USUARIO ######

func _input(event):
	# el programa inicia al presionar la tecla enter
	if event.is_action_pressed("ui_accept"):
		iniciar = true
	
	# si presionamos cursor arriba (y el programa esta iniciado) suma un nivel al quemador y modifica la imagen
	if event.is_action_pressed("ui_up") and move_control() and after_burner_level < 20:
		after_burner_level += 1
		after_burner_scale += after_burner_scale_modifier
		After_burner.offset.y += after_burner_offset
	
	# si presionamos cursor abajo (y el programa esta iniciado) resta un nivel al quemador y modifica la imagen
	if event.is_action_pressed("ui_down") and move_control() and after_burner_level > 0:
		after_burner_level -= 1
		after_burner_scale -= after_burner_scale_modifier
		After_burner.offset.y -= after_burner_offset
	
	# si presionamos tecla derecha o izquierda movemos lateralmente la nave
	if event.is_action_pressed("ui_right") and move_control() and lateral_burner_level > -10:
		lateral_burner_level -= 1
	
	if event.is_action_pressed("ui_left") and move_control() and lateral_burner_level < 10:
		lateral_burner_level += 1
	
	# con la tecla espacio llevamos el quemador a su maximo valor (20) o lo apagamos(0)
	if event.is_action_pressed("ui_select") and move_control():
		if after_burner_level < 20:
			after_burner_level = 20
			after_burner_scale = Vector2(0.3, 0.5)
			After_burner.offset.y = 40
		else:
			after_burner_level = 0
			after_burner_scale = Vector2(0.1, 0.1)
	
	# con la tecla ESC reiniciamos el programa
	if event.is_action_pressed("ui_cancel"):
		get_tree().reload_current_scene()


func move_control():
	if iniciar and apollo_fuel > 0 and not land:
		return true
	else:
		return false
		
################################



###### FUNCIONES DEL PROGRAMA ######

#### CONTROL DE ESCALAS ####
func transform_to_real_coordinate(position):
	var real_coordinate = Vector2()
	real_coordinate.x = screen_size.x / real_size.x * position.x
	real_coordinate.y = screen_size.y - ((screen_size.y / real_size.y) * (position.y))
	real_coordinate.y -= (screen_size.y - floor_position + ((Apollo.texture.get_height() / 2) * Apollo.scale.y))
	return real_coordinate

func calculate_apollo_floor():
	apollo_floor = Apollo.position.y + ((Apollo.texture.get_height() / 2) * Apollo.scale.y)
	distance_to_floor = apollo_floor - floor_position
####

#### FISICA Y RENDER ####

func move_apollo(delta):
	# llamo a la funcion que calcula donde esta el piso del apollo en un momento dado
	calculate_apollo_floor()
	# si el suelo del apollo esta por encima (o es igual) al suelo lunar calculo las fisicas
	# si no (else) detengo la nave y marco el auxiliar "land" en true
	if(apollo_floor <= floor_position):
		# v0 = v0 + g*t
		#apollo_velocity = apollo_velocity + (gravity * delta)
		# y0 = y0 + v0*t + 1/2 g*t**2
		#apollo_position = apollo_position + (apollo_velocity * delta) + ((gravity * pow(delta, 2)) * 0.5)
		
		# aceleracion_resultante = empuje - gravedad
		apollo_aceleration = total_burner_aceleration + gravity # la gravedad es negativa por eso usa operador +
		#print("ap_acel", apollo_aceleration)
		# v0 = v0 + g*t
		apollo_velocity = apollo_velocity + (apollo_aceleration * delta)
		# y0 = y0 + v0*t + 1/2 g*t**2
		apollo_position = apollo_position + (apollo_velocity * delta) + ((apollo_aceleration * pow(delta, 2)) * 0.5)
		# transformo el valor de la posicion que esta en escala real a escala pixeles
		Apollo.position = transform_to_real_coordinate(apollo_position)
		
		# control del timer
		timer += delta
		# auxiliar para tener almacenada la ultima velocidad antes del aterrizaje
		last_velocity = apollo_velocity
		# control de combustible
		if apollo_fuel > 0:
			apollo_fuel -= apollo_combustion * delta
		else:
			apollo_fuel = 0
	else:
		land = true
		stop_apollo()
		land_control()

func move_asteroids(delta):
	for i in range(Asteroids.size()):
		asteroids_velocity[i] = asteroids_velocity[i] + (gravity * delta)
		asteroids_position[i] = asteroids_position[i] + (asteroids_velocity[i] * delta) + ((gravity * pow(delta, 2)) * 0.5)
		Asteroids[i].position = transform_to_real_coordinate(asteroids_position[i])
	

# Esta funcion detiene al apollo => fija su posicion en tierra, apaga los quemadores y lo detiene
func stop_apollo():
	Apollo.position = Apollo.position
	after_burner_level = 0
	lateral_burner_level = 0
	apollo_velocity = Vector2(0, 0)

# esta funcion controla el post aterrizaje y le muestra al usuario que tipo de
# aterrizaje tuvo (espera un segundo para hacerlo)
func land_control():
	yield(get_tree().create_timer(1.0), "timeout")
	
	EndGameCanvas.visible = true
	GUI.visible = false
	set_camera(Camera, GUI, Vector2(1, 1), 683, 380, 1200, 50, 1305)
	if abs(last_velocity.y) > crash_landing:
		#print("estrellado")
		EndGameCanvas.get_node("ColorRect/EstrelladaImg").visible = true
	elif abs(last_velocity.y) <= crash_landing and abs(last_velocity.y) > brutal_landing:
		#print("brusco")
		EndGameCanvas.get_node("ColorRect/BruscaImg").visible = true
	elif abs(last_velocity.y) <= brutal_landing and abs(last_velocity.y) > hard_landing:
		#print("duro")
		EndGameCanvas.get_node("ColorRect/DuroImg").visible = true
	elif abs(last_velocity.y) <= soft_landing:
		#print("suave")
		EndGameCanvas.get_node("ColorRect/SuaveImg").visible = true

# Esta funcion controla la posicion del sprite y sonido de los quemadores asi como su valor
# el cual depende del nivel (1 a 20) que posea en el momento dado
func control_after_burner():
	After_burner.position = Vector2(Apollo.position.x, apollo_floor - 5)	
	After_burner.scale = after_burner_scale
	if lateral_burner_level <= 0:
		Lateral_burner.position = Vector2(Apollo.position.x + 22, Apollo.position.y + 2)
		Lateral_burner.rotation_degrees = -90
	else:
		Lateral_burner.position = Vector2(Apollo.position.x - 22, Apollo.position.y + 2)
		Lateral_burner.rotation_degrees = 90
	
	if apollo_fuel > 0:
		after_burner_newton = Vector2(0, after_burner_level * apollo_push)
		lateral_burner_newton = Vector2(lateral_burner_level * apollo_push * 2, 0)
	else:
		after_burner_level = 0
		after_burner_newton = Vector2(0, 0)
		lateral_burner_level = 0
		lateral_burner_newton = Vector2(0, 0)

	# acel = F/m
	after_burner_aceleration = after_burner_newton / apollo_mass
	lateral_burner_aceleration = lateral_burner_newton / apollo_mass
	total_burner_aceleration = after_burner_aceleration + lateral_burner_aceleration
	apollo_combustion = apollo_rate_combustion * (total_burner_aceleration.x + total_burner_aceleration.y)
	#print(total_burner_aceleration.x + total_burner_aceleration.y)
	
	# si el nivel del quemador es 0 => invisible (apagado)
	# si es mayor que 0 => visible (prendido)
	if after_burner_level == 0:
		After_burner.visible = false
		sound_playing = false
		Burner_sound.stop()		
	elif after_burner_level > 0 and after_burner_level <= 20:
		After_burner.visible = true
		if sound_playing:
			Burner_sound.volume_db = after_burner_level * 0.2
		else:
			Burner_sound.play()
			Burner_sound.volume_db = 0.2
			sound_playing = true
		
		#print(Burner_sound.volume_db)
	
	if lateral_burner_level == 0:
		Lateral_burner.visible = false
		lat_sound_playing = false
		Burner_lat_sound.stop()
	else:
		Lateral_burner.visible = true
		if !lat_sound_playing:			
			Burner_lat_sound.play()
			Burner_lat_sound.volume_db = 0.5
			lat_sound_playing = true
		
####

#### CONTROL DE CAMARA E INTERFAZ DE USUARIO ####

# Funcion que controla la camara
func control_cam():
	# Apollo (683, 380) = camara offset (0, 0)
	var umbral_pequenio = 100 # valor en pixeles donde la camara modifica sus atributos
	var umbral_grande = 600
	if(abs(distance_to_floor) > umbral_grande) and !land:
		# angulo de vision amplio
		set_camera(Camera, GUI, Vector2(1.3, 1.3), 683, 380, 1400, 0, 1305)
	elif (abs(distance_to_floor) < umbral_pequenio) and !land:
		# angulo de vision achicado (mas zoom)
		set_camera(Camera, GUI, Vector2(0.5, 0.5), Apollo.position.x, floor_position, Apollo.position.x + 100, 500, Apollo.position.x + 200)
	elif (abs(distance_to_floor) < umbral_pequenio) and (abs(distance_to_floor) > umbral_grande) and !land:
		# angulo de vision original
		set_camera(Camera, GUI, Vector2(1, 1), 683, 380, 1200, 50, 1305)

func set_camera(camera, GUI, zoom, positionX, positionY, margin_left, margin_top, margin_right):
	camera.zoom = zoom
	camera.position.y = positionY
	camera.position.x = positionX
	GUI.margin_left = margin_left
	GUI.margin_top = margin_top
	GUI.margin_right = margin_right

# Funcion que controla los valores que muestra la interfaz de usuario
func update_gui():
	$GUI/VBoxContainer/LblFloorDistance.text = str(stepify(apollo_position.y, 0.1)) + " [m]"
	$GUI/VBoxContainer/LblTime.text = str(stepify(timer, 0.1)) + " [s]"
	$GUI/VBoxContainer/LblPush.text = str(after_burner_newton.x + after_burner_newton.y)  + " [N]"
	$GUI/VBoxContainer/LblVelXandY.text = str(stepify(apollo_velocity.x, 0.1)) + " [m/s] --  " + str(stepify(apollo_velocity.y, 0.1)) + " [m/s]"
	$GUI/VBoxContainer/LblFuel.text = str(stepify(apollo_fuel, 0.1)) + " [kg]"
	if not land:
		$GUI/VBoxContainer/LblVelocity.text = str(stepify(apollo_velocity.y, 0.1)) + " [m/s]"
	else:
		$GUI/VBoxContainer/LblVelocity.text = str(stepify(last_velocity.y, 0.1)) + " [m/s]"

# Funcion para randomizar valores de inicio de velocidad de los asteroides
func random_var_left_right(velocidad):
	var new_vel_x = velocidad.x + rand_range(40, 30)
	var new_vel_y = velocidad.y + rand_range(-2, 2)
	var new_vel = Vector2(new_vel_x, new_vel_y)
	return new_vel

func random_var_right_left(velocidad):
	var new_vel_x = velocidad.x + rand_range(-40, -30)
	var new_vel_y = velocidad.y + rand_range(-2, 2)
	var new_vel = Vector2(new_vel_x, new_vel_y)
	return new_vel
################################
