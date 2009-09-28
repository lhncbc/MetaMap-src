/* qp_lexicon.pl - all lexicon-related predicates.
*/

/*
    Some general comments regarding predicate names:

    - All retrieval predicates start with the prefix "lex_"
    - After that comes one of "cit|root|form".  This specifies
      whether the search is done for a citation form, a root form
      (lexical base) or any form in the lexicon resp.
    - After that comes "cs|ci" meaning case sensitive or
      case insensitive search.
    - Finally comes "recs|vars|cats" for retrieval of records,
      variants, categories etc.

    All predicates have matching predicates with smaller arity
    for which the lexicon and index default to the standard.
*/

:- module(qp_lexicon, [
	% lexicon searches with return lists
	lex_form_ci_recs/2,	% lexical form, case insensitive
	lex_form_ci_cats/2,	% lexical item, case insensitive, returns cats
	lex_cit_ci_vars/2,	% citation form, case insensitive, returns variants
	lex_form_ci_vars/2,	% lexical item, case insensitive, returns variants
	lex_form_ci_var_lists_4/4,
	% simple queries
	lex_is_a_root_ci/1,	% root form, case insensitive
	lex_is_a_root_ci_cats/2,
	lex_is_a_form_ci/1,	% lexical form, case insensitive

	% for use from the parser
	lex_form_ci_recs_input_5/5,
	% general
        lex_init/2,
	default_lexicon_file/1,
	default_index_file/1,
	use_multi_word_lexicon/0
    ]).

:- use_module(lexicon(qp_fm_lexrec), [
	fm_lexical_record/3
   ]).

:- use_module(lexicon(qp_recio), [
	read_lex_record/3
   ]).

:- use_module(skr_lib(nls_system), [
	control_option/1
   ]).

:- use_module(skr_lib(sicstus_utils), [
	concat_atoms/2
   ]).

:- dynamic lexicon_type/1.

:- use_module(library(file_systems), [
	file_exists/1,
	file_exists/2
   ]).

:- use_module(library(lists), [
	rev/2,
	append/2
   ]).

:- use_module(library(system), [
	environ/2
   ]).

:- dynamic default_lexicon_file/1.
:- dynamic default_index_file/1.
:- dynamic lexicon_files/2.

%%% Define the foreign interface
foreign_resource(qp_lexicon, [
	c_lex_cit, c_lex_root, c_lex_form,
	c_lex_cit_cats, c_lex_root_cats, c_lex_form_cats,
	c_lex_is_a_root, c_lex_is_a_form,
	c_lex_is_a_root_cats,
	c_lex_form_input,
	c_get_varlist
    ]).


foreign(c_lex_cit,            c,
	c_lex_cit(+string, +string, +integer, +integer, +integer, -term, [-integer])).

foreign(c_lex_root,           c,
	c_lex_root(+string, +string, +integer, +integer, +integer, -term, [-integer])).

foreign(c_lex_form,           c,
	c_lex_form(+string, +string, +integer, +integer, +integer, -term, [-integer])).

foreign(c_lex_cit_cats,       c,
	c_lex_cit_cats(+string, +string, +integer, +integer, -term, [-integer])).

foreign(c_lex_root_cats,      c,
	c_lex_root_cats(+string, +string, +integer, +integer, -term, [-integer])).

foreign(c_lex_form_cats,      c,
	c_lex_form_cats(+string, +string, +integer, +integer, -term, [-integer])).

foreign(c_lex_is_a_root,      c,
	c_lex_is_a_root(+string, +string, +integer, +integer, [-integer])).

foreign(c_lex_is_a_form,      c,
	c_lex_is_a_form(+string, +string, +integer, +integer, [-integer])).

foreign(c_lex_is_a_root_cats, c,
	c_lex_is_a_root_cats(+string, +string, +integer, +integer, +term, [-integer])).

foreign(c_lex_form_input,     c,
	c_lex_form_input(+string, +integer, +term, -term, [-integer])).

foreign(c_get_varlist,        c,
	c_get_varlist(+string, +integer, -term, [-integer])).

:- load_foreign_resource(qp_lexicon).

% :- abolish(foreign_resource/2, [force(true)]).

% :- abolish(foreign/3, [force(true)]).

%% See WARNING below.

%%%default_lexicon_file('/nfsvol/nls/umls/releases/1995_release/LEX/DATA/LEXU/lexicon').
%%%default_index_file('/nfsvol/nls/umls/releases/1995_release/LEX/DATA/LEXU/lexicon.index').

%%%default_lexicon_file('/nfsvol/nls/umls/releases/1996_release/LEX/lexicon96').
%%%default_index_file('/nfsvol/nls/umls/releases/1996_release/LEX/lexicon96.index').

