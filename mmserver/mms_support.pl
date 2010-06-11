:- module(mms_support,[
    initialize_skr/4,
    initialize_skr/6,
    process_text/5,
    postprocess_sentences/10
    ]).

:- use_module(lexicon(qp_lexicon),[
	use_multi_word_lexicon/0
    ]).

:- use_module(metamap(metamap_parsing),[
	collapse_syntactic_analysis/2,
	generate_syntactic_analysis_plus/3,
	generate_syntactic_analysis_plus/4
    ]).

:- use_module(mmi(mmi),[
        do_MMI_processing/5
    ]).

:- use_module(skr(skr),[
	initialize_skr/1,
	skr_phrases/14,
	stop_skr/0
   ]).

:- use_module(skr(skr_text_processing),[
	extract_sentences/6,
	get_skr_text/1
%	is_sgml_text/1
    ]).

:- use_module(skr(skr_utilities),[
	compare_utterance_lengths/2,
	compute_original_phrase/7,
	do_formal_tagger_output/0,
	do_sanity_checking_and_housekeeping/2,
	generate_bracketed_output/2,
	generate_candidates_output/3,
	generate_EOT_output/0,
        generate_header_output/6,
	generate_mappings_output/5,
	generate_phrase_output/7,
	generate_utterance_output/6,
	generate_variants_output/2,
	get_program_name/1,
	output_should_be_bracketed/1,
	output_tagging/3,
	replace_crs_with_blanks/4,
	usage/0,
	token_template/5,
	token_template/6,
        write_MMO_terms/1,
        write_raw_token_lists/3,
        write_sentences/3
    ]).

:- use_module(skr(skr_xml),[
	generate_and_print_xml/1
    ]).

:- use_module(skr_db(db_access),[
	default_full_year/1
    ]).

:- use_module(skr_lib(negex),[
        compute_negex/4,
      	generate_negex_output/1
    ]).

:- use_module(skr_lib(efficiency),[
	maybe_atom_gc/2
    ]).

:- use_module(skr_lib(nls_strings),[
	eliminate_multiple_meaning_designator_string/2,
	form_one_string/3,
	normalized_syntactic_uninvert_string/2,
	trim_whitespace/2
    ]).

:- use_module(skr_lib(nls_system), [
	get_control_options_for_modules/2,
	reset_control_options/1,
	toggle_control_options/1,
	set_control_values/2,
	control_option/1,
	parse_command_line/1,
	interpret_options/4,
	interpret_args/4,
	get_from_iargs/4
    ]).

:- use_module(skr_lib(pos_info), [
	create_EXP_raw_token_list/6,
	create_UNEXP_raw_token_list/5,
	get_next_token_state/3
    ]).

:- use_module(tagger(tagger_access),[
	tag_text/4
    ]).

:- use_module(text(text_objects),[
	merge_sentences/2
   ]).

:- use_module(text(text_object_util),[
	higher_order_or_annotation_type/1
   ]).

:- use_module(library(avl),[
	empty_avl/1
    ]).

:- use_module(library(basics),[
	member/2
    ]).

:- use_module(library(lists),[
	append/2,
	rev/2
    ]).

:- use_module(library(strings),[
	subchars/4
    ]).

:- use_module(library(tcp), [
        tcp_input_stream/2,
        tcp_output_stream/2,
        tcp_shutdown/1  
   ]).

% initialize_skr/6

/* initialize_skr(+Options, +Args, -InterpretedArgs, +ProgramName, +FullYear, +IOptions)

initialize_skr/6 interprets command line options and arguments (opening
files as necessary) and, sets and displays the SKR control options
discovered, and performs other initialization tasks including initializing
other modules by calling initialize_skr/1.  It returns InterpretedArgs
for later use (e.g., the stream associated with a file).  */

initialize_skr(Options, Args, IArgs, ProgramName, FullYear, IOptions) :-
	get_control_options_for_modules([metamap], AllOptions),
	interpret_options(Options, AllOptions, metamap, IOptions),
	\+ member(iopt(help,_), IOptions),
	ArgSpecs=[aspec(infile,mandatory,file,read,
			user_input,
			'Input file containing labelled utterances'),
		  aspec(outfile,mandatory,file,write,
			or(['<infile>','.','out'],user_output),
			'Output file')
		 ],
	interpret_args(IOptions, ArgSpecs, Args, IArgs),
	toggle_control_options(IOptions),
	set_control_values(IOptions,IArgs),
	use_multi_word_lexicon,
	do_sanity_checking_and_housekeeping(ProgramName, FullYear),
	initialize_skr([]).


