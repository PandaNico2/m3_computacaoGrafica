# Decisões e dificuldades do projeto (material para o relatório)

Registro das decisões tomadas durante o desenvolvimento e das dificuldades encontradas, para usar nas seções **"Algoritmos utilizados"** e **"Conclusões e observações"** do relatório.

Legenda: **[D]** = decisão · **[X]** = dificuldade / problema encontrado

---

## 1. Escolha do artigo e do tema

**[D1] Artigo escolhido:** Karth e Smith, *WaveFunctionCollapse is Constraint Solving in the Wild*, FDG 2017.
- Critérios: publicado nos últimos 10 anos (2017); algoritmo central pode ser implementado **por completo** em pouco tempo; gera uma demo visual e interativa para os 10 minutos de seminário.
- Alternativas consideradas e descartadas por prazo ou risco:
  - *3D Gaussian Splatting* (SIGGRAPH 2023): treino exige GPU NVIDIA, risco alto.
  - *Water Surface Wavelets* (SIGGRAPH 2018): matemática pesada para 1 semana.
  - *Monte Carlo Geometry Processing* (SIGGRAPH 2020).
  - *Small Steps in Physics Simulation* (SCA 2019).
- O *XPBD* (MIG 2016) foi descartado porque, em novembro de 2026, já passa do limite de 10 anos.

**[D2] Tipo de conteúdo gerado: fases de plataforma** (visão lateral, estilo "Mario").
- Um **estádio** foi descartado: o WFC trabalha com padrões **locais** e não garante uma forma **global** (gramado no centro, arquibancada em volta, simetria).
- Um **mapa visto de cima** (estilo Zelda) seria um pouco mais simples de tornar jogável, mas o próprio artigo testa um cenário *Platformer*, o que liga diretamente nossa implementação aos experimentos dos autores.

**[D3] Visual próprio, sem sprites da Nintendo.** Tiles do pacote *Pixel Platformer* (Kenney, licença CC0, 18×18 px). O jogo é apenas "inspirado em jogos de plataforma".

## 2. Tecnologia

**[D4] Godot 4.7.1 + GDScript.** É a engine usada nas aulas de shaders do M3, gratuita e sem instalação. A equipe já tinha usado.

**[D5] Renderizador "GL Compatibility"** (OpenGL 3.3) em vez de Forward+ (Vulkan). Como o projeto é 2D, não perde nada, e roda em qualquer notebook, inclusive Macs e máquinas sem suporte a Vulkan.

**[D6] O TileSet é montado em código** (`tiles.gd`), e não configurado à mão no editor. Isso evita arquivos de recurso difíceis de revisar no Git e deixa explícito, no código, qual símbolo corresponde a qual tile.

## 3. O algoritmo (seção "Algoritmos utilizados")

**[D7] Modelo de tiles com regras aprendidas do exemplo** (equivale ao padrão N = 1 do artigo).
- Cada tile do exemplo é um padrão. As regras de vizinhança (quem pode ficar à direita, esquerda, acima e abaixo de quem) e as frequências são **lidas do exemplo**. Ninguém escreve regras à mão.
- O artigo usa o modelo *overlapping* com N = 3. Escolhemos N = 1 porque:
  - é mais simples de implementar e de explicar;
  - peças de vários tiles (cano, nuvem, plataforma) funcionam sozinhas, já que o topo do cano só aparece em cima do corpo do cano;
  - gera menos padrões e, portanto, menos contradições.
- **Custo da escolha:** o N = 1 "enxerga" só os vizinhos imediatos, então capta menos estrutura de larga escala. Isso causou os problemas X1 e X2, resolvidos com as extensões D12 e D13.

**[D8] Fase de exemplo escrita em texto (ASCII)** (`samples/exemplo_01.txt`, 40 × 14), em vez de pintada no editor. É fácil de editar, de versionar no Git e de usar nos testes automáticos.

**[D9] Representação da "onda" com bits.** O conjunto de tiles possíveis de cada célula é guardado como um inteiro de 64 bits (bit t = 1 significa que o tile t ainda é possível). A interseção de conjuntos na propagação vira uma operação AND. Limite: 62 tiles diferentes (usamos 20).

**[D10] Mapeamento direto do pseudocódigo do artigo:**

