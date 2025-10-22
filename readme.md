# AGENTE Q\*BERT

**GRUPO:**

*   Gabrielly Maria da Silva Barbosa RA: 831084
*   José Mateus Freitas Queiroz RA: 811840
*   Isabela de Paula Castro RA: 824145
*   João Manoel Ribeiro Machado RA: 822447
*   Giovanna Rabello Luciano RA: 824749

---

## 1. RESUMO DO PROJETO

O jogo Q\*BERT é um clássico arcade em que o jogador controla o personagem-título — uma pequena criatura laranja e esférica com um focinho alongado. O objetivo é ligar todos os blocos da pirâmide, eliminar os inimigos e completar a fase em no máximo 50 movimentos.

A pirâmide é formada por 28 blocos, dispostos de forma triangular. Q\*BERT começa no topo e pode se mover apenas para as quatro diagonais adjacentes (superior esquerda, superior direita, inferior esquerda e inferior direita).

No início da fase, todos os blocos estão desligados (0). Sempre que Q\*BERT pisa em um bloco, ele liga esse bloco (1). Quando um disco é usado, ele se torna vermelho, indicando que já foi ativado.

O jogo apresenta uma variedade de inimigos com comportamentos distintos:

*   **Coily** – Aparece inicialmente como uma bola roxa que desce pela pirâmide. Ao alcançar a base, transforma-se em uma cobra e escolhe um local de parada. Pode ser derrotado se Q\*Bert utiliza um disco lateral, que lhe concede o poder de eliminar inimigos.
*   **Bolas coloridas** – Caem da segunda fileira da pirâmide.
    *   **Vermelhas:** são letais para Q\*BERT.
    *   **Verdes:** concedem 5 passos extras para o jogador.

### DISCOS LATERAIS

Nos lados esquerdo e direito da pirâmide existem discos flutuantes multicoloridos. Quando Q\*Bert salta em um disco, ele é transportado de volta ao topo da pirâmide.

Ao pegar o disco do lado esquerdo, Q\*BERT ganha o poder de eliminar inimigos, e o disco não pode ser reutilizado. Além disso, o disco inverte o comportamento dos blocos: ao pisar em um bloco ligado (1), Q\*BERT o desliga (0), e ao pisar em um bloco desligado (0), ele o liga (1).

### PONTUAÇÃO E RECOMPENSAS

O sistema de pontuação recompensa tanto ações básicas quanto estratégicas:

*   \+25 pontos por mudar a cor de um cubo.
*   \+500 pontos por derrotar Coily com o uso de um disco.
*   \+1 pontos por cada movimento válido realizado por Q\*BERT.
*   **Bônus de fase:** começa em 1.000 pontos na primeira tela do Nível 1 e aumenta 250 pontos por cada conclusão subsequente.

---

## 2. PEAS DO CENÁRIO

### P (Performance Measure) – Medida de Desempenho

O desempenho do agente Q\*BERT é avaliado conforme os seguintes critérios:

*   \+25 pontos por mudar a cor (ligar) de um bloco.
*   \+1 ponto por cada movimento válido.
*   \+500 pontos por derrotar Coily (ou outro inimigo) após adquirir o poder com o disco.
*   Bônus de fase: começa em 1000 pontos, aumentando 250 pontos por cada conclusão subsequente.
*   **Penalizações:**
    *   Morte do personagem (em blocos de perigo) = perda da fase.
    *   Falha em completar o objetivo em até 50 movimentos = derrota.
*   **Objetivo final:**
    *   Ligar todos os blocos (estado 1).
    *   Eliminar todos os inimigos.
    *   Fazer isso dentro do limite de 50 movimentos.

### E (Environment) – Ambiente

*   **Tipo:** Ambiente parcialmente observável, dinâmico e estocástico (há aleatoriedade nos inimigos).
*   **Cenário:** Grade 9x15 composta por 135 estados possíveis.
*   **Características dos blocos:**
    *   **Verdes:** acessíveis a Q\*BERT e inimigos.
    *   **Azuis:** discos especiais acessíveis apenas a Q\*Bert — ao pisar, ele é teletransportado para `(8,H)`.
    *   **Vermelhos:** blocos perigosos — causam a morte do personagem.
    *   **Cinzas:** blocos inacessíveis a todos.
*   **Estados especiais:**
    *   **(8,H):** posição inicial do agente Q\*BERT
    *   **(5,C)** e **(5,M):** discos que concedem poderes.
    *   Demais blocos podem estar ligados (1) ou desligados (0).
*   **Inimigos:**
    *   Bolas vermelhas e verdes e Coily (bola roxa) descem diagonalmente, escolhendo aleatoriamente entre os dois blocos inferiores.
    *   Inimigos não podem acessar blocos azuis ou cinzas.
*   **Regra do disco:**
    *   Após usar um disco, Q\*BERT retorna ao topo `(8,H)`.
    *   O disco torna-se vermelho (inutilizável).
    *   O poder do disco permite matar inimigos e inverter o comportamento dos blocos (pisar liga ↔ desliga).

### A (Actuators) – Atuadores

O agente Q\*BERT pode executar as seguintes ações:

