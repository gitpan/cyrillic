package cyrillic;
$cyrillic::VERSION = '1.23';

=head1 NAME

cyrillic - Library for fast and easy cyrillic text manipulation

=head1 SYNOPSIS

  use cyrillic qw/866 win2dos convert locase upcase detect/;

  print convert( 866, 1251, $str );
  print convert( 'dos','win', \$str );
  print win2dos $str;

=head1 DESCRIPTION

If first import parameter is number of codepage then locale switched to they codepage.
Specialisation (like 'win2dos') call faster then 'convert'.
Easy adding new codepage. For they need only add codepage string.

=head1 FUNCTIONS

Library includes converting and helper functions:
    convert, upcase, locase, upfirst, lofirst;
    detect, charset.


At importing list might be listed named convertors. For Ex.:

  use cyrillic qw/dos2win win2koi mac2dos ibm2dos/;


The following rules are correct for converting functions:

  VAR may be SCALAR or REF to SCALAR.
  If VAR is REF to SCALAR then SCALAR will be converted.
  If VAR is ommited then $_ operated.
  If function called to void context and VAR is not REF
  then result placed to $_.


=item B<convert> SRC_CP, DST_CP, [VAR]

Convert VAR from SRC_CP codepage to DST_CP codepage and returns
converted string.

=item B<upcase> CODEPAGE, [VAR]

Convert VAR to uppercase using CODEPAGE table and returns
converted string.

=item B<locase> CODEPAGE, [VAR]

Convert VAR to lowercase using CODEPAGE table and returns
converted string.

=item B<upfirst> CODEPAGE, [VAR]

Convert first char of VAR to uppercase using CODEPAGE table and returns
converted string.

=item B<lofirst> CODEPAGE, [VAR]

Convert first char of VAR to lowercase using CODEPAGE table and returns
converted string.

=item B<charset> CODEPAGE

Returns charset name for CODEPAGE.

=item B<detect> ARRAY

Detect codepage of data in ARRAY and returns codepage number.
If codepage not detected then returns undefined value;

=head1 EXAMPLES

  use cyrillic qw/convert locase upcase detect dos2win win2dos/;

  $\ = "\n";
  $_ = "\x8F\xE0\xA8\xA2\xA5\xE2 \xF0\xA6\x88\xAA\x88!";

  print; upcase 866;
  print; dos2win;
  print; win2dos;
  print; locase 866;
  print;
  print detect $_;


  # EQVIVALENT CALLS:

  dos2win( $str );        # called to void context -> result placed to $_
  $_ = dos2win( $str );

  dos2win( \$str );       # called with REF to string -> direct converting
  $str = dos2win( $str );

  dos2win();              # with ommited param called -> $_ converted
  dos2win( \$_ );
  $_ = dos2win( $_ );


  # FOR EASY SWITCH LOCALE CODEPAGE

  use cyrillic qw/866/;   # locale switched to 866 codepage

  use locale;
  print $str =~ /(\w+)/;

  no locale;
  print $str =~ /(\w+)/;

=head1 AUTHOR

Albert MICHEEV <Albert@f80.n5049.z2.fidonet.org>

=head1 COPYRIGHT

Copyright (C) 2000, Albert MICHEEV

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=head1 AVAILABILITY

The latest version of this library is likely to be available from:

 http://www.perl.com/CPAN

=cut

use 5.6.0;
use vars qw/%CP_NAME %CODEPAGE %STATISTIC $STATISTIC $TRANSLATOR $TRANSLATOR_FIRST/;

sub prepare
{
    my($src, $dst)=map $$_[2], @CODEPAGE{@_};
    substr($src, length $1, length $2) = '',
    substr($dst, length $1, length $2) = ''  while $dst =~ /^(.+?)( +)/;
    s/-/\\-/g, substr($_, 66, 0) = '\x00-\x7f' for $src, $dst;
    return $src, $dst;
}

sub convert($$;$)
{
    my ($src, $dst) = (shift, shift);
    exists $CP_NAME{$_} and $_ = $CP_NAME{$_} for $src, $dst;
    exists $CODEPAGE{$_} or die"Unknown codepage '$_'\n" for $src, $dst;
    my $fn = $CODEPAGE{$src}[0].'2'.$CODEPAGE{$dst}[0];
    *$fn = eval sprintf $TRANSLATOR, prepare($src, $dst) unless defined *$fn;
    return &$fn( shift );
}

sub upcase($;$)
{
    my $cs = exists $CP_NAME{$_[0]} ? $CP_NAME{shift()} : shift;
    die "Unknown codepage '$cs'\n" unless exists $CODEPAGE{$cs}; my $fn = "upcase_$cs";
    *$fn = eval sprintf $TRANSLATOR, unpack 'a33a33', $CODEPAGE{$cs}[2] unless defined *$fn;
    return &$fn( shift );
}