initialize_skr(Options, Args, ProgramName, FullYear) :-
	get_control_options_for_modules([metamap], AllOptions),
	interpret_options(Options, AllOptions, metamap, IOptions),
	\+ member(iopt(help,_), IOptions),
	ArgSpecs=[aspec(infile,mandatory,file,read,
			user_input,
			'Input file containing labelled utterances'),
		  aspec(outfile,mandatory,file,write,
			or(['<infile>','.','out'],user_output),
			'Output file')
		 ],
	interpret_args(IOptions, ArgSpecs, Args, IArgs),
	toggle_control_options(IOptions),
	set_control_values(IOptions,IArgs),
	use_multi_word_lexicon,
	do_sanity_checking_and_housekeeping(ProgramName, FullYear),
	initialize_skr([]).


% process_text/4

/* process_text(+Lines, +TagOption, -ExpRawTokenList, -MMResults)

   postprocess_text(+Lines, +BracketedOutputFlag, +InterpretedArgs,
   	            +IOptions, +ExpRawTokenList, +MMResults)

   postprocess_sentences(+OrigUtterances, +NegationTerms, +InterpretedArgs, +IOptions,
			 +Sentences, +CoordSentences, +BracketedOutput, +DisambMMOutput,
			 _AllMMO)
   postprocess_phrases(+MMOPhrases, +ExtractedPhrases,
                       +Sentences, +CoordSentencesIn, -CoordSentencesOut,
                       +N, +M, +Label, -PhraseMMO)

process_text/4 maps Lines (in one of the formats recognized by
extract_sentences/5) using the auxiliary process_text/3 which processes
ExpandedUtterances (expanded utterances, e.g., in which acronyms/abbreviations
are replaced with their expanded definitions) and produces MMOutput
which is packaged up with preliminary results and returned as MMResults.

Standard input and output are assumed to be redirected to files.
Tagging is done if TagOption is 'tag'.

process_text/4 does the initial MetaMap processing without writing any results.

postprocess_text/6 has two major functions:
  o it performs word sense disambiguation (WSD) on MMResults; and
  o it does any required writing of results;
    one such required writing of results is Machine Output.
It uses postprocess_sentences/9 which uses postprocess_phrases/8
to process each sentence and phrase.

Written results take account of position information in CoordSentences to
match up the text in ExpandedUtterances (expanded sentences) with the original text
in Sentences in case the original text is preferred. */

% Suppress processing of options within data
% process_text([Lines],_TagOption,reset) :-
%	process_any_new_options(Lines),
%	!.

% MMResults is created by process text, and is one term of the form
% mm_results(Lines0, TagOption, ModifiedLines, InputType,
%            Sentences, CoordSentences, OrigUtterances, MMOutput),
% 
% MMOutput is created by process_text_aux and skr_phrase, and is a list of terms of the form
%
% mm_output(ExpandedUtterance, CitationTextAtom, ModifiedText, Tagging,
%           AAs, Syntax, DisambiguatedMMOPhrases, ExtractedPhrases)
%
% DisambiguatedMMOPhrases = list of
%
% phrase(phrase(PhraseTextAtom0,Phrase,StartPos/Length,ReplacementPos),
% 	 candidates(Evaluations),
% 	 mappings(Mappings),
% 	 pwi(PhraseWordInfo),
% 	 gvcs(GVCs),
% 	 ev0(Evaluations3),
% 	 aphrases(APhrases))

process_text(Text, TagOption, RawTokenList, AAs, MMResults) :-
	( process_text_1(Text, TagOption, RawTokenList, AAs, MMResults) ->
	  true
 	; format('#### ERROR: process_text/4 failed for~n~p~n',[Text]),
	  format(user_output,'#### ERROR: process_text/4 failed for~n~p~n',[Text]),
	  RawTokenList = [],
	  MMResults = [],
	  ttyflush
	).

