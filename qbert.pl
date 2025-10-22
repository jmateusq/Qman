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

vermelho((9,a)). 
vermelho((9,c)). 
vermelho((9,e)). 
vermelho((9,g)). 
vermelho((9,i)). 
vermelho((9,k)). 
vermelho((9,m)). 
vermelho((9,o)).
vermelho((7,a)). 
vermelho((7,o)).
vermelho((6,b)). 
vermelho((6,n)).
vermelho((4,d)). 
vermelho((4,l)).
vermelho((3,e)). 
vermelho((3,k)).
vermelho((2,f)). 
vermelho((2,j)).
vermelho((1,g)). 
vermelho((1,i)).

verde((2,h)).
verde((3,g)). 
verde((3,i)).
verde((4,f)). 
verde((4,h)). 
verde((4,j)).
verde((5,e)). 
verde((5,g)). 
verde((5,i)).
verde((5,k)).
verde((6,d)). 
verde((6,f)). 
verde((6,h)). 
verde((6,j)).
verde((6,l)).
verde((7,c)). 
verde((7,e)). 
verde((7,g)). 
verde((7,i)). 
verde((7,k)). 
verde((7,m)).
verde((8,b)). 
verde((8,d)). 
verde((8,f)). 
verde((8,h)). 
verde((8,j)). 
verde((8,l)). 
verde((8,n)).

% Inimigos estáticos
inimigo(piolho, (6,f)).
inimigo(teju, (4,j)).
inimigo(teju, (8,h)).
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
% DIAGONAIS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
diagonal_sup_esq((L,C), (L1,C1)) :- L1 is L - 1, col_esq(C, C1).
diagonal_sup_dir((L,C), (L1,C1)) :- L1 is L - 1, col_dir(C, C1).
diagonal_inf_esq((L,C), (L1,C1)) :- L1 is L + 1, col_esq(C, C1).
diagonal_inf_dir((L,C), (L1,C1)) :- L1 is L + 1, col_dir(C, C1).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ATUALIZAÇÃO DE BLOCOS (liga idempotente; só mexe em Blocos)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% atualiza_blocos(+Modo, +Pos, +BlocosIn, -BlocosOut) (+:conhecido; -:retornado)
% (Modo por enquanto não altera a regra)
atualiza_blocos(_Modo, Pos, BlocosIn, BlocosOut):-
    ( member(Pos, BlocosIn) %se o bloco já está ligado, não faz nada
    -> BlocosOut = BlocosIn
    ; BlocosOut = [Pos|BlocosIn] %senão, liga o bloco
    ),
    dbg('[atualiza_blocos] Pos ~w -> ~w~n', [Pos, BlocosOut]).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% AÇÕES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% helper: aplica atualização condicional se destino for acessivel
pos_destino((L,C), (L1,C1), PredDiag) :- 
    call(PredDiag, (L,C), (L1,C1)),
    \+ inacessivel((L1,C1)).

acao(mover_sup_esq, %nome da ação
    estado((L,C),Modo,Blocos,DC,DM,M), %estado atual
    estado((L1,C1),Modo,Blocos1,DC,DM,M1)) :- %estado resultante
    pos_destino((L,C),(L1,C1),diagonal_sup_esq),
    (  verde((L1,C1))
    -> atualiza_blocos(Modo,(L1,C1),Blocos,Blocos1),
    ;Blocos1 = Blocos
    ),
    M1 is M - 1.
    dbg('acao(mover_sup_esq): ~w,~w -> ~w,~w  M:~w->~w~n',[L,C,L1,C1,M,M1]).


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

