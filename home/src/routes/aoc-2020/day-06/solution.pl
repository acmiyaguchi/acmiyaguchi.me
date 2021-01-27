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
% however, it needs an extra rule when the intitial set is null, and
% we need to differentiate between the first and last intersection in a set
process2([], _, X, [X]).
process2([H|T], 0, [], Res):-
    string_chars(H, Items),
    process2(T, 1, Items, Res).
process2([""|T], _, X, [X|Res]):-
    process2(T, 0, [], Res).
process2([H|T], C, Acc, Res):-
    string_chars(H, Items),
    intersection(Items, Acc, Acc2),
    C2 is C + 1,
    process2(T, C2, Acc2, Res).

main2(Input, Output):-
    split_string(Input, '\n', '\s', Lines),
    process2(Lines, 0, [], Groups),
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