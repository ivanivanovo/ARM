\ инструменты для управления сегментами памяти
\ автор:~iva дата:2020 ревизия:2
\ ======== ИНФО ================================================================
\ Сементы нужно создавать, писать-читать в/из них.
\ Размер этих сегментов может изменяться прозрачно для пользователя,
\ если очередная запись перелетает текущую границу, то размер автоматически 
\ будет увеличен.

MODULE: segments

    \ структура описывающая сегмент
    0
    CELL -- .adr    \ адрес выделенной памяти в компе
    CELL -- .base   \ начало сегмента в памяти чипа
    CELL -- .size   \ текущий размер выделенной памяти
    CELL -- .lim    \ ограничение размера для выделенной памяти
    CELL -- .finger \ свободный указатель, смещение от начала сегмента
    CELL -- .wender \ указатель конца записи, смещение от начала сегмента
    CONSTANT stuctSEG
    ( name - str)      \ строка со счетчиком примыкает с структуре
    : .name ( adr -- c-adr-name u)
        stuctSEG + COUNT ;
EXPORT
    0 VALUE SEG \ ссылка на структуру текущего сегмента
DEFINITIONS
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


EXPORT
    \ max size createSeg: ROM-SEG
    : createSeg: ( base limit size <name> --)
    \ новое слово <name> выдает адрес структуры
        >IN @ >R
            CREATE DUP >R ALLOCATE THROW
            HERE stuctSEG 0 FILL
            HERE .adr !
            R> HERE .size !
            HERE .lim !
            HERE .base !
        stuctSEG ALLOT
        R> >IN ! BL WORD COUNT str!
        ;

    : ?seg ( --) \ показать структуру текущего сегмента
        CR ." === Текущий сегмент === "  
        CR ." Имя:          "   SEG .name TYPE 
        CR ." Адрес:        0x" SEG .adr    @  .HEX
        CR ." База:         0x" SEG .base   @  .HEX
        CR ." Размер:       "   SEG .size   @ .
        CR ." Лимит:        "   SEG .lim    @ .
        CR ." Указатель:    "   SEG .finger @ .
        CR ." Использовано: "   SEG .wender @ .
        CR
        ;

    : ORG ( u -- ) \ установить указатель сегмента
        SEG .base @ - DUP 0< ABORT" Неверный адрес."
        finger! 
        ;
    
    : finger ( -- baseAdr) \ получить целевой адрес
        SEG .base @
        SEG .finger @
        +
        ;
    : wender ( -- baseAdr) \ получить целевой адрес
        SEG .base @
        SEG .wender @
        +
        ;
    \ запись в сегиент ===============================    
    : >Seg ( n --) \ записать ячейку в сегмент
        CELL u>SEG !
        ;
    : H>Seg ( n -- ) \ записать пол-ячейки в сегмент
        CELL 2/ DUP u>SEG \ n u adr
        DUP >R + R> 
        DO DUP 8 RSHIFT SWAP I C!
        LOOP
        DROP
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

    \ чтение из сегиента ===============================    
    : Seg> ( -- n) \ получить ячейку из сегмента
        CELL SEG>u @
        ;
    : Seg>H ( -- n ) \ получить пол-ячейки из сегмента
        0 CELL 2/ DUP SEG>u \ n' u adr
        DUP ROT + 1- 
        DO 8 LSHIFT I C@ +
        -1 +LOOP
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

\ EOF
\ ======== ТЕСТЫ И ПРИМЕРЫ =====================================================
\ 30  22 createSeg: ROM-SEG
\ ROM-SEG TO SEG
\ HEX
\ ROM-SEG 7 CELLS DUMP CR
\ SEG @ 40 DUMP CR
\ 1 >Seg TRUE 3 B>Seg SEG @ 10 DUMP CR

0x800000 1024 127 createSeg:  tup
tup TO SEG
?seg CR
