# main.gd
# Cena principal: roda o WFC passo a passo e mostra o "colapso" acontecendo.
#
# Controles:
#   R            nova fase (seed aleatória)
#   T            repetir a mesma seed (mesma fase, animada de novo)
#   Espaço       pausar / continuar
#   + / -        mais rápido / mais devagar
#   I            terminar instantaneamente
#   E            mostrar / esconder a fase de EXEMPLO (entrada do algoritmo)
#   Setas / A D  mover a câmera      Roda do mouse   zoom      F   enquadrar tudo

extends Node2D

const WFC = preload("res://scripts/wfc.gd")
const Tiles = preload("res://scripts/tiles.gd")

@export var arquivo_exemplo := "res://samples/exemplo_01.txt"
@export var largura_fase := 48
@export var max_reinicios := 100

const VELOCIDADES := [5, 15, 40, 100, 300, 1000]  # passos do algoritmo por segundo

var wfc := WFC.new()
var semente := 0
var velocidade_idx := 2
var pausado := false
var mostrando_exemplo := false
var status := WFC.Status.RODANDO
var _acumulado := 0.0

@onready var camada_gerada: TileMapLayer = $FaseGerada
@onready var camada_exemplo: TileMapLayer = $FaseExemplo
@onready var sobreposicao: Node2D = $Sobreposicao
@onready var camera: Camera2D = $Camera2D
@onready var hud: Label = $HUD/Texto


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("a0d7f0"))  # azul do céu
	var tileset := Tiles.criar_tileset()
	camada_gerada.tile_set = tileset
	camada_exemplo.tile_set = tileset

	# 1) Aprende as regras a partir da fase de exemplo
	var linhas := Tiles.ler_exemplo(arquivo_exemplo)
	wfc.aprender_do_exemplo(linhas)

	# Desenha o exemplo (fica escondido até apertar E)
	for y in linhas.size():
		for x in linhas[y].length():
			Tiles.pintar(camada_exemplo, Vector2i(x, y), linhas[y][x])
	camada_exemplo.visible = false

	sobreposicao.wfc = wfc
	nova_fase(randi())


func nova_fase(nova_semente: int) -> void:
	semente = nova_semente
	if not wfc.iniciar(largura_fase, semente):
		push_error("As restrições iniciais são incompatíveis com o exemplo.")
	status = WFC.Status.RODANDO
	_acumulado = 0.0
	_redesenhar()
	enquadrar()


func _process(delta: float) -> void:
	if status == WFC.Status.RODANDO and not pausado:
		_acumulado += delta * VELOCIDADES[velocidade_idx]
		var passos := int(_acumulado)
		_acumulado -= passos
		for i in passos:
			_executar_passo()
			if status != WFC.Status.RODANDO:
				break
		if passos > 0:
			_redesenhar()
	_mover_camera(delta)
	_atualizar_hud()


# Executa um passo (Observe + Propagate). Em caso de contradição, faz como o
# WFC original: descarta tudo e recomeça do zero.
func _executar_passo() -> void:
	status = wfc.passo()
	if status == WFC.Status.CONTRADICAO:
		wfc.reinicios += 1
		if wfc.reinicios > max_reinicios:
			push_warning("Muitas contradições; desistindo desta seed.")
			return
		if wfc.reiniciar():
			status = WFC.Status.RODANDO


func terminar_instantaneamente() -> void:
	while status == WFC.Status.RODANDO:
		_executar_passo()
	_redesenhar()


func _redesenhar() -> void:
	for y in wfc.altura:
		for x in wfc.largura:
			Tiles.pintar(camada_gerada, Vector2i(x, y), wfc.simbolo_em(x, y))
	sobreposicao.queue_redraw()


# ---------------------------------------------------------------------------
# Entrada do usuário
# ---------------------------------------------------------------------------
func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventKey and evento.pressed and not evento.echo:
		match evento.keycode:
			KEY_R:
				nova_fase(randi())
			KEY_T:
				nova_fase(semente)
			KEY_SPACE:
				pausado = not pausado
			KEY_EQUAL, KEY_PLUS, KEY_KP_ADD:
				velocidade_idx = mini(velocidade_idx + 1, VELOCIDADES.size() - 1)
			KEY_MINUS, KEY_KP_SUBTRACT:
				velocidade_idx = maxi(velocidade_idx - 1, 0)
			KEY_I:
				terminar_instantaneamente()
			KEY_E:
				mostrando_exemplo = not mostrando_exemplo
				camada_exemplo.visible = mostrando_exemplo
				camada_gerada.visible = not mostrando_exemplo
				sobreposicao.visible = not mostrando_exemplo
				enquadrar()
			KEY_F:
				enquadrar()
	elif evento is InputEventMouseButton and evento.pressed:
		if evento.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom *= 1.1
		elif evento.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom /= 1.1


func _mover_camera(delta: float) -> void:
	var direcao := 0.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		direcao += 1.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		direcao -= 1.0
	camera.position.x += direcao * 600.0 * delta / camera.zoom.x


# Ajusta zoom e posição da câmera para mostrar a fase inteira na altura
func enquadrar() -> void:
	var colunas := wfc.exemplo[0].length() if mostrando_exemplo else wfc.largura
	var tamanho := Vector2(colunas, wfc.altura) * Vector2(Tiles.TAMANHO_TILE)
	var tela := get_viewport_rect().size
	var z := minf(tela.x / tamanho.x, (tela.y - 60.0) / tamanho.y)  # 60 px = HUD
	camera.zoom = Vector2(z, z)
	# Centraliza na horizontal e encosta o chão na parte de baixo da tela
	camera.position = Vector2(tamanho.x / 2.0, tamanho.y - tela.y / (2.0 * z))


func _atualizar_hud() -> void:
	var estado := "concluída ✔" if status == WFC.Status.CONCLUIDO else ("PAUSADO" if pausado else "gerando...")
	if status == WFC.Status.CONTRADICAO:
		estado = "falhou (muitas contradições)"
	if mostrando_exemplo:
		estado = "mostrando o EXEMPLO (entrada)"
	hud.text = "WaveFunctionCollapse  |  seed: %d  |  reinícios: %d  |  células indefinidas: %d/%d  |  %d passos/s  |  %s\n[R] nova  [T] repetir seed  [Espaço] pausar  [+/-] velocidade  [I] instantâneo  [E] exemplo  [Setas] câmera  [F] enquadrar" % [
		semente, wfc.reinicios, wfc.celulas_restantes(), wfc.largura * wfc.altura,
		VELOCIDADES[velocidade_idx], estado]
