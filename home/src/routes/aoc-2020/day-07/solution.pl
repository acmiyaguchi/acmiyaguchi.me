sample("light red bags contain 1 bright white bag, 2 muted yellow bags.
dark orange bags contain 3 bright white bags, 4 muted yellow bags.
bright white bags contain 1 shiny gold bag.
muted yellow bags contain 2 shiny gold bags, 9 faded blue bags.
shiny gold bags contain 1 dark olive bag, 2 vibrant plum bags.
dark olive bags contain 3 faded blue bags, 4 dotted black bags.
vibrant plum bags contain 5 faded blue bags, 6 dotted black bags.
faded blue bags contain no other bags.
dotted black bags contain no other bags.").

is_bag(X):- string_chars(X, ['b', 'a', 'g'|_]).

% create list of key value pairs
parsed_rules([], Key, Value, [Key-Value]).
% first case
parsed_rules([X|R], _, -1, Res):-
    atom_number(X, Value),
    parsed_rules(R, "", Value, Res).
parsed_rules([X|R], Key, Value, [Key-Value|Res]):-
    atom_number(X, Value2),
    parsed_rules(R, "", Value2, Res).
parsed_rules([X|R], "", Value, Res):-
    parsed_rules(R, X, Value, Res).
parsed_rules([X|R], Key, Value, Res):-
    atomic_list_concat([Key, X], ' ', NewKey),
    parsed_rules(R, NewKey, Value, Res).

% test
:- split_string("1 bright red 2 muted yellow", '\s', '\s', X),
parsed_rules(X, "", -1, Y),
list_to_assoc(Y, Z),
assoc_to_keys(Z, ['bright red', 'muted yellow']).

parse_line(Input, Key-Values):-
    split_string(Input, '\s', '\s,.', Words),
    % remove bags from the inputs
    exclude(is_bag, Words, FilteredWords),
    append(X, ["contain"|Y], FilteredWords),
    atomic_list_concat(X, ' ', Key),
    parsed_rules(Y, "", -1, Values).

:- sample(X),
split_string(X, '\n', '\n', [Y|_]),
parse_line(Y, 'light red' - ['bright white' - 1, 'muted yellow' - 2]).