*   Mover-se diagonalmente em qualquer uma das quatro direções possíveis:
    *   superior esquerda, superior direita, inferior esquerda, inferior direita.
*   Ativar blocos (pisar em blocos e alterar seu estado 0→1 ou 1→0 após obter o disco).
*   Usar discos azuis para ser teleportado ao topo `(H9)`.
*   Eliminar inimigos (após adquirir o poder do disco).
*   Esperar (em caso de pausa após eliminar inimigos, se houver).

### S (Sensors) – Sensores

O agente Q\*BERT pode perceber:

*   Sua posição atual (linha e coluna) no tabuleiro.
*   Estado do bloco atual (ligado ou desligado).
*   Presença de inimigos em blocos adjacentes.
*   Presença e localização dos discos `(5,C)` e `(5,M)`.
*   Blocos inacessíveis (cinzas) e blocos de perigo (vermelhos).
*   Quantidade de movimentos restantes (máximo de 50).
*   Pontuação atual.

---

## 3. PEAS DO AGENTE

![][image1]

### P (Performance Measure) – Medida de Desempenho

**Objetivo final:**

*   Todos os blocos verdes = 1 (ligados).
*   Todos os inimigos eliminados.
*   Concluir em ≤ 50 movimentos.
*   **Pontuação:**
    *   \+1 por mover para um bloco válido.
    *   \+5 ao ligar um bloco 0→1.
    *   \+20 por matar inimigo (Coily ou bola vermelha) quando com poder.
    *   \+10 por usar disco válido (teleporte).
    *   Episódio termina com vitória quando (blocos=1 AND inimigos=0) antes ou no 50º movimento.

### E (Environment) – Ambiente

**Layout e tipos de célula:**

*   **Verde:** bloco acessível (por todos);
    *   `(8,H)` é acessível apenas a Q\*BERT e é a posição inicial.
*   **Cinza:** inacessível para todos (parede/vazio).
*   **Azul:** discos em `(5,C)` e `(5,M)` (acessíveis só por Q\*BERT); após uso viram vermelho (inativo).
*   **Vermelho:** bordas/poços; entrar em qualquer um dos estados mortais abaixo causa morte imediata.
*   **Estados mortais (entrar = morte):**
    *   `(1,A) (1,C) (1,E) (1,G) (1,I) (1,K) (1,M) (1,O), (3,A) (3,O), (4,B) (4,N), (6,D) (6,L), (7,E) (7,K), (8,F) (8,J), (9,G) (9,I)`.

**REGRAS GLOBAIS:**

*   Q\*BERT se move apenas nas diagonais:
    *   superior direita, superior esquerda, inferior direita e inferior esquerda entre vizinhos válidos.
*   Inimigos (bolas vermelhas e Coily) descem níveis:
    *   a cada passo escolhem aleatoriamente uma das duas diagonais inferiores possíveis.
*   Teleporte: ao pular num disco azul ⇒ Q\*BERT vai para `(8,H)`. O disco usado torna-se vermelho (inativo).
*   Coily morre se Q\*BERT usar disco estando a ≤ 2 movimentos de distância (Coily salta para onde estava o disco e cai).
*   Blocos começam desligados (0).

**ESTADOS DO AGENTE:**

*   **MODO\_NORMAL** (início): sem poder; ao pisar num verde: 0→1 (liga).
*   **MODO\_PODER** (após pegar um disco): teleporta para `(9,H)`; ganha habilidade de matar inimigos por contato, comportamento de cor inverte (pisar troca: 1→0, 0→1).
*   **MODO\_FINALIZAÇÃO** (após matar todos os inimigos e pegar o outro disco): teleporta para `(9,H)` e volta a inverter os blocos.

### A (Actuators) – Atuadores

*   Uso de disco é implícito: saltar para `(5,C)` ou `(5,M)` executa o teleporte e troca de modo conforme as regras.
*   Q\*BERT se move apenas nas diagonais: superior direita, superior esquerda, inferior direita e inferior esquerda entre vizinhos válidos.

### S (Sensors) – Sensores

**Percepção total do estado:**

*   Posição de Q\*BERT (início em `(8,H)`).
*   Modo atual: `NORMAL` | `PODER` | `FINALIZAÇÃO`.
*   Contador de movimentos restantes (de 50 até 0).
*   Mapa com tipo de cada célula (verde/cinza/azul/vermelho) e estado de cor dos verdes (0/1).
*   Estado dos discos: ativos (azul) ou já usados (vermelho).
*   Posições e tipos dos inimigos, inclusive se Coily está a ≤ 2 movimentos (para efeito de morte ao usar disco).

---

## 4. REGRAS

### ESTRUTURA DE ESTADOS:

*   **PosQBert:** posição do agente `(8,H)`.
*   **Modo:** normal | poder | finalizado.
*   **Blocos:** lista com o estado de cada bloco verde (ligado=1 / desligado=0).
*   **DiscoC (DC) , DiscoM (DM):** ativo/usado.
*   **MovimentosRestantes:** número de passos (até 50).

### Fatos Iniciais:

