package cyrillic;
$curillic::VERSION = '1.10';

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
Easy adding new charset. For they need only add charset string.

=head1 FUNCTIONS

  At importing list might be listed named convertors. For Ex.:

  use cyrillic qw/dos2win win2koi mac2dos ibm2dos/;

=item B<convert> SRC_CP, DST_CP, [VAR]

Convert VAR from SRC_CP codepage to DST_CP codepage and returns
converted string. VAR may be SCALAR or REF to SCALAR. If VAR is
REF to SCALAR then SCALAR will be converted. If VAR is ommited
then $_ operated. If function called to void context and VAR is
not REF then result placed to $_.

=item B<upcase> CODEPAGE, [VAR]

Convert VAR to uppercase using CODEPAGE table and returns
converted string. VAR may be SCALAR or REF to SCALAR. If VAR is
REF to SCALAR then SCALAR will be converted. If VAR is ommited
then $_ operated. If function called to void context and VAR is
not REF then result placed to $_.

=item B<locase> CODEPAGE, [VAR]

Convert VAR to lowercase using CODEPAGE table and returns
converted string. VAR may be SCALAR or REF to SCALAR. If VAR is
REF to SCALAR then SCALAR will be converted. If VAR is ommited
then $_ operated. If function called to void context and VAR is
not REF then result placed to $_.

=item B<detect> ARRAY

Detect charset of data in ARRAY and returns name of charset.
If charset name not detected then returns 'eng';

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

  dos2win( $str );
  $_ = dos2win( $str );

  dos2win( \$str );
  $str = dos2win( $str );

  dos2win();
  dos2win( \$_ );
  $_ = dos2win( $_ );


  # FOR EASY SWITCH LOCALE CODEPAGE

  use cyrillic qw/866/;

  use locale;
  $str =~ /a-ï/;

  no locale;
  $str =~ /a-ï/;

=head1 AUTHOR

Albert MICHEEV <Albert@f80.n5049.z2.fidonet.org>

=head1 COPYRIGHT

Copyright (C) 2000, Albert MICHEEV

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut

use vars qw/%CODEPAGE %CHARSET %STATISTIC $STATISTIC $TRANSLATOR/;

sub prepare
{
    my($src, $dst)=@_;
    substr($src, length $1, length $2) = '',
    substr($dst, length $1, length $2) = ''
        while $dst =~ /^(.+?)( +)/;
    substr($_, 66, 0) = '\x00-\x7f' for $src, $dst;
    return $src, $dst;
}

sub convert($$;$)
{
    my ($src, $dst) = (shift, shift);
    exists $CODEPAGE{$_} and $_ = $CODEPAGE{$_} for $src, $dst; my $fn = $src.'2'.$dst;
    exists $CHARSET{$_}  or  die"Unknown charset '$_'\n" for $src, $dst;
    *$fn = eval sprintf $TRANSLATOR, prepare @CHARSET{$src,$dst} unless defined *$fn;
    return &$fn( shift );
}

sub upcase($;$)
{
    my $cs = exists $CODEPAGE{$_[0]} ? $CODEPAGE{shift()} : shift;
    die "Unknown charset '$cs'\n" unless exists $CHARSET{$cs}; my $fn = "upcase_$cs";
    *$fn = eval sprintf $TRANSLATOR, unpack 'a33a33', $CHARSET{$cs} unless defined *$fn;
    return &$fn( shift );
}

sub locase($;$)
{
    my $cs = exists $CODEPAGE{$_[0]} ? $CODEPAGE{shift()} : shift;
    die "Unknown charset '$cs'\n" unless exists $CHARSET{$cs}; my $fn = "locase_$cs";
    *$fn = eval sprintf $TRANSLATOR, reverse unpack 'a33a33', $CHARSET{$cs} unless defined *$fn;
    return &$fn( shift );
}

