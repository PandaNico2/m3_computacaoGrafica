# Trabalho M3 — WaveFunctionCollapse para fases de plataforma

**Disciplina:** Computação Gráfica — Tópicos Especiais (M3)
**Entrega e apresentação:** 03/12 · **Tempo disponível:** 1 semana
**Última atualização:** 12/11. Partes 0 a 3 prontas; próximo passo: Parte 4 (extras) e Parte 5 (relatório).
**Equipe:** Isadora M., Ismael, Guilherme Thomy, Vinicius Pereira

**Artigo:** Isaac Karth e Adam M. Smith. *WaveFunctionCollapse is Constraint Solving in the Wild.* FDG '17 (ACM), 2017. DOI: 10.1145/3102071.3110566 · [PDF](https://escholarship.org/content/qt1f29235t/qt1f29235t.pdf)

**Ideia:** implementar o WFC no Godot 4 para gerar fases de plataforma (estilo "Mario") a partir de uma fase de exemplo pequena, mostrando o colapso célula por célula ao vivo na apresentação.

---

## Requisitos do enunciado (checklist de entrega)

- [ ] Relatório com: nome do artigo · autores · área de aplicação · algoritmos utilizados · resumo · conclusões e observações
- [x] Implementação de todo ou parte do artigo (WFC completo em `scripts/wfc.gd`)
- [ ] Seminário de **10 minutos** com demonstração do que foi desenvolvido

---

## Decisões técnicas

| Item | Decisão |
|---|---|
| Engine | **Godot 4.7.1** (todos da equipe na mesma versão) |
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
│   └── exemplo_01.txt      # fase de exemplo em texto (cada caractere = 1 tile)
├── scripts/
│   ├── wfc.gd              # algoritmo (sem nada de desenho)
│   ├── main.gd             # animação, teclas, câmera e HUD
│   ├── sobreposicao.gd     # desenho das células indefinidas
│   ├── tiles.gd            # símbolo -> tile do Kenney
│   ├── jogabilidade.gd     # (extra) BFS de alcance de pulo
│   └── player.gd           # (extra) personagem
├── shaders/
│   └── ceu.gdshader        # (extra) céu animado com TIME
├── scenes/
│   └── main.tscn
├── tests/
│   └── teste_wfc.gd        # teste sem interface com estatísticas
└── docs/
    ├── decisoes-relatorio.md  # decisões [D] e dificuldades [X] para o relatório
    ├── resumo-artigo.md       # resumo detalhado do artigo em português
    ├── relatorio.docx         # relatório final (modelo UNIVALI/ABNT)
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

- [x] Criar o repositório no GitHub
- [ ] Adicionar a equipe como colaboradores (Settings → Collaborators)
- [ ] Todos instalarem o **Godot 4.7.1** (Isadora ✔)
- [x] Baixar o Kenney Pixel Platformer e colocar em `assets/`
- [x] Criar o projeto Godot e o `.gitignore` (`.godot/`)
- [ ] Todos lerem o artigo, ou o resumo em português em `docs/resumo-artigo.md` (seções 4 e 5 principalmente)

**Pronto quando:** o projeto abre no computador de todos. (Abre no da Isadora ✔)

---

## Parte 1 — Fase de exemplo (Dia 1)

- [x] Criar um `TileSet` com o tilesheet do Kenney (tiles de 18×18). Feito em código, em `tiles.gd`
- [x] Escolher **~15 a 20 tiles** (usamos 20): céu, nuvem (2 partes), chão-topo, terra, bloco, bloco "?", moeda, plataforma (esquerda/meio/direita), cano 2×2 (4 partes), arbusto
- [x] Montar uma fase de exemplo de 40 × 14 em `samples/exemplo_01.txt` (em texto, em vez de pintada no editor)
- [x] Incluir no exemplo: buracos de 2 e 3 tiles, canos, plataformas flutuantes, blocos, moedas, nuvens, colina

**Pronto quando:** a fase de exemplo está bonita e "jogável a olho".
**Dica:** o WFC só gera o que aparece no exemplo. Se quiser canos na saída, coloque canos no exemplo.

---

## Parte 2 — O algoritmo WFC (Dias 2–3) · `wfc.gd`

Seguir o pseudocódigo da seção 4 do artigo:

