:- dynamic debug_flag/0.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% UTIL: debug simples
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
debug_on  :- (debug_flag -> true ; assertz(debug_flag)).
debug_off :- (retract(debug_flag) -> true ; true).

dbg(Fmt, Args) :- (debug_flag -> format(Fmt, Args) ; true).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ESTADO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% estado(PosQbert, Modo, Blocos, DiscoC, DiscoM, MovimentosRestantes).
% INICIO DO JOGO
inicio(estado((8,h), normal, [], ativo, ativo, 50)).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAPA ESTÁTICO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disco((5,c)).
disco((5,m)).

vermelho((1,a)). 
vermelho((1,c)). 
vermelho((1,e)). 
vermelho((1,g)). 
vermelho((1,i)). 
vermelho((1,k)). 
vermelho((1,m)). 
vermelho((1,o)).
vermelho((3,a)). 
vermelho((3,o)).
vermelho((4,b)). 
vermelho((4,n)).
vermelho((6,d)). 
vermelho((6,l)).
vermelho((7,e)). 
vermelho((7,k)).
vermelho((8,f)). 
vermelho((8,j)).
vermelho((9,g)). 
vermelho((9,i)).

verde((8,h)).
verde((7,g)). 
verde((7,i)).
verde((6,f)). 
verde((6,h)). 
verde((6,j)).
verde((5,e)). 
verde((5,g)). 
verde((5,i)). 
verde((5,k)).
verde((4,d)). 
verde((4,f)). 
verde((4,h)). 
verde((4,j)).
verde((3,c)). 
verde((3,e)). 
verde((3,g)). 
verde((3,i)). 
verde((3,k)). 
verde((3,m)).
verde((2,b)). 
verde((2,d)). 
verde((2,f)). 
verde((2,h)). 
verde((2,j)). 
verde((2,l)). 
verde((2,n)).

% Inimigos estáticos
inimigo(piolho, (4,f)).
inimigo(teju, (6,j)).
inimigo(teju, (2,h)).
inimigo(Pos) :- inimigo(_, Pos).

% Posições fora do mapa
inacessivel((X,Y)) :-
    \+ verde((X,Y)),
    \+ disco((X,Y)),
    \+ vermelho((X,Y)).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COLUNAS COMO LETRAS: vizinhos esquerda/direita
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
colunas([a,b,c,d,e,f,g,h,i,j,k,l,m,n,o]).

col_esq(C, C1) :-
    colunas(Cs), nth0(I, Cs, C), I > 0, I1 is I - 1, nth0(I1, Cs, C1).

col_dir(C, C1) :-
    colunas(Cs), nth0(I, Cs, C), length(Cs, N), I < N - 1,
    I1 is I + 1, nth0(I1, Cs, C1).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ATUALIZAÇÃO DE BLOCOS (liga idempotente; só mexe em Blocos)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% atualiza_blocos(+Modo, +Pos, +BlocosIn, -BlocosOut)
% (Modo por enquanto não altera a regra; fácil estender depois)
atualiza_blocos(_Modo, Pos, BlocosIn, BlocosOut):-
    ( member(Pos, BlocosIn) %se o bloco já está ligado, não faz nada
    -> BlocosOut = BlocosIn
    ; BlocosOut = [Pos|BlocosIn] %senão, liga o bloco
    ),
    dbg('[atualiza_blocos] Pos ~w -> ~w~n', [Pos, BlocosOut]).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% AÇÕES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% movimento diagonal superior esquerda
diagonal_sup_esq((L,C), (L1,C1)) :-
    L1 is L + 1,
    C1 is C - 1.
acao(mover_sup_esq, %nome da ação
    estado((L,C),Modo,Blocos,DC,DM,M), %estado atual
    estado((L1,C1),Modo,Blocos1,DC,DM,M1)) :- %estado resultante
    diagonal_sup_esq((L,C),(L1,C1)),
    (  verde((L1,C1))
    -> atualiza_blocos(Modo,(L1,C1),Blocos,Blocos1),
    ;Blocos1 = Blocos
    ),
    %contagem de movimentos independe de ter alterado bloco ou nao
    M1 is M - 1.


