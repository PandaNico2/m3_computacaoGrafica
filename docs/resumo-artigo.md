# Resumo detalhado do artigo (em português)

**Título original:** *WaveFunctionCollapse is Constraint Solving in the Wild*
**Tradução livre do título:** "O WaveFunctionCollapse é resolução de restrições na prática"
**Autores:** Isaac Karth e Adam M. Smith, Departamento de Mídia Computacional da Universidade da Califórnia em Santa Cruz (UC Santa Cruz), EUA
**Publicado em:** *Proceedings of the 12th International Conference on the Foundations of Digital Games* (FDG '17), Hyannis, Massachusetts, EUA, 14 a 17 de agosto de 2017, ACM. 10 páginas.
**DOI:** 10.1145/3102071.3110566
**PDF gratuito:** https://escholarship.org/uc/item/1f29235t

> Este é um resumo com as nossas palavras, organizado na mesma ordem das seções do artigo, para a equipe estudar. Não é uma tradução literal. Para citar no relatório, use a referência acima.

---

## Ideia central em uma frase
O WaveFunctionCollapse (WFC), algoritmo criado por um desenvolvedor independente e que ficou famoso entre criadores de jogos, é na verdade um **resolvedor de problemas de satisfação de restrições**, o mesmo tipo de problema de um Sudoku. Olhar para ele desse jeito explica por que funciona tão bem e mostra como melhorá-lo.

---

## Resumo do artigo (o "abstract")
O WFC é um gerador de imagens **guiado por exemplo**: recebe uma imagem pequena e gera imagens novas, maiores, no mesmo estilo. A regra que ele segue é que **todo pedacinho (janela) da imagem gerada precisa existir em algum lugar da imagem de exemplo**. Por dentro, ele faz uma busca **gulosa e sem retrocesso** (sem *backtracking*).

Os autores fazem três coisas:
1. contam como o WFC se espalhou entre artistas técnicos e desenvolvedores de jogos;
2. explicam o funcionamento do algoritmo usando o vocabulário da área de resolução de restrições;
3. reescrevem o problema numa ferramenta de programação lógica (*Answer Set Programming*, ASP) para testar o que realmente faz o WFC funcionar.

---

## 1. Introdução
- **Resolução de restrições** não é uma técnica tradicional na **geração procedural de conteúdo** (PCG, *Procedural Content Generation*, a área que estuda como o computador pode criar fases, mapas, texturas etc. automaticamente), mas pode gerar conteúdo de forma bem controlável.
- Em 2016 e 2017, o WFC chamou a atenção de desenvolvedores independentes e hobbystas pelas redes sociais. As animações mostravam a imagem surgindo de uma "neblina" de possibilidades, bem diferente dos métodos tradicionais de "gerar e testar".
- O criador do WFC, **Maxim Gumin**, defende que pessoas também desenham seguindo uma lógica parecida: decidem primeiro as partes que têm menos opções.
- **Diferença para a síntese de texturas:** o WFC **não mistura cores** de pixels. Ele só copia pedaços exatos do exemplo. Por isso preserva o significado de jogo do conteúdo: uma parede continua sendo parede, um chão continua sendo chão. Os autores comparam isso aos geradores de texto por cadeia de Markov, que juntam pedaços de frases reais.
- **Contribuições do artigo:**
  1. mostrar aplicações importantes do WFC "na prática";
  2. apresentar o pseudocódigo com um exemplo passo a passo e com termos de resolução de restrições;
  3. reformular o problema em ASP para investigar de onde vem a força do WFC.

---

## 2. Fundamentação

### 2.1 Síntese de texturas
- **Síntese de texturas** é gerar uma imagem grande, normalmente sem emendas visíveis, parecida com uma textura pequena de entrada. O artigo cita o trabalho clássico de Efros e Leung (amostragem não paramétrica).
- O método de **Liang et al. (2001)** é o mais parecido com o WFC: a imagem cresce aos poucos e, a cada passo, procura-se no exemplo um pedaço (por exemplo, 5×5 pixels) que combine com o que já foi gerado, usando uma medida de distância. **A diferença:** o WFC exige combinação **exata**, não aproximada, e precisa controlar também as regiões ainda não decididas.
- A **síntese de modelos de Paul Merrell** gera modelos 3D a partir de pedaços de um modelo pequeno feito por um artista, reaproveitando pedaços geométricos exatos. Gumin diz que se inspirou nesse trabalho.
- **Caminho de Gumin até o WFC:** ele começou inspirado por redes neurais de transferência de estilo, mas achou que não serviam para gerar fases de jogo. Fez o projeto *SynTex*, bom para texturas mas ruim para objetos com estrutura (como espadas), e depois o *ConvChain*, baseado em amostragem estatística (MCMC). Um pouco dessa ideia estatística sobrevive no WFC na forma da **entropia**.

### 2.2 Algoritmos de resolução de restrições
Um **problema de satisfação de restrições** (CSP, *Constraint Satisfaction Problem*) tem:
- **Variáveis:** as decisões a tomar. No WFC, cada posição (célula) da imagem de saída.
- **Domínio:** os valores possíveis de cada variável. No WFC, os padrões únicos encontrados no exemplo.
- **Atribuição:** dar um valor para cada variável.
- **Restrições:** quais combinações são permitidas. No WFC, padrões vizinhos precisam combinar nos pixels em que se sobrepõem.

O objetivo é encontrar uma atribuição completa que não viole nenhuma restrição. Para isso:
- Os resolvedores trabalham com **atribuições parciais**: escolhem uma variável ainda sem valor, escolhem um valor para ela e seguem. Se chegam a um beco sem saída, **voltam atrás** (*backtracking*). As **heurísticas** mudam a ordem das escolhas, mas não mudam a capacidade de encontrar uma solução.
- A **propagação de restrições** elimina antecipadamente dos domínios os valores que certamente levariam a um beco sem saída. O exemplo clássico é o algoritmo **AC-3** (consistência de arco). A propagação sozinha não resolve o problema inteiro, mas reduz muito o trabalho.

### 2.3 Resolução de restrições em geração procedural
- A área de PCG praticamente ignorou essas técnicas. A classificação clássica de geradores "baseados em busca" (Togelius et al.) nem considera geradores que trabalham com designs parciais.
- **Vantagem:** dão garantias fortes, por exemplo "toda fase gerada é jogável". **Desvantagem:** o tempo de execução é imprevisível.
- Exemplos citados:
  - **Horswill e Foged:** método rápido para povoar fases de jogo com garantia de jogabilidade, usando backtracking com AC-3.
  - **Tanagra (G. Smith et al.):** ferramenta de criação de **fases de plataforma** em que o designer e o computador trabalham juntos. Usa o resolvedor Choco e, ao contrário do WFC, faz backtracking.

### 2.4 Answer Set Programming (ASP) em geração procedural
- **ASP** é uma forma de **programação lógica**: você descreve *o que* quer (as regras do conteúdo válido) e um resolvedor genérico descobre *como* encontrar soluções.
- Adam Smith (um dos autores) propôs em 2011 usar ASP para PCG. O problema é que exige um conhecimento parecido com o de Prolog, que os artistas técnicos atraídos pelo WFC normalmente não têm.
- Os experimentos do artigo usam o resolvedor **Clingo**.

---

## 3. O WFC "na prática" (aplicações reais)
- **Lançamento:** Gumin publicou o WFC no GitHub em **30 de setembro de 2016**. Em pouco tempo, outras pessoas o reimplementaram em várias linguagens e plataformas (até no console de fantasia Pico-8), e as animações se espalharam pelo Twitter.
- **Joseph Parker:** criou uma ferramenta de WFC para a Unity (outubro de 2016) que trabalha com **objetos 3D** em vez de pixels.
- **Proc Skater 2016** (Joseph Parker, Ryan Jones e Oscar Morante): jogo feito para a ProcJam 2016, o **primeiro jogo a usar o WFC para gerar fases**. Gera pistas de skate a partir de um exemplo feito pelo designer. Como o WFC copia pedaços exatos, a pista gerada sempre "encaixa" e pode ser percorrida.
- **Oskar Stålberg:** artista técnico, ex-*Tom Clancy's The Division*. Estendeu o WFC para outros formatos de tile, 3D e malhas, otimizou o desempenho e **acrescentou backtracking**. Em 2017 publicou uma demo no navegador explicando o algoritmo e o comparou a um resolvedor de Sudoku turbinado.
- **Caves of Qud** (Freehold Games): jogo do gênero *roguelike* que usa o WFC para gerar fases. Usa várias passadas do WFC com modelos (*templates*) para ter mais variedade. Como a entrada é simples, toda a equipe consegue experimentar.
- **Martin O'Leary (*Oisín*):** glaciologista que usou o WFC para gerar **poesia**. As sílabas são os "tiles" numa sequência de uma dimensão, e rima e métrica são restrições de longa distância. Gerou sonetos a partir de *Alice no País das Maravilhas*, entre outros.
- **Conclusão da seção:** essas aplicações (pistas, fases, poesia) são explicadas muito melhor pela visão de "resolução de restrições" do que pela visão de "síntese de texturas".

---

## 4. O algoritmo WFC
Os autores analisam o código original de Gumin, em C# e com menos de 1.000 linhas. Como muita gente usa o WFC como uma "caixa-preta", eles o explicam em pseudocódigo. A rotina principal é:

```
Run():
    PatternsFromSample()     # extrai os padrões do exemplo
    BuildPropagator()        # monta o índice de vizinhanças permitidas
    repete até terminar:
        Observe()            # escolhe e decide uma célula
        Propagate()          # espalha as consequências
    OutputObservations()     # gera a imagem final
```

### Padrões e o parâmetro N
- Um **padrão** é um pedaço N×N único da imagem de exemplo.
- Existem dois modelos:
  - **Modelo de tiles (*tiled*):** o designer define à mão quais tiles podem ficar ao lado de quais.
  - **Modelo de sobreposição (*overlapping*):** as regras são deduzidas automaticamente das janelas N×N do exemplo.
- Opcionalmente, também entram as versões **espelhadas e rotacionadas** de cada padrão.

### O exemplo "Red Maze" (labirinto vermelho)
- Imagem de 4×4 pixels com 3 cores (branco, preto e vermelho) que se repete periodicamente: a borda direita "continua" na esquerda, e a de baixo na de cima.
- Com N = 2, espelhamento e rotação, saem **12 padrões únicos**: 4 com um único pixel preto, 4 com dois pretos e dois brancos, e 4 em volta do pixel vermelho.
- Nenhum padrão junta vermelho e branco, porque essas cores nunca se tocam no exemplo. Logo, isso também nunca acontece na saída.

### O índice de vizinhança ("propagador")
- `BuildPropagator()` calcula antes **quais pares de padrões podem ficar lado a lado em cada deslocamento**. Com N = 3, há 36 deslocamentos possíveis.
- Os autores chamam essa estrutura de "índice" para não confundir com o propagador do AC-3. A maioria dos pares é proibida, então o índice é esparso.

### A onda (*wave*)
- É uma tabela de valores verdadeiro/falso dizendo **se cada padrão ainda é possível em cada célula**.
- Tudo começa como "verdadeiro" (qualquer padrão é possível: é a "superposição", daí o nome inspirado na física quântica).
- Os valores **só mudam de verdadeiro para falso**, nunca o contrário.
- O código original **não volta atrás**. Se acontece uma **contradição** (uma célula fica sem nenhum padrão possível), ele **recomeça do zero**. Segundo os autores, isso é raro na prática.

### Observar (*Observe*)
- Procura a célula de **menor entropia diferente de zero**. Entropia zero significa que a célula já está decidida (um único padrão); nenhum padrão possível significa contradição.
- A entropia é calculada a partir das **frequências** dos padrões que ainda restam (quantas vezes cada um aparece no exemplo), mais um pequeno **ruído aleatório** para desempatar.
- Na linguagem de restrições, essa escolha é a heurística **MRV** (*Minimum Remaining Values*): decidir primeiro a variável com menos opções sobrando.
- O padrão escolhido para a célula é **sorteado com peso proporcional à frequência** no exemplo. Assim, a imagem gerada tende a ter a mesma "proporção" de padrões do exemplo.

### Propagar (*Propagate*)
- Funciona como a **consistência de arco do AC-3**, implementada como um "preenchimento por inundação" (*flood fill*): para cada célula vizinha, elimina os padrões que deixaram de combinar e coloca essa vizinha na fila para verificar as vizinhas dela.

### Saída e visualização
- `OutputObservations()` pinta cada célula com a **média das cores** dos padrões ainda possíveis. Dá para gerar essa imagem a cada passo, e é daí que vem a famosa animação da "neblina se dissipando".
- As figuras do artigo mostram o Red Maze passo a passo: na primeira observação todas as células empatam (começo aleatório); depois, cada passo às vezes resolve várias células de uma vez; e no fim aparecem duas saídas possíveis.

### Alternativas citadas
- No lugar do sorteio por frequência, daria para usar a heurística **LCV** (*Least Constraining Value*, escolher o valor que menos restringe os vizinhos), mas é difícil prever o efeito visual.
- Garantir que o sorteio seja estatisticamente uniforme entre todas as soluções possíveis é um problema difícil.

---

## 5. Reformulação em ASP e experimentos
Os autores criaram um **substituto** do WFC no resolvedor **Clingo**. Não é uma reimplementação fiel, porque **não usa a heurística de entropia**. Eles aproveitam o processamento de entrada do Gumin (padrões e índice) e entregam ao Clingo só duas regras:
1. **cada célula recebe exatamente um padrão**;
2. **vizinhos precisam ser compatíveis** (proíbe qualquer célula cujo vizinho não tenha um padrão permitido naquela direção).

Basta considerar os 4 vizinhos diretos (cima, baixo, esquerda, direita), porque eles já garantem as restrições de distância maior.

### Experimento 1: a heurística importa?
- **Cenários:** *Platformer* (**fase de jogo de plataforma**, o mesmo tipo do nosso trabalho), *Skyline* (silhueta de prédios) e *Flowers* (flores). Todos com N = 3 e saída de 48×48, 10 execuções por cenário.
- **Configurações testadas:** a heurística padrão do Clingo (VSIDS), heurística desligada (células na ordem de leitura) e escolha de célula aleatória.

| Cenário | Padrões | Escolhas (VSIDS) | Conflitos (VSIDS) | Escolhas (desligada) | Conflitos (desligada) |
|---|---|---|---|---|---|
| Platformer | 116 | 390 ± 22 | 0 | 433 ± 45 | 0 |
| Skyline | 170 | 415 ± 14 | 0 | 411 ± 38 | 0 |
| Flowers | 106 | 325 ± 14 | 0 | 358 ± 34 | 0 |

- **Resultados:**
  - **Zero conflitos** em todas essas configurações, mesmo sorteando valores ao acaso.
  - Uma imagem 48×48 tem 2.304 células, mas o resolvedor só precisou tomar **cerca de 300 a 430 decisões**. **A propagação decidiu todo o resto sozinha.**
  - Já a **escolha de célula aleatória foi desastrosa**: milhares de conflitos e estouro do limite de 1 minuto.
  - Todos os casos que terminaram levaram menos de 2 segundos (num MacBook Pro de 2011).
- **Conclusão:** o que faz o WFC funcionar é principalmente a **propagação de restrições**, e não a heurística de entropia em si. O importante é não escolher células totalmente ao acaso.

### Experimento 2: uma restrição global
- Foi acrescentada uma restrição **global**: **todo padrão do exemplo precisa aparecer pelo menos uma vez na saída**.
- Em *Flowers* e *Platformer*, quase nada mudou. Em *Skyline*, surgiram **centenas de conflitos**.
- **Recomeçando do zero a cada conflito** (como o WFC faz), **nenhuma solução foi encontrada em 1 minuto**.
- **Com backtracking** (voltando só algumas decisões), o Clingo resolveu **rapidamente**.
- **Lição:** para restrições globais, recomeçar do zero não basta e é preciso voltar atrás localmente. Os autores dão como exemplo justamente a **alcançabilidade** em jogos (garantir que todos os lugares de um mapa possam ser alcançados) e sugerem combinar **backtracking local com reinícios globais**.

---

## 6. Conclusões
- O WFC é uma aplicação importante, feita fora do meio acadêmico, de **resolução de restrições para geração procedural**. Como trabalha com **pedaços abstratos de conteúdo** (e não com cores que se misturam), ele serve para poesia, fases de jogo com restrições e muito mais.
- A heurística de entropia e a estratégia de recomeçar do zero são **escolhas razoáveis para o problema original** (imagens), mas **não são essenciais** para usos futuros.
- Outros desenvolvedores, como Oskar Stålberg, já estavam acrescentando backtracking.
- **As duas grandes forças do WFC** são a **busca em atribuições parciais** (decidir aos poucos, com a "neblina" de possibilidades) e a **propagação de restrições**.
- O fato de ser **guiado por dados** (basta desenhar um exemplo) torna o WFC acessível: muita gente o usa como caixa-preta e mesmo assim gera conteúdo interessante.
- **Caminhos futuros apontados:** suportar restrições globais (como alcançabilidade), combinar backtracking local com reinícios, testar a heurística LCV e estudar a uniformidade estatística do sorteio. Os autores também reconhecem que, como o substituto em ASP não usa a entropia, as conclusões sobre a heurística têm limitações.

---

## Glossário rápido

| Termo | Significado |
|---|---|
| **PCG** (*Procedural Content Generation*) | Geração procedural de conteúdo: o computador cria fases, mapas, texturas etc. automaticamente |
| **CSP** (*Constraint Satisfaction Problem*) | Problema de satisfação de restrições: achar valores para variáveis respeitando regras |
| **Domínio** | Conjunto de valores ainda possíveis para uma variável (no WFC, os padrões possíveis numa célula) |
| **Onda** (*wave*) | Tabela com os padrões ainda possíveis em cada célula |
| **Entropia** | Medida de "incerteza" de uma célula: quanto mais opções e mais equilibradas, maior |
| **MRV** | Heurística de decidir primeiro a variável com menos opções sobrando |
| **Propagação / AC-3 / consistência de arco** | Remover dos vizinhos as opções que ficaram incompatíveis, em cadeia |
| **Backtracking** | Voltar atrás e desfazer decisões quando se chega a um beco sem saída |
| **Contradição** | Uma célula ficou sem nenhuma opção possível |
| **ASP / Clingo** | Programação lógica / resolvedor genérico usado pelos autores nos experimentos |
| **Restrição local × global** | Local: envolve só vizinhos (ex.: tiles que combinam). Global: envolve a fase inteira (ex.: dá para ir do início ao fim) |

---

## Como o artigo se liga ao nosso trabalho
- Implementamos o pseudocódigo da seção 4 (`scripts/wfc.gd`) usando o **modelo de tiles com regras aprendidas do exemplo**, equivalente a N = 1. Os autores usam N = 3 nos experimentos. Ver a decisão D7 em `docs/decisoes-relatorio.md`.
- Nossa contradição é tratada como no WFC original: **recomeçar do zero**.
- O cenário **Platformer** do experimento 1 é o mesmo tipo de conteúdo que geramos.
- O problema das fases impossíveis de terminar (dificuldade X3) é exatamente a **restrição global de alcançabilidade** que os autores apontam como desafio futuro. A verificação de jogabilidade que estamos planejando responde a isso.