sub locase($;$)
{
    my $cs = exists $CP_NAME{$_[0]} ? $CP_NAME{shift()} : shift;
    die "Unknown codepage '$cs'\n" unless exists $CODEPAGE{$cs}; my $fn = "locase_$cs";
    *$fn = eval sprintf $TRANSLATOR, reverse unpack 'a33a33', $CODEPAGE{$cs}[2] unless defined *$fn;
    return &$fn( shift );
}

sub upfirst($;$)
{
    my $cs = exists $CP_NAME{$_[0]} ? $CP_NAME{shift()} : shift;
    die "Unknown codepage '$cs'\n" unless exists $CODEPAGE{$cs}; my $fn = "upfirst_$cs";
    *$fn = eval sprintf $TRANSLATOR_FIRST, unpack 'a33a33', $CODEPAGE{$cs}[2] unless defined *$fn;
    return &$fn( shift );
}

sub lofirst($;$)
{
    my $cs = exists $CP_NAME{$_[0]} ? $CP_NAME{shift()} : shift;
    die "Unknown codepage '$cs'\n" unless exists $CODEPAGE{$cs}; my $fn = "lofirst_$cs";
    *$fn = eval sprintf $TRANSLATOR_FIRST, reverse unpack 'a33a33', $CODEPAGE{$cs}[2] unless defined *$fn;
    return &$fn( shift );
}

sub charset($)
{
    return $CODEPAGE{shift()}[1];
}

sub detect(@)
{
    my (@data, %score) = @_;
    if( $STATISTIC ){
        $STATISTIC{$_} = $STATISTIC for keys %CODEPAGE; undef $STATISTIC;
        convert 866, $_, \$STATISTIC{$_} for grep{ $_ ne 866 }keys %STATISTIC;
        $STATISTIC{$_}={map{unpack 'a2a*',$_}split/\s+/,$STATISTIC{$_}} for keys %STATISTIC;
    }
    local $_ = join ' ', @data;
    tr/\x00-\x7f/ /s; s/ .(?= )//go; s/^ //o; s/ $//o;

    return undef unless length and   # can't detect if 8bit chars count less than 1%
        tr/\x80-\xff// / $_[0] =~ tr/\x40-\xff// > 0.01;
    
    for my $cs( keys %CODEPAGE ){
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
        eval q#unless( defined *LC_CTYPE ){ use POSIX 'locale_h' };
               setlocale LC_CTYPE, 'Russian_Russia.'.shift @_# }

    return unless @_;
    my $pkge = caller;

    while( my $src2dst = shift ){
        unless( defined *$src2dst ){
            my ($src, $dst) = $src2dst =~ /^(\w{3})2(\w{3})$/ or
                die "Unknown import '$src2dst'!\n";
            exists $CP_NAME{$_} or die"Unknown codepage '$_'\n" for $src, $dst;
            *$src2dst = eval sprintf $TRANSLATOR, prepare( @CP_NAME{$src, $dst} );
        }
        *{"${pkge}::${src2dst}"} = *$src2dst;
    }
}

BEGIN{$TRANSLATOR=<<'END'}
sub(;$){ my $str = $_[0];
$str = defined wantarray ? $_ : \$_ unless defined $str;
(ref$str?$$str:$str) =~ tr/%s/%s/;
return ref $str ? $$str : $str if defined wantarray;
$_ = $str if defined $_[0] and not ref $str; }
END

BEGIN{$TRANSLATOR_FIRST=<<'END'}
sub(;$){ my $str = $_[0];
$str = defined wantarray ? $_ : \$_ unless defined $str;
substr(ref$str?$$str:$str,0,1) =~ tr/%s/%s/;
return ref $str ? $$str : $str if defined wantarray;
$_ = $str if defined $_[0] and not ref $str; }
END

BEGIN{%CODEPAGE=map{chomp;@_=split/ +/,$_,4;$CP_NAME{$_[1]}=$_[0];$_[0]=>[@_[1..3]]}split/\n/,<<'END'}
866   dos cp866      ������񦧨�����������������������������������������������������������\xff������Ŀ�ٺ���������ް�����´���˹��������������������cRT
20866 koi koi8-r     �����ţ���������������������������������������������������������񓛟���\xff������������������������������������������������������cRT
855   ibm cp855      ��묦�������������窵���������ޡ�쭧���������������諶����������������\xff    ��Ŀ�ٺ��������  ������´���˹                    cRT
1251  win cp1251     �������������������������������������Ũ�������������������������߯�����\xa0���v�--�L-��-L�=---��---+++T+��+T�����--����TTLL-�++�����
10007 mac cp10007    �������������������������������߀�������������������������������������\xca����                                                  ���
28585 iso iso_8859-5 ��������������������������������ﰱ������������������������������Ϥ��� �\xa0��� ���������������                                 ��cRT
END

BEGIN{$STATISTIC=<<'END'}
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
END

1;
