package cyrillic;
$cyrillic::VERSION = '2.09';

use 5.005_02;
use strict;
use vars qw/%CP_NAME %CODEPAGE %STATISTIC/;

sub __mutator_factory($){ eval q/sub(;$){
    my $str = scalar @_ ? $_[0] : defined wantarray ? $_ : \$_;
    for( ref$str?$$str:$str ){ /. shift() .q/ if length }
    return ref $str ? $$str : $str if defined wantarray;
    $_ = $str if defined $_[0] and not ref $str }/;
}

sub cset_factory($$)
{
    my ($src, $dst, $fn, $sw) = @_;
    no strict qw/refs/;

    if( $src eq 'utf' &&  $dst eq 'uni'      or $sw =    $src eq 'uni' &&  $dst eq 'utf' )
    {
        $fn = $sw ? 'uni2utf' : 'utf2uni';

        return *$fn if defined &$fn;

        require "Unicode/String.pm" unless defined %Unicode::String::;
        *$fn = __mutator_factory( sprintf '$_=Unicode::String::%s($_)->%s',
            $sw ? qw/utf16 utf8/ : qw/utf8 utf16/ );
    }
    elsif( $src eq 'utf' ||  $src eq 'uni'    or $sw =    $dst eq 'utf' ||  $dst eq 'uni' )
    {
        my ($un, $cs) = ($sw ? $dst eq 'uni' : $src eq 'uni', $sw ? $src : $dst );
        $cs = $CP_NAME{$cs} if exists $CP_NAME{$cs};
        $fn = sprintf $sw ? ($un?'%s2uni':'%s2utf') : ($un?'uni2%s':'utf2%s'), $CODEPAGE{$cs}[0];

        return *$fn if defined &$fn;

        require "Unicode/String.pm" unless defined %Unicode::String::;
        require "Unicode/Map.pm"    unless defined %Unicode::Map::;
        local $_;  # Unicode::Map bugfixer

        $CODEPAGE{$cs}[3] = new Unicode::Map( $CODEPAGE{$cs}[1] ) or
            die "Can't create Unicode::Map for '$CODEPAGE{$cs}[1]' charset!\n" unless $CODEPAGE{$cs}[3];

        *$fn = $un ?
            __mutator_factory(sprintf '$_=$CODEPAGE{%s}[3]->%s_unicode($_)', $cs, (!$sw?'from':'to')) :
            __mutator_factory(sprintf !$sw ?
                '$_=$CODEPAGE{%s}[3]->from_unicode(Unicode::String::utf8($_))':
                '$_=Unicode::String::utf16($CODEPAGE{%s}[3]->to_unicode($_) )->utf8', $cs);
    }
    else
    {
        exists $CP_NAME{$_} and $_ = $CP_NAME{$_} for $src, $dst;
        exists $CODEPAGE{$_} or die"Unknown codepage '$_'\n" for $src, $dst;
        $fn = $CODEPAGE{$src}[0].'2'.$CODEPAGE{$dst}[0];

        return *$fn if defined &$fn;

        $_ = $CODEPAGE{$_}[2] for $src, $dst;
        substr($src, length $1, length $2) = '',
        substr($dst, length $1, length $2) = ''  while
            $dst =~ /^(.+?)( +)/ or $src =~ /^(.+?)([\x00-\x7f]+)/;
        s/-/\\-/g for $src, $dst;
        *$fn = __mutator_factory "tr/$src/$dst/";
    }

    return *$fn;
}

sub case_factory($;$$){
    my ($cs, $up, $fr) = @_;
    $cs = $CP_NAME{$cs} if exists $CP_NAME{$cs};
    die "Unknown codepage '$cs'\n" if not exists $CODEPAGE{$cs};
    my $fn = ($up?'up':'lo').($fr?'first':'case').'_'.$cs;
    no strict qw/refs/;
    unless( defined &$fn ){
        *$fn = __mutator_factory( ($fr?'substr($_,0,1)=~':'').sprintf 'tr/%s/%s/',
        $up   ? unpack'a33a33',$CODEPAGE{$cs}[2] :
        reverse unpack'a33a33',$CODEPAGE{$cs}[2] ) }
    return *$fn;
}

