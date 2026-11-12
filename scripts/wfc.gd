# wfc.gd
# Implementação do WaveFunctionCollapse (WFC), seguindo o pseudocódigo de:
#   Karth, I. e Smith, A. M. "WaveFunctionCollapse is Constraint Solving in the Wild".
#   FDG '17, ACM, 2017. https://doi.org/10.1145/3102071.3110566
#
# Variante usada: modelo de TILES com regras APRENDIDAS do exemplo.
#   - Cada tile do exemplo é um "padrão" (equivale a N = 1 no artigo).
#   - As regras de vizinhança são lidas do exemplo: se o tile A aparece à
#     esquerda do tile B no exemplo, então A pode ficar à esquerda de B na saída.
#   - A frequência de cada tile no exemplo vira o peso do sorteio.
#
# Vocabulário do artigo -> nome neste código:
#   PatternsFromSample  -> aprender_do_exemplo()  (tiles + frequências)
#   BuildPropagator     -> aprender_do_exemplo()  (tabela "compativel")
#   Wave                -> onda                   (opções ainda possíveis em cada célula)
#   Observe             -> _observar()            (célula de menor entropia + sorteio)
#   Propagate           -> _propagar()            (remove opções incompatíveis das vizinhas)
#   Contradição         -> status CONTRADICAO     (o WFC original reinicia do zero)
#
# Truque de eficiência: o conjunto de opções de cada célula é guardado como um
# número inteiro em que cada bit representa um tile (bit t = 1 -> tile t ainda é
# possível). Assim, "interseção de conjuntos" vira um simples AND (&).
# Limite: até 62 tiles diferentes.

extends RefCounted

enum Status { RODANDO, CONCLUIDO, CONTRADICAO }

# Direções: 0 = direita, 1 = esquerda, 2 = baixo, 3 = cima
const DIRECOES := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const OPOSTA := [1, 0, 3, 2]

# --- Dados aprendidos do exemplo -------------------------------------------
var simbolos: Array[String] = []   # índice -> símbolo do tile
var pesos: PackedFloat64Array      # índice -> frequência no exemplo
var compativel: Array = []         # compativel[d][t] = máscara dos tiles permitidos na direção d de t
var linhas_permitidas: PackedInt64Array  # linhas_permitidas[y] = máscara dos tiles que podem aparecer na linha y
var borda_cima := 0                # tiles vistos na linha de cima do exemplo
var borda_baixo := 0               # tiles vistos na linha de baixo do exemplo
var exemplo: PackedStringArray
var pesos_linha: Array = []        # pesos_linha[y][t] = frequência do tile t perto da linha y

# --- Estado da geração -------------------------------------------------------
var largura := 0
var altura := 0
var onda: PackedInt64Array          # opções possíveis em cada célula (máscara de bits)
var rng := RandomNumberGenerator.new()
var reinicios := 0                  # quantas contradições aconteceram
var ultima_celula := -1             # última célula colapsada (para destacar na tela)
var colunas_fixas := 3              # nº de colunas do início/fim copiadas do exemplo

# Extensão opcional: só permite cada tile perto das alturas em que ele apareceu
# no exemplo (evita torres de terra até o céu). Tolerância em linhas.
var usar_restricao_de_linha := true
var tolerancia_linha := 1
# Extensão opcional: o sorteio usa a frequência do tile NAQUELA ALTURA do
# exemplo, e não a frequência global. Sem isso o céu (tile mais comum) "ganha"
# o sorteio até nas linhas do chão e a fase fica cheia de buracos.
var usar_pesos_por_linha := true

var _cheia := 0                     # máscara com todos os tiles