%%%default_lexicon_file('/net/cgsb2/aux3/nls/kss/umls/releases/1996_releaseA/lex/lexicon96a').
%%%default_index_file('/net/cgsb2/aux3/nls/kss/umls/releases/1996_releaseA/lex/lexicon96a.index').

%%%default_lexicon_file('/nfsvol/nls2pub/nls/specialist/lexicon/lookup/query/tst/lex98.records').
%%%default_index_file('/nfsvol/nls2pub/nls/specialist/lexicon/lookup/query/tst/lex98.index').

%%%default_lexicon_file('/nfsvol/nls/specialist/lexicon98/query/tst/lex98.records').
%%%default_index_file('/nfsvol/nls/specialist/lexicon98/query/tst/lex98.index').

%%% lex_init(-Lexicon, -Index)
%%% This predicate will return the names of the default location of the lexicon files
lex_init(Lexicon, Index) :-
	lexicon_files(Lexicon,Index),
	!.  % already initialized
lex_init(Lexicon, Index) :-
	lex_init_quietly(Lexicon, Index),
	conditionally_announce_lexicon(Lexicon).

lex_init_quietly(Lexicon, Index) :-
	lexicon_files(Lexicon,Index),
	!.  % already initialized
lex_init_quietly(Lexicon, Index) :-
	environ('DEFAULT_LEXICON_FILE', Lexicon),
	check_valid_lexicon_file(Lexicon),
	environ('DEFAULT_LEXICON_INDEX_FILE', Index),
	concat_atoms([Index, 'ByEui.dbx'], EuiIndexFile),
	check_valid_lexicon_file(EuiIndexFile),
	concat_atoms([Index, 'ByInfl.dbx'], InflIndexFile),
	check_valid_lexicon_file(InflIndexFile),
	retractall(default_lexicon_file(_)),
	assert(default_lexicon_file(Lexicon)),
	retractall(default_index_file(_)),
	assert(default_index_file(Index)),
	retractall(lexicon_files(_,_)),
	assert(lexicon_files(Lexicon,Index)).


conditionally_announce_lexicon(Lexicon) :-
	( \+ control_option(no_header_info) ->
	  format('Accessing lexicon ~a.~n', [Lexicon])
	; true
	).


check_valid_lexicon_file(File) :-
	current_output(OutputStream),
	( \+ file_exists(File) ->
	  % don't duplicate ERROR message if current output is user_output!
	  ( OutputStream \== user_output ->
	    format('~n~*c~nERROR: Lexicon file~n~w~ndoes not exist. Aborting.~n~*c~n~n',
		   [80,35,File,80,35])
	  ; true
	  ),
	  format(user_output,
		 '~n~*c~nERROR: Lexicon file~n~w~ndoes not exist. Aborting.~n~*c~n~n',
		 [80,35,File,80,35]),
	  abort
	; \+ file_exists(File, read) ->
	  % don't duplicate ERROR message if current output is user_output!
	  ( OutputStream \== user_output ->
	    format('~n~*c~nERROR: Lexicon file~n~w~nis not not readable. Aborting.~n~*c~n~n',
		   [80,35,File,80,35])
	  ; true
	  ),
	  format(user_output,
		 '~n~*c~nERROR: Lexicon file~n~w~nis not not readable. Aborting.~n~*c~n~n',
		 [80,35,File,80,35]),
	  abort
	; true
	).

%%% Retrieve records given root form

%%% lex_form_ci_recs(+Form, -Rec)
lex_form_ci_recs(Form, Rec) :-
	default_lexicon_file(Lexicon),
	default_index_file(Index),
	lex_recs(form, Form, Rec, 1, 0, Lexicon, Index).

%%% Retrieves category given root form

%%% lex_form_ci_cats(+Form, -Cats)
lex_form_ci_cats(Form, Cats) :-
	default_index_file(Index),
	lex_cats(form, Form, Cats, 1, Index).

%%% Retrieves inflectional variant info for a citation form

%%% lex_cit_ci_vars(+Cit, -Vars)
lex_cit_ci_vars(Cit, Vars) :-
	default_lexicon_file(Lexicon),
	default_index_file(Index),
	lex_vars(cit, Cit, Vars, 1, Lexicon, Index).

%%% Retrieves inflectional variant info for a lexical item

%%% lex_form_ci_vars(+Form, -Vars)
lex_form_ci_vars(Form, Vars) :-
	default_lexicon_file(Lexicon),
	default_index_file(Index),
	lex_vars(form, Form, Vars, 1, Lexicon, Index).

lex_form_ci_var_lists_4(Form, VarLists, Lexicon, Index) :-
        lex_var_lists(form, Form, VarLists, 1, Lexicon, Index).

