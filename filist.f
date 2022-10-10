\ создание списка подключенных файлов
\ работает только в spf4, так как использует его особенности
REQUIRE chain: chains.f \ для списка файлов
REQUIRE str>   heap.f   \ куча

chain: srcFiles \ цепочка имен файлов
S" TERMINAL" str> CONSTANT srcTerminal
S" EVALUATE" str> CONSTANT srcEvaluate

:NONAME  \ расширение действий (INCLUDED)
    \ новое действие:
    SOURCE-NAME      \ получить имя текущего файла
    str>             \ скопировать его в кучу, ссылку
    srcFiles @ +hung \ подвесить в начало цепочки srcFiles
    \ основное действие, как было
    [ ' (INCLUDED) BEHAVIOR ] LITERAL EXECUTE ; TO (INCLUDED)

: curSrc ( -- u-addr) \ выдать адрес строки со счетчиком 
    \ имени текущего файла
    SOURCE-ID  0= IF srcTerminal ELSE
    SOURCE-ID  0< IF srcEvaluate ELSE 
                  srcFiles @ first
                THEN THEN   
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
