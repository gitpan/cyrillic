package cyrillic;
$curillic::VERSION = 1.00;

=head1 NAME

cyrillic - Library for cyrillic text manipulation

=head1 SYNOPSIS

  use cyrillic qw/866 win2dos/;

  print cyrillic::convert( 866, 1251, $str );
  print cyrillic::convert( 'dos','win', \$str );
  print win2dos $str;

=head1 DESCRIPTION

If first import parameters is number of codepage
then localisation switched to they codepage.
Specialisations like 'win2dos' work more faster then 'convert',
while eval procedure called only once, when function created.

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
                    
=head1 AUTHOR

Albert MICHEEV <Albert@f80.n5049.z2.fidonet.org>

=head1 COPYRIGHT

Copyright (C) 2000, Albert MICHEEV

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut

use vars qw/%CODEPAGE %CHARSET %STATS/;

sub translate(\$\$;$)
{
    my ($src, $dst, $str) = @_;
    $str = defined wantarray ? $_ : \$_ unless defined $str;
    eval sprintf q#(ref$str?$$str:$str) =~ tr/%s/%s/#, $$src, $$dst;
    return ref $str ? $$str : $str if defined wantarray;
    $_ = $str if defined $_[2] and not ref $str;
}

sub convert($$;$)
{
    my ($src, $dst) = (shift, shift);
    exists $CODEPAGE{$_} and $_ = $CODEPAGE{$_} for $src, $dst;
    exists $CHARSET{$_}  or  die"Unknown charset '$_'\n" for $src, $dst;
    translate $CHARSET{$src}, $CHARSET{$dst}, shift;
}

sub upcase($;$)
{
    my $cs = shift; $cs = $CODEPAGE{$cs} if exists $CODEPAGE{$cs};
    die "Unknown charset '$cs'\n" unless exists $CHARSET{$cs};
    my ($src, $dst) = unpack('a33a33', $CHARSET{$cs});
    translate $src, $dst, shift;
}

sub locase($;$)
{
    my $cs = shift; $cs = $CODEPAGE{$cs} if exists $CODEPAGE{$cs};
    die "Unknown charset '$cs'\n" unless exists $CHARSET{$cs};
    my ($src, $dst) = reverse unpack('a33a33', $CHARSET{$cs});
    translate $src, $dst, shift;
}

sub detect(@)
{
    my (@data, %score) = @_;
    my $ps = length each%{$STATS{each%STATS}};
    for my $cs( keys %CHARSET ){
        for( @data ){
            s/[\n\r]//go;
            locase $cs;
            for( split /[-.,:;?!'"()0-9<>\s]+/o ){
                for my $i (0 .. length()-$ps){
                    $score{$cs} += $STATS{$cs}{substr $_, $i, $ps} || 0; }
            }
        }
    }
    $cs = (sort{ $score{$b}<=>$score{$a} }keys%score)[0];
    return $score{$cs} ? $cs : 'eng';
}

sub import
{
    my $self = shift;

    eval q(use POSIX 'locale_h'; setlocale LC_CTYPE, 'Russian_Russia.'.shift @_ )
        if @_ and exists $CODEPAGE{$_[0]};

    return unless @_;
    my $pkge = caller;

    while( my $src2dst = shift )
    {
        unless( defined *$src2dst )
        {
            my ($src, $dst) = $src2dst =~ /^(\w{3})2(\w{3})$/ or
                die "Unknown import '$src2dst'!\n";

            for( $src, $dst ){ exists $CHARSET{$_} or 
                die "Unknown charset '$_'!\n"; }

            *$src2dst = eval sprintf q#sub(;$){
                my $str = $_[0];
                $str = defined wantarray ? $_ : \$_ unless defined $str;
                (ref$str?$$str:$str) =~ tr/%s/%s/;
                return ref $str ? $$str : $str if defined wantarray;
                $_ = $str if defined $_[0] and not ref $str;};#, @CHARSET{$src, $dst};
        }
        *{"${pkge}::${src2dst}"} = *$src2dst;
    }
}

