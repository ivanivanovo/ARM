\ инструменты для управления сегментами памяти
\ автор:~iva дата:2022 ревизия:2
\ ======== ИНФО ================================================================
\ Сементы нужно создавать, писать-читать в/из них.
\ Размер этих сегментов может изменяться прозрачно для пользователя,
\ если очередная запись перелетает текущую границу, то размер автоматически 
\ будет увеличен (кратно текущему размеру).
\ Новое место заполняется дефолтным байтом.
\ Если лимит на размер не установлен (lim=0), то он не учитывается 
\ и размер сегмета увеличивается без ограничения.
\ Запись в сегмент производится по текущему указателю (finger) порциями 
\ по байту, слову (2 байта), ячейке (4 байта) и строкой (u байт). 
\ После записи указатель (finger) перемещается на нужное количество байт
\ и указывает на пустое место в сегменте, так что читать не получится.
\ Перед чтением из сегмента, указатель должен быть установлен на нужное место (ORG).
\ wender указывает на еще не использованное место в сегменте,
\ он всегда больше или равен finger. 
\ finger не обгоняет wender, а толкает его перед собой.
\ 0 <= свободный указатель <= указатель конца записи <= максимальный размер.
\ 0 <=      finger         <=       wender           <= lim

REQUIRE .HEX   toolbox.f
REQUIRE chain: chains.f \ для связывания сегментов в цепь
REQUIRE alloc  heap.f   \ для обращения к куче

