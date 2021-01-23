% https://stackoverflow.com/a/46902736
count(_, [], 0).
count(C, [C|T], N):-
    count(C, T, Res),
    N is Res+1.
count(C, [X|T], N):-
    C \= X,
    count(C, T, N).
    
parse(String, Data):-
    split_string(String, '\s', '\s', [MinMax, CharColon, Password]),
    term_string(Min-Max, MinMax),
    % remove the colon in the data
    string_chars(CharColon, [Char|_]),
    Data = (Min, Max, Char, Password).

verify(String):-
    parse(String, (Min, Max, Char, Password)),
    string_chars(Password, Chars),
    count(Char, Chars, N),
    N >= Min,
    N =< Max.

main(String, Result):-
    split_string(String, '\n', '\n', L),
    include(verify, L, Verified),
    length(Verified, Result).

verify2(String):-
    parse(String, (Min, Max, Char, Password)),
    string_chars(Password, Chars),
    nth1(Min, Chars, Pos0),
    nth1(Max, Chars, Pos1),
    Pos0 \= Pos1,
    (   Pos0 = Char, Pos1 \= Char;
       Pos0 \= Char, Pos1 = Char).

main2(String, Result):-
    split_string(String, '\n', '\n', L),
    include(verify2, L, Verified),
    length(Verified, Result).

    
sample(X):-
    X = "1-3 a: abcde
1-3 b: cdefg
2-9 c: ccccccccc".