| Artigo | Nosso código (`wfc.gd`) |
|---|---|
| PatternsFromSample / BuildPropagator | `aprender_do_exemplo()` |
| Wave | `onda` |
| Observe (menor entropia + sorteio ponderado) | `_observar()` + `entropia()` |
| Propagate (consistência de arco, tipo AC-3) | `_propagar()` |
| Contradição → reinício global | `Status.CONTRADICAO` + `reiniciar()` |

- Entropia de Shannon ponderada: `H = log(Σw) − Σ(w·log w) / Σw`, mais um ruído aleatório minúsculo para desempatar.

**[D11] Contradição tratada como no WFC original: reinício do zero, sem backtracking.** Mantém a fidelidade ao algoritmo estudado. Limite de 100 reinícios por seed. O artigo mostra que backtracking ajuda em restrições globais, o que fica como possível melhoria.

**[D12] Restrições fixas antes de começar:**
- **Bordas aprendidas:** a linha de cima só aceita tiles que apareceram na linha de cima do exemplo (só céu), e o mesmo vale para a linha de baixo.
- **Início e fim fixos:** as 3 primeiras e as 3 últimas colunas são copiadas do exemplo, garantindo chão no começo e no fim da fase.

## 4. Extensões nossas ao WFC

**[D13] Restrição de altura:** cada tile só pode aparecer em linhas próximas (±1) das linhas em que apareceu no exemplo. Resolve X2.

**[D14] Pesos por linha:** o sorteio do Observe usa a frequência do tile **naquela altura** do exemplo, e não a frequência global. Resolve X1.

## 5. Visualização (demo)

**[D15] Animação passo a passo:** cada passo é um Observe + Propagate. A velocidade é ajustável (5 a 1000 passos/s) e pode ser pausada.

**[D16] Células indefinidas aparecem escuras,** e quanto mais opções restam (maior entropia), mais escuras ficam. É inspirado na visualização do WFC original, que mostra cada célula como a média das cores dos padrões possíveis. Um contorno amarelo marca a última célula colapsada, e a tecla **E** mostra a fase de exemplo (a entrada do algoritmo).

## 6. Testes e números

**[D17] Teste automático sem interface** (`tests/teste_wfc.gd`): gera 20 fases (seeds 1 a 20, 60 × 14 células) e mede a taxa de sucesso, os reinícios e o tempo.

| Versão | Sucesso | Reinícios médios | Tempo médio por fase |
|---|---|---|---|
| WFC + restrições (D12, D13) | 20/20 | 0,00 | ~273 ms |
| + pesos por linha (D14) | 20/20 | 0,00 | ~270–280 ms |

(Godot 4.7.1, modo headless, num computador de testes. Os números podem variar no notebook da apresentação.)

---

## Dificuldades encontradas

**[X1] Fases cheias de buracos (céu demais).**
- **Sintoma:** na primeira versão, as fases geradas tinham buracos enormes e pouco chão.
- **Causa:** no exemplo, o céu (`.`) ocupa **66,6% das células** (373 de 560). Com a frequência global como peso, o céu "ganhava" o sorteio até nas linhas do chão, embora na linha de baixo do exemplo só 5 de 40 células sejam céu.
- **Solução:** pesos por linha (D14). As fases passaram a ter chão contínuo com degraus, parecidas com o exemplo.

**[X2] Estruturas em alturas sem sentido.**
- **Causa:** com N = 1, o algoritmo não sabe em que altura está, então um topo de grama poderia surgir em qualquer linha, criando torres de terra até o céu.
- **Solução:** restrição de altura aprendida do exemplo (D13).

**[X3] Fases que não dá para terminar (pendente).**
- Mesmo com as extensões, algumas seeds geram um buraco largo demais para pular (ex.: seed 3).
- É exatamente a limitação apontada pelos autores: o WFC só garante restrições **locais**, e "ser possível chegar ao fim" é uma restrição **global** (alcançabilidade). O artigo sugere combinar backtracking local com reinícios.
- **Plano:** verificação de jogabilidade com BFS simulando o alcance do pulo. Se a fase não for jogável, gera de novo.

**[X4] Prazo de uma semana para tudo.** O escopo foi reduzido ao essencial (WFC completo + animação). Personagem, shader e verificação de jogabilidade viraram extras opcionais.