MODULE: segments
    \ 
        0 \ структура описывающая сегмент
        CELL -- .adr    \ адрес выделенной памяти в компе
        CELL -- .name   \ --> на строку со счетчиком
        CELL -- .base   \ начало сегмента в памяти чипа
        CELL -- .size   \ текущий размер выделенной памяти
        CELL -- .lim    \ ограничение размера для выделенной памяти
        CELL -- .finger \ свободный указатель, смещение от начала сегмента
        CELL -- .wender \ указатель конца записи, смещение от начала сегмента
        CELL -- .labels \ начало цепочки меток в этом сегменте
        1    -- .defsym \ дефолтное значение неиспользованной области сегмента
        CONSTANT stuctSEG
        VARIABLE fid \ идентификатор файла

    EXPORT

        0 VALUE SEG \ ссылка на структуру текущего сегмента
        chain: SegChain \ цепочка сегментов
        : ?segLabels ( -- nexus)
            SEG .labels @
            ;

        : segBaseA ( -- adr) \ адрес переменной base текущего сегмента
            SEG .base 
            ;

        : ?segAddr ( -- adr) \ выдать сегментный адрес памяти
            SEG .adr @
            ; 

        : ?segBase ( -- base) \ base текущего сегмента
            segBaseA @
            ;

        \ : ?segWender ( -- wender) \ выдать указатель конца записи
        \     SEG .wender @
        \     ; 


        \ : ?segDef ( -- sym) \ выдать сегментный симовол
        \     SEG .defsym C@
        \     ; 
        
        : ,name ( seg -- adr u) \ выдать имя сегмента
            .name @ str# ;
        : ?segName ( -- adr u) \ выдать имя текущего сегмента 
            SEG ,name ;   
    DEFINITIONS

        : name. ( seg --) \ напечатать имя сегмента
            ,name TYPE
            ;

        : defFill ( seg -- ) \ заполнить новое место дефолтным символом 
            >R
            R@ .adr  @  R@ .wender @ +
            R@ .size @  R@ .wender @ - 
            R> .defsym C@ 
            FILL 
            ;

        : resize? ( finger' --) \ нужно ли и возможно ли изменение размера сегмента?
            SEG .size @ OVER <
            \ попытка расширить сегмент
            IF  SEG .lim @ ?DUP IF OVER < ABORT" Выход за ограничитель сегмента." THEN
                SEG .size @ OVER SWAP / 1+ SEG .size @ *
                SEG .lim @ ?DUP IF MIN THEN
                \ finger' new-size
                SEG .adr @ OVER RESIZE THROW SEG .adr ! SEG .size !
                SEG defFill
            THEN 
            DROP
            ;
            
        : finger! ( u --) \ установить указатель
            >R
            R@ resize?
            R@ SEG .finger !
            R> SEG .wender @ MAX SEG .wender ! 
            ;

        : finger> ( u --) \ передвинуть указатель на u байт
            SEG .finger @ + finger! 
            ;    
            
        : u>SEG ( u -- adr) \ дать адрес для записи u байт в сегмент
            SEG .finger @ 
            SWAP finger>
            SEG .adr @ + 
            ;

        : SEG>u ( u -- adr) \ дать адрес для чтения u байт из сегмента
            SEG .finger @ 2DUP +
            SEG .wender @ > ABORT" Незаписано."
            SWAP finger>
            SEG .adr @ + 
            ;

        : (.seg) ( seg -- f)
            >R
            SEG R@ = IF CR ." == Текущий сегмент == " THEN
            CR ." Имя:     "   R@ name. 
            CR ." Адрес:   0x" R@ .adr    @ .UHEX
            CR ." База:    0x" R@ .base   @ .UHEX
            CR ." Размер:  "   R@ .size   @ U.
            CR ." Лимит:   "   R@ .lim    @ U.
            CR ." Заполн.: 0x" R@ .defsym C@ .UHEX
            CR ." .finger: "   R@ .finger @ U.
            CR ." .wender: "   R@ .wender @ U.
            CR ." .labels: 0x" R@ .labels @ .UHEX
            CR R> DROP
            TRUE
            ;
        : .seg ( seg --) \ показать структуру сегмента seg
            (.seg) DROP
            ;   
    EXPORT
        \ 0xFF 0x800000 max createSeg: ROM-SEG
        : createSeg: ( sym base limit <name> --)
        \ новое слово <name> выдает адрес структуры
        \ сегмент создается с минимальным размером 256 байт
        \ если он не превышает лимит
            >IN @ >R
                CREATE 
                256 OVER ?DUP IF MIN THEN DUP >R ALLOCATE THROW
                HERE stuctSEG 0 FILL
                HERE SegChain hung+ \ в цепочку
                HERE .adr !
                R> HERE .size !
                HERE .lim !
                HERE .base !
            R> >IN ! BL WORD COUNT str>
                HERE .name !
                HERE .labels iniChain \ начало цепочки местных меток
                HERE .defsym !
                HERE defFill \ забить сегмент символом
                stuctSEG ALLOT
            ;

        : ?seg ( --) \ показать структуру текущего сегмента
            SEG IF SEG .seg THEN
            ;

        : lsSEG ( -- ) \ выдать список всех сегментов
            SegChain  
            IF SegChain ['] (.seg) extEach 
            THEN
            ;
        
        : [DUMP] ( adr u -- ) \ распечатать дамп в заданых границах 
            \ с индексами
            ?DUP 
            IF  HEX[
                    0 -ROT
                    OVER + SWAP \ отображаемые адреса
                    DO
                        DUP 15  AND 0= IF CR DUP 10 .R SPACE THEN
                        DUP 3   AND 0= IF ."  " THEN
                        I C@ 2 .0R SPACE 
                        1+
                        DUP 255 AND 0= IF CR THEN
                    LOOP DROP 
                ]HEX
            ELSE DROP ." Пусто." 
            THEN CR
            ;

        : SEGdump ( seg --) \ распечатать дамп записаной части сегмента
            CR
            DUP .base @ ." 0x" 8 HEX[ .0R ]HEX SPACE DUP name.
            DUP .adr @ SWAP .wender @ [DUMP]
            ;

        : ORG ( u -- ) \ установить указатель сегмента
            SEG .base @ - DUP 0< ABORT" Неверный адрес внутри сегмента."
            finger! 
            ;
        
        : finger ( -- segAdr) \ получить целевой адрес
            SEG .base @
            SEG .finger @ +
            ;
        : wender ( -- segAdr) \ получить целевой адрес
            SEG .base @
            SEG .wender @ +
            ;
        \ запись в сегмент ===============================    
        : >Seg ( n --) \ записать ячейку в сегмент
            CELL u>SEG !
            ;
        : W>Seg ( n -- ) \ записать слово в сегмент
            2 u>SEG W!
            ;    
        : C>Seg ( n -- ) \ записать байт в сегмент
            1 u>SEG C!
            ;    
        : S>Seg ( adr u -- ) \ записать строку в сегмент
            \ как строку со счетчиком
            DUP 1+ u>SEG 2DUP C! 1+ SWAP CMOVE
            ;    

        \ чтение из сегмента ===============================    
        : Seg> ( -- n) \ получить ячейку из сегмента
            CELL SEG>u @
            ;
        : Seg>W (  -- n ) \ получить слово из сегмента
            2 SEG>u W@
            ;    
        : Seg>C (  -- n ) \ получить байт из сегмента
            1 SEG>u C@
            ;    
        : Seg>S (  -- adr u ) \ получить строку из сегмента
            \ как строку со счетчиком
            Seg>C SEG>u COUNT
            ; 

        : binLOADED ( c-adr u -- )   
            \ загрузить бинарный файл с именем в c-adr u в текущий сегмент
            R/O OPEN-FILE THROW fid !  
            fid @ FILE-SIZE THROW 
            ABORT" Огромный файл"
            0 SEG .finger ! 0 SEG .wender ! \ сброс указателей
            finger> \ расширить сегмент до размера файла (если нужно)
            SEG .adr @ SEG .wender @ fid @ READ-FILE THROW DROP 
            fid @ CLOSE-FILE THROW
            ;

        : LOADbin ( <имя-файла> -- )
            BL WORD COUNT binLOADED
            ;  

        : binSAVED ( c-adr u --)    
            \ сохранить текущий сегмент в bin-файл с именем в строке c-adr u
            \ файл создается или перезаписывается без вопросов
            SEG .wender @  
            IF W/O CREATE-FILE ABORT" Ошибка создания файла." fid !
               SEG .adr @ SEG .wender @
               fid @ WRITE-FILE THROW 
               fid @ CLOSE-FILE THROW
            ELSE 2DROP
            THEN
            ;

        : SAVEbin ( <имя-файла> -- )
            BL WORD COUNT binSAVED
            ;
;MODULE

\ ======== ТЕСТЫ И ПРИМЕРЫ =====================================================
[IF_main] \ определено в spf4.ini
    0xFF 0x08000000 0   createSeg: ROM-SEG
    ROM-SEG TO SEG
    0x00 C>Seg
    0x12 C>Seg
    0x5634 W>Seg
    0x9078 W>Seg
    0x78563412 >Seg
    S" test string" S>Seg
    SEG SEGdump
    ?seg CR
    
    0 0x800000 24 createSeg:  tup
    tup TO SEG
    1 C>seg
    2 C>seg
    3 C>seg
    4 C>seg
    5 C>seg
    SEG SEGdump
    CR lsSEG

[THEN]