sub detect(@)
{
    my (@data, %score) = @_;
    if( $STATISTIC ){
        $STATISTIC{$_} = $STATISTIC for keys %CHARSET; undef $STATISTIC;
        convert 'dos', $_, \$STATISTIC{$_} for grep{ $_ ne 'dos' }keys %STATISTIC;
        $STATISTIC{$_}={map{unpack 'a2a*',$_}split/\s+/,$STATISTIC{$_}} for keys %STATISTIC;
    }
    local $_ = join ' ', @data;
    s/[\x00-\x7f]+/ /go;
    for my $cs( keys %CHARSET ){
        local $_ = $_;
        locase $cs;
        for( split / / ){
            for my $i( 0..length()-2 ){ # fetch pairs of symbols
                $score{$cs} += $STATISTIC{$cs}{substr $_, $i, 2}; }
        }
    }
    $cs = (sort{ $score{$b}<=>$score{$a} }keys%score)[0];
    return $score{$cs} ? $cs : 'eng';
}

sub import
{
    my $self = shift;

    if( @_ and exists $CODEPAGE{$_[0]} ){
        eval q#unless(defined *LC_CTYPE){use POSIX 'locale_h'};
               setlocale LC_CTYPE, 'Russian_Russia.'.shift @_# }

    return unless @_;
    my $pkge = caller;

    while( my $src2dst = shift ){
        unless( defined *$src2dst ){
            my ($src, $dst) = $src2dst =~ /^(\w{3})2(\w{3})$/ or
                die "Unknown import '$src2dst'!\n";
            exists $CHARSET{$_} or die"Unknown charset '$_'\n" for $src, $dst;
            *$src2dst = eval sprintf $TRANSLATOR, prepare @CHARSET{$src, $dst};
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

BEGIN{%CHARSET=map{chomp;@_=split/ +/,$_,3;$CODEPAGE{$_[0]}=$_[1];$_[1]=>$_[2]}split/\n/,<<'END'}
866   dos  ¡¢£¤¥ñ¦§¨©ª«¬­®¯àáâãäåæçèéêëìíîï€‚ƒ„…ð†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸôõö÷ýü\xfføùúû³ÚÄ¿ÀÙº»¼ÈÉÍÛÜßÝÞ°±²ÃÁÅÂ´ÌÊÎË¹µ¶·¸½¾ÆÇÏÐÑÒÓÔÕÖ×ØòócRT
20866 koi ÁÂ×ÇÄÅ£ÖÚÉÊËÌÍÎÏÐÒÓÔÕÆÈÃÞÛÝßÙØÜÀÑáâ÷çäå³öúéêëìíîïðòóôõæèãþûýÿùøüàñ“›Ÿ—¿\xffœ•ž–‚€ƒ„…¡¨®«¥ Œ‹Ž‘’†‰Šˆ‡±»¾¸µ²´§¦­¬¯°¹º¶·ª©¢¤½¼™˜cRT
855   ibm  ¢ë¬¦¨„éó·½ÆÐÒÔÖØáãåçªµ¤ûõùžñí÷œÞ¡£ì­§©…êô¸¾ÇÑÓÕ×Ýâäæè«¶¥üöúŸòîøàŒ™˜Ïï\xff    ³ÚÄ¿ÀÙº»¼ÈÉÍÛÜß  °±²ÃÁÅÂ´ÌÊÎË¹                    cRT
1251  win àáâãäå¸æçèéêëìíîïðñòóôõö÷øùúûüýþÿÀÁÂÃÄÅ¨ÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞß¯¿¡¢¤¹\xa0°•·v¦--¬L-¦¬-Lã=---¦¦---+++T+¦¦+T¦¦¦¬¬--¦¦¦¦TTLL-ã++ªº©®™
10007 mac àáâãäå¸æçèéêëìíîïðñòóôõö÷øùúûüýþß€‚ƒ„…ð†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸì•ÙØÛÜ\xca¡¥áÃ                                                  ©¨ª
28585 iso ÐÑÒÓÔÕñÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîï°±²³´µ¡¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏ¤ô¦ö ð\x20§÷ú ƒŠ…†Œ“•œ–š’‘                                 £ócRT
END

BEGIN{$STATISTIC=<<'END'}
áâ21815 ¥­19276 ­ 16528 ®¢15172 £®15161 ­®14457 ­¨14151 ®£13562 ¯à13327 à¥11067  «10935  ­10268 à 10059
«®9899 â 9785 â®9712 ­ë9281 «¨9040 â¢8956 ­­8956  â8884 ¯®8786 ¤¥8713 ®á8626 ¥¤8332 â¥8202 ¥«8125 ®¤7820
¨ï7815 à¨7582 «ì7487 ¢ 7418 ®à7308 ¢®7277 § 7005 ¥à6823 à®6767 ®â6679 ª®6609 ¥â6596 ®¬6329 «¥6066 ¨¨5903
®©5834 ¥á5705 ¢¥5465 « 5440 ¤®5347 â¨5253 æ¨5193 ­¥5075 ¨§5064  á5043 ëå4998 âá4966 ®¡4868 ¬¥4818 ç¥4731
âì4693 ¨¬4656 ¨¥4628  ¢4563 ª 4402 ®«4400 á®4388 é¥4290 áï4197 £ 4191 ¬®4078 ¤ 4049 é¨3968 ¢«3853  æ3797
á«3732 áª3716 ¨­3708  à3706 ¬¨3684 ®¯3632 ¯«3612  ¬3465 ¦¥3459 ¨â3398 âà3392 ¨á3354 ì­3296 ¨«3261 ¨©3242
¥¬3209 ¢ë3182  ª3162  §3090 ¢¨2962 ¥©2958 ®­2878 ë¥2847 «ï2830 ãá2808 ¨ª2804 áã2792 ª¨2724 ¥£2694 ë¬2657
à£2653 ïâ2587 â­2577 ®¦2573 ¯¥2500 àã2482 ®ï2374 ¥ª2366 ¡®2334 ç 2304 ãç2289 ã¯2263 å®2227 ïé2209 ¨å2180
á¨2176 «ã2139 ¨æ2134 áá2118 ¬ 2073 ©á2066  ¥2064 è¥2054 îé2041 ãî1930 ®®1911 ­â1893 ®ª1881 ç¨1873 ã¬1778
¨¢1769  ï1744 ¤á1738 æ¥1695 ¬ã1684 ¨®1658 á¯1639 ìé1633 ¨ç1628 §­1570 ªâ1558 ®¨1551 ¤¨1530  ç1515 ìï1501
á 1493 ¤¯1488 âë1483 ¤ã1460 ¤­1459 ã¤1452 ¬ë1424 ®¥1391 íâ1382 ìá1379 îâ1342 ãé1336 ªá1323 ®§1322 ¦¤1303
¥¦1286 ¡ë1257 £¨1248 ¨î1245 ï§1224  î1197 ë©1192 ã£1192 §¢1191 áà1185 ¤«1182 ¨¤1161 ­á1150 àá1139 ¢ã1126
¡ 1117 ãª1098 ¬¬1094 ¥§1093 §®1076 ï¥1070 ªã1049 ¢­1048 àï1045  å1039 á¢1033 §¨999 ¢ª999 «­949 ®ç944
àë938 á¬938 æ 935 ¡«924 ç­921 ¥¥911 ­ï911 ®å909  ¡891 ¨à882 ï¤878 ª«876 §¤869 ïî847 ­ª840 âã836 ¡ï836
¡à832 ä¨803 ®æ799 ¦ 796 ª¥782 ®è778 ¥ç767 ï¢766 ï¬765 ¨¡755 ¤ë743 ã¦743 ¤à741 «î741 §¬739  ¦716 ­ã711
ì¨700 á­693 àâ683 £à678 ªæ677 ¯ 671 ¤ª660 ¡¥652 ªà651  £646 à¬638 ¥ 635 á¥633 ¦¨632 ¡ê629 ¦­620 ¨ 609
ê¥599  ¤594 ä®591  é591 áå590 ãè559 ¥¢525 áç522 ¥¡516 îç505 ëâ503 ì¥496 à¢496 à­490 ì§487 ¥ï483 ïå482
­¤474 ¯ã471 æ®461 ãâ452 è«438 «¦434 âª433 àà431 §ã430 ª¦416 ¥è414 ¯¨409 ¡á403 ë¢400 §¥400 ã­398 è¨397
ìî395 ¢à394 ¦¡390 ä¥376 ¢ï370 £«369 §ë368 ¡ã365 ë¯363 ¡é358 ¥¯346 ¤ï344 £ã337 à¦326 ã¥325 íª311 ëç305
ã«301 é 297 ¢â286 ¢è286 ¥é286 ¥®285 ¢á280  ¯277 ëà273 ë¤272 ä 272 ­ì271 âç270 ¯¯268 ¯ë266 ã¡260 ¥å255
ëè255 àè254 ãà254 ¤¢242 ¢¯241 áë239 î¤237 ª¢225 ë«224 ë­219 á¡218 æã216 á¤213 êï207 ¡î206 ¤¦206  è205
ëá205 ¬­204 ¡­204 §«204 è 200 ­¢199 çª198 â¤197 ¢§197 ¡¨194 ìâ193 ­§192 çà191 ïæ184 ¥æ183 ¢¢183 ­æ176
­ä174 ìª171 ¨¦169  ¨166 ìè165 £¥162 ®ã161 åá161 «ë157 àì156 áì154 «ª153  ©152 ¨£151 ï­151 ®ä145 ¥î141
ã¢140 ¤¬138 çã134 ®é129 âï122 àª122 ¨ä120 ¬¯119 çâ114 ì£113  ä112 èâ112 §ï112 ¥ä108 è­108 ã 104 ¨¯104
å 102 åà101 ««97 ¨è96 ©­96 ¡å92 å­92 ¤ê90 ï©90 ¬«89 «£89 §à89 ¯ï87 ­ç84 ¢¬82 ïá81  ã79 ì¬78 §ê77 ¥¨76
éã70 ¬á68 £¤68 ¬¢68 ©®67 ¤â63 ¡¦63 à¡62 î¡62 ¬ï61 â¬53 ãå51 ¢æ51 ¢å51 ¤è51 ï¦51 îà50 ää50 ¤£49 ¨é48 æë47
§ª46 ã§45 ¥ã45 ë§38 ¯­38 §£37 ¦ª37 ë¡36 ª­35 ®í34 ëª33 ç«33 ¤ç33 é­33 §æ32 §¡32 äë31 ­£31 ¬ª30 àå30 ìç30
àç30 íä29 ëï29 ¢é28 ä­28 ¤¤27 âæ27 ® 27 ë£27 å¨27 ¯ª26 ï«26 áä26 ¤§26 áè25 ¡¬25 â¯25 ¦ã25 äâ24 âå24 ¢ì24
®î23 ¤æ22 ìæ22 à¤21 ¤¡20 ïç20 ïà20 ©è20 ¤ì19 £è19 äã19 ï£19 í¬19 èª19 ãæ18 ­î18 ïª18 ïï18 àæ17 áî17 ¨ã16
«â16 î§16 í«16 ¯â15 å£15 éì15 ¦¯15 åã15 ¥í15 ä«15 ¬é14 à«14 ¯á13 ¬¡13 ªè13 £­12 â«12 ¯æ12 ©¬12 â£12 çì12
¦£11 ©â11 £ç11 í­11 î¢10 íà10 ¬ì10 í¢10 ¢¤10 ªª10 æ¢9 à¯9  í9 ìä9 îá9 ¡è9 £ª8 îæ8 «á8 ­¦8 ãï7 åâ7 ¯ì7 äì7
çè7 äà6 åª6 ©ª6 àä6 ã¨6 ¬ç6 ãä6 ì¡6 ¡§5  ®5 å¥5 â§5 æª5 î¦5 ¢ê4 èà4 ââ4 èì4 «¬4 ¡ª4 §ì3 ©¥3 áê3 íá3 ï¡3
á£3 ©ä3 áæ3 èã3 âè3 âê3 ä¬2 î«2 àî2 ª§2 îè2 ª£2 äá2 ¡¯2 £â2 ¯ç2 ­é2 å¢2 ç¢2 í¯2 §ç2 å«2 ¡¢1 î­1 îî1 ©¯1
¬à1 ¦ä1 ¢£1 ¯ä1 §â1 ©¤1 éà1 §¦1 ë¨1 ¦à1 å¬1 æ¬1 æ«1 «¤1
END

1;
