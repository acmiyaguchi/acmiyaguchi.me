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


keys(["byr", "iyr", "eyr", "hgt", "hcl", "ecl", "pid"]).

is_valid_key(Key):-
    keys(Keys),
    member(Key, Keys).

is_valid(Entry):-
    pairs_keys(Entry, Keys),
    include(is_valid_key, Keys, ValidKeys),
    length(ValidKeys, Size),
    keys(MustInclude),
    length(MustInclude, Size).

split_entries(Input, Entries):-
    split_string(Input, '\n', '\s', Lines),
    parse_entries(Lines, [], Entries).

main(Input, Output):-
    split_entries(Input, Entries),
    include(is_valid, Entries, Valid),
    length(Valid, Output).

year_valid(Assoc, Key, Lower, Upper):-
    get_assoc(Key, Assoc, Data),
    atom_number(Data, Number),
    Number >= Lower,
    Number =< Upper.

check_height("cm", Data):- Data >= 150, Data =< 193.
check_height("in", Data):- Data >= 59, Data =< 76.

height_valid(Assoc) :-
    get_assoc("hgt", Assoc, Data),
    string_chars(Data, Chars),
    % this can't be the most efficient way, can it?
    append(NumberChars, [X,Y], Chars),
    string_chars(Unit, [X,Y]),
    string_chars(NumberString, NumberChars),
    atom_number(NumberString, Number),
    check_height(Unit, Number).

valid_color_codes(Char):-
    char_code(Char, Code),
    char_code('0', LowerDigit),
    char_code('9', UpperDigit),
    char_code('a', LowerAlpha),
    char_code('f', UpperAlpha),
    (
    	Code >= LowerDigit,
    	Code =< UpperDigit
    ;
    	Code >= LowerAlpha,
        Code =< UpperAlpha
    ).

hair_color_valid(Assoc):-
	get_assoc("hcl", Assoc, Data),
    string_chars(Data, ['#'|Chars]),
    length(Chars, 6),
    include(valid_color_codes, Chars, ValidChars),
    length(ValidChars, 6).

eye_color(["amb", "blu", "brn", "gry", "grn", "hzl", "oth"]).
eye_color_valid(Assoc):-
	get_assoc("ecl", Assoc, Data),
    eye_color(Color),
    member(Data, Color).

pid_valid(Assoc):-
    get_assoc("pid", Assoc, Data),
    string_chars(Data, Chars),
    length(Chars, 9),
    maplist(atom_number, Chars, _).

% what a lengthy puzzle
is_data_valid(Entry):-
    list_to_assoc(Entry, Assoc),
    year_valid(Assoc, "byr", 1920, 2002),
    year_valid(Assoc, "iyr", 2010, 2020),
    year_valid(Assoc, "eyr", 2020, 2030),
    height_valid(Assoc),
    hair_color_valid(Assoc),
    eye_color_valid(Assoc),
    pid_valid(Assoc).

% some simple test cases, not comprehensive
hcl(Data):-
    list_to_assoc(["hcl"-Data], Assoc),
    hair_color_valid(Assoc).
ecl(Data):-
    list_to_assoc(["ecl"-Data], Assoc),
    eye_color_valid(Assoc).
pid(Data):-
    list_to_assoc(["pid"-Data], Assoc),
    pid_valid(Assoc).

:- hcl("#123abc").
:- \+ hcl("#123abz").
:- \+ hcl("123abc").
:- ecl("brn").
:- \+ ecl("wat").
:- pid("000000001").
:- \+ pid("0123456789").

main2(Input, Output):-
    split_entries(Input, Entries),
    include(is_valid, Entries, ValidEntries),
    include(is_data_valid, ValidEntries, ValidDataEntries),
    length(ValidDataEntries, Output).
