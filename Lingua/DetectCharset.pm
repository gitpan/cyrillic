# Package Lingua::DetectCharset
# Version 1.00
# Part of "WWW Cyrillic Encoding Suite"
# Get docs and newest version from
#	http://www.neystadt.org/cyrillic/
#
# Copyright (c) 1997-98, John Neystadt <http://www.neystadt.org/john/>
# You may install this script on your web site for free
# To obtain permision for redistribution or any other usage
#	contact john@neystadt.org.
#
# Drop me a line if you deploy this script on tyour site.

package Lingua::DetectCharset;

$VERSION = "1.00";

use Convert::Cyrillic;
use Lingua::DetectCharset::StatKoi;
use Lingua::DetectCharset::StatWin;

$PairSize = 2;
$MinRatio = 1.5; # Mark must be in $MinRatio times larger of 
			# one encoding than another to decide upon, or ENG.
$DoubtRatio = 1;
$DoubtLog = 'doubt.txt';

sub Detect {
	my (@Data) = @_;
	my ($KoiMark) = GetCodeScore ('Koi', @Data);
	my ($WinMark) = GetCodeScore ('Win', @Data);

#	print "GetEncoding: Koi8 - $KoiMark, Win - $WinMark\n";

	$KoiRatio =  $KoiMark/($WinMark+1);
	$WinRatio =  $WinMark/($KoiMark+1);

	if ($DoubtLog) {
		if (($KoiRatio < $MinRatio && $KoiRatio > $DoubtRatio) ||
			($WinRatio < $MinRatio && $WinRatio > $DoubtRatio)) {
				open Log, ">>$DoubtLog";
				print Log " Koi8 - $KoiMark, Win - $WinMark\n", 
					join ("\n", @Data), "\n\n";
				close Log;
		}
	}

	return 'KOI8' if $KoiRatio > $WinRatio;	# $MinRatio;
#	return 'WIN'; 				# if $WinRatio > $MinRatio;

	# We do english, only if no single cyrillic character were detected
	return 'WIN' if $WinRatio + $KoiRatio > 0;
	return 'ENG';
}

sub GetCodeScore {
	my ($Code, @Data) = @_;
	my ($Table);

	if ($Code eq 'Koi') {
		$Table = \%Lingua::DetectCharset::StatKoi::StatsTableKoi;
	} elsif ($Code eq 'Win') {
		$Table = \%Lingua::DetectCharset::StatWin::StatsTableWin;
	} else {
		die "Don't know $Code!\n";
	}

	my ($Mark, $i);
	for (@Data) {
		s/[\n\r]//go;
		$_ = Convert::Cyrillic::toLower ($_, $Code);
		for (split (/[\.\,\-\s\:\;\?\!\'\"\(\)\d<>]+/o)) {
			for $i (0..length ()-$PairSize) {
				$Mark += ${$Table} {substr ($_, $i, $PairSize)};
			}
		}
	}

	$Mark;
}
1;

__END__

=head1 NAME

Lingua::DetectCharset - Routine for automatically detecting cyrillic charset.

=head1 SYNOPSIS

use Lingua::DetectCharset;

$Charset = Lingua::DetectCharset::Detect ($Buffer); 

The returned $Ecoding is either 'WIN', 'KOI8' or 'ENG'. The last is return when 
no single cyrillic token are found in buffer.

=head1 DESCRIPTION

This package implements routine for detection charset of the given text snippet. 
Snippet may contain anything from few words to many kilobytes of text, and may 
have line breaks, English text and html tags embedded. 

This routine is implemented using algorithm of statistical analysis of text, 
which was proved to be very efficient and showed around B<99.98% acccuracy> in 
tests.

=head1 AUTHOR

John Neystadt <john@neystadt.org>

=head1 SEE ALSO

perl(1), Convert::Cyrillic(3).

=head1 NOTES

Part of "WWW Cyrillic Encoding Suite"
Get docs and newest version from
	http://www.neystadt.org/cyrillic/

Copyright (c) 1997-98, John Neystadt <http://www.neystadt.org/john/>
You may install this script on your web site for free
To obtain permision for redistribution or any other usage
contact john@neystadt.org.

Drop me a line if you deploy this script on your site.

=cut
