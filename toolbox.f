\ инструментальные слова для удобства
DECIMAL

\ ------------------------------------------------------------------------------
: [FOUND?] ( "слово" -- f) \ узнать есть-ли такое слово, true - слово определено
    BL WORD FIND NIP  ;
: [NOT?] ( "слово" -- f) \ узнать есть-ли такое слово, true - слово НЕ определено
    [FOUND?] 0= ;
: [WITH?] [FOUND?] ['] [IF] EXECUTE ;
: [WITHOUT?] [NOT?] ['] [IF] EXECUTE ;

[WITHOUT?] CELL- : CELL- CELL - ; [THEN]
[WITHOUT?] 2+    : 2+ 2 + ; [THEN]
[WITHOUT?] /STRING    
    : /STRING ( adr u n -- adr' u')
        ROT OVER + -ROT - ; 
[THEN]
[WITHOUT?] WARNING VARIABLE WARNING [THEN]
[WITHOUT?] 2VARIABLE : 2VARIABLE CREATE  2 CELLS ALLOT ; [THEN]
: FindWord ( adr u -- 0 | xt 1| xt -1) \ ищет слово во всех словарях из списка поиска
    2>R \ сохранить имя
    GET-ORDER \ получить список словарей
    BEGIN DUP \ пробег по словарям
        WHILE \ пока есть словари
        1- SWAP 2R@ ROT SEARCH-WORDLIST ?DUP 
    UNTIL \ пока не найдёт
    \ найдено
    2>R \ сохранить результат
    0 ?DO DROP LOOP \ удалить остаток списка
    2R> \ восстановить результат 
        THEN \ словари кончились, поиск не удался
    2R> 2DROP \ удалить имя
    ;
VARIABLE CurVoc
: FindVoc ( adr u -- 0 | wid) \ ищет слово во всех словарях, возвращает id словаря
    2>R \ сохранить имя
    GET-ORDER  \ получить список словарей
    BEGIN DUP \ пробег по словарям
        WHILE \ пока есть словари
        1- SWAP 2R@ ROT \ подготовиться к поиску
            DUP CurVoc ! \ запомнить id где ищем
            SEARCH-WORDLIST \ ищем
            DUP IF TRUE ELSE  0 CurVoc ! THEN \ не нашли - забываем
    UNTIL \ пока не найдёт
    \ найдено
    2DROP \ удалить результат
    0 ?DO DROP LOOP \ удалить остаток списка
        THEN \ словари кончились, поиск не удался
    2R> 2DROP \ удалить имя
    CurVoc @
    ;
[WITH?] VOC-NAME.
: FindVoc. ( adr u -- ) \ найти слово и напечатать имя словаря, где найдено
    FindVoc ?DUP IF VOC-NAME. ELSE ." Не найдено." THEN
    ;
[THEN]
\ ------------------------------------------------------------------------------
\ V-stack
REQUIRE NEW>S sstack.f \ S-stack 
\ ------------------------------------------------------------------------------
\ Vocs-stack
\ ------------------------------------------------------------------------------
\ bases
REQUIRE HEX[ bases.f
\ ------------------------------------------------------------------------------

[WITHOUT?] OFF 
: OFF ( adr -- ) \ выключить переменную
    FALSE SWAP ! ; 
: ON  ( adr -- ) \ включить переменную   
    TRUE  SWAP ! ; 
[THEN]


[WITHOUT?] W! 
HEX[
: W! ( cc addr -- ) \ записать два байта как число
    OVER 0FF AND OVER C! 
    SWAP 0FF00 AND 8 RSHIFT SWAP 1+ C!  
    ;
]HEX
[THEN]    

[WITHOUT?] W@ 
HEX[
: W@ ( addr -- cc) \ взять два байта как число
    @ 0FFFF AND 
    ;
]HEX
[THEN]    
: W@+ ( adr -- adr+2 w) \ w@ с постинкрементом указателя 
    DUP 2+ SWAP W@ 
    ;
: C@+ ( adr -- adr+1 c) \ чтение символа с постинкрементом адреса
    DUP 1+ SWAP C@ 
    ;
: ,R ( n1 u2 -- adr u)
    NEW>S
    OVER 0< DUP >R IF SWAP NEGATE SWAP  THEN
    SWAP S>D <# #S #> 
    ROT OVER SWAP - \ adr u u-u2
    DUP 0< IF ABS R@ IF 1- THEN 0 DO BL EMIT>S LOOP ELSE DROP THEN
    R> IF [CHAR] - EMIT>S THEN
    +>S S> 
    ;


: [U,0R] ( u1 u2 -- adr u)
    \ преобразует число u1 в строку, с ведущими нулями в поле размером НЕ более u2
    SWAP 0 ROT 
    <# 0 DO # LOOP #> ;
: [U.0R] ( u1 u2 --) 
    \ печатать число u1 с ведущими нулями в поле размером НЕ более u2
    [U,0R] TYPE
    ;

: U,0R ( u1 u2 -- addr u ) 
    \ преобразует число u1 в строку, с ведущими нулями в поле размером u2
    >R 0 <# #S #> \ adr u R:u2
    R> OVER - \ adr u u2-u
    DUP 0 > IF NEW>S 0 DO [CHAR] 0 EMIT>S LOOP +>S S>  ELSE DROP THEN
    ;
: U.0R ( u1 u2 -- ) 
    \ печатать число u1 с ведущими нулями в поле размером u2
    U,0R TYPE
    ;
: ,0R ( n1 u2 -- adr u)
    \ преобразует число n1 в строку, с ведущими нулями в поле размером u2
    NEW>S
    OVER 0< DUP >R IF SWAP NEGATE SWAP R@ IF [CHAR] - EMIT>S THEN THEN
    SWAP S>D <# #S #> 
    ROT OVER SWAP - \ adr u u-u2
    DUP 0< IF ABS R@ IF 1- THEN 0 DO [CHAR] 0 EMIT>S LOOP ELSE DROP THEN
    R> DROP
    +>S S> 
    ;
: .0R ( n1 u2 --) 
    \ печатать число n1 с ведущими нулями в поле размером u2
    ,0R TYPE
    ;  
: ,L ( n u -- adr u) \ преобразовать число n строку размером u или больше
    SWAP 1 ,R >S
    S@ NIP - DUP 0< 0= IF 0 DO BL EMIT>S LOOP ELSE DROP THEN
    S>
    ;
: .L ( n u --) \ напечатать число n в поле шириной u, левое выравниваие 
    ,L TYPE ;

[WITHOUT?] .R 
: .R ( n1 u2 --) \ форматный ввывод числа n1, вправо в поле с u2 позициями)
    ,R TYPE ;
[THEN]
\ [WITHOUT?] VECT 
\ Простейшая реализация векторизаци кода
\ : VECT ( "name"--) CREATE 0 , DOES> @ EXECUTE ;
\ : VECT> ( xt --)    BL WORD FIND IF >BODY ! THEN ;    
\ [ELSE] : VECT> ( xt --) [COMPILE] TO ;    
\ [THEN]    

[WITHOUT?] DEFER  \ реализация из стандарта 200х
: DEFER ( "name" -- )
    CREATE ['] ABORT ,
    DOES>   @  EXECUTE ;
: DEFER! ( xt2 xt1 -- )
     >BODY ! ;
: DEFER@ ( xt1 -- xt2 )
     >BODY @ ;
: IS ( xt " <spaces> name" -- )
    STATE @ 
    IF POSTPONE ['] POSTPONE DEFER!
    ELSE  ' DEFER!
    THEN ; IMMEDIATE
[THEN]


: #bits ( n --i) \ подсчитать число значащих бит в числе
    2* 0  
    BEGIN \ n i
        SWAP 1 RSHIFT ?DUP WHILE SWAP 1+ 
    REPEAT
    ;
 
: EMIT_ASCII ( n -- ) \ напечатать n как символ ASCII
    DUP BL < IF DROP ." ."
             ELSE DUP 127 < 
                IF EMIT ELSE DROP ." ?" THEN
             THEN
    ;
: TYPE_ASCII ( adr u --) \ распечатать байты как ASCII символы
    OVER + SWAP
    DO  I C@ EMIT_ASCII LOOP
    ;

HEX[
: WORD-SPLIT ( n -- lo hi) \ разбить на слова (2байта)
    DUP 0FFFF AND SWAP 0FFFF0000 AND  10 RSHIFT ;
: (LW) WORD-SPLIT DROP ;    \ выделить младшее слово
: (HW) WORD-SPLIT NIP ;     \ выделить старшее слово

: BYTE-SPLIT ( n -- lo hi)  \ разбить на байты
    DUP 0FF AND SWAP 0FF00 AND  8 RSHIFT ;
: (LB) BYTE-SPLIT DROP ;    \ выделить младший байт
: (HB) BYTE-SPLIT NIP ;     \ выделить старший байт

: UTF? ( w -- f) \ истина если двухбайтное число похоже на UTF
    0C0C0 AND 080C0 = ;
: SYMBOLS ( adr u - u1) \ число символов в строке
    \ подсчёт именно СИМВОЛОВ, а не байт
    DUP -ROT
    OVER + SWAP
    ?DO I C@  7F > \ если не ASCII
        IF I W@ UTF? \ если UTF
           -1 AND + \ уменьшить счётчик символов 
        THEN 
    LOOP
    ; 
]HEX
: UTF8-CASEv ( -- adr u ) \ русские символы нижнего регистра
    S" йцукенгшщзхъфывапролджэячсмитьбюё" ;
: UTF8-CASE^ ( -- adr u ) \ РУССКИЕ СИМВОЛЫ ВЕРХНЕГО РЕГИСТРА
    S" ЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮЁ" ;

S" ~iva/AVR/KOI8-R.f" INCLUDED
\ S" ~iva/AVR/WIN1251.f" INCLUDED
\ S" ~iva/AVR/CP866.f" INCLUDED

WARNING @ WARNING OFF
: CHAR-UPPERCASE ( c -- c1 ) 
\ подмена однобайтного символа версией верхнего регистра
  \ для правильной работы с символами не ASCII
  \ требуется подключить файл нужной кодировки
  DUP [CHAR] a [CHAR] z 1+ WITHIN IF 32 - EXIT THEN
  STR-CASEv 0
  ?DO 
    2DUP I + C@ = 
        IF 2DROP STR-CASE^ DROP I + C@ UNLOOP EXIT  THEN
  LOOP  DROP
;

: UPPERCASE ( addr1 u1 -- ) \ перевести все символы строки addr1 u1 в верхний регистр
  \ строка меняется "на месте"
  \ работает с однобайтными символами
  OVER + SWAP ?DO
    I C@ CHAR-UPPERCASE I C!
  LOOP ;

WARNING !

: CASE^ ( adr u --) \ перевести строку в верхний регистр
    UPPERCASE \ НЕ работает с русскими в UTF8
    ;
: WCHAR-UPPERCASE ( wc -- wc1 ) 
\ подмена двухбайтного символа версией верхнего регистра
    UTF8-CASEv 0
    DO 2DUP I + W@ =
        IF 2DROP UTF8-CASE^ DROP I + W@ UNLOOP EXIT  THEN
    LOOP DROP   
    ;

: UPPERCASE-W ( addr1 u1 -- ) \ работает с однобайтными и 2х-байтными символами
    OVER + SWAP
    ?DO I W@ UTF? \ если UTF 
        IF   I W@ WCHAR-UPPERCASE I W!
        ELSE I C@  CHAR-UPPERCASE I C!
        THEN
    LOOP    
;   
\ S" ЖерБёнок-Funt" 2dup UPPERCASE-W type cr

: BETH ( n a b -- f) \ true если a<=n<=b или b<=n<=a
    2DUP MIN -ROT MAX
    >R OVER > SWAP R> > OR 0= ; 

[WITHOUT?] ASCIIZ>  
: ASCIIZ> ( c-adr -- adr u) \ преобразовать представление строки с нулём на 
                          \ конце, в нормальное
        DUP BEGIN DUP C@ WHILE 1+ REPEAT OVER - ;
[THEN]
: ASCIIZ>> ( c-adr u -- adr1) \ c-adr начальный адрес строки с кучей нулей на конце,
    \  adr1 -первый выровненный адрес с ненулевым содержанием
    + ALIGNED \ выровненный адрес после строки с нулём
    BEGIN DUP @ 0= WHILE CELL+ REPEAT 
    ;
: 3DUP ( a b c -- a b c a b c )
    >R 2DUP R@ -ROT R> ;
: COUNTER: ( n "name" -- ) \ создать счетчик с именем name и начальным значением n
\ при каждом вызове этого слова выдается новое значение на 1 больше предыдущего
    CREATE , DOES> DUP @ SWAP 1+!  ;

WARNING @ WARNING OFF
: str! ( adr u --) \ поместить строку, как строку со счётчиком по HERE
    -TRAILING \ обрезать хвостовые пробелы
    HERE >R  
    DUP 1+ ALLOT \ a u  
    DUP R@ C! \ a u
    R> 1+ SWAP  CMOVE 
    ;
WARNING !


: #def ( <name строка.... > -- ) \ запомнить строку под именем name
    \ при исполненни name - выполнить строку  
    CREATE  \ выделяем name, создаём статью
        10 PARSE str!   \ выделяем и сохраняем остаток строки 
        ALIGN
        IMMEDIATE       \ новое слово будет немедленным
    DOES> COUNT  EVALUATE  ; \ прочитать строку и выполнить

: see#def ( <name_def> -- ) \ показать определение #def
    ' >BODY COUNT TYPE ;
\ Примеры:
\ #def +C5.  C5 + . \ макрос с еще неопределенным макросом (C5) внутри
\ #def C5 2 3 +     \ определение простого макроса C5
\ #def основа 10    \ значение зависит от системы счисления на момент выполнения

\ #def naa : aa ." AA" cr ; \ определение слова в макросе


: MACROS ( adr u <name> --) \ запомнить строку под именем name
    \ при исполненни name - выполнить строку
    CREATE HERE OVER DUP 1+ ALLOT ALIGN \ резервируем место под строку со счётчиком
        OVER C!         \ запомним u
        1+ SWAP CMOVE   \ сохраним строку
        IMMEDIATE       \ новое слово будет немедленным
    DOES> COUNT EVALUATE ; \ прочитать строку и выполнить

\ S" 4 3 + . " MACROS M7. \ без параметров
\ M7.  cr
\ S" + . CR " MACROS сложить   \ с параметрами 
\ 4 6 сложить


: (DUMP) ( adr u -- ) \ распечатать дамп в заданых границах 
    \ с выровненными адресами
    ?DUP IF
        HEX[
            OVER + SWAP \ отображаемые адреса
            2DUP 
            -16 AND
            DO
                I 255 AND 0= IF CR THEN
                I 15  AND 0= IF CR I . SPACE THEN
                I 3   AND 0= IF ."  " THEN
                2DUP I -ROT BETH
                IF I C@ 2 .0R SPACE ELSE ." -- " THEN
            LOOP 2DROP
        ]HEX
    ELSE DROP ." Пусто." 
    THEN CR
    ;

[NOT?] sh
[IF]
: sh ( "cmd" -- ) \ выполнить команду оболочки
    10 PARSE OVER + 0 SWAP C! 1 <( )) system THROW     ; 
[THEN]

[NOT?] mkdir
[IF]
: mkdir ( "dir" --)
    10 PARSE OVER + 0 SWAP C! 1 <( 511 )) mkdir THROW ; \ 511 = 0777
[THEN]

#def toolbox .( loaded) CR
