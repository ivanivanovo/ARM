\ цепочки
MODULE: chains
    \ связывание объектов в цепочку
    \ имя цепочки указывает (содержит адрес) на первый элемент,
    \ тот на второй... последний = 0
    \ name --v первый nexus
    \        |next|---->|next|---->...-->| 0  |
    \        |hook|->a  |hook|->b  ...   |hook|->c
    0 
    CELL -- .next \ указатель на следующее звено цепочки
    CELL -- .hook \ указатель на объект 
                  \ или крюк на который насаживается объект
    CONSTANT structNexus

    : newNexus ( -- nexus) \ создать звено цепочки (nexus)
        structNexus ALLOCATE THROW 
        0 OVER .next ! \ =0
        0 OVER .hook ! \ =0
        ;
EXPORT

    : first ( nexus -- obj) \ получить первый объект
        .hook @ \ объект
        ;
        
    : tail ( nexus -- nexus'|0) \ получить хвост цепочки
        .next @ \ следующий или 0
        ;

DEFINITIONS

    : cpNexus ( nexusA nexusB --) \ копировать nexusA в nexusB
        >R DUP tail  R@ .next !
               first @ R> .hook !
        ;

    : exCnt ( i obj -- i+1 f) \ счетчик элементов в цепи
        DROP 1+ TRUE ;
    : exPrint ( obj -- f) \ печать объектов
        . TRUE ;

EXPORT
    : +hung ( obj nexus --)  \ подвесить объект obj перед этим местом цепочки
        \ либо на пустой крюк этого места
        DUP first 
        IF newNexus 2DUP cpNexus ( o x1 x2 ) \ x2=x1
           OVER .next ! ( 0 x1) \ [x1]->x2 
        THEN
        .hook !
        ;

    : hung ( obj nexus --) \ подвесить объект obj после этого места цепочки     
        \ либо на пустой крюк этого места
        DUP first
        IF newNexus >R \ o x R:x'
           DUP tail R@ .next ! \ o x R:x'
           R@ SWAP .next ! R> \ x'
        THEN
        .hook !
        ;
    
    : delnexus ( nexus --) \ удалить звено из цепочки и освободить память
        \ кроме последнего
        DUP tail 
        IF DUP tail DUP ROT cpNexus 
           FREE THROW 
        ELSE DROP THEN
        ;

    : iniChain ( adr -- ) \ проинициализировать цепочку по адресу
        newNexus SWAP ! \ [a]->x1 
        ;

    : chain: ( <name> --) \ создание новой цепочки с именем <name>
        CREATE HERE iniChain CELL ALLOT
        DOES> @
        ;

DEFINITIONS

    : last ( nexus -- nexus=0) \ дать последнее звено
        BEGIN DUP tail ?DUP WHILE NIP REPEAT
        ;

EXPORT

    : hung+ ( obj nexus --)  \ подвесить объект obj в конце цепочки
        last hung
        ;

    : extEach ( nexus xt -- i*x ) \ выполнить xt для всех объектов nexus
        \ xt ( obj -- i*x f )
        \ xt принимает адрес объекта и выдает флаг,
        \ TRUE - продолжить обход
        \ FALSE - завершить обход
        SWAP 2>R
        BEGIN 2R@ NIP first WHILE 2R@ first SWAP EXECUTE WHILE 2R@ NIP tail WHILE 2R> tail 2>R REPEAT THEN THEN
        2R> 2DROP
        ;

    : chCount ( nexus -- u) \ выдать количество элементов в цепочке
        0 SWAP ['] exCnt extEach 
        ;

    : chPrint ( nexus --) \ выдать цепочку
        ['] exPrint extEach
        ;

;MODULE 


\EOF пример использования и тесты
chain: asd
3 asd  +hung
4 asd  hung+
2 asd  +hung
5 asd  hung+
6 asd hung+
1 asd +hung
CR asd chPrint
ALSO chains CR \ EOF
34 asd tail tail hung
CR asd chPrint
asd tail tail tail delnexus
CR asd chPrint
CR asd chCount DUP . 6 = [IF] .( test OK) [ELSE] .( test FAIL) [THEN] CR
HEX
QUIT