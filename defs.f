\ создание макросов

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