process_text_1(Lines0, TagOption, ExpRawTokenList, AAs, MMResults) :-
	%%% temp
	%display_time_and_reset('ET fe 1'),
 	% Construct output terms
	%    MMResults=mm_results(Lines0,TagOption,ModifiedLines,InputType,
	%			  UtteranceTerms,MMOutput),
	MMResults = mm_results(Lines0, TagOption, ModifiedLines, InputType,
			       Sentences, CoordSentences, OrigUtterances, MMOutput),
	ModifiedLines = modified_lines(Lines),
	% ( is_sgml_text(Lines0) ->
	%   current_input(CurrentInput),
	%   fget_all_non_null_lines(CurrentInput, Lines1),
	%   append(Lines0, Lines1, Lines2)
	% ; Lines2 = Lines0
	% ),
	Lines2 = Lines0,
	% Sentences and CoordSentences are the token lists
	% CoordSentences includes the positional information for the original text
	% format(user_output, 'Processing PMID ~w~n', [PMID]),
	extract_sentences(Lines2, InputType, Sentences, CoordSentences, AAs, Lines),
	% fail,
	% RawTokenList is the copy of Sentences that includes an extra pos(_,_) term
	% showing the position of each token in the raw, undoctored text.
	form_one_string(Lines, [10], InputStringWithCRs),
	form_one_string(Lines, " ", InputStringWithBlanks),
	atom_chars(CitationTextAtomWithCRs, InputStringWithCRs),

	write_sentences(PMID, CoordSentences, Sentences),

	% '' is just the previous token type, which, for the initial call, is null
	create_EXP_raw_token_list(Sentences, '',  0, 0, InputStringWithBlanks, TempExpRawTokenList),
	% merge_sentences(TempExpRawTokenList, ExpRawTokenList),
	ExpRawTokenList = TempExpRawTokenList,
	create_UNEXP_raw_token_list(Sentences, 0, 0, InputStringWithBlanks, UnExpRawTokenList),
	!,
	% halt,
	% length(Sentences,         SentencesLength),
	% length(UnExpRawTokenList, UnExpRawTokenListLength),

	% length(CoordSentences,  CoordSentencesLength),
	% length(ExpRawTokenList, ExpRawTokenListLength),

	% format(user_output,
	%        'LENGTHS:~nSent:  ~w~nUnExp: ~w~n~nCoord: ~w~nExp:   ~w~n',
	% 	[SentencesLength,UnExpRawTokenListLength,
	% 	 CoordSentencesLength,ExpRawTokenListLength]),

	write_raw_token_lists(PMID, ExpRawTokenList, UnExpRawTokenList),
	form_original_sentences(Sentences, 1, 0, 0, CitationTextAtomWithCRs,
				UnExpRawTokenList, OrigUtterances),
	% format(user_output, '~n~n#### ~w OrigUtterances:~n', [PMID]),
	% write_utterances(OrigUtterances),
	% form_original_sentences(Sentences, OrigUtterances),
	% temp
	%    format('OrigUtterances:~n',[]),
	%    wl(OrigUtterances),
	% form_expanded_sentences(CoordSentences, 1, 0, 0, ExpRawTokenList, ExpandedUtterances),
	form_expanded_sentences(CoordSentences, OrigUtterances, ExpandedUtterances),
	% format(user_output, '~n~n#### ~w ExpandedUtterances:~n', [PMID]),
	% write_utterances(ExpandedUtterances),
	% format(user_output, '~n~n', []),
	compare_utterance_lengths(OrigUtterances, ExpandedUtterances),
	ttyflush,
	MMOutput \== '',
	ExpRawTokenList \== '',
	empty_avl(WordDataCacheIn),
	empty_avl(USCCacheIn),
	process_text_aux(ExpandedUtterances, TagOption, CitationTextAtomWithCRs, AAs, 
			 ExpRawTokenList, WordDataCacheIn, USCCacheIn,
			 _RawTokenListOut, _WordDataCacheOut, _USCacheOut, MMOutput),
	%%% temp
	%display_time_and_reset('ET fe 99'),
        !.

process_text_aux([], _TagOption, _CitationTextAtom, _AAs, ExpRawTokenListOut,
		 WordDataCache, USCCache,
		 ExpRawTokenListOut,
		 WordDataCache, USCCache, []).
