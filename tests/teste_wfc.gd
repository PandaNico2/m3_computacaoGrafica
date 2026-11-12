# Teste sem interface: roda o WFC com várias seeds e mostra estatísticas.
# Uso (terminal): godot --headless --path . --script res://tests/teste_wfc.gd
extends SceneTree

const WFC = preload("res://scripts/wfc.gd")
const Tiles = preload("res://scripts/tiles.gd")

func _init() -> void:
	var linhas := Tiles.ler_exemplo("res://samples/exemplo_01.txt")
	var wfc := WFC.new()
	wfc.aprender_do_exemplo(linhas)
	print("Tiles diferentes no exemplo: ", wfc.simbolos.size(), " -> ", "".join(wfc.simbolos))

	var ok := 0
	var total_reinicios := 0
	var inicio := Time.get_ticks_msec()
	var N := 20
	for semente in range(1, N + 1):
		var status = WFC.Status.CONTRADICAO
		if wfc.iniciar(60, semente):
			for tentativa in 50:
				status = WFC.Status.RODANDO
				while status == WFC.Status.RODANDO:
					status = wfc.passo()
				if status == WFC.Status.CONCLUIDO:
					break
				wfc.reinicios += 1
				if not wfc.reiniciar():
					break
		if status == WFC.Status.CONCLUIDO:
			ok += 1
			total_reinicios += wfc.reinicios
			if semente <= 3:
				print("\n--- seed ", semente, " (reinicios: ", wfc.reinicios, ") ---")
				print(wfc.como_texto())
				var f := FileAccess.open("user://saida_seed_%d.txt" % semente, FileAccess.WRITE)
				f.store_string(wfc.como_texto())
	var ms := Time.get_ticks_msec() - inicio
	print("Sucesso: %d/%d | reinícios médios: %.2f | tempo médio: %.0f ms" % [ok, N, float(total_reinicios) / max(ok, 1), float(ms) / N])
	quit()
