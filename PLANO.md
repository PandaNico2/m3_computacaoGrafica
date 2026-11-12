# Trabalho M3 — WaveFunctionCollapse para fases de plataforma

**Disciplina:** Computação Gráfica — Tópicos Especiais (M3)
**Entrega e apresentação:** 03/12 · **Tempo disponível:** 1 semana
**Equipe:** Isadora M., Ismael, Guilherme Thomy, Vinicius Pereira

**Artigo:** Isaac Karth e Adam M. Smith. *WaveFunctionCollapse is Constraint Solving in the Wild.* FDG '17 (ACM), 2017. DOI: 10.1145/3102071.3110566 · [PDF](https://escholarship.org/content/qt1f29235t/qt1f29235t.pdf)

**Ideia:** implementar o WFC no Godot 4 para gerar fases de plataforma (estilo "Mario") a partir de uma fase de exemplo pequena, mostrando o colapso célula por célula ao vivo na apresentação.

---

## Requisitos do enunciado (checklist de entrega)

- [ ] Relatório com: nome do artigo · autores · área de aplicação · algoritmos utilizados · resumo · conclusões e observações
- [ ] Implementação de todo ou parte do artigo
- [ ] Seminário de **10 minutos** com demonstração do que foi desenvolvido

---

## Decisões técnicas

