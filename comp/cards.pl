#!/usr/bin/perl 

# Created: 西元2015年01月09日 11時38分54秒
# Last Edit: 2020 Apr 17, 07:45:59 PM
# $Id$

=head1 NAME

cards.pl - jigsaw and compcomp card creation from yaml files

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

perl ../cclass/cards.pl --list -t ./$TOPIC -f namequestionsA7 && xelatex ./$TOPIC/{jigsaw,quiz}_$STORY_$FORM.tex && evince {jigsaw,quiz}_$STORY_$FORM.pdf

=cut

package Script;
use strict;
use warnings;
use Moose;
with 'MooseX::Getopt';

has 'man' => (is => 'ro', isa => 'Bool');
has 'help' => (is => 'ro', isa => 'Bool');
has 'list' => (traits => ['Getopt'], is => 'ro', isa => 'Bool', cmd_aliases => 'l');
has 'topic' => (traits => ['Getopt'], is => 'ro', isa => 'Str',
		cmd_aliases => 't',);
has 'format' => (traits => ['Getopt'], is => 'ro', isa => 'Str',
		cmd_aliases => 'f',);

package main;

use Pod::Usage;
use YAML qw/LoadFile DumpFile/;
use IO::All;
use Text::Template;

my %romanize = (
	0 => "Zero", 1 => "One", 2 => "Two", 3 =>"Three"
	, 4 => "Four", 5 => "Five", 6 => "Six", 7 =>"Seven"
	, 8 => "Eight", 9 => "Nine", 10 => "Ten", 11 =>"Eleven" 
);

=head1 DESCRIPTION

YAML content is in $COURSE/$TOPIC/cards.yaml files in $STORY/{jigsaw,compcomp}/$FORM/ mappings

The list arg is for latex description list jigsaw cards. The format arg is for the jigsaw quiz template in methodology/tmpl/tags.

=cut

my $script = Script->new_with_options;
pod2usage(1) if $script->help;
pod2usage(-exitstatus => 0, -verbose => 2) if $script->man;
my $list = ""; $list = "_list" if $script->list;
my $topic_dir = "./" . $script->topic;
my $format = $script->format;
my $cards = LoadFile "$topic_dir/cards.yaml";

for my $t ( keys %$cards ) {
	my $topic = $cards->{$t};
	next unless ref $topic eq 'HASH';
	my $compcomp = $topic->{compcomp};
	for my $f ( keys %$compcomp ) {
		my $form = $compcomp->{$f};
                my $pairtmpl = Text::Template->new( type => 'file',
                        source =>  '/home/drbean/methodology/tmpl/compcompA4.tmpl' ,
                        delimiters => [ '<TMPL>', '</TMPL>' ]);
		my $quiztmpl = Text::Template->new( type => 'file',
			source =>  '/home/drbean/methodology/tmpl/namequestionsB7.tmpl' ,
			delimiters => [ '<TMPL>', '</TMPL>' ]);
                my $cio = io "$topic_dir/compcomp_$t" . "_$f.tex";
		my $qio = io "$topic_dir/compcomp_quiz_$t" . "_$f.tex";
		my $hio = io "$topic_dir/compcomp_quiz_$t" . "_$f.html";
		my $n = 1;
		my $questions = $form->{quiz};
		for my $qa ( @$questions ) {
			$form->{ "q$n" } = $qa->{question};
			$n++;
		}
                $cio->print( $pairtmpl->fill_in( hash=> $form ) );
		$qio->print( $quiztmpl->fill_in( hash=> $form ) );
		my @htmlq = map { $form->{"q$_"} } 1 .. $n-1;
		$,="\n<li>";
		$hio->print("<h2>$form->{identifier}</h2><ol>", @htmlq);
	}
	my $jigsaw = $topic->{jigsaw};
	for my $f ( keys %$jigsaw ) {
		my $form = $jigsaw->{$f};
		# my $tmplfile = "8_ABC_jigsaw_" . $list . "cards.tmpl";
		my $tmplfile = "jigsaw_D" . $list . ".tmpl";
		# my $tmplfile = "jigsaw" . $list . ".tmpl";
		# my $tmplfile = "4_scenario_12_cards" . $list . ".tmpl";
		my $fourtmpl = Text::Template->new( type => 'file',
			source =>  "/home/drbean/methodology/tmpl/tags/$tmplfile" ,
			delimiters => [ '<TMPL>', '</TMPL>' ])
			or die "Couldn't construct template: $Text::Template::ERROR";
		my $quiztmpl = Text::Template->new( type => 'file',
            source =>  "/home/drbean/methodology/tmpl/tags/$format.tmpl" ,
			delimiters => [ '<TMPL>', '</TMPL>' ]);
		my $fio = io "$topic_dir/jigsaw_$t" . "_student.tex";
		my $qio = io "$topic_dir/quiz_$t" . "_$f.tex";
		my $hio = io "$topic_dir/quiz_${t}_$f.html";
		my $form;
		my $n = 1;
		my $questions = $form->{quiz};
		for my $qa ( @$questions ) {
			$form->{ "q$n" } = $qa->{question};
			$n++;
		}
		$form->{topic} = $t;
		$form->{form} = $romanize{ $f };
		my $result = $fourtmpl->fill_in( hash=> $form  ) ;
		if (defined $result) { $fio->print( $result  )   }
			else { die "Couldn't fill in template: $Text::Template::ERROR"   }
		$qio->print( $quiztmpl->fill_in( hash=> $form ) );
		my @htmlq = map { $form->{"q$_"} } 1 .. $n-1;
		$,="\n<h1><li>";
		$hio->print("<h2>$form->{identifier}</h2><ol>", @htmlq);
	}
}

=head1 AUTHOR

Dr Bean C<< <drbean at cpan, then a dot, (.), and org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2015 Dr Bean, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# End of cards.pl

# vim: set ts=8 sts=4 sw=4 noet:


