
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

% File:	    metamap_stop_phrase.pl
% Module:   MetaMap
% Author:   Lan
% Purpose:  Improve efficiency by avoiding fully processing phrases with
%           no candidates

% Source:   NLM TC, OMED TC, NCBI TC and MMI TS
% In Full.2012AA, we took the top 228 entries (all those with frequency of at least 10),
% giving us 44685 of the 58176 stop phrases collected, i.e., 76.81%.
% In 2011AA.NLM, we took the top 375 entries (all those with frequency of at least 10),
% giving us 63528 of the 81485 stop phrases collected, i.e., 77.96%.

:- module(metamap_stop_phrase, [
    stop_phrase/2
    ]).

stop_phrase('and', [conj]).
stop_phrase(')', [punc]).
stop_phrase('were', [aux]).
stop_phrase('was', [aux]).
stop_phrase(':', [punc]).
stop_phrase('or', [conj]).
stop_phrase(',', [punc]).
stop_phrase('is', [aux]).
stop_phrase(').', [punc,punc]).
stop_phrase('ab -', [head,punc]).
stop_phrase(';', [punc]).
stop_phrase('had', [aux]).
stop_phrase('are', [aux]).
stop_phrase('be', [aux]).
stop_phrase('have', [aux]).
stop_phrase('we', [pron]).
stop_phrase('been', [aux]).
stop_phrase('that', [compl]).
stop_phrase('but', [conj]).
stop_phrase('has', [aux]).
stop_phrase('both', [conj]).
stop_phrase('which', [pron]).
stop_phrase('(', [punc]).
stop_phrase('it', [pron]).
stop_phrase('that', [pron]).
stop_phrase('as', [conj]).
stop_phrase('who', [pron]).
stop_phrase('when', [conj]).
stop_phrase('there', [adv]).
stop_phrase('however,', [adv,punc]).
stop_phrase('either', [conj]).
stop_phrase('-', [punc]).
stop_phrase('of', [prep]).
stop_phrase('can', [modal]).
stop_phrase('than', [prep]).
stop_phrase('may', [modal]).
stop_phrase('did', [aux]).
stop_phrase(')-', [punc,punc]).
stop_phrase('could', [modal]).
stop_phrase('also', [adv]).
stop_phrase('while', [conj]).
stop_phrase('although', [conj]).
stop_phrase('in', [prep]).
stop_phrase('they', [pron]).
stop_phrase('with', [prep]).
stop_phrase('whereas', [conj]).
stop_phrase('--', [punc,punc]).
stop_phrase('et', [conj]).
stop_phrase('versus', [conj]).
stop_phrase('am', [aux]).
stop_phrase('as well as', [conj]).
stop_phrase('by', [prep]).
stop_phrase('for', [prep]).
stop_phrase('plus', [conj]).
stop_phrase('whether', [compl]).
stop_phrase('vs', [conj]).
stop_phrase('[', [punc]).
stop_phrase('underwent', [verb]).
stop_phrase('after', [conj]).
stop_phrase('being', [aux]).
stop_phrase('since', [conj]).
stop_phrase('(10', [punc,shapes]).
stop_phrase(']', [punc]).
stop_phrase('having', [aux]).
stop_phrase('all', [pron]).
stop_phrase('would', [modal]).
stop_phrase('a', [det]).
stop_phrase('and/or', [conj]).
stop_phrase('10', [shapes]).
stop_phrase('than 0.001', [prep,shapes]).
stop_phrase('this', [pron]).
stop_phrase('to', [prep]).
stop_phrase('because', [conj]).
stop_phrase('j.', [head,punc]).
stop_phrase('does', [aux]).
stop_phrase('consisted', [verb]).
stop_phrase('(6', [punc,shapes]).
stop_phrase('before', [prep]).
stop_phrase('do', [aux]).
stop_phrase('differ', [verb]).
stop_phrase('might', [modal]).
stop_phrase('on', [prep]).
stop_phrase('will', [modal]).
stop_phrase('than 0.01', [prep,shapes]).
stop_phrase('this', [det]).
stop_phrase('undergoing', [verb]).
stop_phrase('(+', [punc,punc]).
stop_phrase('],', [punc,punc]).
stop_phrase('should', [modal]).
stop_phrase('than 0.05', [prep,shapes]).
stop_phrase('< 0.01', [punc,shapes]).
stop_phrase('furthermore,', [adv,punc]).
stop_phrase('and -', [conj,punc]).
stop_phrase('if', [conj]).
stop_phrase('to that', [prep,pron]).
stop_phrase('of which', [prep,pron]).
stop_phrase('those', [det]).
stop_phrase('in which', [prep,pron]).
stop_phrase('< 0.05', [punc,shapes]).
stop_phrase('ab - to', [mod,punc,adv]).
stop_phrase('< 0.001', [punc,shapes]).
stop_phrase('<', [punc]).
stop_phrase('most', [pron]).
stop_phrase('thus,', [adv,punc]).
stop_phrase('must', [modal]).
stop_phrase('(-', [punc,punc]).
stop_phrase('].', [punc,punc]).
stop_phrase('from', [prep]).
stop_phrase('some', [pron]).
stop_phrase('than that', [prep,pron]).
stop_phrase('thus', [adv]).
stop_phrase('each', [pron]).
stop_phrase('if', [compl]).
stop_phrase('nor', [conj]).
stop_phrase('(7', [punc,shapes]).
stop_phrase('(8', [punc,shapes]).
stop_phrase('cmf', [conj]).
stop_phrase('to those', [prep,det]).
stop_phrase('(9', [punc,shapes]).
stop_phrase('25', [shapes]).
stop_phrase('[14c', [punc,head]).
stop_phrase('these', [det]).
stop_phrase('even', [adv]).
stop_phrase('still', [adv]).
stop_phrase('the', [det]).
stop_phrase('ab - 1.', [mod,punc,shapes,punc]).
stop_phrase('here', [adv]).
stop_phrase('neither', [conj]).
stop_phrase('of whom', [prep,pron]).
stop_phrase('than those', [prep,pron]).
stop_phrase('than .01', [prep,punc,shapes]).
stop_phrase('(-6', [punc,punc,shapes]).
stop_phrase('(-7', [punc,punc,shapes]).
stop_phrase('[35s', [punc,head]).
stop_phrase('a.', [det,punc]).
stop_phrase('al.,', [head,punc,punc]).
stop_phrase('at', [prep]).
stop_phrase('moreover,', [adv,punc]).
stop_phrase('therefore,', [adv,punc]).
stop_phrase('with that', [prep,pron]).
stop_phrase('with those', [prep,det]).
stop_phrase('(11', [punc,shapes]).
stop_phrase('[125i', [punc,head]).
stop_phrase('a.,', [det,punc,punc]).
stop_phrase('before', [conj]).
stop_phrase('consisting', [verb]).
stop_phrase('me', [pron]).
stop_phrase('than .05', [prep,punc,shapes]).
stop_phrase('6', [shapes]).
stop_phrase('became', [verb]).
stop_phrase('in all', [prep,pron]).
stop_phrase('quantified', [verb]).
stop_phrase('18', [shapes]).
stop_phrase('7,', [shapes,punc]).
stop_phrase('8', [shapes]).
stop_phrase('>', [punc]).
stop_phrase('during', [prep]).
stop_phrase('important', [head]).
stop_phrase('of them', [prep,pron]).
stop_phrase('though', [conj]).
stop_phrase('(17', [punc,shapes]).
stop_phrase('7', [shapes]).
stop_phrase('done', [aux]).
stop_phrase('he', [pron]).
stop_phrase('influenced', [verb]).
stop_phrase('of 10', [prep,shapes]).
stop_phrase('seems', [verb]).
stop_phrase('usually', [adv]).
stop_phrase('where', [pron]).
stop_phrase('20', [shapes]).
stop_phrase('< .05', [punc,punc,shapes]).
stop_phrase('al.', [head,punc]).
stop_phrase('of these', [prep,det]).
stop_phrase('pm', [head]).
stop_phrase('vs.', [conj,punc]).
stop_phrase('11', [shapes]).
stop_phrase('12', [shapes]).
stop_phrase('9', [shapes]).
stop_phrase('] ab -', [punc,head,punc]).
stop_phrase('abolished', [verb]).
stop_phrase('both', [pron]).
stop_phrase('de', [prep]).
stop_phrase('j.,', [head,punc,punc]).
stop_phrase('undergo', [verb]).
stop_phrase('until', [conj]).
stop_phrase('0', [shapes]).
stop_phrase('6,', [shapes,punc]).
stop_phrase('8,', [shapes,punc]).
stop_phrase('9,', [shapes,punc]).
stop_phrase('also,', [adv,punc]).
stop_phrase('an', [det]).
stop_phrase('become', [verb]).
stop_phrase('consists', [verb]).
stop_phrase('despite', [conj]).
stop_phrase('e.g.', [conj]).
stop_phrase('influence', [verb]).
stop_phrase('therefore', [adv]).
stop_phrase('up', [prep]).
stop_phrase('(-8', [punc,punc,shapes]).
stop_phrase('(-9', [punc,punc,shapes]).
stop_phrase('(10%', [punc,shapes]).
stop_phrase('14,', [shapes,punc]).
stop_phrase('21', [shapes]).
stop_phrase('50', [shapes]).
stop_phrase('< .01', [punc,punc,shapes]).
stop_phrase('distinguish', [verb]).
stop_phrase('regarding', [verb]).
stop_phrase('seem', [verb]).
stop_phrase('than 0.0001', [prep,shapes]).
stop_phrase('with regard', [prep,head]).
stop_phrase('without', [prep]).
stop_phrase('yielded', [verb]).
stop_phrase('''', [punc]).
stop_phrase('(12', [punc,shapes]).
stop_phrase('(19', [punc,shapes]).
stop_phrase('(7%', [punc,shapes]).
stop_phrase('16', [shapes]).
stop_phrase('=', [punc]).
stop_phrase('accompanied', [verb]).
stop_phrase('from that', [prep,pron]).
stop_phrase('in whom', [prep,pron]).
stop_phrase('once', [conj]).
stop_phrase('so', [prep]).
stop_phrase('than 0.005', [prep,shapes]).
stop_phrase('that there', [compl,adv]).
stop_phrase('the importance', [det,head]).
stop_phrase('them', [pron]).
stop_phrase('v-', [conj]).
