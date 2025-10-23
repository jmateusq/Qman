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

estado(_PosQbert, _Modo, _Blocos, _DiscoC, _DiscoM, _MovimentosRestantes, _InimigosMortos).
% INICIO DO JOGO
inicio(estado((2,h), normal, [], ativo, ativo, 50, [])).


resolve_unica(EstadoFinal) :-
    once(consegue(EstadoFinal)).

mknode(Pos, Modo, Blocos, DC, DM, M, InimigosMortos,
       estado(Pos, Modo, Blocos, DC, DM, M, InimigosMortos)).

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
% ATUALIZAÇÃO DE BLOCOS (só mexe em Blocos)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% atualiza_blocos(+Modo, +Pos, +BlocosIn, -BlocosOut)
% (Modo por enquanto não altera a regra; fácil estender depois)
atualiza_blocos(Modo, Pos, BlocosIn, BlocosOut):-
    (   Modo = normal
    ->  % comportamento original: liga o bloco se ainda não estiver ligado
        ( member(Pos, BlocosIn)
        -> BlocosOut = BlocosIn
        ;  BlocosOut = [Pos|BlocosIn]
        )
    ;   Modo = poder
    ->  % modo poder: desliga o bloco (remove Pos da lista)
        delete(BlocosIn, Pos, BlocosOut)
    ;   % modo desconhecido (fallback)
        BlocosOut = BlocosIn
    ),
    dbg('   [atualiza_blocos] (~w) Pos ~w -> ~w~n', [Modo, Pos, BlocosOut]).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DIAGONAIS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
diagonal_sup_esq((L,C), (L1,C1)) :- L1 is L - 1, col_esq(C, C1).
diagonal_sup_dir((L,C), (L1,C1)) :- L1 is L - 1, col_dir(C, C1).
diagonal_inf_esq((L,C), (L1,C1)) :- L1 is L + 1, col_esq(C, C1).
diagonal_inf_dir((L,C), (L1,C1)) :- L1 is L + 1, col_dir(C, C1).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% AÇÕES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% helper: aplica atualização condicional se destino for acessivel
pos_destino((L,C), (L1,C1), PredDiag) :- 
    call(PredDiag, (L,C), (L1,C1)),
    \+ inacessivel((L1,C1)).

% usar DISCO ao subir pela esquerda, quando em (5,C) e DC ativo
acao(mover_sup_esq,
    estado((6,d), Modo, Blocos, DC, DM, M,Mortos),
    estado((2,h), Modo1, Blocos1, DC1, DM, M1,Mortos)) :-
    (  Modo = normal
    -> Modo1 = poder
    ;  Modo1 = normal 
    ),
    dbg('dc ~w~n', [DC]),
    (   DC = ativo
    ->  DC1 = usado
    ;   fail
    ),
    atualiza_blocos(Modo,(2,h),Blocos,Blocos1),
    M1 is M - 1,
    dbg('acao(mover_sup_esq/disco C): 5,c -> 2,h  M:~w->~w~n', [M,M1]).


% usar DISCO ao subir pela direita, quando em (5,M) e DM ativo
acao(mover_sup_dir,
     estado((6,l), Modo, Blocos, DC, DM, M, Mortos),
     estado((2,h), Modo1, Blocos1, DC, DM1, M1,Mortos)) :-
    (  Modo = normal
    -> Modo1 = poder
    ;  Modo1 = normal
    ),
    (   DM = ativo
    ->  DM1 = usado
    ;   fail
    ),
    atualiza_blocos(Modo,(2,h),Blocos,Blocos1),
    M1 is M - 1,
    dbg('acao(mover_sup_dir/disco M): 5,m -> 2,h  M:~w->~w~n', [M,M1]).

acao(mover_sup_esq, %nome da ação Geral
    estado((L,C),Modo,Blocos,DC,DM,M,Mortos) , %estado atual
    estado((L1,C1),Modo,Blocos1,DC,DM,M1,Mortos)) :- %estado resultante
    \+ ((L,C) = (6,d) ; (L,C) = (6,l)), % evita conflito com uso de disco 
    pos_destino((L,C),(L1,C1),diagonal_sup_esq),
    mata_inimigo_if_poder(Modo, (L1,C1), Mortos, Mortos), %atualiza lista de inimigos mortos se estiver em modo poder
    (perde(estado((L1,C1),Modo,Blocos,DC,DM,M,Mortos)) -> fail ; true),
    (  verde((L1,C1))
    -> atualiza_blocos(Modo,(L1,C1),Blocos,Blocos1)
    ; Blocos1 = Blocos
    ),
    M1 is M - 1,
    dbg('acao(mover_sup_esq): ~w,~w -> ~w,~w  M:~w->~w~n',[L,C,L1,C1,M,M1]).

acao(mover_sup_dir,
    estado((L,C),Modo,Blocos,DC,DM,M,Mortos), %estado atual
    estado((L1,C1),Modo,Blocos1,DC,DM,M1,Mortos1)) :- %estado resultante
    pos_destino((L,C),(L1,C1),diagonal_sup_dir),
    dbg('Mortos antes ~w~n',[Mortos]),
    mata_inimigo_if_poder(Modo, (L1,C1), Mortos, Mortos1), %atualiza lista de inimigos mortos se estiver em modo poder
    dbg('Mortos depois ~w~n',[Mortos1]),
    (perde(estado((L1,C1),Modo,Blocos,DC,DM,M,Mortos1)) -> fail ; true),
    (  verde((L1,C1))
    -> atualiza_blocos(Modo,(L1,C1),Blocos,Blocos1)
    ; Blocos1 = Blocos
    ),
    %contagem de movimentos independe de ter alterado bloco ou nao
    M1 is M - 1,
    dbg('acao(mover_sup_dir): ~w,~w -> ~w,~w  M:~w->~w~n',[L,C,L1,C1,M,M1]).


