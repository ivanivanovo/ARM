\ цепочки
\ связывание элементов в цепочечную структуру
\ имя цепочки (VARIABLE) указывает (содержит адрес) на первый элемент,
\ тот на второй... последний на 0.
\ name-->a-->b-->...-->0
: net: ( <name> --) \ создание новой цепочки
    \ как VARIABLE инициируемой нулем
    >IN @ VARIABLE 
    >IN ! 0 ' EXECUTE !
    ;
\ "net: foo" эквивиалентно "VARIABLE foo 0 foo !"
\ но это позволит при необходимости изменить определение цепочек,
\ не затрагивая код, использующий их.
\ например добавить указатель на последний элемент цепочки,
\ счетчик элементов, поле связи, что позволит делать цепочки из цепочек

: +net ( adr net -- ) \ включить adr в начало цепочки net
    \ net-->b-->a-->0 
    \      [3] [2] [1]
    \ net-->adr-->b-->a-->0 
    \       [4]  [3] [2] [1]
    DUP @ -ROT OVER SWAP ! ! \ net указывает на adr,
    \ а тот - на прежнее значение net
    ;

: net+ ( adr net -- ) \ включить adr в конец цепочки net
    DUP @ 
    IF \ начало уже есть
        \ net-->a-->b-->0 
        \      [1] [2] [3]
        \ net-->a-->b-->adr-->0 
        \      [1] [2] [3]   [4]
        BEGIN DUP @ WHILE @ REPEAT !
    ELSE \ цепочка пуста
        \ net-->0 
        +net \ включить в начало
        \ net-->adr-->0 
    THEN
    ;

: (foreach) ( xt net -- ) \ выполнить xt для всех элементов net
    BEGIN DUP @ WHILE @ 2DUP SWAP EXECUTE REPEAT 2DROP
    ;
: foreach ( xt <net> -- ) \ выполнить xt для всех элементов net
    ' EXECUTE 
    STATE @ IF POSTPONE LITERAL POSTPONE (foreach)
            ELSE (foreach) THEN
    ; IMMEDIATE

