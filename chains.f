\ цепочки
MODULE: chainsStruct
\ связывание элементов в цепочечную структуру
\ имя цепочки (VARIABLE) указывает (содержит адрес) на первый элемент,
\ тот на второй... последний на 0.
\ name-->a-->b-->...-->stoper
VARIABLE stoper stoper stoper ! \ признак конца цепочки
\ .( stoper )stoper .HEX CR
: noExt ; \ слово пустышка
: counter ( i chain -- i+1 chain) \ счетчик элементов в цепи
    >R 1+ R> ;

EXPORT

: iniChain ( adr -- ) \ проинициализировать цепочку по адресу
    stoper SWAP ! 
    ;

: chain: ( <name> --) \ создание новой цепочки
    \ как VARIABLE инициируемой стоп-словом
    >IN @ VARIABLE 
    >IN ! ' EXECUTE iniChain
    ;

: extEach ( chain xt -- last ) \ выполнить xt для всех элементов chain
    \ xt (j*x chain-- i*x chain')
    \ xt принимает адрес элемента (chain) и 
    \ может оставить его без изменения,
    \ либо модифицировать, для досрочного завершения
    \ или перехода на другую цепь  
    >R
    BEGIN DUP @ stoper <>  WHILE @ R@ EXECUTE REPEAT 
    R> DROP
    ;

: chain> ( chain -- last) \ последний член --> stoper
    ['] noExt extEach \ пройти по цепочке ничего не делая
    ;

: +chain ( adr chain -- ) \ включить adr в начало цепочки chain
    \ chain-->b-->a-->stoper 
    \      [3] [2] [1]
    \ chain-->adr-->b-->a-->stoper 
    \       [4]  [3] [2] [1]
    DUP @ -ROT OVER SWAP ! ! \ chain указывает на adr,
    \ а тот - на прежнее значение chain
    ;

: chain+ ( adr chain -- ) \ включить adr в конец цепочки chain
    \ chain-->a-->b-->stoper 
    \      [1] [2] [3]
    \ chain-->a-->b-->adr-->stoper 
    \      [1] [2] [3]   [4]
    DUP @ stoper <> IF chain> THEN  \ начало уже есть, дойти до конца
    +chain
    ;

: chainCount ( chain -- u) \ выдать количество элементов в цепочке
    0 SWAP ['] counter extEach DROP
    ;

;MODULE

\EOF пример использования
chain: tstchain
here tstchain chain+
cell allot
here tstchain +chain
cell allot
here tstchain chain+
cell allot
tstchain chainCount . CR ( -- 3)
QUIT