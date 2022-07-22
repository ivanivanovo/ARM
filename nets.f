\ цепочки
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
        \ net-->adr-->0 
        +net \ включить в начало
    THEN
    ;
