REQUIRE VSTACK vstack.f

 32 VSTACK VOCS \ стек словарей
: SAVE-VOCS ( -- )  \ сохранить текущее состояние словарей
    GET-CURRENT GET-ORDER 1+ ( wid-c wid-n ... wid1 n+1 )
    \ >V ; 
     VOCS >STACK ; 
: RESTORE-VOCS ( --) \ востановить предыдущее состояние словарей
   \ V> 
    VOCS STACK> 
    1- SET-ORDER SET-CURRENT ;