- [x] **Extrair regras do exemplo:** para cada tile, anotar quais tiles aparecem à direita, esquerda, acima e abaixo, e a frequência de cada tile
- [x] **Wave:** cada célula guarda o conjunto de tiles ainda possíveis (começa com todos)
- [x] **Aplicar restrições fixas** (céu no topo, chão no início/fim) e propagar
- [x] **Observe:** achar a célula com **menor entropia** (menos opções, com um pequeno ruído aleatório para desempatar) e sortear um tile **ponderado pela frequência**
- [x] **Propagate:** pilha/fila a partir da célula colapsada, removendo das vizinhas os tiles que não têm suporte
- [x] **Contradição:** se alguma célula ficar sem opções, reiniciar e contar o reinício
- [x] **Seed:** usar `RandomNumberGenerator` com seed para poder repetir uma fase

**Pronto quando:** gera uma grade completa sem erros, e a mesma seed gera a mesma fase. ✔ Teste: 20/20 fases, 0 reinícios, ~0,3 s cada.

Extras já feitos: restrição de altura e pesos por linha (ver D13, D14 e X1, X2 em `docs/decisoes-relatorio.md`).

---

## Parte 3 — Visualização e demo (Dia 4) · `gerador.gd`

- [x] Desenhar o resultado num `TileMapLayer`
- [x] **Animação do colapso:** executar um passo (observe + propagate) por frame ou a cada X ms
- [x] Células ainda não colapsadas aparecem como um quadrado com cor ou transparência proporcional à entropia, como na visualização do WFC original
- [x] Teclas: **R** = nova fase · **Espaço** = pausar/continuar · **+/−** = velocidade · **I** = gerar instantâneo
- [x] HUD: seed, número de reinícios, células restantes
- [x] Câmera que rola para ver a fase inteira

**Pronto quando:** dá para apertar R e assistir à fase sendo construída. ✔ Também tem **T** (repetir seed), **E** (ver o exemplo) e **F** (enquadrar).

---

## Parte 4 — Extras (Dia 5, só se a Parte 3 estiver pronta)

Na ordem de custo-benefício:

1. [ ] **Shader de céu** (`ceu.gdshader`, CanvasItem): gradiente + nuvens se movendo com `TIME`. Liga o trabalho ao conteúdo do M3. (~1 h)
2. [ ] **Personagem jogável:** `CharacterBody2D` com o template de movimento do próprio Godot + sprite do Kenney. Permite alguém da turma jogar a fase na apresentação. (~meio dia)
3. [ ] **Verificação de jogabilidade** ⭐ prioridade: resolve a dificuldade X3 (`jogabilidade.gd`): BFS sobre as posições onde dá para ficar em pé, com alcance máximo de pulo (ex.: 4 tiles na horizontal, 3 na vertical). Se o fim não for alcançável, gera de novo. É o "trabalho futuro" citado pelos autores (restrição global de alcance). (~meio dia)

---

## Parte 5 — Relatório (Dias 1–6, em paralelo) · `docs/relatorio.docx`

**Modelo:** mesmo formato do relatório de Redes II da Isadora (UNIVALI, ABNT), numa versão mais enxuta (~12 a 15 páginas).

- [x] Resumo do artigo em português (`docs/resumo-artigo.md`)
- [x] Registro de decisões e dificuldades (`docs/decisoes-relatorio.md`)
- [ ] Rascunho do relatório no modelo
- [ ] Prints da demo (exemplo, colapso em andamento, fase pronta)
- [ ] Revisão final e exportação em PDF

| Seção do modelo | Conteúdo | Atende ao item do enunciado |
|---|---|---|
| Capa + Sumário | UNIVALI, curso, disciplina, equipe, professor, Itajaí 2026 | — |
| 1 Introdução | Geração procedural, objetivo do trabalho, organização do relatório | — |
| 2 O artigo | 2.1 Identificação (título, evento, DOI) · 2.2 Autores · 2.3 Área de aplicação · 2.4 Resumo | Nome, autores, área, resumo |
| 3 Algoritmos utilizados | Onda, entropia/MRV, sorteio ponderado, propagação (AC-3), reinício; tabela artigo → código | Algoritmos |
| 4 Ambiente e metodologia | Godot 4.7.1, tiles Kenney, fase de exemplo, testes; uso de IA generativa (Claude) | — |
| 5 Implementação e resultados | Modelo N = 1, extensões, visualização, prints, tabela de testes | Implementação |
| 6 Desafios encontrados | Quadro problema / diagnóstico / solução (X1 a X4) | Observações |
| 7 Considerações finais | Conclusões dos autores + nossas observações e limitações | Conclusões e observações |
| Referências + Apêndice | Artigo, WFC original, Kenney, Godot · Declaração de contribuição | — |

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
