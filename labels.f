\ работа с метками
\ автор: ~iva дата: 2022 ревизия: 1
\ Метка помечает текущий адрес в текущем сегменте памяти.
\ При вызове по имени метка выдает это адрес, а факт вызова увеличивает 
\ её внутренний счетчик использования, это можно использовать для выявления
\ "мертвого кода".
\ Цепочка allLabels объединяет все метки во всех сегментах, но кроме этого
\ каждый сегмент памяти имеет собственную цепочку меток расположенных
\ именно в этом сегменте. Таким образом каждая метка доступна как слово, по имени,
\ или через цепочки (длинную и покороче), по любому полю.

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
    CELL -- .type   \ тип метки
    CELL -- .cnt    \ счетчик использования метки
    CELL -- .name   \ --> имя метки
    CELL -- .file   \ --> в каком файле определена
    CELL -- .line   \ в какой строке
    CELL -- .pos    \ на какой позиции
    CONSTANT structLabel

    : (create) ( type adr u --) \ создать метку
        TUCK \ type u adr u
        2DUP CREATED 
        structLabel alloc DUP >R ,
        SEG      R@ .seg  !
        finger   R@ .adr  !
        0        R@ .cnt  !   
        str>     R@ .name ! \ type u
        curSrc   R@ .file !
        CURSTR @ R@ .line !
        >IN @ SWAP - R@ .pos ! \ type
                 R@ .type !
        R@ allLabels @ +hung \ ввести в цепочку меток
        R> segLabels @ +hung \ ввести в цепочку меток сегмента
        DOES> @ DUP .cnt 1+! .adr @
        ;

EXPORT 

    0 CONSTANT CodeType \ код
    1 CONSTANT DataType \ данные
    2 CONSTANT RegType  \ регистры
    3 CONSTANT PortType \ порты
    4 CONSTANT BitType  \ биты
    5 CONSTANT MarkType \ внутренняя метка

DEFINITIONS

    : typeLabel ( type -- adr u) \ строка типа метки
        >R
        R@ CodeType = IF S" Code " ELSE  
        R@ DataType = IF S" Data " ELSE  
        R@ RegType  = IF S" Reg  " ELSE  
        R@ PortType = IF S" Port " ELSE  
        R@ BitType  = IF S" Bit  " ELSE
        R@ MarkType = IF S" mark " ELSE S" ---"
                THEN THEN THEN THEN THEN THEN 
        R> DROP 
    ;

EXPORT
    
    \ NOTFOUND
    \ если слово не найдено И кончается двоеточием,
    \ сделать из него метку (без двоеточия в конце!)
    :NONAME ( adr u -- true| adr u false)
        2DUP + 1- C@ [CHAR] : =
        IF 1- CodeType -ROT (create) TRUE ELSE FALSE THEN
        ; enqueueNOTFOUND

    : ?label ( obj --) \ показать структуру метки по адресу объекта метки
        CR DUP ." label: " .name @ str# TYPE 
        CR DUP ." seg:   " .seg @ segments::name.
        CR DUP ." adr:   0x" .adr @ .HEX
        CR DUP ." type:  " .type @ typeLabel TYPE
        CR DUP ." cnt:   " .cnt @ .
        CR DUP ." file:  " .file @ str# TYPE
        CR DUP ." line:  " .line @ .
        CR     ." pos:   " .pos @ .
        ;

    : shwLabel ( xt --) \ показать структуру метки по токену метки
        >BODY @ ?label
        ;
    
    : createLabel ( type <name> --) \ создать метку <name>
        BL WORD COUNT (create)
        ;

;MODULE
