\ описание ошибок
REQUIRE +net nets.f
USER errNet  0 errNet  ! \ кончик цепочки ошибок

0 \ структура статьи ошибки
CELL -- .NextErr \ поле связи 
CELL -- .NumErr  \ номер ошибки
   1 -- .TxtErr  \ строка со счетчиком, описание ошибки
DROP \ размер неопределен

: err: ( n "описание" --)
    CREATE 
    HERE errNet +net , ,
    BL WORD DROP
    [CHAR] " PARSE str! ALIGN
    DOES> .NumErr @ ;

: err? ( n -- c-addr u) \ найти описание ошибки
    >R errNet
    BEGIN @ DUP \ пока не 0
    WHILE DUP .NumErr @ R@ = UNTIL .TxtErr COUNT ELSE
        DROP S" неизвестная ошибка" 
    THEN
    R> DROP
    ;

\EOF пример использования
300 COUNTER: ErrNo
ErrNo err: errEncode S" не удалось закодировать"
ErrNo err: errNoReg  S" Не регистр"
ErrNo err: errRlo    S" Не младший регистр"
...
errRlo err? TYPE