\ слова для работы в куче
: alloc ( size -- adr) \ взять из кучи size байт 
    \ и проинициализировать их 0
    DUP ALLOCATE THROW >R
    R@ SWAP 0 FILL
    R>
    ;
: str> ( adr u -- c-adr) \ разместить строку со счетчиком в куче
    0xFF AND \ ограничение 255 сиволов
    DUP 1+ alloc \ a u a1
    2DUP C! 
    DUP >R
    1+ SWAP CMOVE
    R>
    ;