# ============================================================================
# 1) APRENDER DO EXEMPLO  (PatternsFromSample + BuildPropagator)
# ============================================================================
func aprender_do_exemplo(linhas: PackedStringArray) -> void:
	exemplo = linhas
	simbolos.clear()
	var indice := {}        # símbolo -> índice
	var contagem := []

	# Descobre os tiles diferentes e conta a frequência de cada um
	for linha in linhas:
		for ch in linha:
			if not indice.has(ch):
				indice[ch] = simbolos.size()
				simbolos.append(ch)
				contagem.append(0)
			contagem[indice[ch]] += 1
	assert(simbolos.size() <= 62, "O WFC desta versão suporta no máximo 62 tiles diferentes.")

	var n := simbolos.size()
	pesos = PackedFloat64Array()
	for c in contagem:
		pesos.append(float(c))
	_cheia = (1 << n) - 1

	# Tabela de compatibilidade, inicialmente vazia
	compativel.clear()
	for d in 4:
		var por_tile := PackedInt64Array()
		por_tile.resize(n)
		compativel.append(por_tile)

	# Para cada par de vizinhos no exemplo, registra que a combinação é válida
	var h := linhas.size()
	var w := linhas[0].length()
	linhas_permitidas = PackedInt64Array()
	linhas_permitidas.resize(h)
	for y in h:
		for x in w:
			var a: int = indice[linhas[y][x]]
			linhas_permitidas[y] |= 1 << a
			for d in 4:
				var viz: Vector2i = Vector2i(x, y) + DIRECOES[d]
				if viz.x < 0 or viz.y < 0 or viz.x >= w or viz.y >= h:
					continue
				var b: int = indice[linhas[viz.y][viz.x]]
				compativel[d][a] |= 1 << b

	# Frequência de cada tile em cada linha do exemplo (com a mesma tolerância)
	var por_linha := []
	for y in h:
		var cont := PackedFloat64Array()
		cont.resize(n)
		for x in w:
			cont[indice[linhas[y][x]]] += 1.0
		por_linha.append(cont)
	pesos_linha.clear()
	for y in h:
		var p := PackedFloat64Array()
		p.resize(n)
		for t in n:
			var soma := 0.0
			for dy in range(-tolerancia_linha, tolerancia_linha + 1):
				soma += por_linha[clampi(y + dy, 0, h - 1)][t]
			p[t] = soma + 0.1   # +0.1 para nenhum peso ser zero
		pesos_linha.append(p)

	# Tiles que aparecem nas bordas de cima e de baixo do exemplo
	borda_cima = 0
	borda_baixo = 0
	for x in w:
		borda_cima |= 1 << indice[linhas[0][x]]
		borda_baixo |= 1 << indice[linhas[h - 1][x]]


# ============================================================================
# 2) PREPARAR UMA NOVA GERAÇÃO
# ============================================================================
func iniciar(nova_largura: int, semente: int) -> bool:
	largura = nova_largura
	altura = exemplo.size()
	rng.seed = semente
	reinicios = 0
	return reiniciar()


# Volta a onda ao estado inicial ("tudo é possível") e aplica as restrições
# fixas. Chamado no início e depois de cada contradição.
func reiniciar() -> bool:
	onda = PackedInt64Array()
	onda.resize(largura * altura)
	onda.fill(_cheia)
	ultima_celula = -1

	var alteradas: Array[int] = []

	# Restrição de altura (extensão): tile só perto das linhas onde apareceu
	if usar_restricao_de_linha:
		for y in altura:
			var mascara := 0
			for dy in range(-tolerancia_linha, tolerancia_linha + 1):
				var yy := clampi(y + dy, 0, altura - 1)
				mascara |= linhas_permitidas[yy]
			for x in largura:
				_restringir(x, y, mascara, alteradas)

	# Bordas de cima e de baixo: só tiles que apareceram nessas bordas no exemplo
	for x in largura:
		_restringir(x, 0, borda_cima, alteradas)
		_restringir(x, altura - 1, borda_baixo, alteradas)

	# Início e fim da fase: copia as primeiras/últimas colunas do exemplo,
	# garantindo um ponto de partida e de chegada seguros.
	var w_ex := exemplo[0].length()
	for i in colunas_fixas:
		for y in altura:
			_restringir(i, y, 1 << simbolos.find(exemplo[y][i]), alteradas)
			var x_fim := largura - colunas_fixas + i
			var x_ex := w_ex - colunas_fixas + i
			_restringir(x_fim, y, 1 << simbolos.find(exemplo[y][x_ex]), alteradas)

	for c in alteradas:
		if onda[c] == 0:
			return false
	return _propagar(alteradas)


func _restringir(x: int, y: int, mascara: int, alteradas: Array[int]) -> void:
	var c := y * largura + x
	var nova := onda[c] & mascara
	if nova != onda[c]:
		onda[c] = nova
		alteradas.append(c)


