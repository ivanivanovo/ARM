REQUIRE >V vstack.f
[WITHOUT?] BINARY : BINARY  2 BASE ! ; [THEN]
\ ------------------------------------------------------------------------------
: BASE: CREATE , DOES> @ BASE @ 1 >V  BASE ! ; \ определяющее слово
: :BASE CREATE   DOES> DROP V> DROP BASE ! ;   \ определяющее слово
DECIMAL
16 BASE: HEX[ \ временно работаем в шестнадцатеричной системе  
        :BASE ]HEX \ восстановить предыдущую систему
10 BASE: DEC[ \ временно работаем в десятичной системе  
        :BASE ]DEC \ восстановить предыдущую систему
 8 BASE: OCT[ \ временно работаем в восмеричной системе  
        :BASE ]OCT \ восстановить предыдущую систему
 2 BASE: BIN[ \ временно работаем в двоичной системе  
        :BASE ]BIN \ восстановить предыдущую систему
: .BIN  ( n -> ) BIN[ .  ]BIN ; \ вывести число в двоичной форме
: .UBIN ( n -> ) BIN[ U. ]BIN ; \ вывести беззнаковое число в двоичной форме
: .OCT  ( n -> ) OCT[  . ]OCT ; \ вывести число в восьмеричной форме
: .UOCT ( n -> ) OCT[ U. ]OCT ; \ вывести беззнаковое число в восьмеричной форме
: .DEC  ( n -> ) DEC[  . ]DEC ; \ вывести в десятичной форме
: .UDEC ( n -> ) DEC[ U. ]DEC ; \ вывести беззнаковое число в десятичной форме
: .HEX  ( n -> ) HEX[  . ]HEX ; \ вывести число в шестнадцатиричной форме
: .UHEX ( n -> ) HEX[ U. ]HEX ; \ вывести беззнаковое число в шестнадца-ой форме

: asNum ( "str" -- n ) \ преобразовать строку в число
    0 S>D BL WORD COUNT >NUMBER 2DROP D>S ;
: HEX> ( "str" -- n) \ взять число как шестнадцатеричное
    HEX[ asNum ]HEX ; IMMEDIATE 
: 0x [COMPILE] HEX> ; IMMEDIATE 
: 0h [COMPILE] HEX> ; IMMEDIATE  
: BIN> ( "str" -- n) \ взять число как двоичное
    BIN[ asNum ]BIN ; IMMEDIATE 
: OCT> ( "str" -- n) \ взять число как восмеричное
    OCT[ asNum ]OCT ; IMMEDIATE 
: DEC> ( "str" -- n) \ взять число как десятичное
    DEC[ asNum ]DEC ; IMMEDIATE 