*   Posição inicial e posições especiais.
    *   **(8,H):** Posição inicial.
    *   **normal:** modo padrão (sem poder).
    *   **todos\_desligados:** todos os blocos verdes estão em 0.
    *   **ativo, ativo:** os discos C e M ainda podem ser usados.
    *   **50:** número de movimentos disponíveis.
*   `disco((5,C))` E `disco((5,M)):` posições dos discos que teletransportam.
*   `vermelho((x,y)):` são posições indisponíveis para jogar.
*   `verde((x,y)):` são posições disponíveis para jogar.

Esses dados são a base fixa do ambiente.
(O verde precisa ser feito para todas as posições possíveis).

### AÇÕES POSSÍVEIS:

São os movimentos que o agente pode realizar.

*   **Cabeça:**
    *   `acao(mover_sup_esq, EstadoAntes, EstadoDepois)`
    *   “Existe uma ação chamada `mover_sup_esq` que transforma o `EstadoAntes` no `EstadoDepois`."
*   **Corpo (parte depois de `:-`):**
    *   `diagonal_sup_esq((L,C),(L1,C1)):` verifica se o destino é a diagonal superior esquerda da posição atual.
    *   `\+ vermelho((L1,C1)):` garante que não é um bloco mortal.
    *   `verde((L1,C1)):` garante que o destino existe e é seguro.
    *   `atualiza_blocos(...):` altera o estado do bloco (liga ou inverte).
    *   `M1 is M - 1:` consome 1 movimento.

*   **O QUE ACONTECE EM EXECUÇÃO:**
    *   Quando o prolog tenta provar uma jogada (`acao(mover_sup_esq, E1, E2)`), ele:
        1.  Tenta achar `(L1,C1)` válido.
        2.  Verifica se é verde.
        3.  Atualiza o estado dos blocos.
        4.  Cria um novo estado `E2` com um movimento a menos.
        5.  Retorna esse novo estado com o resultado possível.

![][image2]

É assim que o Prolog “gera” os próximos estados possíveis do jogo:

![][image3]

### REGRA DO DISCO (TELEPORTE E MODO DE PODER):

Define o que acontece quando Q\*BERT pisa num disco:

*   Se ele estiver em `(5,c)` e o disco estiver ativo, ele:
    *   é **teletransportado** para o topo `(9,h)`.
    *   muda o modo para `poder` (agora ele pode matar inimigos).
    *   o disco `(5,c)` passa a estar `usado`.

O ponto e vírgula (`;`) significa **“ou”**, então vale para `(5,c)` ou `(5,m)`.

![][image4]

### CONDIÇÃO DE DERROTA (LIMBO):

É uma regra simples para detectar uma derrota:

*   **“Se a posição atual é um bloco vermelho, o jogador perdeu”:**
    *   O underline (`_`) significa “não importa o que tem aqui”.
    *   Então só a posição é verificada.

Isso serve para o prolog não ficar testando movimentos inválidos.

![][image5]

### CONDIÇÃO DE VITÓRIA:

Essa é a regra do fim do jogo com vitória:

*   Ela é verdadeira quando:
    *   **Todos os blocos verdes estão “LIGADOS” (`todos_ligados(Blocos)` = todos = 1).**
    *   **Ainda restam movimentos (`M >= 0`).**

![][image6]

### REGRA RECURSIVA (JOGABILIDADE COMPLETA):

Essas três regras fazem o motor do jogo lógico, igual o exemplo do “macaco e a banana” apresentados na aula de inteligência artificial ministrada pelo professor **Murilo Coelho Naldi.**

*   `consegue(EstadoFinal)`
    *   **COMEÇA O JOGO:** diz ao Prolog para partir do estado inicial e buscar um estado final vencedor.
*   `caminho(Estado,Estado)`
    *   **CASO BASE:** se o estado atual já é vencedor (`vence(Estado)`), para a busca.
*   `caminho(Estado1,EstadoFinal)`
    *   **CASO RECURSIVO:**
        *   Tenta achar uma ação (`acao(_,Estado1,Estado2)`) que leve a outro estado.
        *   Garante que esse novo estado não seja derrota (`\+ perde(Estado2)`).
        *   Continua buscando (`caminho(Estado2,EstadoFinal)`).

O Prolog usa backtracking, ou seja, se uma sequência de ações não leva à vitória, ele volta e tenta outro caminho automaticamente.

![][image7]

### EXEMPLO DE CONSULTA:

![][image8]

Essa é a pergunta feita ao Prolog:

*   O (`?-`) significa **“CONSULTAR”**.
*   `consegue(...)` é o predicado que inicia a busca de uma solução.
*   O underline (`_`) indica que você **não se importa** com os valores específicos do estado final, só quer saber se é possível chegar a algum estado vencedor.
*   **Se houver uma sequência de ações que leve Q\*BERT à vitória (sem cair, e dentro de 50 movimentos), o Prolog responderá:**
    *   `true`
*   **Caso contrário:**
    *   `false`

---

## 6. REFERÊNCIAS

*   Qbert (game) — Fandom Wiki. Disponível em: <https://qbert.fandom.com/wiki/Q*bert_(game)>
*   Free Qbert Project. Disponível em: <https://freeqbert.org/>