# ============================================================================
# 3) UM PASSO DO ALGORITMO: Observe + Propagate
# ============================================================================
func passo() -> Status:
	var c := _observar()
	if c == -1:
		return Status.CONCLUIDO     # todas as células têm exatamente 1 opção
	if c == -2:
		return Status.CONTRADICAO   # alguma célula ficou sem opções
	ultima_celula = c
	if not _propagar([c]):
		return Status.CONTRADICAO
	return Status.RODANDO


# Observe: escolhe a célula com MENOR ENTROPIA (a mais "decidida") e colapsa
# ela para um único tile, sorteado com peso proporcional à frequência.
# Retorna o índice da célula, -1 se tudo já colapsou, -2 se há contradição.
func _observar() -> int:
	var melhor := -1
	var menor := INF
	for c in onda.size():
		var m := onda[c]
		if m == 0:
			return -2
		if (m & (m - 1)) == 0:
			continue  # só 1 bit ligado = célula já colapsada
		# Pequeno ruído aleatório para desempatar células com a mesma entropia
		var e := entropia(m, _pesos_da_celula(c)) + rng.randf() * 1e-6
		if e < menor:
			menor = e
			melhor = c
	if melhor == -1:
		return -1

	# Sorteio ponderado entre os tiles ainda possíveis
	var m := onda[melhor]
	var w_cel := _pesos_da_celula(melhor)
	var total := 0.0
	for t in simbolos.size():
		if m & (1 << t):
			total += w_cel[t]
	var r := rng.randf() * total
	var escolhido := -1
	for t in simbolos.size():
		if m & (1 << t):
			escolhido = t
			r -= w_cel[t]
			if r <= 0.0:
				break
	onda[melhor] = 1 << escolhido
	return melhor


# Entropia de Shannon das opções de uma célula, ponderada pelas frequências:
#   H = log(soma w) - (soma w*log w) / (soma w)
func entropia(mascara: int, w_cel: PackedFloat64Array) -> float:
	var soma := 0.0
	var soma_wlogw := 0.0
	for t in simbolos.size():
		if mascara & (1 << t):
			var w := w_cel[t]
			soma += w
			soma_wlogw += w * log(w)
	return log(soma) - soma_wlogw / soma


func _pesos_da_celula(c: int) -> PackedFloat64Array:
	if usar_pesos_por_linha:
		return pesos_linha[c / largura]
	return pesos


# Propagate: a partir das células alteradas, remove das vizinhas os tiles que
# não são compatíveis com NENHUMA opção restante da célula alterada.
# É a "consistência de arco" (parecido com o AC-3) citada no artigo.
func _propagar(inicio: Array) -> bool:
	var pilha: Array[int] = []
	pilha.assign(inicio)
	while not pilha.is_empty():
		var c: int = pilha.pop_back()
		var x := c % largura
		var y := c / largura
		var m := onda[c]
		for d in 4:
			var nx: int = x + DIRECOES[d].x
			var ny: int = y + DIRECOES[d].y
			if nx < 0 or ny < 0 or nx >= largura or ny >= altura:
				continue
			# União de tudo que as opções de "c" permitem na direção d
			var permitido := 0
			for t in simbolos.size():
				if m & (1 << t):
					permitido |= compativel[d][t]
			var v := ny * largura + nx
			var nova := onda[v] & permitido
			if nova != onda[v]:
				onda[v] = nova
				if nova == 0:
					return false   # contradição
				pilha.append(v)
	return true


# ============================================================================
# 4) CONSULTAS (usadas pela visualização)
# ============================================================================
func colapsada(x: int, y: int) -> bool:
	var m := onda[y * largura + x]
	return m != 0 and (m & (m - 1)) == 0

func simbolo_em(x: int, y: int) -> String:
	var m := onda[y * largura + x]
	for t in simbolos.size():
		if m == (1 << t):
			return simbolos[t]
	return ""

func num_opcoes(x: int, y: int) -> int:
	var m := onda[y * largura + x]
	var n := 0
	while m:
		m &= m - 1
		n += 1
	return n

func celulas_restantes() -> int:
	var n := 0
	for m in onda:
		if m != 0 and (m & (m - 1)) != 0:
			n += 1
	return n

# Resultado em texto (útil para testes e para o relatório)
func como_texto() -> String:
	var s := ""
	for y in altura:
		for x in largura:
			var simb := simbolo_em(x, y)
			s += simb if simb != "" else "?"
		s += "\n"
	return s