BEGIN{%CHARSET=map{chomp;@_=split/ +/,$_,3;$CODEPAGE{$_[0]}=$_[1];$_[1]=>$_[2]}split/\n/,<<'END';}
866   dos  ¡¢£¤¥ñ¦§¨©ª«¬­®¯àáâãäåæçèéêëìíîï€‚ƒ„…ð†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸÄÍùúþø
855   ibm  ¢ë¬¦¨„éó·½ÆÐÒÔÖØáãåçªµ¤ûõùžñí÷œÞ¡£ì­§©…êô¸¾ÇÑÓÕ×Ýâäæè«¶¥üöúŸòîøà
1251  win àáâãäå¸æçèéêëìíîïðñòóôõö÷øùúûüýþÿÀÁÂÃÄÅ¨ÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞß—=•·¤¶°
20866 koi ÁÂ×ÇÄÅ£ÖÚÉÊËÌÍÎÏÐÒÓÔÕÆÈÃÞÛÝßÙØÜÀÑáâ÷çäå³öúéêëìíîïðòóôõæèãþûýÿùøüàñ€ •ž”œ
10007 mac àáâãäå¸æçèéêëìíîïðñòóôõö÷øùúûüýþß€‚ƒ„…ð†‡ˆ‰Š‹ŒHŽ‘’“”•–—˜™š›œžŸ
28585 iso ÐÑÒÓÔÕñÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîï°±²³´µ¡¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏ
END

