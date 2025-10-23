:- dynamic debug_flag/0.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% UTIL: debug simples
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
debug_on  :- (debug_flag -> true ; assertz(debug_flag)).
debug_off :- (retract(debug_flag) -> true ; true).

dbg(Fmt, Args) :- (debug_flag -> format(Fmt, Args) ; true).

testa_cores :-
    forall(vermelho(P), (write('vermelho '), writeln(P))),
    forall(verde(P),    (write('verde    '), writeln(P))),
    forall(disco(P),    (write('disco    '), writeln(P))),
    forall(inacessivel(P), (write('cinza    '), writeln(P))).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ESTADO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% mknode(+Pos, +Modo, +Blocos, +DC, +DM, +M, -Estado)
mknode(Pos, Modo, Blocos, DC, DM, M, estado(Pos, Modo, Blocos, DC, DM, M)).

estado(_PosQbert, _Modo, _Blocos, _DiscoC, _DiscoM, _MovimentosRestantes).
% INICIO DO JOGO
inicio(estado((2,h), normal, [], ativo, ativo, 50)).


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
%inimigo(piolho, (6,f)).
%inimigo(teju, (4,j)).
%inimigo(teju, (8,h)).
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
% ATUALIZAÇÃO DE BLOCOS (só mexe em Blocos)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% atualiza_blocos(+Modo, +Pos, +BlocosIn, -BlocosOut)
% (Modo por enquanto não altera a regra; fácil estender depois)
atualiza_blocos(_Modo, Pos, BlocosIn, BlocosOut):-
    ( member(Pos, BlocosIn) %se o bloco já está ligado, não faz nada
    -> BlocosOut = BlocosIn
    ; BlocosOut = [Pos|BlocosIn] %senão, liga o bloco
    ),
    dbg('   [atualiza_blocos] Pos ~w -> ~w~n', [Pos, BlocosOut]).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% AÇÕES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% helper: aplica atualização condicional se destino for acessivel
pos_destino((L,C), (L1,C1), PredDiag) :- 
    call(PredDiag, (L,C), (L1,C1)),
    \+ inacessivel((L1,C1)).

% usar DISCO ao subir pela esquerda, quando em (5,c) e DC ativo
acao(mover_sup_esq,
     estado((6,d), Modo, Blocos, ativo, DM, M),
     estado((2,h), Modo1, Blocos1, usado, DM, M1)) :-
    (  Modo = normal
    -> Modo1 = poder
    ;  Modo1 = normal
    ),
    atualiza_blocos(Modo,(2,h),Blocos,Blocos1),
    M1 is M - 1,
    dbg('acao(mover_sup_esq/disco C): 5,c -> 2,h  M:~w->~w~n', [M,M1]).


% usar DISCO ao subir pela direita, quando em (5,m) e DM ativo
acao(mover_sup_dir,
     estado((6,l), Modo, Blocos, DC, ativo, M),
     estado((2,h), Modo1, Blocos1, DC, usado, M1)) :-
    (  Modo = normal
    -> Modo1 = poder
    ;  Modo1 = normal
    ),
    atualiza_blocos(Modo,(2,h),Blocos,Blocos1),
    M1 is M - 1,
    dbg('acao(mover_sup_dir/disco M): 5,m -> 2,h  M:~w->~w~n', [M,M1]).

acao(mover_sup_esq, %nome da ação
    estado((L,C),Modo,Blocos,DC,DM,M), %estado atual
    estado((L1,C1),Modo,Blocos1,DC,DM,M1)) :- %estado resultante
    \+ ((L,C) = (6,d) ; (L,C) = (6,l)), % evita conflito com uso de disco
    pos_destino((L,C),(L1,C1),diagonal_sup_esq),
    (  verde((L1,C1))
    -> atualiza_blocos(Modo,(L1,C1),Blocos,Blocos1)
    ; Blocos1 = Blocos
    ),
    M1 is M - 1,
    dbg('acao(mover_sup_esq): ~w,~w -> ~w,~w  M:~w->~w~n',[L,C,L1,C1,M,M1]).


% movimento diagonal superior direita
diagonal_sup_dir((L,C), (L1,C1)) :-
    L1 is L + 1,
    C1 is C + 1.