| Item | Decisão |
|---|---|
| Engine | **Godot 4.3 ou mais recente** (precisa do nó `TileMapLayer`) |
| Linguagem | GDScript |
| Tiles | [Kenney Pixel Platformer](https://kenney.nl/assets/pixel-platformer): 18×18, licença CC0 (crédito no relatório) |
| Modelo do WFC | Modelo de **tiles com regras aprendidas do exemplo**: o código lê a fase de exemplo e anota quais tiles aparecem vizinhos em cada direção e com que frequência. Ninguém escreve regras à mão e canos 2×2 funcionam sozinhos. |
| Tamanho da fase gerada | ~60 × 14 tiles (ajustável) |
| Restrições fixas | Linhas de cima = céu · coluna inicial e final = chão (início/fim da fase) |
| Contradição | Igual ao artigo: **reinicia do zero** (sem backtracking) e conta quantos reinícios ocorreram |
| Visual | Não usar sprites da Nintendo. Visual "inspirado em jogos de plataforma". |

---

## Estrutura do repositório

```
wfc-plataforma/
├── README.md               # como rodar + créditos
├── PLANO.md                # este arquivo
├── .gitignore              # ignorar .godot/
├── project.godot
├── assets/
│   └── kenney_pixel-platformer/
├── samples/
│   └── exemplo_01.tscn     # fase de exemplo pintada no TileMapLayer
├── scripts/
│   ├── wfc.gd              # algoritmo (sem nada de desenho)
│   ├── gerador.gd          # liga o WFC ao TileMapLayer + animação
│   ├── jogabilidade.gd     # (extra) BFS de alcance de pulo
│   └── player.gd           # (extra) personagem
├── shaders/
│   └── ceu.gdshader        # (extra) céu animado com TIME
├── scenes/
│   └── main.tscn
└── docs/
    ├── relatorio.md        # depois exportar para PDF/Word
    ├── slides/
    └── demo.mp4            # vídeo de segurança
```

---

## Divisão da equipe (sugestão)

| Papel | Responsável | Foco |
|---|---|---|
| **Dev 1 — Algoritmo** | _a definir_ | `wfc.gd`: regras, wave, observe, propagate |
| **Dev 2 — Godot/Visual** | _a definir_ | projeto, tiles, fase de exemplo, animação, extras |
| **Doc 1 — Relatório** | _a definir_ | os 6 itens do relatório |
| **Doc 2 — Apresentação** | _a definir_ | slides, roteiro, vídeo da demo |

> ⚠️ **Todos** precisam conseguir explicar o algoritmo (entropia → colapso → propagação). O professor costuma perguntar.

---

## Parte 0 — Preparação (Dia 1)

- [ ] Criar o repositório no GitHub e adicionar a equipe
- [ ] Todos instalarem o **Godot 4.3+** (godotengine.org, sem instalação)
- [ ] Baixar o Kenney Pixel Platformer e colocar em `assets/`
- [ ] Criar o projeto Godot e o `.gitignore` (`.godot/`)
- [ ] Todos lerem o artigo (seções 4 e 5 principalmente). É curto.

**Pronto quando:** o projeto abre no computador de todos.

---

## Parte 1 — Fase de exemplo (Dia 1)

- [ ] Criar um `TileSet` com o tilesheet do Kenney (tiles de 18×18)
- [ ] Escolher **~15 a 20 tiles**: céu, nuvem (2 partes), chão-topo, terra, bloco, bloco "?", moeda, plataforma (esquerda/meio/direita), cano 2×2 (4 partes), arbusto
- [ ] Pintar uma fase de exemplo de ~30 × 14 em `samples/exemplo_01.tscn`
- [ ] Incluir no exemplo: buracos de 1 a 3 tiles, canos, plataformas flutuantes, blocos

**Pronto quando:** a fase de exemplo está bonita e "jogável a olho".
**Dica:** o WFC só gera o que aparece no exemplo. Se quiser canos na saída, coloque canos no exemplo.

---

## Parte 2 — O algoritmo WFC (Dias 2–3) · `wfc.gd`

Seguir o pseudocódigo da seção 4 do artigo:

- [ ] **Extrair regras do exemplo:** para cada tile, anotar quais tiles aparecem à direita, esquerda, acima e abaixo, e a frequência de cada tile
- [ ] **Wave:** cada célula guarda o conjunto de tiles ainda possíveis (começa com todos)
- [ ] **Aplicar restrições fixas** (céu no topo, chão no início/fim) e propagar
- [ ] **Observe:** achar a célula com **menor entropia** (menos opções, com um pequeno ruído aleatório para desempatar) e sortear um tile **ponderado pela frequência**
- [ ] **Propagate:** pilha/fila a partir da célula colapsada, removendo das vizinhas os tiles que não têm suporte
- [ ] **Contradição:** se alguma célula ficar sem opções, reiniciar e contar o reinício
- [ ] **Seed:** usar `RandomNumberGenerator` com seed para poder repetir uma fase

**Pronto quando:** gera uma grade completa sem erros, e a mesma seed gera a mesma fase.

---

## Parte 3 — Visualização e demo (Dia 4) · `gerador.gd`

- [ ] Desenhar o resultado num `TileMapLayer`
- [ ] **Animação do colapso:** executar um passo (observe + propagate) por frame ou a cada X ms
- [ ] Células ainda não colapsadas aparecem como um quadrado com cor ou transparência proporcional à entropia, como na visualização do WFC original
- [ ] Teclas: **R** = nova fase · **Espaço** = pausar/continuar · **+/−** = velocidade · **I** = gerar instantâneo
- [ ] HUD: seed, número de reinícios, células restantes
- [ ] Câmera que rola para ver a fase inteira

**Pronto quando:** dá para apertar R e assistir à fase sendo construída.

---

## Parte 4 — Extras (Dia 5, só se a Parte 3 estiver pronta)

Na ordem de custo-benefício:

1. [ ] **Shader de céu** (`ceu.gdshader`, CanvasItem): gradiente + nuvens se movendo com `TIME`. Liga o trabalho ao conteúdo do M3. (~1 h)
2. [ ] **Personagem jogável:** `CharacterBody2D` com o template de movimento do próprio Godot + sprite do Kenney. Permite alguém da turma jogar a fase na apresentação. (~meio dia)
3. [ ] **Verificação de jogabilidade** (`jogabilidade.gd`): BFS sobre as posições onde dá para ficar em pé, com alcance máximo de pulo (ex.: 4 tiles na horizontal, 3 na vertical). Se o fim não for alcançável, gera de novo. É o "trabalho futuro" citado pelos autores (restrição global de alcance). (~meio dia)

---

## Parte 5 — Relatório (Dias 1–6, em paralelo) · `docs/relatorio.md`

| Seção | Conteúdo |
|---|---|
| 1. Nome do artigo | Título completo + evento + DOI |
| 2. Autores | Isaac Karth e Adam M. Smith (UC Santa Cruz) |
| 3. Área de implementação | Geração procedural de conteúdo gráfico para jogos; relação com síntese de texturas |
| 4. Algoritmos utilizados | Extração de padrões · wave/superposição · heurística de menor entropia (MRV) · propagação de restrições (consistência de arco, tipo AC-3) · reinício em contradição · comparação com ASP/backtracking feita pelos autores |
| 5. Resumo | O que é o WFC, origem (Maxim Gumin, 2016), a tese do artigo (WFC = resolução de restrições), experimentos (Platformer, Skyline, Flowers) |
| 6. Conclusões e observações | Conclusões dos autores + **nossa implementação**: decisões, prints, nº médio de reinícios, limitações (sem garantia de jogabilidade no WFC puro) e o que fizemos a respeito |
| Referências | Artigo, repositório do WFC original (github.com/mxgmn/WaveFunctionCollapse), Kenney (CC0), Godot |

**Pronto quando:** os 6 itens estão completos, com prints da demo, exportado em PDF.

---

## Parte 6 — Apresentação (Dias 5–6) · roteiro de 10 min

| Tempo | Conteúdo |
|---|---|
| 0:00–1:00 | Problema: criar fases à mão é caro → geração procedural |
| 1:00–2:00 | O artigo: autores, evento, tese principal |
| 2:00–5:00 | Como o WFC funciona (entrada → regras → entropia → colapso → propagação), com animação/diagrama |
| 5:00–8:30 | **Demo ao vivo:** fase de exemplo → apertar R → colapso animado → 2–3 seeds diferentes → (extra) alguém joga |
| 8:30–9:30 | Resultados, limitações, conclusões dos autores |
| 9:30–10:00 | Encerramento e perguntas |

---

## Parte 7 — Fechamento (Dia 7)

- [ ] **Gravar o vídeo da demo** (`docs/demo.mp4`) como plano B, caso o notebook falhe
- [ ] **Ensaio cronometrado** com os 4. Cada um apresenta uma parte.
- [ ] Revisão final do relatório (ortografia, nomes, referências)
- [ ] Testar a demo **no notebook que será usado na apresentação**
- [ ] Atualizar o README com instruções de execução e créditos
- [ ] Entregar

---

## Cronograma resumido

| Dia | Dev 1 | Dev 2 | Doc 1 | Doc 2 |
|---|---|---|---|---|
| 1 | Ler artigo | Setup + fase de exemplo | Ler artigo, itens 1–3 | Ler artigo |
| 2 | WFC: regras + wave | TileSet / ajudar Dev 1 | Item 4 (algoritmos) | Esqueleto dos slides |
| 3 | WFC: observe + propagate | Desenhar resultado no TileMap | Item 5 (resumo) | Diagramas do algoritmo |
| 4 | Testes / bugs | Animação + teclas + HUD | Prints da demo | Slides da teoria |
| 5 | Jogabilidade (extra) | Shader céu + personagem (extras) | Item 6 (conclusões) | Slides da demo |
| 6 | Correções | Gravar vídeo | Revisão + PDF | Roteiro final |
| 7 | **Ensaio geral + entrega** | | | |
