sample(X):-
    X = "..##.......
#...#...#..
.#....#..#.
..#.#...#.#
.#...##..#.
..#.##.....
.#.#.#....#
.#........#
#.##...#...
#...##....#
.#..#...#.#".

atPos(String, Counter, Char):-
    string_chars(String, Chars),
    length(Chars, Modulus),
    % 3 right, 1 down
    Index is mod(Counter*3, Modulus),
    nth0(Index, Chars, Char).

isTree([], _, X, X).
isTree([X|Xs], Counter, Acc, Result):-
    atPos(X, Counter, Char),
    Char \= '#',
    C1 is Counter + 1,
    isTree(Xs, C1, Acc, Result).
isTree([X|Xs], Counter, Acc, Result):-
    atPos(X, Counter, Char),
    Char = '#',
    C1 is Counter + 1,
    A1 is Acc + 1,
    isTree(Xs, C1, A1, Result).

main(Input, Result):-
    split_string(Input, '\n', '\n', L),
    isTree(L, 0, 0, Result).

atPos2(String, Counter, Right, Char):-
    string_chars(String, Chars),
    length(Chars, Modulus),
    % make sure to take into account the slope
    Index is mod(Counter*Right, Modulus),
    nth0(Index, Chars, Char).

% This is necessary to traverse down the slope correclty
skipList(L, 0, L).
skipList([_], _, []).
skipList([_|Rest], Counter, Result):-
    C1 is Counter - 1,
    skipList(Rest, C1, Result).

isTree2([], _,_,_, X, X).
isTree2([X|Xs], Right, Down, Counter, Acc, Result):-
    atPos2(X, Counter, Right, Char),
    skipList([X|Xs], Down, Xss),
    C1 is Counter + 1,
    (   Char = '#' ->
    	A1 is Acc + 1;
    	A1 is Acc
    ),
    isTree2(Xss, Right, Down, C1, A1, Result).

main2(Input, Result):-
    split_string(Input, '\n', '\n', L),
    isTree2(L, 1, 1, 0, 0, A),
    isTree2(L, 3, 1, 0, 0, B),
    isTree2(L, 5, 1, 0, 0, C),
    isTree2(L, 7, 1, 0, 0, D),
    isTree2(L, 1, 2, 0, 0, E),
    Result is A*B*C*D*E.
