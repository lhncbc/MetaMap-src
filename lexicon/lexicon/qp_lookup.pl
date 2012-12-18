
/****************************************************************************
*
*                          PUBLIC DOMAIN NOTICE                         
*         Lister Hill National Center for Biomedical Communications
*                      National Library of Medicine
*                      National Institues of Health
*           United States Department of Health and Human Services
*                                                                         
*  This software is a United States Government Work under the terms of the
*  United States Copyright Act. It was written as part of the authors'
*  official duties as United States Government employees and contractors
*  and thus cannot be copyrighted. This software is freely available
*  to the public for use. The National Library of Medicine and the
*  United States Government have not placed any restriction on its
*  use or reproduction.
*                                                                        
*  Although all reasonable efforts have been taken to ensure the accuracy 
*  and reliability of the software and data, the National Library of Medicine
*  and the United States Government do not and cannot warrant the performance
*  or results that may be obtained by using this software or data.
*  The National Library of Medicine and the U.S. Government disclaim all
*  warranties, expressed or implied, including warranties of performance,
*  merchantability or fitness for any particular purpose.
*                                                                         
*  For full details, please see the MetaMap Terms & Conditions, available at
*  http://metamap.nlm.nih.gov/MMTnCs.shtml.
*
***************************************************************************/

/* qp_lookup.pl - lexical lookup predicates.
*/

:- module(qp_lookup, [
	assemble_definitions/4
   ]).

:- use_module(lexicon(lexical), [
	lowercase_list/2
    ]).

:- use_module(lexicon(qp_lexicon), [
	lex_form_ci_recs_input_7_LEXACCESS_TOGGLE/7,
	default_lexicon_file/1,
	default_index_file/1
   ]).

:- use_module(lexicon(qp_shapes), [
	shapes/3
   ]).

:- use_module(skr_lib(ctypes), [
	is_alpha/1,
	is_punct/1
   ]).

:- use_module(skr_lib(nls_system), [
	control_option/1
   ]).

:- use_module(library(avl), [
	ord_list_to_avl/2
   ]).


:- use_module(library(lists), [
	append/2
   ]).


assemble_definitions(Input, TagList, LexiconServerInfo, Recs) :-
	default_lexicon_file(Lexicon),
	default_index_file(Index),
	assembledefns_6(Input, TagList, LexiconServerInfo, Lexicon, Index, Recs),
	maybe_display_defns(Recs).

maybe_display_defns(Defns) :-
	( control_option(showlex) ->
	  (  foreach(LexicalRecord, Defns)
	  do format(user_output, 'LEXICON: ~q~n', [LexicalRecord])
	  )
	; true
	).

assembledefns_6([], _TagList,  _LexiconServerInfo, _Lexicon, _Index, []).
assembledefns_6([FirstPhrase|RestPhrases], TagList, LexiconServerInfo, Lexicon, Index,  AllRecs) :-
	assembledefns_aux(FirstPhrase, '', [], TagList, LexiconServerInfo, Lexicon, Index, SomeRecs),
	append(SomeRecs, MoreRecs, AllRecs),
	assembledefns_6(RestPhrases, TagList, LexiconServerInfo, Lexicon, Index, MoreRecs).

%%% returns matching records in the form: lexicon:[lexmatch:X, inputmatch:Y, records:Z]
%%% where X is the "best" lexical item that matched, Y is a list of tokens from the
%%% input, and Z is a list of records of the form: lexrec:[base:B, ...etc]
assembledefns_aux([], _PrevToken, [], _TagList, _LexiconServerInfo, _Lexicon, _Index, []).

%%% from lexicon
assembledefns_aux([Token|MoreTokens], _PreviousToken, Rest, TagList,
		  LexiconServerInfo, Lexicon, Index, [Recs|MoreRecs]) :-
	\+ control_option(no_lex),
	atom_codes(Token, Codes),
	Codes = [FirstChar|_],
	\+ is_punct(FirstChar),
       	lex_form_ci_recs_input_7_LEXACCESS_TOGGLE([Token|MoreTokens], Recs, Remaining, TagList,
						  LexiconServerInfo, Lexicon, Index),
	!,
	assembledefns_aux(Remaining, Token, Rest, TagList,
			  LexiconServerInfo, Lexicon, Index, MoreRecs).