sub convert($$;$){ my $fn = cset_factory shift,shift; goto &$fn }
sub upfirst($;$) { my $fn = case_factory shift, 1, 1; goto &$fn }
sub lofirst($;$) { my $fn = case_factory shift, 0, 1; goto &$fn }
sub upcase($;$)  { my $fn = case_factory shift, 1, 0; goto &$fn }
sub locase($;$)  { my $fn = case_factory shift, 0, 0; goto &$fn }
sub charset($)   { $CODEPAGE{shift()}[1] }

sub detect(@)
{
    unless( keys %STATISTIC ){
        my $STATISTIC = join '', <DATA>;
        for( keys %CODEPAGE ){
            $STATISTIC{$_} = $STATISTIC;
            convert 866, $_, \$STATISTIC{$_} if $_ != 866;
            $STATISTIC{$_} = { map{ unpack 'a2a*',$_ }split /\s+/, $STATISTIC{$_} };
        }
    }

    my $score = shift if ref $_[0];
    local $_ = join ' ', @_;
    tr/\x00-\x7f/ /s; s/ .(?= )//go; s/^ //o; s/ $//o;

    return undef unless length and   # can't detect if 8bit chars count less than 1%
        tr/\x80-\xff// / $_[0] =~ tr/\x40-\xff// > 0.01;

    my %score;
    for my $cs( $score ? @$score : keys %CODEPAGE ){
        local $_ = $_;
        locase $cs;
        for( split / / ){
            for my $i( 0..length()-2 ){ # fetch pairs of symbols
                $score{$cs} += $STATISTIC{$cs}{substr $_, $i, 2}||0; }
        }
    }
    return (sort{ $score{$b}<=>$score{$a} }keys%score)[0];
}

sub import
{
    my $self = shift;

    if( @_ and exists $CODEPAGE{$_[0]} ){
        require 'POSIX.pm' unless defined &POSIX::setlocale;
        POSIX::setlocale( &POSIX::LC_CTYPE, 'Russian_Russia.'.shift @_ );
    }

    return unless @_;
    my $pkg = caller;
    no strict qw/refs/;

    while( my $src2dst = shift ){
        *{$pkg.'::'.$src2dst} = \&$src2dst, next if
            defined &$src2dst;

        my ($src, $dst) = $src2dst =~ /^([a-z]{3})2([a-z]{3})$/ or
            die "Unknown import '$src2dst'!\n";

        *{$pkg.'::'.$src2dst} = sub(;$){
            undef *{$pkg.'::'.$src2dst};
            *{$pkg.'::'.$src2dst} = cset_factory $src, $dst;
            goto &$src2dst;
        };
    }
}

BEGIN{%CODEPAGE=map{chomp;@_=split/ +/,$_,4;$CP_NAME{$_[1]}=int $_[0];int $_[0]=>[@_[1..3]]}split/\n/,<<'END'}
866   dos ibm866        ������񦧨������������������������������������������������������������������Ŀ�ٺ���������ް������´���˹��������������������cRT
20866 koi koi8-r        �����ţ���������������������������������������������������������񓛟�����������������������������������������������������������cRT
855   ibm cp855         ��묦�������������窵���������ޡ�쭧���������������諶�����������������o..v��Ŀ�ٺ��������||�������´���˹�����������������·�cRT
1251  win windows-1251  �������������������������������������Ũ�������������������������߯���������v�r-�LJ��JLr=---��---o�-�r���+r�����JJ����rnLtfn+������
10007 mac ms-cyrillic   �������������������������������߀�������������������������������������ʡ���|r-�LJ|�JLr=BbP||BBBo+++-||-+-|||��JJ||=-=--tfn+=�����
28585 iso iso-8859-5    ��������������������������������ﰱ������������������������������Ϥ��� ���v�����������������������+����+������������������++��cRT
END

1;

=head1 NAME

cyrillic - Library for fast and easy cyrillic text manipulation

=head1 SYNOPSIS

 use cyrillic qw/866 win2dos convert locase upcase detect/;

 print convert( 866, 1251, $str );
 print convert( 'dos','win', \$str );
 print win2dos $str;

