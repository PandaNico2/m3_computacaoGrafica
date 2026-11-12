# tiles.gd
# Catálogo de tiles: liga cada símbolo do arquivo de exemplo (.txt) a um tile
# do tilesheet do Kenney (Pixel Platformer, licença CC0).
#
# O tilesheet "tilemap_packed.png" tem 20 x 9 tiles de 18 x 18 px, sem espaço
# entre eles. Vector2i(coluna, linha) é a posição do tile nessa grade.

extends RefCounted

const TAMANHO_TILE := Vector2i(18, 18)
const CAMINHO_TEXTURA := "res://assets/kenney_pixel-platformer/Tilemap/tilemap_packed.png"

# "." é o céu (célula vazia), por isso não aparece aqui.
const ATLAS := {
	# Chão
	"[": Vector2i(1, 1),  # topo de grama - borda esquerda
	"=": Vector2i(2, 1),  # topo de grama - meio
	"]": Vector2i(3, 1),  # topo de grama - borda direita
	"(": Vector2i(1, 6),  # terra - parede esquerda
	"#": Vector2i(2, 6),  # terra - preenchimento
	")": Vector2i(3, 6),  # terra - parede direita
	# Plataforma flutuante
	"<": Vector2i(1, 0),
	"-": Vector2i(2, 0),
	">": Vector2i(3, 0),
	# Blocos e itens
	"Y": Vector2i(9, 0),   # bloco amarelo
	"!": Vector2i(10, 0),  # bloco de item
	"c": Vector2i(11, 7),  # moeda
	# Cano
	"T": Vector2i(15, 4),  # topo do cano
	"P": Vector2i(15, 5),  # corpo do cano
	# Nuvem
	"{": Vector2i(13, 7),
	"~": Vector2i(14, 7),
	"}": Vector2i(15, 7),
	# Decoração
	"p": Vector2i(4, 6),   # planta
	"m": Vector2i(8, 6),   # cogumelo
}

const CEU := "."

# Monta o TileSet em código (não precisa configurar nada no editor).
static func criar_tileset() -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = TAMANHO_TILE

	var fonte := TileSetAtlasSource.new()
	fonte.texture = load(CAMINHO_TEXTURA)
	fonte.texture_region_size = TAMANHO_TILE
	for simbolo in ATLAS:
		var coord: Vector2i = ATLAS[simbolo]
		if not fonte.has_tile(coord):
			fonte.create_tile(coord)

	tileset.add_source(fonte, 0)
	return tileset

# Desenha um símbolo numa célula de um TileMapLayer.
static func pintar(camada: TileMapLayer, celula: Vector2i, simbolo: String) -> void:
	if ATLAS.has(simbolo):
		camada.set_cell(celula, 0, ATLAS[simbolo])
	else:
		camada.erase_cell(celula)  # céu ou célula ainda indefinida

# Lê o arquivo de exemplo e devolve as linhas (ignora linhas vazias).
static func ler_exemplo(caminho: String) -> PackedStringArray:
	var texto := FileAccess.get_file_as_string(caminho)
	var linhas := PackedStringArray()
	for linha in texto.split("\n"):
		linha = linha.strip_edges()
		if linha != "":
			linhas.append(linha)
	return linhas
