% File:	    consulttt.pl
% Module:   consulttt
% Author:   tcr
% Purpose:  Consult tagged text and resolve part-of-speech ambiguity 
%           for single word tokens


% ----- Module declaration and exported predicates

:- module(consulttt,                [ consult_tagged_text/5 ]).


% ----- Imported predicates

:- use_module( library( lists ),    [ nth1/3 ] ).


/* CONSULT_TAGGED_TEXT

Category label ambiguity resolution. consult_tagged_text/5 resolves
category label ambiguity for single word tokens by consulting the
output of the stochastic tagger.


consult_tagged_text( +Definitions, +VarInfoList, +TaggedTextIn,
		     -TaggedTextOut, ?Index ?PreviousLabel) :-

Definitions has multiword tokens, and CLA 
TaggedTextIn has no multiword tokens and no CLA 
TaggedTextOut has multiword tokens and no CLA
(Multiword items are assumed not to be ambiguous.)

Also have to worry about making complement information available for verbs

*/

consult_tagged_text(Definitions, VarInfoList, TaggedText, CatLabText, Index) :-
    consult_tagged_text(Definitions, VarInfoList, TaggedText, CatLabText, Index, none).

consult_tagged_text( [], [], _, [], _, _).

% In ADJ X-ed, force "X-ed" to be adj, e.g. a moderate sized vessel
consult_tagged_text( [ lexicon:[ lexmatch:LexMatch, inputmatch:InputMatch | _ ] | MoreDefinitions ],
                     [ _VarInfoAtom:VarInfoList | MoreVarInfoList ],
                     TaggedTextIn,
                     [ ThisItem | MoreTaggedTextOut ],
                     IndexIn, PrevLabel ) :-

    can_be_pastP(VarInfoList),

    PrevLabel == adj,

    length( InputMatch, Len ),

    % get the tag of the *last* word in the InputMatch list
    RealIndexIn is IndexIn + Len,

    nth1( RealIndexIn, TaggedTextIn, [ _TagToken, Tag ] ),

    Tag \== aux,
    !,
    IndexOut is IndexIn + Len,

    Info = [ lexmatch(LexMatch), inputmatch(InputMatch), tag(Tag) ],

    ( Len = 1 
      -> functor( ThisItem, adj, 1 ),
         arg( 1, ThisItem, Info )
      ;  functor( ThisItem, adj, 1 ),
         arg( 1, ThisItem, Info )
    ),

    consult_tagged_text( MoreDefinitions, MoreVarInfoList, TaggedTextIn, MoreTaggedTextOut, IndexOut, Tag ).

% Force "in" to be a preposition
consult_tagged_text( [ lexicon:[ lexmatch:LexMatch, inputmatch:InputMatch, 
                       records:[ lexrec:[base:['In']| _ ] |_ ] | _ ] | MoreDefinitions ],
                     [ _VarInfoAtom:[_Label:_ | _ ] | MoreVarInfoList ],
                     TaggedTextIn,
                     [ ThisItem | MoreTaggedTextOut ],
                     IndexIn,_PrevLab ) :-

    !, 

    length( InputMatch, Len),

    IndexOut is IndexIn + Len,

    ThisItem = prep( [lexmatch(LexMatch), inputmatch(InputMatch), tag(prep)]),

    consult_tagged_text( MoreDefinitions, MoreVarInfoList, TaggedTextIn, MoreTaggedTextOut, IndexOut,prep ).


% !!! Force "run" to be a verb
consult_tagged_text( [ lexicon:[ lexmatch:LexMatch, inputmatch:InputMatch, 
                       records:[ lexrec:[base:['run']| _ ] |_ ] | _ ] | MoreDefinitions ],
                     [ _VarInfoAtom:[_Label:_ | _ ] | MoreVarInfoList ],
                     TaggedTextIn,
                     [ ThisItem | MoreTaggedTextOut ],
                     IndexIn,_PrevLab ) :-

    !, IndexOut is IndexIn + 1,

    ThisItem = verb( [lexmatch(LexMatch), inputmatch(InputMatch), tag(verb)]),

    consult_tagged_text( MoreDefinitions, MoreVarInfoList, TaggedTextIn, MoreTaggedTextOut, IndexOut,verb ).


