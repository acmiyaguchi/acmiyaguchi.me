process([], X, [X]).
process([""|T], X, [X|Res]):-
    process(T, [], Res).
process([H|T], Acc, Res):-
    string_chars(H, Items),
    union(Items, Acc, Acc2),
    process(T, Acc2, Res).

main(Input, Output):-
    split_string(Input, '\n', '\s', Lines),
    process(Lines,[], Groups),
    maplist(length, Groups, Counts),
    sumlist(Counts, Output).

% the same as process, except an intersection instead of union
process2([], X, [X]).
process2([""|T], X, [X|Res]):-
    process2(T, [], Res).
% however, it needs an extra rule when the intitial set is null
process2([H|T], [], Res):-
    string_chars(H, Items),
    process2(T, Items, Res).
process2([H|T], Acc, Res):-
    string_chars(H, Items),
    intersection(Items, Acc, Acc2),
    process2(T, Acc2, Res).

main2(Input, Output):-
    split_string(Input, '\n', '\s', Lines),
    process2(Lines,[], Groups),
    maplist(length, Groups, Counts),
    sumlist(Counts, Output).

sample("abc

a
b
c

ab
ac

a
a
a
a

b").