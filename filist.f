REQUIRE chain: chains.f \ для списка файлов
REQUIRE str>   heap.f   \ куча

MODULE: srcList
\ создание списка подключенных файлов
\ работает только в spf4, так как использует его особенности
    chain: srcFiles \ цепочка имен файлов
    S" TERMINAL" str> CONSTANT srcTerminal
    S" EVALUATE" str> CONSTANT srcEvaluate

    : addSRC ( --) \ добавить имя файла в цепочку
        SOURCE-NAME      \ получить имя текущего файла
        str>             \ скопировать его в кучу, ссылку
        srcFiles +hung \ подвесить в начало цепочки srcFiles
        ;

    : extSrc ( obj -- TRUE) 
        str# TYPE CR \ вывести имя
        TRUE \ продолжать до конца цепочки
        ;
EXPORT    
    
    :NONAME  \ расширение действий (INCLUDED)
        \ новое действие:
        addSRC
        \ основное действие, как было
        [ ' (INCLUDED) BEHAVIOR ] LITERAL EXECUTE ; TO (INCLUDED)

    : curSrc ( -- u-addr) \ выдать адрес строки со счетчиком 
        \ имени текущего файла
        SOURCE-ID   0= IF srcTerminal  ELSE
        SOURCE-ID   0< IF srcEvaluate  ELSE 
                          srcFiles chCount 0= 
                          \ если пусто - проинициализировать список
                          IF addSRC  THEN
                          srcFiles first
                    THEN THEN   
        ;

    : lsSrc ( --) \ вывести список файлов
        srcFiles 
        IF srcFiles ['] extSrc extEach
        THEN
        ;
;MODULE

\ примеры использования и тест
[IF_main] \ определено в spf4.ini
    SOURCE-NAME TYPE CR
    curSrc str# TYPE CR
    lsSrc 
[THEN]