%%% generic record retrieval predicate
lex_recs(cit, Cit, Rec, LowerFlag, FlushFlag, Lexicon, Index) :-
	LexiconType = 0,
	c_lex_cit(Index, Cit, LexiconType, LowerFlag, FlushFlag, OfsList, 1),
	sort(OfsList, SortedOfsList),
	get_records_from_offsets(SortedOfsList, Rec, Lexicon).
lex_recs(root, Root, Rec, LowerFlag, FlushFlag, Lexicon, Index) :-
	LexiconType = 0,
	c_lex_root(Index, Root, LexiconType, LowerFlag, FlushFlag, OfsList, 1),
	sort(OfsList, SortedOfsList),
	get_records_from_offsets(SortedOfsList, Rec, Lexicon).
lex_recs(form, Form, Rec, LowerFlag, FlushFlag, Lexicon, Index) :-
	LexiconType = 0,
	c_lex_form(Index, Form, LexiconType, LowerFlag, FlushFlag, OfsList, 1),
	sort(OfsList, SortedOfsList),
	get_records_from_offsets(SortedOfsList, Rec, Lexicon).

%%% generic category retrieval predicate
lex_cats(cit, Cit, Cats, LowerFlag, Index) :-
	lexicon_type(LexiconType),
	% LexiconType = 0,
	c_lex_cit_cats(Index, Cit, LexiconType, LowerFlag, Cats, 1).
lex_cats(root, Root, Cats, LowerFlag, Index) :-
	lexicon_type(LexiconType),
	% LexiconType = 0,
	c_lex_root_cats(Index, Root, LexiconType, LowerFlag, Cats, 1).
lex_cats(form, Form, Cats, LowerFlag, Index) :-
	lexicon_type(LexiconType),
	% LexiconType = 0,
	c_lex_form_cats(Index, Form, LexiconType, LowerFlag, Cats, 1).

%%% generic variant retrieval predicate
lex_vars(cit, Cit, Vars, LowerFlag, Lexicon, Index) :-
	LexiconType = 0,
	c_lex_cit(Index, Cit, LexiconType, LowerFlag, 0, OfsList, 1),
	sort(OfsList, SortedOfsList),
	lex_vars_aux(SortedOfsList, Vars, Lexicon).
lex_vars(root, Root, Vars, LowerFlag, Lexicon, Index) :-
	LexiconType = 0,
	c_lex_root(Index, Root, LexiconType, LowerFlag, 0, OfsList, 1),
	sort(OfsList, SortedOfsList),
	lex_vars_aux(SortedOfsList, Vars, Lexicon).
lex_vars(form, Form, Vars, LowerFlag, Lexicon, Index) :-
	LexiconType = 0,
	c_lex_form(Index, Form, LexiconType, LowerFlag, 0, OfsList, 1),
	sort(OfsList, SortedOfsList),
	lex_vars_aux(SortedOfsList, Vars, Lexicon).

%%% auxiliary
lex_vars_aux(OfsList, Vars, Lexicon) :-
	findall(V,
	       (member(Ofs, OfsList), c_get_varlist(Lexicon, Ofs, V, 1)),
	       Vs),
	flatten(Vs, FVs),
	reformat_list(FVs, RFVs),
	sort(RFVs, Vars).

%%% generic variant retrieval predicate
%%% LRA
lex_var_lists(form, Form, VarLists, LowerFlag, Lexicon, Index) :-
	lexicon_type(LexiconType),
	c_lex_form(Index, Form, LexiconType, LowerFlag, 0, OfsList, 1),
	sort(OfsList, SortedOfsList),
	lex_var_lists_aux(SortedOfsList, VarLists, Lexicon).

%%% auxiliary
lex_var_lists_aux([],[],_).
lex_var_lists_aux([Ofs|Rest],[V|RestV],Lexicon) :-
	c_get_varlist(Lexicon,Ofs,V0,1),
	reformat_list(V0,V1),
	sort(V1,V),
	lex_var_lists_aux(Rest,RestV,Lexicon).

/* Simple queries */

%%% lex_is_a_root_ci(+Root)
%%% Queries for a root form.
lex_is_a_root_ci(Root) :-
	default_index_file(Index),
	lex_is_a_root_ci_2(Root, Index).

lex_is_a_root_ci_2(Root, Index) :-
	lexicon_type(LexiconType),
	c_lex_is_a_root(Index, Root, LexiconType, 1, 1).

%%% lex_is_a_form_ci(+Form)
%%% Queries for a lexical item.
lex_is_a_form_ci(Form) :-
	default_index_file(Index),
	lex_is_a_form_ci_2(Form, Index).

lex_is_a_form_ci_2(Form, Index) :-
	lexicon_type(LexiconType),
	c_lex_is_a_form(Index, Form, LexiconType, 1, 1).

