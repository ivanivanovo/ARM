\ работа с метками
REQUIRE .HEX            toolbox.f
REQUIRE enqueueNOTFOUND nf-ext.f
REQUIRE alloc           heap.f
REQUIRE SEG             segments.f
REQUIRE curSrc          filist.f
REQUIRE segLabels       segments.f

chain: allLabels \ все метки в одной цепочке

MODULE: Mlabels

    0 \ структура метки
    CELL -- .seg    \ сегмент метки
    CELL -- .adr    \ значение метки (base+ofs)
    CELL -- .name   \ --> имя метки
    CELL -- .file   \ --> в каком файле определена
    CELL -- .line   \ в какой строке
    CELL -- .pos    \ на какой позиции
    CONSTANT structLabel

    : (create) ( adr u --) \ создать метку
        TUCK \ u adr u
        2DUP CREATED 
        structLabel alloc DUP >R ,
        SEG      R@ .seg  !
        finger   R@ .adr  !
        str>     R@ .name !
        curSrc   R@ .file !
        CURSTR @ R@ .line !
        >IN @ SWAP - R@ .pos !
        R@ allLabels @ +hung \ ввести в цепочку
        R> segLabels @ +hung \ ввести в цепочку сегмента
        DOES> @ .adr @
        ;

EXPORT 
    \ NOTFOUND
    \ если слово не найдено И кончается двоеточием,
    \ сделать из него метку (без двоеточия в конце!)
    :NONAME ( adr u -- true| adr u false)
        2DUP + 1- C@ [CHAR] : =
        IF 1- (create) TRUE ELSE FALSE THEN
        ; enqueueNOTFOUND

    : ?label ( obj --) \ показать структуру метки по адресу объекта метки
        CR DUP ." label: " .name @ str# TYPE 
        CR DUP ." seg:   " .seg @ segments::name.
        CR DUP ." adr:   0x" .adr @ .HEX
        CR DUP ." file:  " .file @ str# TYPE
        CR DUP ." line:  " .line @ .
        CR     ." pos:   " .pos @ .
        ;

    : shwLabel ( xt --) \ показать структуру метки по токену метки
        >BODY @ ?label
        ;
    : createLabel ( <name> --) \ создать метку <name>
        BL WORD COUNT (create)
        ;

;MODULE