consult_tagged_text( [ lexicon:[ lexmatch:LexMatch, inputmatch:InputMatch | _ ] | MoreDefinitions ],
                     [ _VarInfoAtom:VarInfoList | MoreVarInfoList ],
                     TaggedTextIn,
                     [ ThisItem | MoreTaggedTextOut ],
                     IndexIn,_PrevLab ) :-

    length( InputMatch, Len ),

    RealIndexIn is IndexIn + Len - 1,

    % get the tag of the *last* word in the InputMatch list
    nth1( RealIndexIn, TaggedTextIn, [ _TagToken, Tag ] ), !,

    VarInfoList = [Label:_ | _ ],

    ( Len = 1 
      -> functor( ThisItem, Tag, 1 ),
         arg( 1, ThisItem, Info ),
         POS = Tag
      ;  functor( ThisItem, Label, 1 ),
         arg( 1, ThisItem, Info ),
         POS = Label
    ),

    Info = [ lexmatch(LexMatch), inputmatch(InputMatch), tag(POS) ],

    IndexOut is IndexIn + Len,

    (can_be_adj(VarInfoList)
     -> ThisLab = adj
     ;  ThisLab = Tag
    ),

    consult_tagged_text( MoreDefinitions, MoreVarInfoList, TaggedTextIn, MoreTaggedTextOut, IndexOut, ThisLab ).



consult_tagged_text( [ shapes:[ inputmatch:ShapesList, features:FeatList | _ ] | MoreDefinitions ],
                     [ _ | MoreVarInfoList ],
                     TaggedTextIn,
                     [ shapes([ inputmatch(ShapesList),features(FeatList) ]) | MoreTaggedTextOut ],
                     IndexIn, _PrevLab ) :- 

    !,
    length( ShapesList, Len ),

    IndexOut is IndexIn + Len,

    consult_tagged_text( MoreDefinitions, MoreVarInfoList, TaggedTextIn, MoreTaggedTextOut, IndexOut, shapes ).


consult_tagged_text( [ punctuation:[ _Lexmatch, inputmatch:InputMatch | _ ] | MoreDefinitions ],
                     [ _ | MoreVarInfoList ],
                     TaggedTextIn,
                     [ punc([ inputmatch(InputMatch) ]) | MoreTaggedTextOut ],
                     IndexIn, _PrevLab ) :- 

    !,
    IndexOut is IndexIn + 1,

    consult_tagged_text( MoreDefinitions, MoreVarInfoList, TaggedTextIn, MoreTaggedTextOut, IndexOut, punc ).



consult_tagged_text( [ unknown:[ inputmatch:[Token]| _ ] | MoreDefinitions ],
                     [ _ | MoreVarInfoList ],
                     TaggedTextIn,
                     [ ThisItem | MoreTaggedTextOut ],
                     IndexIn, _PrevLab ) :- 


    nth1( IndexIn, TaggedTextIn, [ Token, Tag ] ), !,  

    (  memberchk( Tag, [ bl, ba, dq, ap, bq, at, nm, dl, pc,
                         up, am ,ax ,pl, eq, tl, un, lb, rb, ls, gr ] )

       -> Label = punc
       ;  Label = not_in_lex
    ),

    functor( ThisItem, Label, 1),
    
    arg( 1, ThisItem, [ inputmatch([Token]) ] ),

    IndexOut is IndexIn + 1,

    consult_tagged_text( MoreDefinitions, MoreVarInfoList, TaggedTextIn, MoreTaggedTextOut, IndexOut, unknown ).


% --------

% can_be_pastP([]) :- !,fail.
can_be_pastP([verb:[pastpart]|_]) :- !.
can_be_pastP([_|More]) :-
	can_be_pastP(More).


% ----------

% can_be_adj([]) :- !,fail.
can_be_adj([adj:_|_]) :- !.
can_be_adj([_|More]) :-
	can_be_adj(More).
