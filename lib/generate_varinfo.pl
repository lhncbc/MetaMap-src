% File:	    generate_varinfo.pl
% Module:   generate_varinfo
% Author:   tcr
% Purpose:  generate variant information from a lexical entry



% ----- Module declaration and exported predicates

:- module(generate_varinfo, [
	generate_variant_info/2
   ]).


% ----- Imported predicates

:- use_module( lexicon(qp_lexicon), [
	lex_form_ci_vars/2
  ]).

:- use_module(skr_lib(sicstus_utils), [
	lower/2,
	midstring/5,
	midstring/6,
	string_char/3,
	string_size/2
  ]).


% ******************************* GENERATE_VARIANT_INFO *******************************

generate_variant_info([], []).
generate_variant_info([LexiconOrOther:List|RestDefinitions], Variants) :-
	generate_variant_info_1(LexiconOrOther, List, RestDefinitions, Variants).

generate_variant_info_1(unknown, UnkList, RestDefinitions, [ThisItem|NewGap]) :-
	!,
	get_lex_item(UnkList, inputmatch, InpMatch),
	InpMatch = [ThisItem],
	generate_variant_info(RestDefinitions, NewGap).
generate_variant_info_1(lexicon, [lexmatch:[LexMatch], InputMatch|_], RestDefinitions,
		      [LexMatch:ThisVarInfo|NewGap]) :-
	!,
	lex_form_ci_vars(LexMatch, VarInfo),
	get_this_variant(VarInfo, LexMatch, ThisVarInfo, VariantTail),
	% append(ThisVarInfo, [InputMatch], ThisVarInfoAndInputMatch),   % Lan needs InputMatch
	VariantTail = [InputMatch], 
	generate_variant_info(RestDefinitions, NewGap).
% This is for shapes, punctuation, and perhaps other stuff
generate_variant_info_1(Other, OtherList, RestDefinitions, [Other:OtherList|NewGap]) :-
	generate_variant_info(RestDefinitions, NewGap).

% ----- GET_LEX_ITEM

% get_lex_item([], _Item, _ItemInfo) :- !, fail.

get_lex_item([Item:ItemInfo|_More], Item, ItemInfo) :-
	!.
get_lex_item([_Other|More], Item, ItemInfo) :-
	get_lex_item(More, Item, ItemInfo).

% ----- GET_THIS_VARIANT
% LexKeys other than forms of *be* and *have* have the format: Entry:VarList
% LexKeys for forms of *be* have the format: 'VarForm;Agr':VarList

get_this_variant([], _ThisWord, ThisVarInfo, ThisVarInfo).
get_this_variant([LexKey:[ThisList]|MoreVariants], ThisWord, [ThisList|Rest], Tail) :-
	% I believe this predicate is useless
	% get_actual_lex_key(LexKey, ActualLexKey, _AgrInfo),
	ActualLexKey = LexKey,
	lower(ActualLexKey, LowerLexKey),
	lower(ThisWord, LowerLexKey),
	!,
	get_this_variant(MoreVariants, ThisWord, Rest, Tail).
get_this_variant([_Other|MoreVariants], ThisWord, ThisVarInfo, Rest) :-
	get_this_variant(MoreVariants, ThisWord, ThisVarInfo, Rest).

/*
%--- GET_ACTUAL_LEX_KEY

get_actual_lex_key(LexKey, ActualLexKey, AgrInfo) :-
	string_char(Index, LexKey, 0';), %' % Comment is there just to fake out Emacs
	!,
	string_size(LexKey, Length),
	LLen is Index - 1,
	RLen is Length - Index,
	midstring(LexKey, _, LexKeyAndAgrInfo , LLen, 1, RLen),
	midstring(LexKeyAndAgrInfo, ActualLexKey, AgrInfo, 0, LLen).
get_actual_lex_key(ActualLexKey, ActualLexKey, none).
*/
