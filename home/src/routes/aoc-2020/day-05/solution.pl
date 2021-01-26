search([], _, _, R, R, R).
% Lower Character, Upper Character, Lower bound, Upper bound
search([X|Xs], LC, UC, L, U, ID):-
    X = LC,
    U2 is L + ((U - L) // 2),
    search(Xs, LC, UC, L, U2, ID).
search([X|Xs], LC, UC, L, U, ID):-
    X = UC,
    L2 is L + ((U - L) // 2) + 1,
    search(Xs, LC, UC, L2, U, ID).

:- string_chars("RRR", X), search(X, 'L', 'R', 0, 7, 7).
:- string_chars("RLL", X), search(X, 'L', 'R', 0, 7, 4).
:- string_chars("LLL", X), search(X, 'L', 'R', 0, 7, 0).

searchRow(X, ID):- search(X, 'F', 'B', 0, 127, ID).
searchColumn(X, ID):- search(X, 'L', 'R', 0, 7, ID).

decode(Pass, Seat):-
    string_chars(Pass, X),
    append(RowData, ColData, X),
    length(ColData, 3),
    searchRow(RowData, Row),
    searchColumn(ColData, Col),
    Seat is Row * 8 + Col.

:- decode("BFFFBBFRRR", 567).
:- decode("FFFBBBFRRR", 119).
:- decode("BBFFBBFRLL", 820).

main(Input, Output):-
    split_string(Input, '\n', '\n', Lines),
    maplist(decode, Lines, Decoded),
    max_list(Decoded, Output).

findSeat([A, B|_], Y):-
    B is A + 2,
    Y is A + 1.
findSeat([A, B|Xs], Y):-
    B is A + 1,
    findSeat([B|Xs], Y).

:- findSeat([1, 3], 2).
:- findSeat([1, 2, 4], 3).

main2(Input, Output):-
    split_string(Input, '\n', '\n', Lines),
    maplist(decode, Lines, Decoded),
    sort(Decoded, Sorted),
    findSeat(Sorted, Output).