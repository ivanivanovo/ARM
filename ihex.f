\ http://microsin.net/programming/pc/intel-hex-file-format.html
\ слова для работы с файлами в формате intel-HEX
\ автор: ~iva 2022 

\ ======== ИНФО ================================================================
( Каждая запись представляет собой ASCII-строку файла. 
    Одна строка – одна запись.
    Общий формат записей
    ---------------------------------------------
    «:» 1байт 2байта 1байт RECLEN_байт      1байт 
    ---------------------------------------------    
     :  08    0010   00    1895189518951895 34   <-- пример записи
     :  00    0000   01                     FF
     ^  ^     ^      ^     ^                ^
     |  |     |      |     |                |
     |  |     |      |     |                контрольная сумма.
     |  |     |      |     |                сумма всех байт записи, 
     |  |     |      |     |                исключая «:», по модулю 256
     |  |     |      |     |                должна быть равной нулю
     |  |     |      |     |                CHKSUM
     |  |     |      |     данные
     |  |     |      |     INFO или DATA
     |  |     |      тип записи
     |  |     |      00 - данные "Data Record"
     |  |     |      01 - конец файла "End of File Record"
     |  |     |      02 - адрес сегмента "Extended Segment Address Record"
     |  |     |      03 - сегментный адрес старта "Start Segment Address Record"
     |  |     |      04 - линейный адрес "Extended Linear Address Record"
     |  |     |      05 - линейный адрес старта "Start Linear Address Record"
     |  |     |      RECTYP
     |  |     смещение, старший байт впереди 
     |  |     LOAD.ofsSET
     |  количество байт в поле данных 
     |  RECLEN
     маркер записи
     RECORD MARK

Пример:
    :100000001BC6189518951895189518951895D9C563
)
                                                     
\ ======== ЗАДАЧИ ==============================================================
\ 1-ая задача: 
\ нужно открыть файл, прочитать его с контролем, разместить данные в текущем сегменте 
\ : hexLOADED ( c-adr u -- ) c-adr u - это строка с именем файла
\ : LOADhex ( "имя-файла" -- )  