% movimento diagonal superior direita
diagonal_sup_dir((L,C), (L1,C1)) :-
    L1 is L + 1,
    C1 is C + 1.
acao(mover_sup_dir,
    estado((L,C),Modo,Blocos,DC,DM,M), %estado atual
    estado((L1,C1),Modo,Blocos1,DC,DM,M1)) :- %estado resultante
    diagonal_sup_dir((L,C),(L1,C1)),
    (  verde((L1,C1))
    -> atualiza_blocos(Modo,(L1,C1),Blocos,Blocos1),
    ;Blocos1 = Blocos
    ),
    %contagem de movimentos independe de ter alterado bloco ou nao
    M1 is M - 1.


% movimento diagonal inferior esquerda
diagonal_inf_esq((L,C), (L1,C1)) :-
    L1 is L - 1,
    C1 is C - 1.
acao(mover_inf_esq,
    estado((L,C),Modo,Blocos,DC,DM,M), %estado atual
    estado((L1,C1),Modo,Blocos1,DC,DM,M1)) :- %estado resultante
    diagonal_inf_esq((L,C),(L1,C1)),
    (  verde((L1,C1))
    -> atualiza_blocos(Modo,(L1,C1),Blocos,Blocos1),
    ;Blocos1 = Blocos
    ),
    %contagem de movimentos independe de ter alterado bloco ou nao
    M1 is M - 1.

% movimento diagonal inferior direita
diagonal_inf_dir((L,C), (L1,C1)) :-
    L1 is L - 1,
    C1 is C + 1.
acao(mover_inf_dir,
    estado((L,C),Modo,Blocos,DC,DM,M), %estado atual
    estado((L1,C1),Modo,Blocos1,DC,DM,M1)) :- %estado resultante
    diagonal_inf_dir((L,C),(L1,C1)),
    (  verde((L1,C1))
    -> atualiza_blocos(Modo,(L1,C1),Blocos,Blocos1),
    ;Blocos1 = Blocos
    ),
    %contagem de movimentos independe de ter alterado bloco ou nao
    M1 is M - 1.

acao(usardisco,
    estado((L,C),Modo,Blocos,DC,DM,M), %estado atual
    estado((9,h),poder,Blocos,DC1,DM1,M1)) :- %estado resultante
    ((L,C) = (5,c), DC = ativo, DC1 = usado, DM1 = DM; % Se o DC está ativo e pos valida ele é usado
     (L,C) = (5,m), DM = ativo, DM1 = usado, DC1 = DC),% Se o DM está ativo e pos valida ele é usado
    M1 is M - 1. % Só atualiza se o movimento se concretiza


perde(estado((L,C),_,_,_,_,_)) :- %Caso esteja num bloco vermelho então perde
    vermelho((L,C)).
    
vence(estado(_,_,Blocos,_,_,M)) :- %se todos os blocos estão ligados e ainda tem movimentos ganhamos
    todos_ligados(Blocos),
    M >= 0.
    
consegue(EstadoFinal) :- %tenta achar algum EstadoFinal que seja vencedor partindo do EstadoInicial
    inicio(EstadoInicial),
    caminho(EstadoInicial,EstadoFinal).

caminho(Estado,Estado) :- vence(Estado). %caso base: se o estado atual é vencedor, então o caminho termina aqui
caminho(Estado1,EstadoFinal) :- %busca recursiva de caminho entre Estado1 e EstadoFinal
    acao(_,Estado1,Estado2), %se existe uma ação que leva do Estado1 ao Estado2
    \+ perde(Estado2), % e essa ação não causa perda
    caminho(Estado2,EstadoFinal).%tenta recursivamente achar um caminho do Estado2 ao EstadoFinal até chegar caso base
    
?- consegue(estado(_,_,_,_,_,_)).