acao(mover_inf_esq,
    estado((L,C),Modo,Blocos,DC,DM,M,Mortos), %estado atual
    estado((L1,C1),Modo,Blocos1,DC,DM,M1,Mortos)) :- %estado resultante
    pos_destino((L,C),(L1,C1),diagonal_inf_esq),
    mata_inimigo_if_poder(Modo, (L1,C1), Mortos, Mortos), %atualiza lista de inimigos mortos se estiver em modo poder
    (perde(estado((L1,C1),Modo,Blocos,DC,DM,M,Mortos)) -> fail ; true),
    (  verde((L1,C1))
    -> atualiza_blocos(Modo,(L1,C1),Blocos,Blocos1)
    ;Blocos1 = Blocos
    ),
    %contagem de movimentos independe de ter alterado bloco ou nao
    M1 is M - 1,
    dbg('acao(mover_inf_esq): ~w,~w -> ~w,~w  M:~w->~w~n',[L,C,L1,C1,M,M1]).


acao(mover_inf_dir,
    estado((L,C),Modo,Blocos,DC,DM,M,Mortos), %estado atual
    estado((L1,C1),Modo,Blocos1,DC,DM,M1,Mortos)) :- %estado resultante
    pos_destino((L,C),(L1,C1),diagonal_inf_dir),
    mata_inimigo_if_poder(Modo, (L1,C1), Mortos, Mortos), %atualiza lista de inimigos mortos se estiver em modo poder
    (perde(estado((L1,C1),Modo,Blocos,DC,DM,M,Mortos)) -> fail ; true),
    (  verde((L1,C1))
    -> atualiza_blocos(Modo,(L1,C1),Blocos,Blocos1)
    ;Blocos1 = Blocos
    ),
    %contagem de movimentos independe de ter alterado bloco ou nao
    M1 is M - 1,
    dbg('acao(mover_inf_dir): ~w,~w -> ~w,~w  M:~w->~w~n',[L,C,L1,C1,M,M1]).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PERDA / VITÓRIA
perde(estado((L,C),_,_,_,_,_,Mortos)) :-
    (   vermelho((L,C))
    ->  dbg('  [perde] caiu em ~w,~w~n', [L,C])
    ;   (   inimigo((L,C)), \+ member((L,C), Mortos)
        ->  dbg('  [perde] inimigo em ~w,~w não está morto~n', [L,C])
        ;   fail
        )
    ).


% vitória: todas as verdes ligadas e M >= 0
todos_ligados(Blocos) :-
    findall(P, verde(P), Verdes),
    sort(Verdes, Vs),
    sort(Blocos, Bs),
    Vs = Bs.
    
vence(estado(_,_,Blocos,_,_,M,_)) :-
    todos_ligados(Blocos),
    M >= 0,
    dbg('  [vence] todos os blocos ligados com M >= 0 ~w~n', [M]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BUSCA (revisada)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Resolve encontrando um estado final vitorioso a partir do estado inicial
consegue(EstadoFinal) :-
    inicio(EstadoInicial),
    caminho(EstadoInicial, [EstadoInicial], EstadoFinal).

% Caso base: chegou num estado vencedor
caminho(Estado, _, Estado) :-
    vence(Estado),
    !.  % corta aqui — evita continuar procurando outras soluções redundantes

% Passo recursivo: busca em profundidade
caminho(Estado1, Visitados, EstadoFinal) :-
    Estado1 = estado(_,_,_,_,_,M,_),
    M > 0,  % ainda há movimentos disponíveis
    acao(_, Estado1, Estado2),  % gera próximo estado possível
    \+ member(Estado2, Visitados),  % evita ciclos
    \+ perde(Estado2),  % não entra em estados perdedores
    caminho(Estado2, [Estado2 | Visitados], EstadoFinal).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MORTE AOS INIMIGOS E VIVA A REVOLUÇÃO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

adiciona_morto(Pos, MortosIn, MortosOut) :-
    (   member(Pos, MortosIn) -> MortosOut = MortosIn
    ;   MortosOut = [Pos|MortosIn]
    ).

mata_inimigo_if_poder(Modo, Pos, MortosIn, MortosOut) :-
    (   Modo = poder,
        inimigo(Pos)
    ->  adiciona_morto(Pos, MortosIn, MortosOut),
        dbg('  [poder] inimigo em ~w removido~n', [Pos])
    ;   MortosOut = MortosIn
    ).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% UTILIDADE: mostrar estado bonitinho
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
show_estado(estado((L,C),Modo,Blocos,DC,DM,M,Mortos)) :-
    format('Pos: (~w,~w)  Modo: ~w  DC: ~w  DM: ~w  M: ~w~n, Mortos: ~w~n', [L,C,Modo,DC,DM,M,Mortos]),
    sort(Blocos, Bs), format('Ligados: ~w~n', [Bs]).