\ 2-ая задача:
\ сохранить данные из текущего сегмента в файл в hex-формате
\ : hexSAVED ( c-adr u -- ) c-adr u - это строка с именем файла
\ : SAVEhex ( "имя-файла" -- ) 
\ ==============================================================================
REQUIRE HEX[  toolbox.f
REQUIRE segments segments.f

[IF_main] CASE-INS OFF [THEN] \ для проверки регистра слов

MODULE: Mihex

    DECIMAL
    VARIABLE fid \ идентификатор файла
    \ учитывается при формировании записей
    00 CONSTANT typDat \ "Data Record"
    01 CONSTANT typEOF \ "End of File Record"
    02 CONSTANT typESA \ "Extended Segment Address Record"
    03 CONSTANT typSSA \ "Start Segment Address Record"
    04 CONSTANT typELA \ "Extended Linear Address Record"
    05 CONSTANT typSLA \ "Start Linear Address Record"

    VARIABLE baseHex  0 baseHex  ! \ базовый адрес загрузки
    VARIABLE startHex 0 startHex ! \ стартовый адрес прошивки

    0 \ структура двоичной записи (в байтах)
      1 -- .len
      2 -- .ofs
      1 -- .typ
    256 -- .dat \ максимально возможный размер данных (255) + 1 на CRC
    CONSTANT structRec
    CREATE byteBuf structRec ALLOT  \ буфер для байтовых записей
    structRec 2* 1+ 2+ CONSTANT  szBuf \ размер буфера для символьных записей
    \ 1 байт = 2 символам, +1 на символ :, +2 на переводы строк
    CREATE recBuf  szBuf ALLOT \ буфер для символьных записей


    : toByte ( adr u -- u') \ преобразовать символьную строку в u' байт
        0 -ROT \ i, индекс байта 
        OVER + SWAP
        DO  0 S>D I 2 HEX[ >NUMBER ]HEX ABORT" Ошибка преобразования HEX-числа"
            DROP  D>S 
            OVER byteBuf + C! 1+ \ i++
        2 +LOOP
        ;

    : prunREC ( u -- adr u') \ обрезать запись
        recBuf SWAP 1 /STRING \ adr u-1 убрать маркер записи 
        BEGIN 2DUP + C@ BL < WHILE 1- REPEAT \ отрезать переводы строк
        ;

    : chkRec ( u --) \ проверка CRC
        >R 0 byteBuf R> + byteBuf
        DO I C@ + LOOP
        0xFF AND ABORT" Ошибка CRC записи"
        ;

    : BigEndian@ ( adr u -- n) \ взять число в BigEndian нотации
        0 -ROT OVER + SWAP
        DO 8 LSHIFT I C@ + LOOP
        ;

    : BigEndian! ( n adr u -- ) \ записать u байт числа n по адресу adr 
        \ в BigEndian нотации
        1- OVER + 
        DO 0x100 /MOD SWAP I C! -1 +LOOP DROP
        ;

    : dat>Seg ( -- ) \ приём данных
        baseHex @  byteBuf .ofs 2 BigEndian@ + 
        segBaseA @ OVER > IF segBaseA @ + THEN ORG
        byteBuf .len C@ 0
        DO byteBuf .dat I + C@ C>Seg LOOP
        ;

    DECIMAL   
    : parseRec ( --) \ разбор записи
        byteBuf .typ C@
        DUP typDat = IF dat>Seg ELSE
        DUP typEOF = IF ELSE
        DUP typESA = IF byteBuf .dat 2 BigEndian@  4 LSHIFT baseHex  ! ELSE
        DUP typSSA = IF byteBuf .dat 4 BigEndian@           startHex ! ELSE
        DUP typELA = IF byteBuf .dat 2 BigEndian@ 16 LSHIFT baseHex  ! ELSE
        DUP typSLA = IF byteBuf .dat 4 BigEndian@           startHex ! ELSE 
                     ABORT" Неверный тип записи"
        THEN THEN THEN THEN THEN THEN DROP
        ;
    
    : record ( n -- ) \ обработка считанной записи 
        \ n-количество принятых символов
        recBuf C@ [CHAR] : =
        IF \ маркер записи
            prunREC toByte
            chkRec 
            parseRec 
        ELSE DROP
        THEN
        ;
        
    : file@ ( -- n) \ считать строку из файла
        recBuf szBuf fid @ READ-LINE THROW
        ;
EXPORT

    : hexLOADED ( c-adr u -- )   
        \ загрузить файл с именем в c-adr u в текущий сегмент
        R/O OPEN-FILE THROW fid !  
        recBuf szBuf fid @ READ-LINE THROW  \ считать первую запись  
        IF record \ один раз можно согласовать базы сегмента и hex  
           segBaseA @ wender - 0= IF baseHex @ segBaseA ! THEN 
        THEN
        \ цикл по остальным записям
        BEGIN
            file@   \ считать_запись  
        WHILE \ данные
            record
        REPEAT
        DROP fid @ CLOSE-FILE THROW
        ;

    : LOADhex ( "имя-файла" -- )
        BL WORD COUNT hexLOADED
        ;  

    : binLOADED ( c-adr u -- )   
        \ загрузить бинарный файл с именем в c-adr u в текущий сегмент
        R/O OPEN-FILE THROW fid !  
        fid @ FILE-SIZE THROW 
        ?DUP ABORT" Огромный файл"
        ?segBase + ORG
        ?segAddr ?segWender fid @ READ-FILE THROW DROP 
        fid @ CLOSE-FILE THROW
        ;

    : LOADbin ( "имя-файла" -- )
        BL WORD COUNT binLOADED
        ;  
DEFINITIONS \ 2-я задача
    DECIMAL
    VARIABLE maxRECLEN  \ максимальный размер поля данных
EXPORT
    \ писать или нет строки целиком состоящих их дефолтных символов
    VARIABLE shortHex   
    shortHex ON \ не писать

    : shortRec ( --) \ установить короткую длину записей
        16 maxRECLEN !
        ;
    shortRec

    : wideRec ( --) \ установить широкую длину записей
        32 maxRECLEN !
        ;
DEFINITIONS

    : toSym ( -- adr u) \ преобразовать байтовую запись в hex-строку
        byteBuf DUP .len C@ 5 + \ adr1 u1 
        S" :" >S
        OVER + SWAP HEX[ DO I C@ 0 <# # # #> +>S LOOP ]HEX
        S>
        ;

    : hexCRC ( adr u -- crc) \ расчитать контрольный байт
        0x100 -ROT
        OVER + SWAP DO I C@ - LOOP 
        0xFF AND
        ;

    : ELArecord ( base --) \ записать базовый адрес
        DUP baseHex !
        16 RSHIFT byteBuf .dat 2 BigEndian!
             2 byteBuf .len C!
             0 byteBuf .ofs W!
        typELA byteBuf .typ C!
        ;

    : SLArecord ( -- ) \ стартовая запись
        startHex @ ?DUP
        IF byteBuf .dat 4 BigEndian!
                4 byteBuf .len C!
                0 byteBuf .ofs W!
           typSLA byteBuf .typ C!
        THEN
        ;

    : NewDatRecord ( ofs --) \ новая запись данных
               byteBuf .ofs 2 BigEndian!
             0 byteBuf .len C!
        typDat byteBuf .typ C!  
        ;

    : EOFrecord ( --) \ последняя запись
             0 byteBuf .len C!
             0 byteBuf .ofs W!
        typEOF byteBuf .typ C!  
        ;

    : cntNoDef ( -- n) \ выдать число НЕ дефолтных символов
        byteBuf .typ C@ typDat = \ только в записях с данными
        IF byteBuf .dat byteBuf .len C@ TUCK
           OVER + SWAP ?DO I C@ ?segDef = IF 1- THEN LOOP
        ELSE TRUE
        THEN
        ; 
    
    : rec2file ( --) \ запись в файл
        \ с пропуском пустых записей (заполненых дефолтным символом)
        byteBuf .len C@ maxRECLEN @ > IF EXIT THEN
        shortHex @ IF cntNoDef ELSE TRUE THEN
        IF byteBuf DUP .len C@ 0 .dat + 2DUP hexCRC
           -ROT + C!
           toSym fid @ WRITE-LINE THROW 
           -1 byteBuf .len C!
        THEN  
        ;

    : toRec ( adr --) \ упаковать [adr] в запись
        DUP baseHex @ - 0x10000 MOD 0= IF rec2file DUP ELArecord THEN \ новая база
        baseHex @ - \ ofs 
        DUP maxRECLEN @ MOD TUCK 0= IF rec2file NewDatRecord ELSE DROP THEN \ новая запись
        ( idxRec) byteBuf .dat + Seg>C SWAP C!
        1 byteBuf .len +! 
        ;

    : segBody! ( --) \ записать сегмент в hex-файл
        ?segBase ORG \ установить указатель в начало сегмента
        -1 byteBuf .len C! \ буфер еще не готов для записи в файл
        wender ?segBase DO I toRec LOOP
        ;
EXPORT
        
    : hexSAVED ( c-adr u --) 
        \ сохранить текущий сегмент в hex-файл с именем в строке c-adr u
        \ файл создается или перезаписывается без вопросов
        W/O CREATE-FILE ABORT" Ошибка создания файла." fid !
        segBody!  rec2file
        SLArecord rec2file
        EOFrecord rec2file  \ последняя запись
        fid @ CLOSE-FILE THROW
        ;

    : SAVEhex ( "имя-файла" -- )
        BL WORD COUNT hexSAVED
        ;

    : binSAVED ( c-adr u --)    
        \ сохранить текущий сегмент в bin-файл с именем в строке c-adr u
        \ файл создается или перезаписывается без вопросов
        W/O CREATE-FILE ABORT" Ошибка создания файла." fid !
        ?segAddr ?segWender ?DUP IF fid @ WRITE-FILE THROW THEN
        fid @ CLOSE-FILE THROW
        ;

    : SAVEbin ( "имя-файла" -- )
        BL WORD COUNT binSAVED
        ;

;MODULE

\ примеры использования и тест
[IF_main] \ определено в spf4.ini
CASE-INS ON
0xFF 0x08000000 0 256  createSeg: TST-SEG
TST-SEG TO SEG
\ LOADhex app1.hex
\ LOADhex control_module_app1_w_boot_v2.7.4.hex
\ LOADhex test-af.hex
\ TST-SEG segDump CR
LOADbin aa.bin
?seg
\ wideRec
ALSO Mihex
HEX
SAVEhex aa.hex
\ SAVEbin aa.bin
[THEN]

