% test case for split_entries/2
test_a(X):-
    X = "a:b
         e:f
    
c:d".

sample(X):-
    X = "ecl:gry pid:860033327 eyr:2020 hcl:#fffffd
byr:1937 iyr:2017 cid:147 hgt:183cm

iyr:2013 ecl:amb cid:350 eyr:2023 pid:028048884
hcl:#cfa07d byr:1929

hcl:#ae17e1 iyr:2013
eyr:2024
ecl:brn pid:760753108 byr:1931
hgt:179cm

hcl:#cfa07d eyr:2025 pid:166559648
iyr:2011 ecl:brn hgt:59in".

to_dict(Item, K-V):-
    split_string(Item, ':', ':', [K,V]).

parse_entries([], [], []).
parse_entries([], Acc, [Acc]).
parse_entries([Head|Tail], Acc, [Acc|Results]):-
    % confused on how this predicate works
    normalize_space(atom(Normed), Head),
    Normed = '',
    parse_entries(Tail, [], Results).
parse_entries([Head|Tail], Acc, Results):-
    split_string(Head, '\s', '\s', Entries),
    maplist(to_dict, Entries, Parsed),
    append(Acc, Parsed, NewAcc),
    parse_entries(Tail, NewAcc, Results). 


split_entries(Input, Entries):-
    split_string(Input, '\n', '\s', Lines),
    parse_entries(Lines, [], Entries).
