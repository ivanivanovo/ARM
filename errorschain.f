\ описание ошибок
REQUIRE chain: chains.f
REQUIRE alloc  heap.f

MODULE: errorsChain

    chain: errStp   \ пустая цепочка, 
    \ служит для досрочного прекращения перебора цепочки и
    \ как признак того, что искомое найдено
    
    0 \ структура статьи ошибки
    CELL -- .NextErr \ поле связи 
    CELL -- .NumErr  \ номер ошибки
    CELL -- .TxtErr  \ -->строка со счетчиком, описание ошибки
    CONSTANT structErr

    : ext? ( n chain -- n chain'| adr errStp )
                  \          \          \__ когда найдет
                   \ _________\_ пока ищет
        \ поисковый бегунок
        2DUP .NumErr @ = 
        IF NIP errStp THEN \ прекратить поиск по совпадению
        ;
    
    : extList ( adr -- adr )
        DUP .NumErr @ .
        DUP .TxtErr @ COUNT TYPE CR ;

EXPORT

    chain: errChain \ цепочка ошибок

    : err: ( n "описание" --)
        CREATE 
        structErr alloc DUP >R ,
        R@ errChain +chain \ включить в цепочку
        R@ .NumErr ! \ запомнить номер
        BL WORD DROP \ поглотить следующее слово, S"
        [CHAR] " PARSE str> \ взять описание
        R> .TxtErr !
        DOES> @ .NumErr @ ;

    : err? ( n -- c-addr u) \ найти описание ошибки
        errChain ['] ext? extEach 
        errStp = \ нашел или нет
        IF .TxtErr @ COUNT ELSE DROP S" неизвестная ошибка" THEN 
        ;

    : errList. ( -- ) \ распечатать известные ошибки
        errChain ['] extList extEach DROP
        ;

;MODULE

\EOF пример использования
300 COUNTER: ErrNo
ErrNo err: errEncode S" не удалось закодировать"
ErrNo err: errNoReg  S" Не регистр"
ErrNo err: errRlo    S" Не младший регистр"
\ ...
errRlo err? TYPE CR
