cast_int([X], [Y]) :- atom_number(X, Y).
cast_int([X|XS], [Y|YS]):-
    atom_number(X, Y),
    cast_int(XS, YS).

main(Input, Answer):-
    split_string(Input, "\n", "\n", L),
    cast_int(L, Casted),
    append([_, [X], _, [Y], _], Casted),
    2020 is X+Y,
    Answer is X*Y.

main2(Input, Answer):-
    split_string(Input, "\n", "\n", L),
    cast_int(L, Casted),
    append([_,[X],_,[Y],_,[Z],_], Casted),
    2020 is X+Y+Z,
    Answer is X*Y*Z.

sample(X):-
    X = "1721
979
366
299
675
1456".