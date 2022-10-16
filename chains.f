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
    CELL -- .used \ признак использования крюка, TRUE или FALSE
    \ введение отдельного признака использования крюка 
    \ позволяетт помещать в цепочку не только адреса объектов,
    \ но и любый числа, включая 0
    CONSTANT structNexus

    : newNexus ( -- nexus) \ создать звено цепочки (nexus)
        structNexus ALLOCATE THROW 
        0     OVER .next ! \ =0
        0     OVER .hook ! \ =0
        FALSE OVER .used ! \ =крюк пустой
        ;
EXPORT

    : first ( nexus -- obj) \ получить первый объект
        .hook @ \ объект
        ;
        
    : tail ( nexus -- nexus'|0) \ получить хвост цепочки
        .next @ \ следующий или 0
        ;

DEFINITIONS

    : used? ( nexus -- f) \ флаг использования крюка
        .used @ 
        ;

    : cpNexus ( nexusA nexusB --) \ копировать nexusA в nexusB
        >R DUP tail  R@ .next !
           DUP first R@ .hook !
               used? R> .used !
        ;

    : exCnt ( i obj -- i+1 f) \ счетчик элементов в цепи
        DROP 1+ TRUE ;
    : exPrint ( obj -- f) \ печать объектов
        . TRUE ;

EXPORT
    : onHook ( obj nexus --) \ подвесить объект obj на hook
        TUCK .hook !
        TRUE SWAP .used !
        ;

    : +hung ( obj nexus --)  \ подвесить объект obj перед этим местом цепочки
        \ либо на пустой крюк этого места
        DUP used? 
        IF newNexus 2DUP cpNexus ( o x1 x2 ) \ x2=x1
           OVER .next ! ( 0 x1) \ [x1]->x2 
        THEN
        onHook
        ;

    : hung ( obj nexus --) \ подвесить объект obj после этого места цепочки     
        \ либо на пустой крюк этого места
        DUP used?
        IF newNexus >R \ o x R:x'
           DUP tail R@ .next ! \ o x R:x'
           R@ SWAP .next ! R> \ x'
        THEN
        onHook
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

    : extEach ( j*x nexus xt -- i*x ) \ выполнить xt для всех объектов nexus
        \ xt ( obj -- i*x f )
        \ xt принимает адрес объекта и выдает флаг,
        \ TRUE - продолжить обход
        \ FALSE - завершить обход
        \ 
        \ цикл выполняется пока:
        \     есть объект на крючке
        \ И   xt возвращает TRUE
        \ И   цепочка не закончилась
        \ 
        \ циклу нужно убирать свои параметры со стека данных,
        \ чтоб не мешать xt использовать стек по своему усмотрению
        SWAP 2>R \ R:xt nx      
        BEGIN 2R@ DUP used? 
            IF    first SWAP EXECUTE ELSE NIP THEN 
            WHILE 2R> tail TUCK 2>R \ на следующий
        WHILE REPEAT THEN
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
34 asd tail tail hung
CR asd chPrint
asd tail tail tail delnexus
CR asd chPrint
0 asd +hung
CR asd chPrint
CR asd chCount DUP . 7 = [IF] .( test OK) [ELSE] .( test FAIL) [THEN] CR
HEX
\ QUIT