%%% lex_is_a_root_ci_cats(+Root, +Cats)
%%% succeeds if +Root is a root form in any category in +Cats
lex_is_a_root_ci_cats(Root, Cats) :-
	default_index_file(Index),
	lex_is_a_root_ci_cats_3(Root, Cats, Index).

lex_is_a_root_ci_cats_3(Root, Cats, Index) :-
	lexicon_type(LexiconType),
	c_lex_is_a_root_cats(Index, Root, LexiconType, 1, Cats, 1).

%%% This is for retrieval of records with sensitivity to input context
%%% for use from a parser.
%%% lex_form_ci_recs_input(+Input, -Recs, -Remaining)
lex_form_ci_recs_input_5(Input, Recs, Remaining, Lexicon, Index) :-
	lexicon_type(LexiconType),
	c_lex_form_input(Index, LexiconType, Input, Matches, 1),
	sort_matches(Matches, SortedMatches),
	get_best_match(SortedMatches, BestMatch),
	BestMatch = match(Term, OfsList, BestLength),
	get_records_from_offsets(OfsList, LexRecs, Lexicon),
	skip_n_tokens(BestLength, Input, IM, Remaining),
	Recs = lexicon:[lexmatch:[Term], inputmatch:IM, records:LexRecs].

%%% gets the best match, and collapses all offsets
get_best_match([F|R], N) :-
	F = match(Type, Term, Ofs, Length),
	( findall(SomeOfs, member(match(Type, Term, SomeOfs, Length), R), MoreOfs) ->
	  N = match(Term, [Ofs|MoreOfs], Length)
	; N = match(Term, [Ofs], Length)
	).

%%% skip_n_tokens(+N, +List, -NTok, -Remain)
%%% returns the result of skipping 'n' tokens in a list

skip_n_tokens(N, List, Tokens, Remaining) :-
	( N =:= 0 ->
	  Tokens = [],
	  Remaining = List
	; N1 is N - 1,
	  List = [FirstTokenInList|RestTokensInList],
	  Tokens = [FirstTokenInList|RestTokensChosen],
	  skip_n_tokens(N1, RestTokensInList, RestTokensChosen, Remaining)
	).

% skip_n_tokens(0, X, [], X).
% skip_n_tokens(N, [F|Y], [F|X], Z) :-
% 	N > 0,
% 	M is N - 1,
% 	skip_n_tokens(M, Y, X, Z).


%%% get_records_from_offsets(+OfsList, -RecsList, Lexicon)
get_records_from_offsets([], [], _Lexicon).
get_records_from_offsets([Ofs|R], [X|Y], Lexicon) :-
	read_lex_record(Lexicon, Ofs, Rec),
	fm_lexical_record(X, Rec, []),
	get_records_from_offsets(R, Y, Lexicon).

%%% sort_matches(+In, -Out)
%%% sorts matches by decreasing match length.  Also, discards
%%% lower case matches in favor of and exact match of same length
%%% and record offset.
sort_matches(In, Out) :-
	make_keys(In, InKeys),
	keysort(InKeys, OutKeys),
	rev(OutKeys, RevOutKeys),
	make_unkeys(RevOutKeys, UnOut),
	prune(UnOut, Out).

%%% constructs keys for sorting
make_keys([], []).
make_keys([F1|R1], [F2|R2]) :-
	F1 = match(Type, _Term, Ofs, Length),
	map_type(Type, MappedType),
	F2 = key(Length, MappedType, Ofs) - F1,
	make_keys(R1, R2).

map_type(punct, 0).
map_type(lower, 1).
map_type(exact, 2).

%%% removes keys
make_unkeys([], []).
make_unkeys([F1|R1], [F2|R2]) :-
	F1 = _Key - Term,
	F2 = Term,
	make_unkeys(R1, R2).

%%% Between matches of the same length and offset, prefers the exact.
prune([], []) :- !.
prune([X], [X]) :- !.
prune([X1, X2|R1], Y) :-
	X1 = match(exact, _T1, Ofs, Length),
	( X2 = match(lower, _T2, Ofs, Length)
	; X2 = match(punct, _T3, Ofs, Length)
        ),
	!,
	prune([X1|R1], Y).
prune([F|R1], [F|R2]) :-
	prune(R1, R2).

%%% reformats a Term(Cat, Feature) to a Term:[Cat:[Feature]]
reformat_list([], []).
reformat_list([F|R], [X|Y]) :-
	functor(F, Term, 2),
	arg(1, F, Cat),
	arg(2, F, Feature),
	X = Term:[Cat:[Feature]],
	reformat_list(R, Y).

%%% flattens a list of lists
flatten(ListOfLists, FlatList) :-
	append(ListOfLists, FlatList).  /* from library(lists) */

use_multi_word_lexicon  :-
	retractall(lexicon_type(_)),
	assert(lexicon_type(0)).