=head1 DESCRIPTION

This module includes cyrillic string converting functions
from one and to another charset, to upper and to lower case without
locale switching. Also included single-byte charsets detection routine.
It is easy to add new code pages. For this purpose it is necessary
only to add appropriate string of a code page.

Supported charsets:
 ibm866, koi8-r, cp855, windows-1251, MacWindows, iso_8859-5, unicode, utf8;

If the first imported parameter - number of a code page, then locale will be switched to it.

=head1 FUNCTIONS

=over 4

=item * cset_factory - between charsets convertion function generator

=item * case_factory - case convertion function generator

=item * convert - between charsets convertor

=item * upcase - convert to upper case

=item * locase - convert to lower case

=item * upfirst - convert first char to upper case

=item * lofirst - convert first char to lower case

=item * detect - detect codepage number

=item * charset - returns charset name for codepage number

=back

At importing list also might be listed named convertors. For Ex.:

 use cyrillic qw/dos2win win2koi mac2dos ibm2dos/;


NOTE! Specialisations (like B<win2dos>, B<utf2win>) call faster then B<convert>.


NOTE! Only B<convert> function and they specialisation work with Unicode and UTF-8 strings.
All others function work only with single-byte sharsets.


Names for using in named charset convertors:

 dos ibm866       866
 koi koi8-r       20866
 ibm cp855        855
 win windows-1251 1251
 mac ms-cyrillic  10007
 iso iso-8859-5   28585
 uni Unicode
 utf UTF-8


The following rules are correct for converting functions:

 VAR may be SCALAR or REF to SCALAR.
 If VAR is REF to SCALAR then SCALAR will be converted.
 If VAR is ommited then $_ operated.
 If function called to void context and VAR is not REF
 then result placed to $_.


=head1 CONVERSION METHODS

=item B<cset_factory> SRC_CP, DST_CP

Generates between codepages convertor function, from SRC_CP to DST_CP,
and returns reference to his.

The converting Unicode or UTF-8 data requires presence of
installed Unicode::String and Unicode::Map.

=item B<case_factory> CODEPAGE, [TO_UP], [ONLY_FIRST_LETTER]

Generates case convertor function for single-byte CODEPAGE
and returns reference to his.

=item B<convert> SRC_CP, DST_CP, [VAR]

Convert VAR from SRC_CP codepage to DST_CP codepage and returns
converted string. Internaly calls B<cset_factory>.

=item B<upcase> CODEPAGE, [VAR]

Convert VAR to uppercase using CODEPAGE table and returns
converted string. Internaly calls B<case_factory>.

=item B<locase> CODEPAGE, [VAR]

Convert VAR to lowercase using CODEPAGE table and returns
converted string. Internaly calls B<case_factory>.

=item B<upfirst> CODEPAGE, [VAR]

Convert first char of VAR to uppercase using CODEPAGE table and returns
converted string. Internaly calls B<case_factory>.

=item B<lofirst> CODEPAGE, [VAR]

Convert first char of VAR to lowercase using CODEPAGE table and returns
converted string. Internaly calls B<case_factory>.

=head1 MAINTAINANCE METHODS

=item B<charset> CODEPAGE

Returns charset name for CODEPAGE.

=item B<detect> ARRAY

Detect single-byte codepage of data in ARRAY and returns codepage number.
If first element of ARRAY is REF to array of codepages numbers, then detecting
will made between these codepages, otherwise - between all single-byte codepages.
If codepage not detected then returns undefined value;

