\ слова для обращения к командам оболочки
REQUIRE [NOT?] toolbox.f

[NOT?] sh
[IF]
: sh ( "cmd" -- ) \ выполнить команду оболочки
    10 PARSE OVER + 0 SWAP C! 1 <( )) system THROW     ; 
[THEN]

\ пример:
\ sh pwd
\ sh locate spf4

[NOT?] mkdir
[IF]
: mkdir ( "dir" --)
    10 PARSE OVER + 0 SWAP C! 1 <( 511 )) mkdir THROW ; \ 511 = 0777
[THEN]
