# Package Convert::Cyrillic
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

package Convert::Cyrillic;

$VERSION = "1.0";

$UCase {'KOI'} = "áâ÷çäå³öúéêëìíîïğòóôõæèãşûı\377ùøüàñ";
$LCase {'KOI'} = "ÁÂ×ÇÄÅ£ÖÚÉÊËÌÍÎÏĞÒÓÔÕÆÈÃŞÛİßÙØÜÀÑ";
$UCase {'WIN'} = "ÀÁÂÃÄÅ¨ÆÇÈÉÊËÌÍÎÏĞÑÒÓÔÕÖ×ØÙÚÛÜİŞß";
$LCase {'WIN'} = "àáâãäå¸æçèéêëìíîïğñòóôõö÷øùúûüış\377";
$UCase {'DOS'} = "€‚ƒ„…ğ†‡ˆ‰Š‹Œ‘’“”•–—˜™š›œŸ";
$LCase {'DOS'} = " ¡¢£¤¥ñ¦§¨©ª«¬­®¯àáâãäåæçèéêëìíîï";

$tab{"KOI8"}="áâ÷çäå³öúéêëìíîïğòóôõæèãşûı\377ùøüàñÁÂ×ÇÄÅ£ÖÚÉÊËÌÍÎÏĞÒÓÔÕÆÈÃŞÛİßÙØÜÀÑ";
$tab{"DOS"}="€‚ƒ„…ğ†‡ˆ‰Š‹Œ‘’“”•–—˜™š›œŸ ¡¢£¤¥ñ¦§¨©ª«¬­®¯àáâãäåæçèéêëìíîï";
$tab{"ISO"}="°±²³´µ¡¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏĞÑÒÓÔÕñÖ×ØÙÚÛÜİŞßàáâãäåæçèéêëìíîï";
$tab{"WIN"}="ÀÁÂÃÄÅ¨ÆÇÈÉÊËÌÍÎÏĞÑÒÓÔÕÖ×ØÙÚÛÜİŞßàáâãäå¸æçèéêëìíîïğñòóôõö÷øùúûüış\377";
$tab{"VOL"}="ABVGDE¨ÆZIJKLMNOPRSTUFXC×ØW~Y'İŞßabvgde¸æzijklmnoprstufxc÷øw~y'ış\377";
$tab{"MAC"}="€‚ƒ„…İ†‡ˆ‰Š‹Œ‘’“”•–—˜™š›œŸàáâãäåŞæçèéêëìíîïğñòóôõö÷øùúûüışß";
#	     1234567890123456789012345678901234567890123456789012345678901234567890

sub cstocs {
	my ($Src, $Dst, $Buf) = @_;
	$Src = uc ($Src); $Src .= '8' if $Src eq 'KOI';
	$Dst = uc ($Dst); $Dst .= '8' if $Dst eq 'KOI';

	eval "\$Buf =~ tr/$tab{$Src}/$tab{$Dst}/";
	if ($Dst eq 'VOL') {
		$Buf =~s/¨/YO/go; $Buf =~s/Æ/ZH/go; $Buf =~s/×/CH/go;
		$Buf =~s/Ø/SH/go; $Buf =~s/İ/E\'/go; $Buf =~s/Ş/YU/go; 
		$Buf =~s/ß/YA/go; $Buf =~s/¸/yo/go; $Buf =~s/æ/zh/go;  
		$Buf =~s/÷/ch/go; $Buf =~s/ø/sh/go; $Buf =~s/ı/e\'/go; 
		$Buf =~s/ş/yu/go; $Buf =~s/\377/ya/go;
	}
	$Buf;
}

sub toLower {
	my ($s, $Code) = @_;
	$Code = uc ($Code);
	eval ("\$s =~ tr/$UCase{$Code}/$LCase{$Code}/");
	$s;
}

sub toUpper {
	my ($s, $Code) = @_;
	$Code = uc ($Code);
	eval ("\$s =~ tr/$LCase{$Code}/$UCase{$Code}/");
	$s;
}

__END__

=head1 NAME

Convert::Cyrillic - Routines for converting from one cyrillic charset to another.

=head1 SYNOPSIS

	use Convert::Cyrillic;

	$src = 'koi8';
	$dst = 'win';
	$SrcBuf = 'text in koi8 here';
	$DstBuf = Convert::Cyrillic::cstocs ($Src, $Dst, $SrcBuf); 

=head1 DESCRIPTION

This package implements routine for converting from one cyrillic charset to 
another. It is intended to be used from cgi's which need built-in support for
translations. For example, you may wish to use it in form processor to translate 
from user encoding to one used by your site.

Where B<$Src> and B<$Dst> are one of: 

	KOI8 - for KOI8-R 
	DOS - for DOS, alternative, CP-866 
	ISO - for ISO-8859-5 
	WIN - for WIN-1251 
	VOL - for Volapuk (transliteration) 
	MAC - for Macintosh 

Buffer may contain line breaks, which are preserved.

=head1 NOTES

Part of "WWW Cyrillic Encoding Suite"
Get docs and newest version from
	http://www.neystadt.org/cyrillic/

Copyright (c) 1997-98, John Neystadt <http://www.neystadt.org/john/>
You may install this script on your web site for free.
To obtain permision for redistribution or any other usage
contact john@neystadt.org.

Drop me a line if you deploy this script on your site.

=head1 AUTHOR

John Neystadt <john@neystadt.org>

=head1 SEE ALSO

perl(1), Lingua::DetectCharset(3).

=cut
