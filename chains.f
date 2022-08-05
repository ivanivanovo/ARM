\ цепочки
MODULE: chains
\ связывание объектов в цепочечку
\ имя цепочки (VARIABLE) указывает (содержит адрес) на первый элемент,
\ тот на второй... последний = 0
\ name-->|next|---->|next|---->...-->|0|
\        |hook|->a  |hook|->b  ...   |*|
0 
CELL -- .next \ указатель на следующее звено цепочки
CELL -- .hook \ указатель на объект
CONSTANT structNexus

: newNexus ( -- nexus) \ создать звено цепочки (nexus)
    structNexus ALLOCATE THROW 
    ;

: cpNexus ( nexusA nexusB --) \ копировать nexusA в nexusB
    >R DUP .next @ R@ .next !
    .hook @ R> .hook !
    ;

: exCnt ( i obj -- i+1 f) \ счетчик элементов в цепи
    DROP 1+ TRUE ;
: exPrint ( obj -- f) \ печать объектов
    . TRUE ;

EXPORT

: +tie ( obj nexus1 --)  \ привязать объект obj в начало цепочки, перед nexus1 
    newNexus 2DUP cpNexus ( o x1 x2 ) \ x2=x1
    OVER .next ! ( 0 x1) \ [x1]->x2 
    .hook !
    ;

: iniChain ( adr -- ) \ проинициализировать цепочку по адресу
    newNexus 0 OVER ! ( a x1) \ [x]=0
    SWAP ! \ [a]->x1, указатель на пустую строку
    ;

: chain: ( <name> --) \ создание новой цепочки с именем <name>
    >IN @ VARIABLE 
    >IN ! ' EXECUTE 
    iniChain 
    ;

: first ( nexus -- obj) \ получить первый объект
    DUP .next 0= ABORT" Конец цепочки!"
    .hook @ \ объект
    ;
    
: tail ( nexus -- nexus'|0) \ получить хвост цепочки
    DUP IF .next @ THEN \ следующий или 0
    ;

DEFINITIONS

: last ( nexus -- nexus=0) \ дать последнее звено
    BEGIN DUP tail ?DUP WHILE NIP REPEAT
    ;

EXPORT

: tie+ ( obj nexus --)  \ привязать объект obj в конец цепочки
    last +tie
    ;

: extEach ( nexus xt -- i*x ) \ выполнить xt для всех объектов nexus
    \ xt ( obj -- i*x f )
    \ xt принимает адрес объекта и выдает флаг,
    \ TRUE - продолжить обход
    \ FALSE - завершить обход
    SWAP 2>R
    BEGIN 2R@ NIP .next @ WHILE 2R@ first SWAP EXECUTE WHILE 2R> tail 2>R REPEAT THEN
    2R> 2DROP
    ;

: chCount ( nexus -- u) \ выдать количество элементов в цепочке
    0 SWAP ['] exCnt extEach 
    ;

: chPrint ( nexus --) \ выдать цепочку
    ['] exPrint extEach
    ;

;MODULE 


\EOF пример использования
chain: asd
1 asd @ +tie
2 asd @ +tie
3 asd @ +tie
4 asd @ tie+
CR asd @ chPrint
55 asd @ tie+
66 asd @ +tie
CR asd @ chPrint
CR asd @ chCount DUP . 6 = [IF] .( test OK) [ELSE] .( test FAIL) [THEN] CR
HEX
QUIT