=head1 EXAMPLES

 use cyrillic qw/convert locase upcase detect dos2win win2dos/;

 $_ = "\x8F\xE0\xA8\xA2\xA5\xE2 \xF0\xA6\x88\xAA\x88!";

 printf "    dos: '%s'\n", $_;
 upcase 866;
 printf " upcase: '%s'\n", $_;
 dos2win;
 printf "dos2win: '%s'\n", $_;
 win2dos;
 printf "win2dos: '%s'\n", $_;
 locase 866;
 printf " locase: '%s'\n", $_;
 printf " detect: '%s'\n", detect $_;

 # detect between 866 and 20866 codepages
 printf " detect: '%s'\n", detect [866, 20866], $_;


 # CONVERTING TEST:

 use cyrillic qw/utf2dos mac2utf dos2mac win2dos utf2win/;

 $_ = "Хелло Ворльд!\n";

 print "UTF-8: $_";
 print "  DOS: ", utf2dos mac2utf dos2mac win2dos utf2win $_;


 # EQVIVALENT CALLS:

 dos2win( $str );        # called to void context -> result placed to $_
 $_ = dos2win( $str );

 dos2win( \$str );       # called with REF to string -> direct converting
 $str = dos2win( $str );

 dos2win();              # with ommited param called -> $_ converted
 dos2win( \$_ );
 $_ = dos2win( $_ );

 my $convert = cset_factory 866, 1251;
 &$convert( $str );            # faster call convertor function via ref to his
   convert( 866, 1251, $str ); # slower call convertor function


 # FOR EASY SWITCH LOCALE CODEPAGE

 use cyrillic qw/866/;   # locale switched to Russian_Russia.866

 use locale;
 print $str =~ /(\w+)/;

 no locale;
 print $str =~ /(\w+)/;

=head1 FAQ

 * Q: Why module say: Can't create Unicode::Map for 'koi8-r' charset!
   A: Your Unicode::Map module can't find map file for 'koi8-r' charset.
      Copy file koi8-r.map to site/lib/Unicode/Map and add to file
      site/lib/Unicode/Map/registry followings three strings:

      name:    KOI8-R
      map:     $UnicodeMappings/koi8-r.map
      alias:   csKOI8R

 * Q: Why perl say: "Undefined subroutine koi2win called" ?
   A: The function B<koi2win> is specialization of the function B<convert>,
      which is created at inclusion it of the name in the list of import.

=head1 AUTHOR

Albert MICHEEV <Albert@f80.n5049.z2.fidonet.org>

=head1 COPYRIGHT

Copyright (C) 2000, Albert MICHEEV

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=head1 AVAILABILITY

The latest version of this library is likely to be available from:

http://www.perl.com/CPAN

=head1 SEE ALSO

Unicode::String, Unicode::Map.

=cut

