\ слова для работы в куче
: alloc ( size -- adr) \ взять из кучи size байт 
    \ и проинициализировать их 0
    DUP ALLOCATE THROW 
    DUP ROT 0 FILL
    ;

\ очень длинные строки с большим счетчиком
: str> ( adr u -- u-adr) \ разместить строку со счетчиком в куче
    DUP CELL+ alloc \ a u a1
    2DUP ! 
    DUP >R
    CELL+ SWAP CMOVE
    R>
    ;

: str# ( u-adr -- adr u) \ преобразовать адрес строки с большим счетчиком к виду adr u
    DUP CELL+ SWAP @  
    ;

