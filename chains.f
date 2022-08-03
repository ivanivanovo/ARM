\ цепочки
MODULE: chains
\ связывание объектов в цепочечку
\ имя цепочки (VARIABLE) указывает (содержит адрес) на первый элемент,
\ тот на второй... последний = NIL.
\ name-->|next|---->|next|---->...-->|NIL |
\        |hook|->a  |hook|->b  ...   |hook|->x
0 
CELL -- .next \ указатель на следующее звено цепочки
CELL -- .hook \ указатель на объект
CONSTANT structNexus

VARIABLE NIL NIL NIL ! \ признак конца цепочки

: noExt ; \ слово пустышка
: counter ( i chain -- i+1 chain) \ счетчик элементов в цепи
    >R 1+ R> ;

EXPORT
: nexus ( -- adr) \ создать звено цепочки
    structNexus ALLOCATE THROW 
    ;

: +tie ( obj chain --)  \ привязать объект obj в начало цепочки chain
    nexus ( o c n )
    OVER @ OVER .next ! \ n.next=[c]
    TUCK SWAP !         \ c=n
    .hook !             \ n.hook=o
    ;

: iniChain ( adr -- ) \ проинициализировать цепочку по адресу
    NIL SWAP !
    ;

: chain: ( <name> --) \ создание новой цепочки с именем <name>
    >IN @ VARIABLE 
    >IN ! ' EXECUTE 
    iniChain 
    ;

: first ( @chain -- obj) \ получить первый объект
    DUP NIL <> IF .hook @ THEN \ объект или NIL
    ;
    
: tail ( @chain -- @chain') \ взять хвост цепочки
    DUP NIL <> IF @ THEN
    ;

: last ( @chain -- @chain-last) \ дать последнее звено
    BEGIN DUP tail DUP NIL <> WHILE NIP REPEAT DROP
    ;
: tie+ ( obj chain --)  \ привязать объект obj в конец цепочки chain
    last +tie
    ;

: print ( @chain --) \ выдать цепочку
    BEGIN DUP NIL <> WHILE DUP first . tail REPEAT DROP
    ;
.( NIL=) NIL .HEX CR
 chain: asd
1 asd +tie
2 asd +tie
3 asd +tie
asd @ tail tail first .
 4 asd tie+
asd @ first .
CR asd @ print
;MODULE HEX QUIT
: extEach ( chain xt -- last ) \ выполнить xt для всех элементов chain
    \ xt (j*x chain-- i*x chain')
    \ xt принимает адрес элемента (chain) и 
    \ может оставить его без изменения,
    \ либо модифицировать, для досрочного завершения
    \ или перехода на другую цепь  
    >R
    BEGIN DUP @ NIL <>  WHILE @ R@ EXECUTE REPEAT 
    R> DROP
    ;

: chain> ( chain -- last) \ последний член --> NIL
    ['] noExt extEach \ пройти по цепочке ничего не делая
    ;

: +chain ( adr chain -- ) \ включить adr в начало цепочки chain
    \ chain-->b-->a-->NIL 
    \      [3] [2] [1]
    \ chain-->adr-->b-->a-->NIL 
    \       [4]  [3] [2] [1]
    DUP @ -ROT OVER SWAP ! ! \ chain указывает на adr,
    \ а тот - на прежнее значение chain
    ;

: chain+ ( adr chain -- ) \ включить adr в конец цепочки chain
    \ chain-->a-->b-->NIL 
    \      [1] [2] [3]
    \ chain-->a-->b-->adr-->NIL 
    \      [1] [2] [3]   [4]
    DUP @ NIL <> IF chain> THEN  \ начало уже есть, дойти до конца
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