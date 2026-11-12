# WaveFunctionCollapse: fases de plataforma

Trabalho M3 de **Computação Gráfica (Tópicos Especiais)**.

Implementação do algoritmo **WaveFunctionCollapse (WFC)** no Godot 4 para gerar fases de jogo de plataforma a partir de uma fase de exemplo pequena.

**Artigo base:** Isaac Karth e Adam M. Smith. *WaveFunctionCollapse is Constraint Solving in the Wild.* Proceedings of the 12th International Conference on the Foundations of Digital Games (FDG '17), ACM, 2017. [DOI 10.1145/3102071.3110566](https://doi.org/10.1145/3102071.3110566)

**Equipe:** Isadora M., Ismael, Guilherme Thomy, Vinicius Pereira

## Como rodar
1. Instalar o **Godot 4.7** (godotengine.org, versão padrão, não a .NET).
2. Abrir o Godot → **Importar** → selecionar o `project.godot` desta pasta.
3. Apertar **F5** (Play).

## Controles
| Tecla | Ação |
|---|---|
| **R** | Gerar uma fase nova (seed aleatória) |
| **T** | Repetir a mesma seed |
| **Espaço** | Pausar / continuar a animação |
| **+ / -** | Mais rápido / mais devagar |
| **I** | Terminar instantaneamente |
| **E** | Mostrar a fase de **exemplo** (a entrada do algoritmo) |
| **Setas / A D** | Mover a câmera |
| **Roda do mouse** | Zoom |
| **F** | Enquadrar a fase inteira |

Na animação, as células escuras ainda não foram decididas. Quanto mais escura, mais opções a célula ainda tem (maior entropia). O contorno amarelo marca a última célula colapsada.

## Como funciona
1. **Aprender do exemplo** (`samples/exemplo_01.txt`): cada caractere é um tile. O código anota quais tiles aparecem vizinhos em cada direção e com que frequência.
2. **Onda:** cada célula da fase nova começa podendo ser qualquer tile.
3. **Observar:** escolhe a célula de **menor entropia** e sorteia um tile, ponderado pela frequência.
4. **Propagar:** remove das células vizinhas os tiles que ficaram incompatíveis (consistência de arco).
5. Repete até todas as células estarem decididas. Se alguma célula ficar sem opção (**contradição**), recomeça do zero, como no WFC original.

**Extensões nossas** (podem ser desligadas em `wfc.gd`):
- **Restrição de altura:** cada tile só aparece perto das linhas onde apareceu no exemplo.
- **Pesos por linha:** o sorteio usa a frequência do tile naquela altura.
- **Início e fim fixos:** as 3 primeiras e as 3 últimas colunas são copiadas do exemplo.

## Estrutura
```
scripts/wfc.gd            algoritmo WFC (sem nenhuma parte gráfica)
scripts/main.gd           animação, câmera, teclado e HUD
scripts/sobreposicao.gd   desenho das células ainda indefinidas
scripts/tiles.gd          símbolo do exemplo -> tile do Kenney
samples/exemplo_01.txt    fase de exemplo (entrada do algoritmo)
tests/teste_wfc.gd        teste sem interface com estatísticas
```

Para rodar o teste pelo terminal:
```
godot --headless --path . --script res://tests/teste_wfc.gd
```

## Editar a fase de exemplo
Abra `samples/exemplo_01.txt` num editor de texto. Todas as linhas precisam ter o mesmo tamanho.

| Símbolo | Tile | Símbolo | Tile |
|---|---|---|---|
| `.` | céu | `Y` | bloco amarelo |
| `[` `=` `]` | topo de grama (esq/meio/dir) | `!` | bloco de item |
| `(` `#` `)` | terra (esq/meio/dir) | `c` | moeda |
| `<` `-` `>` | plataforma flutuante | `T` `P` | cano (topo/corpo) |
| `{` `~` `}` | nuvem | `p` `m` | planta, cogumelo |

## Créditos
- Tiles: [Pixel Platformer](https://kenney.nl/assets/pixel-platformer) by **Kenney** (kenney.nl), licença CC0.
- WFC original: Maxim Gumin, https://github.com/mxgmn/WaveFunctionCollapse
- Engine: [Godot Engine](https://godotengine.org) (MIT).
