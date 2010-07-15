:- module(mmserver,[ main/0 ]).

% :- use_module(library(basics),      [ member/2 ]).
:- use_module(library(prologbeans), [ register_query/2, start/0, start/1 ]).
:- use_module(library(codesio),     [ read_from_codes/2 ]).
:- use_module(library(system),      [ environ/2 ]).

:- use_module(tagger(tagger_access),[
        get_tagger_server_hosts_and_port/3

   ]).

:- use_module(wsd(wsdmod),[
        get_WSD_server_hosts_and_port/3 
   ]).

:- use_module(skr(skr_fe), [
	postprocess_sentences/9,
	initialize_skr/4,
	process_text/11
   ]).

:- use_module(skr(skr),[
	initialize_skr/1,
	stop_skr/0
   ]).

:- use_module(skr(skr_utilities),[
	output_should_be_bracketed/1
    ]).

:- use_module(skr_lib(nls_system), [
	add_to_control_options/1,
	subtract_from_control_options/1,
	reset_control_options/1,
	toggle_control_options/1,
	get_control_options_for_modules/2,
	set_control_options/1,        				    
	set_control_values/2,
	control_option/1,
	parse_command_line/1,
	parse_command_line/3,
	interpret_options/4,
	interpret_args/4		   
    ]).

:- use_module(skr_lib(nls_strings), [
	split_string_completely/3
    ]).

:- use_module(skr_lib(negex), [ compute_negex/4, generate_negex_output/1 ]).

%% Register acceptable queries and start the server (using default port)
main :-
    environ('MMSERVER_PORT', ServerPortEnv),
    atom_codes(ServerPortEnv, ServerPortChars),
    number_codes(ServerPort, ServerPortChars),
    environ('ACCEPTED_HOSTS', AcceptedHostsEnv),
    atom_codes(AcceptedHostsEnv, AcceptedHostsChars),
    append(AcceptedHostsChars, ".", AcceptedHostsCharsWithPeriod),
    read_from_codes(AcceptedHostsCharsWithPeriod, AcceptedHosts),
    ServerOptions=[port(ServerPort),accepted_hosts(AcceptedHosts)],
    format(user_error, 'Server options: ~q~N', [ServerOptions]),
    register_query(get_options(AllOptions), get_options(AllOptions)),
    register_query(process_string(Input,Output), process_string(Input,Output)),
    register_query(reset_options, reset_options),
    register_query(set_options(Options), set_options(Options)),
    register_query(unset_options(Options), unset_options(Options)),
    % ArgSpecs=[aspec(infile,mandatory,file,read,
    % 		    user_input,
    % 		    'Input file containing labelled utterances'),
    % 	      aspec(outfile,mandatory,file,write,
    % 		    or(['<infile>','.','out'],user_output),
    % 		    'Output file')
    % 	      ],
    parse_command_line(CLTerm),
    CLTerm=command_line(Options,Args),
    initialize_skr(Options, Args, _IArgs, IOptions),
    add_to_control_options(IOptions),
    start(ServerOptions).

set_options(OptionString) :-
    append(OptionString, ".", OptionStringWithPeriod),
    read_from_codes(OptionStringWithPeriod, RawCL),
    parse_command_line(RawCL, Options, Args),
    get_control_options_for_modules([metamap], AllOptions),
    interpret_options(Options, AllOptions, metamap, IOptions),
    ArgSpecs=[aspec(infile,mandatory,file,read,
		    user_input,
		    'Input file containing labelled utterances'),
	      aspec(outfile,mandatory,file,write,
		    or(['<infile>','.','out'],user_output),
		    'Output file')
	      ],
    interpret_args(IOptions, ArgSpecs, Args, IArgs),
    ( \+ member(iopt(machine_output,none),IOptions) -> 
	append([iopt(machine_output,none)], IOptions, IOptionsFinal)),
    add_to_control_options(IOptionsFinal),
    set_control_values(IOptionsFinal,IArgs).

unset_options(OptionString) :-
    append(OptionString, ".", OptionStringWithPeriod),
    read_from_codes(OptionStringWithPeriod, RawCL),
    parse_command_line(RawCL, Options, Args),
    get_control_options_for_modules([metamap], AllOptions),
    interpret_options(Options, AllOptions, metamap, IOptions),
    ArgSpecs=[aspec(infile,mandatory,file,read,
		    user_input,
		    'Input file containing labelled utterances'),
	      aspec(outfile,mandatory,file,write,
		    or(['<infile>','.','out'],user_output),
		    'Output file')
	      ],
    interpret_args(IOptions, ArgSpecs, Args, _IArgs),
    subtract_from_control_options(IOptions).

get_options(AllOptions) :-
	setof(X,nls_system:control_option(X),AllOptions).

reset_options :-
	reset_control_options([metamap]),
	IOptions=[iopt(machine_output,none)],
	add_to_control_options(IOptions).

process_string(Input,Output) :-
	TagOption = tag,
	split_string_completely(Input,"\n",Strings),
	InterpretedArgs = [iarg(infile,aspec(infile,mandatory,file,read,no_default,
					     'Input file containing labelled utterances'),
				[name(user_input),stream(user_input)]),
			   iarg(outfile,aspec(outfile,mandatory,file,write,no_default,'Output file'),
				[name(user_output),stream(user_output)])],
	get_tagger_server_hosts_and_port(TaggerServerHosts, TaggerForced, TaggerServerPort),
	get_WSD_server_hosts_and_port(WSDServerHosts, WSDForced, WSDServerPort),
	process_text(Strings,
		     TagOption, TaggerServerHosts, TaggerForced, TaggerServerPort,
		     WSDServerHosts, WSDForced, WSDServerPort,
		     ExpRawTokenList, AAs, MMResults),
	IOptions=[iopt(machine_output,none)],
	output_should_be_bracketed(BracketedOutput),
	postprocess_text_mmserver(Strings, BracketedOutput, InterpretedArgs,
		 IOptions,  ExpRawTokenList, AAs, MMResults, Output).

postprocess_text_mmserver(Lines0, BracketedOutput, InterpretedArgs,
			  IOptions,  ExpRawTokenList, AAs, MMResults, AllMMO) :-
	MMResults = mm_results(Lines0, _TagOption, _ModifiedLines, _InputType,
			       Sentences, _CoordSentences, OrigUtterances, DisambMMOutput),

	compute_negex(ExpRawTokenList, Lines0, DisambMMOutput, NegationTerms),
	generate_negex_output(NegationTerms),
	postprocess_sentences(OrigUtterances, NegationTerms, InterpretedArgs, IOptions, AAs,
			      Sentences, BracketedOutput, DisambMMOutput,
			      AllMMO).
