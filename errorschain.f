\ описание ошибок
REQUIRE chain: chains.f
REQUIRE alloc  heap.f

MODULE: errorsChain

    
    0 \ структура статьи ошибки
    CELL -- .NumErr  \ номер ошибки
    CELL -- .TxtErr  \ -->строка со счетчиком, описание ошибки
    CONSTANT structErr

    : ext? ( n errObj -- n TRUE| adrErrStr FALSE )
        \ поисковый бегунок
        >R ( n)
        R@ .NumErr @ OVER = ( n f)
        IF DROP R@ .TxtErr @ FALSE ELSE TRUE THEN
        R> DROP
        ;
    
    : extList ( obj -- TRUE )
        DUP 
        .NumErr @ .
        .TxtErr @ str# TYPE CR 
        TRUE ;

EXPORT

    chain: errChain \ цепочка ошибок

    : err: ( n "описание" --)
        CREATE 
        structErr alloc DUP >R ,
        R@ errChain @ +hung \ включить в цепочку
        R@ .NumErr ! \ запомнить номер
        BL WORD DROP \ поглотить следующее слово, S"
        [CHAR] " PARSE str> \ взять описание
        R> .TxtErr !
        DOES> @ .NumErr @ ;

    : err? ( n -- c-addr u) \ найти описание ошибки
        DUP errChain @ ['] ext? extEach 
        TUCK = IF THROW ELSE str# THEN 
        ;

    : errList. ( -- ) \ распечатать известные ошибки
        errChain @ ['] extList extEach
        ;

;MODULE

\EOF пример использования
300 COUNTER: ErrNo
ErrNo err: errEncode S" не удалось закодировать"
ErrNo err: errNoReg  S" Не регистр"
ErrNo err: errRlo    S" Не младший регистр"
\ ...
errNoReg err? TYPE CR
errList.
QUIT 
