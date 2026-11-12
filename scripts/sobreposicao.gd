# sobreposicao.gd
# Desenha por cima da fase as células que ainda NÃO colapsaram.
# Quanto mais opções uma célula ainda tem (maior entropia), mais escura ela fica.
# A última célula colapsada ganha um contorno amarelo.

extends Node2D

const Tiles = preload("res://scripts/tiles.gd")

var wfc  # referência ao objeto WFC (definida pelo main.gd)


func _draw() -> void:
	if wfc == null or wfc.onda.is_empty():
		return
	var t := Vector2(Tiles.TAMANHO_TILE)
	var total := float(wfc.simbolos.size())
	for y in wfc.altura:
		for x in wfc.largura:
			if wfc.colapsada(x, y):
				continue
			var n: int = wfc.num_opcoes(x, y)
			# n/total perto de 1 = quase tudo possível (escuro); perto de 0 = quase decidido (claro)
			var f := clampf(float(n) / total, 0.0, 1.0)
			var cor := Color(0.12, 0.16, 0.28, 0.35 + 0.55 * f)
			draw_rect(Rect2(Vector2(x, y) * t, t), cor)
			draw_rect(Rect2(Vector2(x, y) * t, t), Color(1, 1, 1, 0.08), false, 1.0)

	if wfc.ultima_celula >= 0 and wfc.celulas_restantes() > 0:
		var c: int = wfc.ultima_celula
		var pos := Vector2(c % wfc.largura, c / wfc.largura) * t
		draw_rect(Rect2(pos, t), Color(1.0, 0.85, 0.1), false, 2.0)