__DATA__
��21815 ��19276 ��16528 ��15172 ��15161 ��14457 ��14151 ��13562 ��13327 �11067 ��10935 ��10268 �10059
��9899 �9785 �9712 ��9281 ��9040 �8956 ��8956 ��8884 ��8786 ��8713 ��8626 ��8332 �8202 ��8125 ��7820
��7815 �7582 ��7487 ��7418 ��7308 ��7277 ��7005 ��6823 �6767 ��6679 ��6609 ��6596 ��6329 ��6066 ��5903
��5834 ��5705 ��5465 ��5440 ��5347 �5253 �5193 ��5075 ��5064 ��5043 ��4998 ��4966 ��4868 ��4818 �4731
��4693 ��4656 ��4628 ��4563 ��4402 ��4400 �4388 �4290 ��4197 ��4191 ��4078 ��4049 �3968 ��3853 ��3797
�3732 �3716 ��3708 ��3706 ��3684 ��3632 ��3612 ��3465 ��3459 ��3398 ��3392 ��3354 �3296 ��3261 ��3242
��3209 ��3182 ��3162 ��3090 ��2962 ��2958 ��2878 �2847 ��2830 ��2808 ��2804 ��2792 ��2724 ��2694 �2657
�2653 ��2587 �2577 ��2573 ��2500 ��2482 ��2374 ��2366 ��2334 �2304 ��2289 �2263 �2227 ��2209 ��2180
�2176 ��2139 ��2134 ��2118 ��2073 ��2066 ��2064 �2054 ��2041 ��1930 ��1911 ��1893 ��1881 �1873 �1778
��1769 ��1744 ��1738 �1695 ��1684 ��1658 �1639 ��1633 ��1628 ��1570 ��1558 ��1551 ��1530 ��1515 ��1501
�1493 ��1488 ��1483 ��1460 ��1459 �1452 ��1424 ��1391 ��1382 ��1379 ��1342 ��1336 ��1323 ��1322 ��1303
��1286 ��1257 ��1248 ��1245 �1224 ��1197 �1192 �1192 ��1191 ��1185 ��1182 ��1161 ��1150 ��1139 ��1126
��1117 �1098 ��1094 ��1093 ��1076 �1070 ��1049 ��1048 ��1045 ��1039 �1033 ��999 ��999 ��949 ��944
��938 �938 �935 ��924 �921 ��911 ��911 ��909 ��891 ��882 �878 ��876 ��869 ��847 ��840 ��836 ��836
��832 �803 ��799 ��796 ��782 ��778 ��767 �766 �765 ��755 ��743 �743 ��741 ��741 ��739 ��716 ��711
�700 �693 ��683 ��678 ��677 ��671 ��660 ��652 ��651 ��646 �638 ��635 �633 ��632 ��629 ��620 ��609
�599 ��594 �591 ��591 ��590 ��559 ��525 ��522 ��516 ��505 ��503 �496 �496 �490 �487 ��483 ��482
��474 ��471 �461 ��452 �438 ��434 �433 ��431 ��430 ��416 ��414 ��409 ��403 �400 ��400 �398 �397
��395 ��394 ��390 �376 ��370 ��369 ��368 ��365 �363 ��358 ��346 ��344 ��337 �326 �325 �311 ��305
�301 �297 ��286 ��286 ��286 ��285 ��280 ��277 ��273 �272 �272 ��271 ��270 ��268 ��266 �260 ��255
��255 ��254 ��254 ��242 ��241 ��239 �237 ��225 �224 �219 �218 ��216 �213 ��207 ��206 ��206 ��205
��205 ��204 ��204 ��204 �200 ��199 �198 �197 ��197 ��194 ��193 ��192 ��191 ��184 ��183 ��183 ��176
��174 �171 ��169 ��166 ��165 ��162 ��161 ��161 ��157 ��156 ��154 ��153 ��152 ��151 �151 ��145 ��141
�140 ��138 ��134 ��129 ��122 �122 ��120 ��119 ��114 �113 ��112 ��112 ��112 ��108 �108 �104 ��104
�102 ��101 ��97 ��96 ��96 ��92 �92 ��90 �90 ��89 ��89 ��89 ��87 ��84 ��82 ��81 ��79 �78 ��77 ��76
��70 ��68 ��68 ��68 ��67 ��63 ��63 �62 �62 ��61 �53 ��51 ��51 ��51 ��51 �51 ��50 ��50 ��49 ��48 ��47
��46 �45 ��45 �38 ��38 ��37 ��37 �36 ��35 ��34 �33 �33 ��33 �33 ��32 ��32 ��31 ��31 ��30 ��30 ��30
��30 ��29 ��29 ��28 �28 ��27 ��27 ��27 �27 �27 ��26 �26 ��26 ��26 ��25 ��25 �25 ��25 ��24 ��24 ��24
��23 ��22 ��22 �21 ��20 ��20 ��20 ��20 ��19 ��19 ��19 �19 �19 �19 ��18 ��18 �18 ��18 ��17 ��17 ��16
��16 �16 �16 ��15 �15 ��15 ��15 ��15 ��15 �15 ��14 �14 ��13 ��13 ��13 ��12 �12 ��12 ��12 �12 ��12
��11 ��11 ��11 �11 �10 ��10 ��10 �10 ��10 ��10 �9 �9 ��9 ��9 ��9 ��9 ��8 ��8 ��8 ��8 ��7 ��7 ��7 ��7
��7 ��6 �6 ��6 ��6 �6 ��6 ��6 �6 ��5 ��5 �5 �5 �5 �5 ��4 ��4 ��4 ��4 ��4 ��4 ��3 ��3 ��3 ��3 �3
�3 ��3 ��3 ��3 ��3 ��3 �2 �2 ��2 ��2 ��2 ��2 ��2 ��2 ��2 ��2 ��2 �2 �2 �2 ��2 �2 ��1 �1 ��1 ��1
��1 ��1 ��1 ��1 ��1 ��1 ��1 ��1 �1 ��1 �1 �1 �1 ��1