acao(mover_sup_dir,
    estado((L,C),Modo,Blocos,DC,DM,M), %estado atual
    estado((L1,C1),Modo,Blocos1,DC,DM,M1)) :- %estado resultante
    pos_destino((L,C),(L1,C1),diagonal_sup_dir),
    (  verde((L1,C1))
    -> atualiza_blocos(Modo,(L1,C1),Blocos,Blocos1)
    ; Blocos1 = Blocos
    ),
    %contagem de movimentos independe de ter alterado bloco ou nao
    M1 is M - 1,
    dbg('acao(mover_sup_dir): ~w,~w -> ~w,~w  M:~w->~w~n',[L,C,L1,C1,M,M1]).


acao(mover_inf_esq,
    estado((L,C),Modo,Blocos,DC,DM,M), %estado atual
    estado((L1,C1),Modo,Blocos1,DC,DM,M1)) :- %estado resultante
    pos_destino((L,C),(L1,C1),diagonal_inf_esq),
    (  verde((L1,C1))
    -> atualiza_blocos(Modo,(L1,C1),Blocos,Blocos1)
    ;Blocos1 = Blocos
    ),
    %contagem de movimentos independe de ter alterado bloco ou nao
    M1 is M - 1,
    dbg('acao(mover_inf_esq): ~w,~w -> ~w,~w  M:~w->~w~n',[L,C,L1,C1,M,M1]).


acao(mover_inf_dir,
    estado((L,C),Modo,Blocos,DC,DM,M), %estado atual
    estado((L1,C1),Modo,Blocos1,DC,DM,M1)) :- %estado resultante
    pos_destino((L,C),(L1,C1),diagonal_inf_dir),
    (  verde((L1,C1))
    -> atualiza_blocos(Modo,(L1,C1),Blocos,Blocos1)
    ;Blocos1 = Blocos
    ),
    %contagem de movimentos independe de ter alterado bloco ou nao
    M1 is M - 1,
    dbg('acao(mover_inf_dir): ~w,~w -> ~w,~w  M:~w->~w~n',[L,C,L1,C1,M,M1]).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PERDA / VITÓRIA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
perde(estado((L,C),_,_,_,_,_)) :- %Caso esteja num bloco vermelho então perde
    (    vermelho((L,C))
    ;   inimigo((L,C)) %Caso esteja na mesma posição que um inimigo então perde
    ),
    dbg('  [perde] caiu em ~w,~w~n', [L,C]).


% vitória: todas as verdes ligadas e M >= 0
todos_ligados(Blocos) :-
    findall(P, verde(P), Verdes),
    sort(Verdes, Vs),
    sort(Blocos, Bs),
    dbg('  [verdes] ~w~n', [Vs]),
    dbg('  [blocos] ~w~n', [Bs]),
    Vs = Bs.
    
vence(estado(_,_,Blocos,_,_,M)) :-
    todos_ligados(Blocos),
    M >= 0,
    dbg('  [vence] todos os blocos ligados com M >= 0 ~w~n', [M]).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BUSCA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
consegue(EstadoFinal) :- %tenta achar algum EstadoFinal que seja vencedor partindo do EstadoInicial
    inicio(EstadoInicial),
    caminho(EstadoInicial,EstadoFinal).

%caso base: se o estado atual é vencedor, então o caminho termina aqui
caminho(Estado,Estado) :- vence(Estado). 

% passo recursivo: só expande se ainda tem movimentos
caminho(Estado1,EstadoFinal) :- %busca recursiva de caminho entre Estado1 e EstadoFinal
    acao(_,Estado1,Estado2), %se existe uma ação que leva do Estado1 ao Estado2
    \+ perde(Estado2), % e essa ação não causa perda
    caminho(Estado2,EstadoFinal).%tenta recursivamente achar um caminho do Estado2 ao EstadoFinal até chegar caso base
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% UTILIDADE: mostrar estado bonitinho
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
show_estado(estado((L,C),Modo,Blocos,DC,DM,M)) :-
    format('Pos: (~w,~w)  Modo: ~w  DC: ~w  DM: ~w  M: ~w~n', [L,C,Modo,DC,DM,M]),
    sort(Blocos, Bs), format('Ligados: ~w~n', [Bs]).