BEGIN{my $table=<<'END';
áâ21815 ¥­19276 ­ 16528 ®¢15172 £®15161 ­®14457 ­¨14151 ®£13562 ¯à13327 à¥11067
 «10935  ­10268 à 10059 «®9899 â 9785 â®9712 ­ë9281 «¨9040 â¢8956 ­­8956  â8884
¯®8786 ¤¥8713 ®á8626 ¥¤8332 â¥8202 ¥«8125 ®¤7820 ¨ï7815 à¨7582 «ì7487 ¢ 7418
®à7308 ¢®7277 § 7005 ¥à6823 à®6767 ®â6679 ª®6609 ¥â6596 ®¬6329 «¥6066 ¨¨5903
®©5834 ¥á5705 ¢¥5465 « 5440 ¤®5347 â¨5253 æ¨5193 ­¥5075 ¨§5064  á5043 ëå4998
âá4966 ®¡4868 ¬¥4818 ç¥4731 âì4693 ¨¬4656 ¨¥4628  ¢4563 ª 4402 ®«4400 á®4388
é¥4290 áï4197 £ 4191 ¬®4078 ¤ 4049 é¨3968 ¢«3853  æ3797 á«3732 áª3716 ¨­3708
 à3706 ¬¨3684 ®¯3632 ¯«3612  ¬3465 ¦¥3459 ¨â3398 âà3392 ¨á3354 ì­3296 ¨«3261
¨©3242 ¥¬3209 ¢ë3182  ª3162  §3090 ¢¨2962 ¥©2958 ®­2878 ë¥2847 «ï2830 ãá2808
¨ª2804 áã2792 ª¨2724 ¥£2694 ë¬2657 à£2653 ïâ2587 â­2577 ®¦2573 ¯¥2500 àã2482
®ï2374 ¥ª2366 ¡®2334 ç 2304 ãç2289 ã¯2263 å®2227 ïé2209 ¨å2180 á¨2176 «ã2139
¨æ2134 áá2118 ¬ 2073 ©á2066  ¥2064 è¥2054 îé2041 ãî1930 ®®1911 ­â1893 ®ª1881
ç¨1873 ã¬1778 ¨¢1769  ï1744 ¤á1738 æ¥1695 ¬ã1684 ¨®1658 á¯1639 ìé1633 ¨ç1628
§­1570 ªâ1558 ®¨1551 ¤¨1530  ç1515 ìï1501 á 1493 ¤¯1488 âë1483 ¤ã1460 ¤­1459
ã¤1452 ¬ë1424 ®¥1391 íâ1382 ìá1379 îâ1342 ãé1336 ªá1323 ®§1322 ¦¤1303 ¥¦1286
”¥1284 ®1272 ¡ë1257 £¨1248 ¨î1245 ï§1224  î1197 ë©1192 ã£1192 §¢1191 áà1185
‘â1184 ¤«1182 ¨¤1161 Š®1153 ­á1150 àá1139 ¢ã1126 ¡ 1117 ãª1098 ¬¬1094 ¥§1093
§®1076 ï¥1070 ªã1049 ¢­1048 àï1045  å1039 á¢1033 §¨999 ¢ª999 «­949 ®ç944 àë938
á¬938 æ 935 ¡«924 ç­921 ¥¥911 ­ï911 ®å909  ¡891 ¨à882 ï¤878 ª«876 §¤869 ïî847
­ª840  838 ¡ï836 âã836 à835 ¡à832 ä¨803 ®æ799 ¦ 796 ª¥782 ®è778 ¥ç767 ï¢766
ï¬765 ¨¡755 ã¦743 ¤ë743 ¤à741 «î741 §¬739  ¦716 ­ã711 ì¨700 á­693 àâ683 £à678
ªæ677 ¯ 671 ¤ª660 ¡¥652 ªà651  £646 à¬638 ¥ 635 á¥633 ¦¨632 ¡ê629 ¦­620 ¨ 609
ê¥599  ¤594  é591 ä®591 áå590 ãè559 ¥¢525 áç522 ¥¡516 îç505 ëâ503 à¢496 ì¥496
à­490 ì§487 ¥ï483 ïå482 ­¤474 ¯ã471 æ®461 ãâ452 è«438 «¦434 âª433 àà431 §ã430
ª¦416 ¥è414 ¯¨409 ¡á403 ®401 ë¢400 §¥400 ã­398 è¨397 ìî395 ¢à394 ¦¡390 ä¥376
¢ï370 £«369 §ë368 ¡ã365 ë¯363 ¡é358 ¥¯346 ¤ï344 £ã337 à¦326 ã¥325 íª311 ëç305
ã«301 é 297 ¢è286 ¥é286 ¢â286 ¥®285 ¢á280  ¯277 ëà273 ä 272 ë¤272 ­ì271 âç270
¯¯268 ¯ë266 ã¡260 Ž¡259 ëè255 ¥å255 àè254 ãà254 ¤¢242 ¢¯241 áë239 î¤237 …á231
ª¢225 ë«224 ë­219 á¡218 æã216 á¤213 êï207 ¡î206 ¤¦206  è205 ëá205 ¡­204 §«204
¬­204 ƒ«201 è 200 ­¢199 çª198 ¢§197 â¤197 ¡¨194 ìâ193 ­§192 ¥192 çà191 ïæ184
¢¢183 ¥æ183 ƒ®178 ­æ176 ‘ã174 ­ä174 ìª171 ¨¦169  ¨166 ìè165 £¥162 åá161 ®ã161
«ë157 Žá156 àì156 áì154 «ª153  ©152  152 ¨£151 ï­151 ®ä145 ¥î141 ã¢140 ¤¬138
ˆ­134 çã134 ®é129 ¥127 “ª124 âï122 àª122 ¨ä120 ¬¯119 çâ114 ì£113  ä112 èâ112
§ï112 è­108 ¥ä108 „®107 ã 104 ¨¯104 å 102 åà101 ’ 100 ««97 ¨è96 ©­96 å­92 ¡å92
‡ 92 ¤ê90 ï©90 «£89 ¬«89 §à89 ¯ï87 ­ç84 Žâ83 ¢¬82 ïá81  ã79 ì¬78 §ê77 ¥¨76 ‘®70
éã70 ¬¢68 £¤68 ¬á68 ©®67 ¥64 ¡¦63 ¤â63 à¡62 î¡62 ¬ï61 Ž¯60 Œ¨59 ‚ë56 “¯56 â¬53
‘à52 ¤è51 ¢æ51 ï¦51 –¥51 ãå51 ¢å51 ää50 îà50 ¤£49 ¨é48 æë47 §ª46 Žà46 ˆá46 ã§45
¥ã45 Œ¥41 ¯­38 ë§38 §£37 ¦ª37 ë¡36 “ç36 ª­35 „«35 ‘‘34 ®í34 ç«33 ¤ç33 ëª33 ®33
é­33 ˆ§33 §æ32 ‚®32 §¡32 äë31 ‹¨31 ­£31 àç30 àå30 ¬ª30 ìç30 ëï29 íä29 ’à28 ¢é28
ä­28 ë£27 å¨27 âæ27 ® 27 ¤¤27 áä26 ï«26 ¯ª26 ‚§26 ¤§26 â¯25 ¡¬25 áè25 ¦ã25 Œ 24
¢ì24 äâ24 „¥24 âå24 ®î23 ”®22 ‘¯22 ¤æ22 ìæ22 à¤21 ¤¡20 ïà20 ïç20 ©è20 ‘19 £è19
èª19 í¬19 ¤ì19 ª19 ï£19 äã19 ïª18 ãæ18 ”¨18 ­î18 ïï18 àæ17 áî17 ƒ¥17 “á17  17
‚­16 ¨ã16 î§16 í«16 Œ®16 «â16 å£15 ¥í15 éì15 åã15 ä«15 ¦¯15 ¯â15 ‚â14 ¬é14 à«14
¯á13 ¬¡13 ‚¥13 ªè13  13 ’®12 €à12 â£12 çì12 â«12 ¯æ12 ª‚12 ©¬12 ’¥12 ‘¥12 £­12
¦£11 ©â11 £ç11 í­11 „ 11 ‘¢11 ‚¨11 Š 11 —¥10 í¢10 ªª10 ¢¤10 íà10 ‘10 ¬ì10 “¡10
î¢10 æ¢9  í9 à¯9 ìä9 îá9 ¡è9 €8 £ª8 €¬8 ‚¢8 ŽŽ8 Ž8 ­¦8 îæ8 €á8 «á8 äì7 €­7 «7
ãï7 çè7 €¢7 ¯ì7 €ª7 åâ7 Ž¤7 ƒà7 åª6 ¬ç6 ì¡6 ‘¨6 ã¨6 ¥6 Žæ6 ˆ¬6 àä6 äà6 ‘’6 ãä6
©ª6 Šà5 ‘¤5  ®5 ˆ”5 ¨5 î¦5 „¨5 æª5 å¥5 â§5 ¡§5 ‡­4 ‹¥4 ë4 ‘«4 ââ4 ”Ž4 èà4 ƒŽ4
¨4 èì4 «¬4 † 4 «4 ¢ê4 “£4 „­4 Ž‘4 “¢4 ” 4 Ž£4 ’ã4 ¡ª4 ‚à3 €«3 èã3 áê3 „à3 ƒ€3
âè3 áæ3 âê3 ‘ 3 á£3 íá3 ‹î3 î3 ©ä3 €ˆ3 ï¡3 §ì3 ŒŠ3 ©¥3 Š’3 ’“3 ‚á3 â3 Ž­2 ‘ç2
í¯2 ”ˆ2 ‹ì2 ¬‡2 ç¢2 ¡¯2 ‡¥2 ª§2 å¢2 §ç2 Šã2 å«2 à2 îè2 ª£2 ƒ2 “â2 —€2 –¢2 €‘2
€¯2 „ã2 †¥2 ‡¢2 ­é2 ä¬2 äá2 ’œ2 £â2 ‹ˆ2 àî2 Š­2 ¯ç2 î«2 ž¢1 €Ÿ1 €’1 ‘1 §¦1 ‘‚1
™€1 ”’1 …¢1 îî1 å¬1 ©¤1 “¤1 §â1 æ¬1 æ«1 …¦1 éà1 ¦à1 ã1 ¡¢1 ˆ¦1 ˆ¤1 „¢1 ’¢1 ¦ä1
ã1 ë¨1 ‘¡1 …«1 ˆâ1 †¨1 ‚¬1 ¯ä1 ’‘1 ¬à1 ‘ª1 î­1 ”«1 ‚ˆ1 ‚ª1 ¢£1 Ÿ§1 ©¯1 ™1 “¬1
Žä1 ‘”1 ”‘1 Ž1 «¤1
END
$STATS{$_}=$table for keys %CHARSET;
convert 'dos', $_, \$STATS{$_} for grep{ $_ ne 'dos' }keys %STATS;
$STATS{$_}={map{unpack 'a2a*',$_}split/\s+/,$STATS{$_}} for keys %STATS;
}

1;