process_text_aux([ExpandedUtterance|Rest], TagOption, CitationTextAtom, AAs,
		 ExpRawTokenListIn, WordDataCacheIn, USCCacheIn,
		 ExpRawTokenListOut, WordDataCacheOut, USCCacheOut,
		 [mm_output(ExpandedUtterance,CitationTextAtom,ModifiedText,Tagging,AAs,
			    Syntax,DisambiguatedMMOPhrases,ExtractedPhrases)|RestMMOutput]) :-
	% Construct output terms
	ModifiedText = modified_text(UtteranceText),
	Tagging = tagging(TagOption,FullTagList,TagList,HRTagStrings),
	Syntax = syntax(SyntAnalysis0, SyntAnalysis, Definitions),
	% DisambiguatedMMOPhrases and ExtractedPhrases are passed back as lists (historical)
	% Decompose input terms
	ExpandedUtterance = utterance(InputLabel,Text0,_PosInfo,_ReplacementPos),
	conditionally_announce_processing(InputLabel, Text0),
	maybe_atom_gc(_DidGC,_SpaceCollected),
	set_utterance_text(Text0, UtteranceText),
	do_syntax_processing(TagOption, UtteranceText, FullTagList, TagList,
			     HRTagStrings, Definitions, SyntAnalysis0),
	conditionally_collapse_syntactic_analysis(SyntAnalysis0, SyntAnalysis),
	skr_phrases(InputLabel, UtteranceText, CitationTextAtom,
		    AAs, SyntAnalysis, WordDataCacheIn, USCCacheIn,
		    ExpRawTokenListIn, ExpRawTokenListNext, WordDataCacheNext, USCCacheNext,
		    DisambiguatedMMOPhrases, ExtractedPhrases, _SemRepPhrases),
	process_text_aux(Rest, TagOption, CitationTextAtom, AAs,
			 ExpRawTokenListNext, WordDataCacheNext, USCCacheNext,
			 ExpRawTokenListOut, WordDataCacheOut, USCCacheOut, RestMMOutput).

postprocess_text(Lines0, BracketedOutput, InterpretedArgs,
		 IOptions,  ExpRawTokenList, AAs, MMResults) :-
	% If the phrases_only debug option is set, don't do postprocessing,
	% because we've already computed and displayed the phrase lengths,
	% and that's all we care about if this option is on.
	( control_option(phrases_only) ->
	  true
	; postprocess_text_1(Lines0, BracketedOutput, InterpretedArgs,
			     IOptions,  ExpRawTokenList, AAs, MMResults) ->
	  true
	; format(user_output, 'ERROR: postprocess_text/2 failed for~n~p~n', [Lines0]),
	  format('ERROR: postprocess_text/2 failed for~n~p~n', [Lines0]),
	  abort
	).

postprocess_text_1(Lines0, BracketedOutput, InterpretedArgs,
		   IOptions, ExpRawTokenList, AAs, MMResults) :-
	% Decompose input
	MMResults = mm_results(Lines0, _TagOption, _ModifiedLines, _InputType,
			       Sentences, CoordSentences, OrigUtterances, DisambMMOutput),

	compute_negex(ExpRawTokenList, Lines0, DisambMMOutput, NegationTerms),
	generate_negex_output(NegationTerms),
	postprocess_sentences(OrigUtterances, NegationTerms, InterpretedArgs, IOptions, AAs,
			      Sentences, CoordSentences, BracketedOutput, DisambMMOutput,
			      AllMMO),
	% All the XML output for the current citation is handled here
	generate_and_print_xml(AllMMO),
	do_MMI_processing(OrigUtterances, BracketedOutput,
			  Sentences, CoordSentences, DisambMMOutput),
	do_formal_tagger_output.

postprocess_sentences(OrigUtterances, NegExList, IArgs, IOptions, AAs,
		      Sentences, CoordSentences, BracketedOutput, DisambMMOutput,
		      AllMMO) :-
	AllMMO = HeaderMMO,
	HeaderMMORest = UtteranceMMO,
	generate_header_output(IArgs, IOptions, NegExList, DisambMMOutput,
			       HeaderMMO, HeaderMMORest),
	postprocess_sentences_1(OrigUtterances, Sentences, CoordSentences,
				BracketedOutput, 1, AAs, DisambMMOutput, UtteranceMMO, []),
	write_MMO_terms(AllMMO).

postprocess_sentences_1([], _Sentences, _CoordSentencesIn,
			_BracketedOutput, _N, _AAs, [], MMO, MMO) :- !.
