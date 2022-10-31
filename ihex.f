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
     |  |     LOAD OFFSET
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
\ : HEX-LOAD ( c-adr u -- ) c-adr u - это строка с именем файла
\ : LOAD-AS-HEX ( "имя-файла" -- )  

\ 2-ая задача:
\ сохранить данные из текущего сегмента в файл в hex-формате
\ : HEX-SAVE ( c-adr u -- ) c-adr u - это строка с именем файла
\ : SAVE-AS-HEX ( "имя-файла" -- ) 
\ ==============================================================================
REQUIRE alloc heap.f
REQUIRE HEX[  toolbox.f
REQUIRE segments segments.f


MODULE: IHEX

    DECIMAL
    VARIABLE fid \ идентификатор файла
    VARIABLE maxRECLEN  16 maxRECLEN ! \ максимальный размер поля данных
    \ учитывается при формировании записей
    \ 32 IHEX::maxRECLEN !  так можно изменить размер
    00 CONSTANT typDat \ "Data Record"
    01 CONSTANT typEOF \ "End of File Record"
    02 CONSTANT typESA \ "Extended Segment Address Record"
    03 CONSTANT typSSA \ "Start Segment Address Record"
    04 CONSTANT typELA \ "Extended Linear Address Record"
    05 CONSTANT typSLA \ "Start Linear Address Record"

    VARIABLE baseAddr  0 baseAddr  ! \ базовый адрес загрузки
    VARIABLE startAddr 0 startAddr ! \ стартовый адрес прошивки

    0 \ структура записи (в байтах)
      1 -- .len
      2 -- .off
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

    : BigEndian@ ( adr u -- n) \ взять число в BigEndian@ нотации
        0 -ROT OVER + SWAP
        DO 8 LSHIFT I C@ + LOOP
        ;

    : dat>Seg ( -- ) \ приём данных
        baseAddr @  byteBuf .off 2 BigEndian@ + ORG
        byteBuf .len C@ 0
        DO byteBuf .dat I + C@ C>Seg LOOP
        ;

     DECIMAL   
    : parseRec ( --) \ разбор записи
        byteBuf .typ C@
        DUP typDat = IF dat>Seg ELSE
        DUP typEOF = IF ELSE
        DUP typESA = IF byteBuf .dat 2 BigEndian@  4 LSHIFT baseAddr  ! ELSE
        DUP typSSA = IF byteBuf .dat 4 BigEndian@           startAddr ! ELSE
        DUP typELA = IF byteBuf .dat 2 BigEndian@ 16 LSHIFT baseAddr  ! ELSE
        DUP typSLA = IF byteBuf .dat 4 BigEndian@           startAddr ! ELSE 
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

EXPORT

    : HEX-LOAD ( c-adr u -- )   
        \ загрузить файл с именем в c-adr u в текущий сегмент
        R/O OPEN-FILE THROW fid !  
        BEGIN
            recBuf szBuf fid @ READ-LINE THROW  \ считать_запись  
        WHILE \ данные
            record
        REPEAT
        DROP fid @ CLOSE-FILE THROW
        ;

    : LOAD-AS-HEX ( "имя-файла" -- )
        BL WORD COUNT HEX-LOAD
        ;  

    : HEX-SAVE ( c-adr u --) 
        \ сохранить текщий сегмент в файл с именем в строке c-adr u
        \ файл создается или перезаписывается без вопросов
        W/O CREATE-FILE ABORT" Ошибка создания файла." fid !


        S" :00000001FF" fid @ WRITE-LINE THROW  \ последняя запись
        fid @ CLOSE-FILE THROW
        ;

    : SAVE-AS-HEX ( "имя-файла" -- )
        BL WORD COUNT HEX-SAVE
        ;

DEFINITIONS

;MODULE

\ примеры использования и тест
[IF_main] \ определено в spf4.ini
0xFF 0x08000000 0 256  createSeg: TST-SEG
TST-SEG TO SEG
LOAD-AS-HEX app1.hex
\ TST-SEG segDump
[THEN]