%%% punctuation
assembledefns_aux([Token|MoreTokens], _PreviousToken, Rest, TagList,
		  LexiconServerInfo, Lexicon, Index, [R|MoreRecs]) :- 
	punct_token(Token, R),
	!,
	assembledefns_aux(MoreTokens, Token, Rest, TagList,
			  LexiconServerInfo, Lexicon, Index, MoreRecs).

%%% from shapes
assembledefns_aux([Token|MoreTokens], _PreviousToken, Rest, TagList,
		  LexiconServerInfo, Lexicon, Index, Recs) :-
	% shapes(Shapes, PreviousToken, [Token|MoreTokens], Remaining),
	shapes(Shapes, [Token|MoreTokens], Remaining),
	( Shapes = [_|_] ->
	  append(Shapes, MoreRecs, Recs)
	; Recs = [Shapes|MoreRecs]
	),
	!,
	assembledefns_aux(Remaining, Token, Rest, TagList,
			  LexiconServerInfo, Lexicon, Index, MoreRecs).

%%% unknown token
assembledefns_aux([Token|MoreTokens], _PreviousToken, Rest, TagList,
		  LexiconServerInfo, Lexicon, Index, [R|MoreRecs]) :-
	R = unknown:[inputmatch:[Token]],
	% format(user_output, '### UNKNOWN token ~q~n', [Token]),
	assembledefns_aux(MoreTokens, Token, Rest, TagList,
			  LexiconServerInfo, Lexicon, Index, MoreRecs).

%%% punctuation records
punct_token(Token, punctuation:[lexmatch:[Token], inputmatch:[Token], records:[punct:PunctName]]) :-
	atom_codes(Token, [C]),
	is_punct(C),
	punct_name(Token, PunctName).

% punct_token('.', punctuation:[lexmatch:['.'], inputmatch:['.'], records:[punct:[period]]]).
% punct_token(',', punctuation:[lexmatch:[','], inputmatch:[','], records:[punct:[comma]]]).
% punct_token(':', punctuation:[lexmatch:[':'], inputmatch:[':'], records:[punct:[colon]]]).
% punct_token(';', punctuation:[lexmatch:[';'], inputmatch:[';'], records:[punct:[semicolon]]]).
% punct_token('(', punctuation:[lexmatch:['('], inputmatch:['('], records:[punct:[lparen]]]).
% punct_token(')', punctuation:[lexmatch:[')'], inputmatch:[')'], records:[punct:[rparen]]]).
% punct_token('[', punctuation:[lexmatch:['['], inputmatch:['['], records:[punct:[lparen]]]).
% punct_token(']', punctuation:[lexmatch:[']'], inputmatch:[']'], records:[punct:[rparen]]]).
% punct_token('/', punctuation:[lexmatch:['/'], inputmatch:['/'], records:[punct:[slash]]]).
% punct_token('?', punctuation:[lexmatch:['?'], inputmatch:['?'], records:[punct:[question]]]).
% punct_token('!', punctuation:[lexmatch:['!'], inputmatch:['!'], records:[punct:[exclaim]]]).
% punct_token('-', punctuation:[lexmatch:['-'], inputmatch:['-'], records:[punct:[dash, hyphen]]]).

punct_name('.', [period])       :- !.
punct_name(',', [comma])        :- !.
punct_name(':', [colon])        :- !.
punct_name(';', [semicolon])    :- !.
punct_name('(', [lparen])       :- !.
punct_name(')', [rparen])       :- !.
punct_name('[', [lparen])       :- !.
punct_name(']', [rparen])       :- !.
punct_name('/', [slash])        :- !.
punct_name('?', [question])     :- !.
punct_name('!', [exclaim])      :- !.
punct_name('-', [dash, hyphen]) :- !.
punct_name(_,   [otherpunct]).

%%%%%% ------------------------

