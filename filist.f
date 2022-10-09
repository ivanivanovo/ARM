\ создание списка подключенных файлов
\ работает только в spf4, так как использует его особенности

REQUIRE chain: chains.f \ для списка файлов
REQUIRE str>   heap.f   \ куча

chain: srcFiles \ цепочка имен файлов

:NONAME  \ расширение действий (INCLUDED)
    \ новое действие:
    SOURCE-NAME      \ получить имя текущего файла
    str>             \ скопировать его в кучу, ссылку
    srcFiles @ +hung \ подвесить в начало церочки
    \ основное действие, как было
    [ ' (INCLUDED) BEHAVIOR ] LITERAL EXECUTE ; TO (INCLUDED)

: curSrc ( -- c-addr) \ выдать адрес строки со счетчиком 
    \ имени текущего файла
    srcFiles @ first
    ;
    
: (lsSrc) ( obj -- TRUE) 
    str# TYPE CR \ вывести имя
    TRUE \ продолжать до конца церочки
    ;

: lsSrc ( --) \ вывести список файлов
    srcFiles @
    IF srcFiles @ ['] (lsSrc) extEach
    THEN
    ;
