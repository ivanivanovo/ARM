\ язык для описания команд ассемблера
REQUIRE NewChain chain.f
NewChain asmChain
: Assm: ( <mem> --) \ начинает цепочку связанных полей для описания 
    \ ассемблерной команда <mem>  
    BL PARSE ( adr u)
    DUP IF asmChain inject ELSE 2DROP THEN
    ;