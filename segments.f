\ инструменты для управления сегментами памяти
\ автор:~iva дата:2022 ревизия:2
\ ======== ИНФО ================================================================
\ Сементы нужно создавать, писать-читать в/из них.
\ Размер этих сегментов может изменяться прозрачно для пользователя,
\ если очередная запись перелетает текущую границу, то размер автоматически 
\ будет увеличен (кратно текущему размеру).
\ Если лимит на размер не установлен (lim=0), то он не учитывается 
\ и размер сегмета увеличивается без ограничения.
\ Запись в сегмент производится по текущему указателю (finger) порциями 
\ по байту, слову (2 байта), ячейке (4 байта) и строкой (u байт). 
\ После записи указатель перемещается на нужное количество байт и указывает на
\ пустое место в сегменте, так что читать из сегмента не получится.
\ Перед чтением из сегмента, указатель должен быть установлен на нужное место (ORG).

REQUIRE chain: chains.f \ для свзывания сегментов в цепь
REQUIRE alloc  heap.f   \ для обращения к куче

MODULE: segments

    \ структура описывающая сегмент
    0
    CELL -- .adr    \ адрес выделенной памяти в компе
    CELL -- .name   \ --> на строку со счетчиком
    CELL -- .base   \ начало сегмента в памяти чипа
    CELL -- .size   \ текущий размер выделенной памяти
    CELL -- .lim    \ ограничение размера для выделенной памяти
    CELL -- .finger \ свободный указатель, смещение от начала сегмента
    CELL -- .wender \ указатель конца записи, смещение от начала сегмента
    CELL -- .labels \ начало цепочки меток в этом сегменте
    CONSTANT stuctSEG

\ 0 <= свободный указатель <= указатель конца записи <= максимальный размер.
\ 0 <=      finger         <=       wender           <= lim

EXPORT

    0 VALUE SEG \ ссылка на структуру текущего сегмента
    chain: SegChain \ цепочка сегментов

DEFINITIONS
    : name. ( seg --) \ напечатать имя сегмента
        .name @ str# TYPE
        ;

    : resize? ( finger' --) \ нужно ли и возможно ли изменение размера сегмента?
        SEG .size @ OVER <
        \ попытка расширить сегмент
        IF  SEG .lim @ ?DUP IF OVER < ABORT" Выход за ограничитель сегмента." THEN
            SEG .size @ OVER SWAP / 1+ SEG .size @ *
            SEG .lim @ ?DUP IF MIN THEN
            \ finger' new-size
            SEG .adr @ OVER RESIZE THROW SEG .adr ! SEG .size !
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
        SEG .finger @ TUCK +
        SEG .wender @ > ABORT" Незаписано."
        SEG .adr @ + 
        ;

    : (.seg) ( seg -- f)
        >R
        SEG R@ = IF CR ." == Текущий сегмент == " THEN
        CR ." Имя:     "   R@ name. 
        CR ." Адрес:   0x" R@ .adr    @ .HEX
        CR ." База:    0x" R@ .base   @ .HEX
        CR ." Размер:  "   R@ .size   @ .
        CR ." Лимит:   "   R@ .lim    @ .
        CR ." .finger: "   R@ .finger @ .
        CR ." .wender: "   R@ .wender @ .
        CR ." .labels: "   R@ .labels @ .HEX
        CR R> DROP
        TRUE
        ;
    : .seg ( seg --) \ показать структуру сегмента seg
        (.seg) DROP
        ;
       
EXPORT
    \ max size createSeg: ROM-SEG
    : createSeg: ( base limit size <name> --)
    \ новое слово <name> выдает адрес структуры
        >IN @ >R
            CREATE DUP >R ALLOCATE THROW
            HERE stuctSEG 0 FILL
            HERE SegChain @ hung+ \ в цепочку
            HERE .adr !
            R> HERE .size !
            HERE .lim !
            HERE .base !
        R> >IN ! BL WORD COUNT str>
            HERE .name !
            HERE .labels iniChain \ начало цепочки местных меток
            stuctSEG ALLOT
        ;

    : ?seg ( obj--) \ показать структуру текущего сегмента
        SEG IF SEG .seg THEN
        ;

    : segLabels ( -- nexus)
        SEG .labels 
        ;

    : lsSEG ( -- ) \ выдать список всех сегментов
        SegChain @ 
        IF SegChain @ ['] (.seg) extEach 
        THEN
        ;

    : SEGdump ( seg --) \ распечатать дамп сегмента
        CR
        DUP .adr @ SWAP .wender @ DUMP
        ;

    : ORG ( u -- ) \ установить указатель сегмента
        SEG .base @ - DUP 0< ABORT" Неверный адрес."
        finger! 
        ;
    
    : finger ( -- baseAdr) \ получить целевой адрес
        SEG .base @
        SEG .finger @ +
        ;
    : wender ( -- baseAdr) \ получить целевой адрес
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

;MODULE

\EOF \ ======== ТЕСТЫ И ПРИМЕРЫ =====================================================
0x08000000 30  22 createSeg: ROM-SEG
ROM-SEG TO SEG
0x123 >seg
SEG SEGdump
?seg CR

0x800000 1024 127 createSeg:  tup
tup TO SEG
\ ?seg CR
0x800100 200 127 createSeg:  tmp
tmp TO SEG
\ ?seg CR
0x800200 200 10 createSeg:  tmp2
tmp2 TO SEG
\ ?seg CR

tup TO SEG
CR lsSEG
QUIT