postprocess_sentences_1([OrigUtterance|RestOrigUtterances], Sentences, CoordSentencesIn,
			BracketedOutput, N, AAs, [MMOutput|RestMMOutput],
			MMOIn, MMOOut) :-
	% Decompose input
	OrigUtterance = utterance(Label, TextString, StartPos/Length,ReplPos),
	MMOutput = mm_output(_ExpandedUtterance, _Citation, _ModifiedText, Tagging,
			     _AAs, _Syntax, MMOPhrases, ExtractedPhrases),
	Tagging = tagging(_TagOption, FullTagList, _TagList, HRTagStrings),
	generate_utterance_output(Label, TextString, StartPos, Length, ReplPos, UtteranceMMO),
	% CHANGE
	MMOIn = [UtteranceMMO|MMONext1],
	output_tagging(BracketedOutput, HRTagStrings, FullTagList),
	postprocess_phrases(MMOPhrases, ExtractedPhrases,
			    Sentences, CoordSentencesIn, CoordSentencesNext,
			    BracketedOutput, N, 1, AAs, Label, MMONext1, MMONext2),
	!,
	NextN is N + 1,
	postprocess_sentences_1(RestOrigUtterances, Sentences, CoordSentencesNext,
				BracketedOutput, NextN, AAs, RestMMOutput,
				MMONext2, MMOOut).
postprocess_sentences_1([FailedUtterance|_], _Sentences, _CoordSentencesIn,
			_BracketedOutput, _N, _AAs, _MMOutput, _MMOIn, _MMOOut) :-
	FailedUtterance = utterance(UtteranceID,UtteranceText,_PosInfo,_ReplPos),
	format(user_output,
	       'ERROR: postprocess_sentences/3 failed on sentence ~w:~n       "~s"~n',
	       [UtteranceID,UtteranceText]),
	ttyflush,
	fail.


postprocess_phrases([], [], _Sentences, _CoordSentencesIn, _CoordSentencesIn,
		    _BracketedOutput, _N, _M, _AAs, _Label, MMO, MMO) :- !.
postprocess_phrases([MMOPhrase|RestMMOPhrases],
		    [_ExtractedPhrase|RestExtractedPhrases],
		    Sentences, CoordSentencesIn, CoordSentencesOut,
		    BracketedOutput, N, M, AAs, Label, MMOIn, MMOOut) :-
	MMOPhrase = phrase(phrase(PhraseTextAtom0,Phrase,StartPos/Length,ReplacementPos),
			   candidates(Evaluations),
			   mappings(Mappings),
			   pwi(PhraseWordInfo),
			   gvcs(GVCs),
			   ev0(Evaluations3),
			   aphrases(APhrases)),
	compute_original_phrase(PhraseTextAtom0, AAs,
				Sentences, CoordSentencesIn, CoordSentencesNext,
				_CoordPhraseTokens, PhraseTextAtom),
	% format('PhraseTextAtom:~n~p~n',[PhraseTextAtom]),
	generate_phrase_output(PhraseTextAtom, Phrase, StartPos, Length, ReplacementPos,
			       BracketedOutput, PhraseMMO),
	generate_bracketed_output(BracketedOutput, PhraseWordInfo),
	generate_variants_output(GVCs, BracketedOutput),
	generate_candidates_output(Evaluations3, BracketedOutput, CandidatesMMO),
	generate_mappings_output(Mappings, Evaluations, APhrases,
				 BracketedOutput, MappingsMMO),
	% format('PhraseTextAtom:~n~p~n',[PhraseTextAtom]),
	% CHANGE
	MMOIn = [PhraseMMO,CandidatesMMO,MappingsMMO|MMONext],
	NextM is M + 1,
	postprocess_phrases(RestMMOPhrases, RestExtractedPhrases,
			    Sentences, CoordSentencesNext, CoordSentencesOut,
			    BracketedOutput, N, NextM, AAs, Label, MMONext, MMOOut).
/*
   form_original_sentences(+Sentences, +StartPos, +EndPos, +TokenState, +CitationTextAtom,
			   +RawTokenList, -OrigUtterances)
   form_original_sentences_aux(+Sentences, +StartPos, +EndPos, +TokenState, +CitationTextAtom,
   			       +RawTokenList, +Label, +RevTexts, -OrigUtterances)

form_original_sentences/7 extracts OrigUtterances from Sentences.
(See skr_text_processing:extract_sentences/4 for a description of Sentences.)

OrigUtterances is a list of terms of the form
  utterance(<Label>,<Text>,<PosInfo>,<ReplacementPos>)
where <Label> is an atom identifying the sentence, e.g., UI.<field>.<n>,
      <Text> is a string consisting of the original sentence, and
      <PosInfo> is a StartPos/Length pair representing
          * the starting character position of the utterance in the original text and
          * the number of characters of the utterance in the original text
      <ReplacementPos> is a list of integers representing the character positions
          in Text in which <CR>s have been replaced by blanks
form_original_sentences_aux/9 is an auxiliary that keeps track of the Label to use
for each sentence and the accumulated text strings, RevTexts.

TokenState represents if we're in the middle of a sentence.
TokenState == 0 means that we have NOT YET consumed a regular token (e.g., an, ic, lc, etc.)
		in the current sentence.
TokenState == 1 means that we have ALREADY consumed a regular token in the current sentence.

The terms here are utterance/3 for historical reasons. */

form_original_sentences(Sentences, StartPos, EndPos, TokenState, CitationTextAtom,
			RawTokenList, OrigUtterances) :-
	form_original_sentences_aux(Sentences, StartPos, EndPos, TokenState, CitationTextAtom,
				    RawTokenList, '', [], OrigUtterances).

% If there are no more tokens in the sentence list (first arg == [])
% and the RevText list is empty, because we haven't been accumulating any text,
% then just terminate, and return [] as the final tail of OrigUtterances.

form_original_sentences_aux([], _StartPos, _EndPos, _TokenState, _CitationTextAtom,
			    _RawTokenList, _Label, [], []) :-
	!.
% Add StartPos/EndPos to the utterance term
% because we're at the end of the token list.
form_original_sentences_aux([], StartPos, EndPos, _TokenState, CitationTextAtom, _RawTokenList, 
			    Label, _RevTexts,
			    [utterance(Label,OrigText,StartPos/Length,ReplPos)]) :-
	!,
	% rev(RevTexts, Texts),
	% append(Texts, Text0),
	% trim_blanks(Text0, Text),
	Length is EndPos - StartPos,
	subchars(CitationTextAtom, OrigTextWithCRs, StartPos, Length),
	replace_crs_with_blanks(OrigTextWithCRs, StartPos, OrigText, ReplPos).
% Skip a "label" field if there is no previous RevText,
% but convert the Label text to an atom and pass it along.
% form_original_sentences_aux([tok(label,TokLabel,_,_)|Rest], StartPos, EndPos,
form_original_sentences_aux([Token|Rest], StartPos, EndPos,
			    TokenState,  CitationTextAtom,
			    [_|RestRawTokenList], _Label, [], OrigUtterances) :-
	token_template(Token, label, TokLabel, _PosInfo1, _PosInfo2),
	!,
	atom_chars(NewLabel, TokLabel),
	form_original_sentences_aux(Rest, StartPos, EndPos, TokenState, CitationTextAtom,
				    RestRawTokenList, NewLabel, [], OrigUtterances).
% Add StartPos/EndPos to the utterance term
% because the current token is a label, and thus begins the next utterance.
% form_original_sentences_aux([tok(label,TokLabel,_,_)|Rest], StartPos, EndPos,
form_original_sentences_aux([Token|Rest], StartPos, EndPos,
			    TokenState, CitationTextAtom,
			    [_|RestRawTokenList], Label, _RevTexts,
			    [utterance(Label,OrigText,StartPos/Length,ReplPos)|RestOrigUtterances]) :-
	token_template(Token, label, TokLabel, _PosInfo1, _PosInfo2),
	!,
	% rev(RevTexts, Texts),
	% append(Texts, Text0),
	% trim_blanks(Text0, Text),
	atom_chars(NewLabel, TokLabel),
	Length is EndPos - StartPos,
	subchars(CitationTextAtom, OrigTextWithCRs, StartPos, Length),
	replace_crs_with_blanks(OrigTextWithCRs, StartPos, OrigText, ReplPos),
	form_original_sentences_aux(Rest, StartPos, EndPos, TokenState, CitationTextAtom,
				    RestRawTokenList, NewLabel, [], RestOrigUtterances).
% form_original_sentences_aux([tok(TokenType,_,_,_)|Rest], StartPos, EndPos,
form_original_sentences_aux([Token|Rest], StartPos, EndPos,
			    TokenState, CitationTextAtom,
			    [RawToken|RestRawTokens], Label, RevTexts, OrigUtterances) :-
	% skip token types
	% field, sn, pe (higher order), and
	% aa, and aadef (annnotation) altogether
	token_template(Token, TokenType, _TokenString, _PosInfo1, _PosInfo2),
	higher_order_or_annotation_type(TokenType),
	!,
	get_next_token_state(TokenState, TokenType, NextTokenState),
	consume_matching_raw_token(TokenType, RawToken, RestRawTokens, NewRestRawTokens),
	form_original_sentences_aux(Rest, StartPos, EndPos, NextTokenState, CitationTextAtom,
				    NewRestRawTokens, Label, RevTexts, OrigUtterances).
% Token here is a normal token (an, ic, uc, mc, ws, pn, etc.)
% Set the StartPos (the starting character position of the utterance) IFF
% (1) the token is not a higher_order_or_annotation_type (which is this clause), and
% (2) the TokenState is 0 (meaning we're not currently in a sentence).
% In other words, set the utterance's StartPos
% at the first normal token after an sn token.
% form_original_sentences_aux([tok(TokenType,TokenText,_,_)|Rest],
form_original_sentences_aux([Token|Rest],
			    CurrStartPos, _CurrEndPos, TokenState, CitationTextAtom,
			    [RawToken|RestRawTokenList],
			    Label, RevTexts, OrigUtterances) :-
	% temp
	%    format('  ~a:"~s"~n',[TokenType,TokenText]),
	token_template(Token, TokenType, TokenText, _PosInfo1, _PosInfo2),
	get_next_token_state(TokenState, TokenType, NextTokenState),
	RawToken = tok(_Type, _String, _LCStr, _Pos1, pos(RawTokStartPos,RawTokLength)),
	set_utterance_start_end_pos(TokenState,
				    RawTokStartPos, RawTokLength,
				    CurrStartPos, NewStartPos, NewEndPos),
	% format(user_output, 'Orig: ~s ~w~n', [TokenText, NewEndPos]),
	form_original_sentences_aux(Rest, NewStartPos, NewEndPos, NextTokenState, CitationTextAtom,
				    RestRawTokenList, Label,
				    [TokenText|RevTexts], OrigUtterances).

consume_matching_raw_token(TokenType, RawToken, RestRawTokens, NewRestRawTokens) :-
	token_template(RawToken, TokenType, _TokenString, _LCTokenString, _PosInfo1, _PosInfo2),
	NewRestRawTokens = RestRawTokens.

set_utterance_start_end_pos(0, RawTokStartPos, RawTokLength,
			   _CurrStartPos, NewStartPos, NewEndPos) :-
	NewStartPos is RawTokStartPos,
	NewEndPos is NewStartPos + RawTokLength.
	% atom_chars(TokenAtom, TokenString).
	% RawTokStartPos is the starting character position of the utterance,
	% because it's the first printing token after an sn token,
	% i.e., when the TokenState is 0.
	% format(user_output, '~w StartPos ~w~n', [TokenAtom, NewStartPos]).


set_utterance_start_end_pos(1, RawTokStartPos, RawTokLength,
			    CurrStartPos, NewStartPos, NewEndPos) :-
	NewStartPos is CurrStartPos,
	NewEndPos is RawTokStartPos + RawTokLength.
% The calculation of NewEndPos needs some explanation:

/* form_expanded_sentences(+CoordSentences, +OrigUtterances, -ExpandedSentences)
   form_expanded_sentences(+CoordSentences, +OrigUtterances, +Label, +RevTexts,
                           -ExpandedSentences)

OrigUtterances is passed in simply to copy the positional information.

form_expanded_sentences/3 extracts ExpandedSentences from CoordSentences.
(See skr_text_processing:extract_sentences/4 for a description of
CoordSentences.

ExpandedSentences is a list of terms of the form
  utterance(<label>,<text>)
where <label> is an atom identifying the sentence, e.g., UI.<field>.<n> and
      <text> is a string consisting of the expanded sentence.

form_expanded_sentences/4 is an auxiliary that keeps track of the Label to use
for each sentence and the accumulated text strings, RevTexts.

The terms here are utterance/2 for historical reasons. */

form_expanded_sentences(CoordSentences, OrigUtterances, ExpandedSentences) :-
        form_expanded_sentences_aux(CoordSentences, OrigUtterances, '', [], ExpandedSentences).

form_expanded_sentences_aux([], [],_Label, [], []) :-
        !.
form_expanded_sentences_aux([], [utterance(Label,_OrigText,StartPos/Length,ReplPos)],
			    Label, RevTexts, [utterance(Label,Text,StartPos/Length,ReplPos)]) :-
        !,
        rev(RevTexts,Texts),
        append(Texts,Text0),
        trim_whitespace(Text0,Text).
% This is for the first label token in a citation,
% because the next-to-last argument,
% which holds the previous utterance's RevTexts, is [].
% form_expanded_sentences_aux([tok(label,Label,_LCLabel,_,_)|Rest], OrigUtterances,
form_expanded_sentences_aux([Token|Rest], OrigUtterances,
			    _NoPrevLabel, [], ExpandedSentences) :-
	token_template(Token, label, Label, _LCLabel, _PosInfo1, _PosInfo2),
        !,
        atom_chars(NewLabel, Label),
        form_expanded_sentences_aux(Rest, OrigUtterances, NewLabel, [], ExpandedSentences).
% form_expanded_sentences_aux([tok(label,NextLabel,_NextLCLabel,_,_)|Rest],
form_expanded_sentences_aux([Token|Rest],
			    [utterance(PrevLabel,_OrigText,StartPos/Length,ReplPos)
			        |RestOrigUtterances],
			    PrevLabel, RevTexts,
                           [utterance(PrevLabel,Text,StartPos/Length,ReplPos)
			        |RestExpandedSentences]) :-
	token_template(Token, label, NextLabel, _LCNextLabel, _PosInfo1, _PosInfo2),
	!,
        rev(RevTexts,Texts),
        append(Texts,Text0),
        trim_whitespace(Text0,Text),
        atom_chars(NewLabel,NextLabel),
        form_expanded_sentences_aux(Rest, RestOrigUtterances, NewLabel, [], RestExpandedSentences).
% form_expanded_sentences_aux([tok(Type,_,_,_,_)|Rest], OrigUtterances,
form_expanded_sentences_aux([Token|Rest], OrigUtterances,
			    Label, RevTexts, ExpandedSentences) :-
	token_template(Token, Type, _TokenString, _LCTokenString, _PosInfo1, _PosInfo2),
        higher_order_or_annotation_type(Type),
        !,
        form_expanded_sentences_aux(Rest, OrigUtterances, Label, RevTexts, ExpandedSentences).
% form_expanded_sentences_aux([tok(_Type,TokenText,_,_,_)|Rest], OrigUtterances,
form_expanded_sentences_aux([Token|Rest], OrigUtterances,
			    Label, RevTexts, ExpandedSentences) :-
	token_template(Token, _TokenType, TokenText, _LCTokenText, _PosInfo1, _PosInfo2),
        % temp
        %    format('  ~a:"~s"~n',[Type,TokenText]),
        form_expanded_sentences_aux(Rest, OrigUtterances,
				    Label, [TokenText|RevTexts], ExpandedSentences).


conditionally_announce_processing(InputLabel, Text0) :-
	current_output(CurrentOutput),
	( CurrentOutput == user_output ->
	  true
	; format(user_output,'Processing ~a: ~s~n', [InputLabel,Text0]),
	  flush_output(user_output)
	),
	flush_output(CurrentOutput).

set_utterance_text(Text0, UtteranceText) :-
	( control_option(term_processing) ->
	  eliminate_multiple_meaning_designator_string(Text0, Text1),
	  normalized_syntactic_uninvert_string(Text1, UtteranceText)
	; UtteranceText = Text0
	).

do_syntax_processing(TagOption, UtteranceText, FullTagList, TagList,
		     HRTagStrings, Definitions, SyntAnalysis0) :-
	( TagOption == tag ->
	  tag_text(UtteranceText,FullTagList,TagList,HRTagStrings),
	  generate_syntactic_analysis_plus(UtteranceText,TagList,SyntAnalysis0,Definitions)
	; FullTagList = [],
	  TagList = [],
	  HRTagStrings = [],
	  generate_syntactic_analysis_plus(UtteranceText,SyntAnalysis0,Definitions)
	).

conditionally_collapse_syntactic_analysis(SyntAnalysis0, SyntAnalysis) :-
	( control_option(term_processing) ->
	  collapse_syntactic_analysis(SyntAnalysis0, SyntAnalysis)
	; SyntAnalysis = SyntAnalysis0
	).
