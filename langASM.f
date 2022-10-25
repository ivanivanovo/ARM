\ язык для описания команд ассемблера
\ 
REQUIRE 2CONSTANT       lib/include/double.f
REQUIRE toolbox         toolbox.f
REQUIRE chain:          chains.f
REQUIRE err:            errorschain.f
REQUIRE enqueueNOTFOUND nf-ext.f
REQUIRE alloc           heap.f
REQUIRE >Seg            segments.f
REQUIRE createLabel     labels.f

#def NOT 0= ( x --T|F) \ инверсия результата
    \ усли x=0 - FALSE, иначе TRUE

VOCABULARY ASSEMBLER
ALSO ASSEMBLER DEFINITIONS

chain: encodes \ кончик цепочки енкодов

300 COUNTER: ErrNo
ErrNo err: errEncode S" Не удалось закодировать"
ErrNo err: errNoReg  S" Не регистр"
ErrNo err: errRlo    S" Не младший регистр"
ErrNo err: errRdn    S" Разные регистры"
ErrNo err: errBigOp  S" Слишком большое число в операнде"
ErrNo err: errOddOp  S" Лишнее операнды или их нехватка"
ErrNo err: errImm!2  S" Нечетное число"
ErrNo err: errImm!4  S" Невыровненное число"
ErrNo err: err+Label S" Метка должна быть только вперед"
ErrNo err: errNoSym  S" Неверный символ-аргумент"

\ Condition number
\    cond          Mnemonic  Meaning                         Condition flags
BIN> 0000 CONSTANT   ..EQ    \ EQual                           Z == 1
BIN> 0001 CONSTANT   ..NE    \ Not Qqual                       Z == 0
BIN> 0010 CONSTANT   ..CS    \ Carry Set                       C == 1
BIN> 0010 CONSTANT   ..HS    \ unsigned Higher or Same         C == 1
BIN> 0011 CONSTANT   ..CC    \ Carry Clear                     C == 0
BIN> 0011 CONSTANT   ..LO    \ unsigned LOwer                  C == 0
BIN> 0100 CONSTANT   ..MI    \ MInus, negative                 N == 1
BIN> 0101 CONSTANT   ..PL    \ PLus, positive or zero          N == 0
BIN> 0110 CONSTANT   ..VS    \ oVerflow Set                    V == 1
BIN> 0111 CONSTANT   ..VC    \ oVerflow Clear                  V == 0
BIN> 1000 CONSTANT   ..HI    \ unsigned HIgher                 C == 1 and Z == 0
BIN> 1001 CONSTANT   ..LS    \ unsigned Lower or Same          C == 0 or Z == 1
BIN> 1010 CONSTANT   ..GE    \ signed Greater than or Equal    N == V
BIN> 1011 CONSTANT   ..LT    \ signed Less Than                N != V
BIN> 1100 CONSTANT   ..GT    \ signed Greater Than             Z == 0 and N == V
BIN> 1101 CONSTANT   ..LE    \ signed Less than or Equal       Z == 1 or N != V
BIN> 1110 CONSTANT   ..AL    \ ALways (unconditional) Any


\ Регистр представлен на стеке парой чисел:
\ признак регистра & номер регистра
\ в стековой нотации эта пара обозначается [r,x]
129 CONSTANT itisReg \ признак регистра
: REGISTER: ( n <name> --) \ слово определяющее регистр
    CREATE , itisReg , 
    DOES> 2@ 
    ;
 0 REGISTER: R0     1 REGISTER: R1     2 REGISTER: R2      3 REGISTER: R3
 4 REGISTER: R4     5 REGISTER: R5     6 REGISTER: R6      7 REGISTER: R7
 8 REGISTER: R8     9 REGISTER: R9    10 REGISTER: R10    11 REGISTER: R11
12 REGISTER: R12   13 REGISTER: R13   14 REGISTER: R14    15 REGISTER: R15
                   13 REGISTER: SP    14 REGISTER: LR     15 REGISTER: PC




0 \ структура мнемоники
CELL -- .mAlt \ ->указатель на цепочку вариантов операндов/енкода для ассемблирования
CELL -- .mStr \ ->указатель на мнемонику, строку со счетчиком
CONSTANT structMnem 

0 \ структура операнда
CELL -- .oTag       \ метка операнда
CELL -- .oMask      \ маска операнда    
CELL -- .oXt        \ обработчик операнда
CONSTANT structOp

0 \ структура кодировщика варианта команды
CELL -- .eHlp       \ ->цепочка, помощники команды
CELL -- .eCliche    \ клише команды
CELL -- .eMask      \ маска команды
CELL -- .eXt        \ токен предварительного исполнения
CELL -- .eMnemo     \ адрес структуры мнемоники
CELL -- .eOps       \ ->цепь операндов
CONSTANT structEncode


\ ===================================================================
VARIABLE ASM? \ переменная состояния, TRUE кодирование, FALSE декодирование 
VARIABLE enc \ текущий код команды
VARIABLE lastDepth \ глубина стека перед отсрочкой оператора

MODULE: Masmcoding
\ кодировщик команд
    VARIABLE operator 0 operator ! \ текущий оператор (команда)

        MODULE: MerrorsEncode
        \ накопитель ошибок
        \ если все альтернативы дали сбой - выдать весь список
        \ если хоть одна сработала - забыть про них

                0 \ структура описания источника ошибок
                CELL -- .file   \ --> в каком файле определена
                CELL -- .line   \ в какой строке
                CELL -- .pos    \ на какой позиции
                256  -- .src    \ буфер строки
                CONSTANT structSrc

                CREATE srcA structSrc ALLOT \ текущий оператор (исходик)
                CREATE srcB structSrc ALLOT \ отложенный оператор (исходик)

                chain: errAsm    \ накопитель ошибок
                
                : extErrs ( pos #err -- pos TREUE)
                    OVER 2- SPACES ." ^-- " err? TYPE CR
                    TRUE
                    ;

                : extErr ( # #' -- # #' f)
                    2DUP = NOT 
                    ;

                : new? ( #  -- f)
                    \ проверить наличие такого номера в списке
                    errAsm chCount 0= 
                    IF DROP TRUE 
                    ELSE errAsm ['] extErr extEach = NOT
                    THEN
                    ;

            EXPORT

            : S! ( adr u adr1 -- ) \ записать строку adr u в adr1 как строку со счётчиком
                >R 0xFF AND DUP R@ C! R> 1+ SWAP CMOVE
                ;

            : SOURCE! ( adr -- ) \ запомнить источник возможных проблем
                >R
                curSrc   R@ .file !
                CURSTR @ R@ .line !
                >IN    @ R@ .pos  !
                SOURCE   R> .src S!
                ;
            
            : errClean ( --) \ очистить список ошибок
                errAsm chClean
                ;

            : +errAsm ( # --) \ добавить новый код ошибки к списку ошибок
                DUP new?
                IF errAsm +hung ELSE DROP THEN
                ;

            : errQuit ( --) \ выход с ошибкой
                0 operator ! 
                CR ." Ошибка: " srcA >R
                R@ .file @ str# TYPE ." :" R@ .line @ . ." :" R@ .pos @ . CR
                R@ .src COUNT TYPE CR 
                R> .pos @ errAsm ['] extErrs extEach
                QUIT \ THROW
                ;

            : srcSWAP ( --)    
                srcB srcA structSrc CMOVE
                \ захватить текущую строку исходника для отладки
                srcB SOURCE! 
                ;
        ;MODULE

        \ ============ стек временного хранения стека данных ================
        100 VSTACK T \ V-стек 
        
        : nDROP ( j*x u -- [j-n]*x) \ множественное удаление данных со стека
            >R DEPTH R> MIN
            ?DUP IF 0 DO DROP LOOP THEN
            ;

        : T! DEPTH T >STACK ; \ запомнит стек на всю глубину

        : T@ DEPTH T @ @ MIN nDROP \ очистить стек под восстановление
             T STACK@ DROP \ востановить данные стека
             ;

        : Tdrop T STACK>DROP ; \ убрать запись восстановления 

        : execOp ( j*x obj -- i*x f) \ выполнить обработчики операндов
            >R
                R@ .oMask @ 
                R@ .oXt @ EXECUTE 
            R> DROP
            TRUE
            ; 

        : sacker ( j*x obj --) \ упаковать операнды в код
            DUP .eCliche @ enc !
            .eOps @ ['] execOp extEach
            \ проверить потребление операндов
            DEPTH lastDepth @ - IF errOddOp THROW THEN
            ;

        : overJump ( nexus -- nexus') \ прыжок оператора черз свои параметры
            \ заменить оператор на предыдущий,
            operator @ SWAP operator ! \ а текущий будет ждать своих операндов
            \ заменить исходник на предыдущий,
            srcSWAP 
            ;

        : tryAlts ( j*x nexus -- i*x ) \ цикл перебора альтернативных кодировок
            T! \ сделать снимок стека
            BEGIN T@  \ восстановить стек
             first ['] sacker CATCH ?DUP \ попытка кодирования 
            WHILE +errAsm \ неудача, накопление ошибок
               \ восстановить стек после сбоя
               T@ tail ?DUP \ перейти на альтернативную кодировку, если есть 
            WHILE Tdrop  T! \ сделать новый снимок стека
            REPEAT errQuit  \ уход с ошибкой
            THEN
            Tdrop \ нормальный выход, сброс снимка
            errClean \ очистить список ошибок
            ;
    EXPORT

    : asmcoder ( j*x nexus -- i*x ) 
        \ на стеке лежат операнды предыдущего оператора/команды
        DUP \ не 0
        IF \ предисполнитель
            DUP first .eXt @ ?DUP IF EXECUTE THEN
        THEN
        overJump ?DUP 
        IF  tryAlts \ попытаться закодировать команду
            \ сохранить полученную команду в текущем сегменте
            \ старшее слово (если не 0) пишется первым
            enc @ WORD-SPLIT ?DUP IF W>Seg THEN W>Seg 
        THEN
        DEPTH lastDepth ! \ запомнить текущую глубину стека
        ;

    DEFINITIONS

        : finishEnc ( --) \ обработать последний операнд
            0 asmcoder 
            ; 
    EXPORT

    
    : C[ ( --) \ начать ассемблирование
        ASM? ON \ переключить режим
        ;

    \ NOTFOUND
    \ если слово не найдено И кончается двоеточием,
    \ сделать из него метку (без двоеточия в конце!)
    :NONAME ( adr u -- true| adr u false)
        2DUP + 1- C@ [CHAR] : =
        IF 2>R finishEnc 2R> 
           1- MarkType -ROT  labelCreated TRUE ELSE FALSE THEN
        ; enqueueNOTFOUND

    : ]C ( --) \ закончить ассемблирование
        finishEnc
        ASM? OFF \ переключить режим
        ;    

    : CODE ( <name> -- ) \ начать ассемблирование
        CodeType labelCreate
        C[
        ;

    : C; ( -- ) ]C ; \ закончить ассемблирование

    : discoder ( )
        \ TODO
        ;
;MODULE

\ ***********************************************************************************
MODULE: Mcommands
\ работа с описанием ассемблерных команд
        MODULE: OperandsHandlers
        \ ============ Обработка операндов ==================================

            ASM? ON 

            #def ASM> ASM? @ IF
            #def DIS> EXIT THEN
            #def R<<  R> 1 LSHIFT >R

            : 2RSHIFT ( x1 x2 u -- x1>>u x2>>u) \ сдвинуть вправо пару чисел
                DUP >R RSHIFT SWAP R> RSHIFT SWAP 
                ;

            : disperse ( u mask -- u') \ рассыпать биты числа u по маске
                0 -ROT 1 >R
                BEGIN ( _u _mask) OVER \ пока_u>0
                WHILE DUP \ пока _mask>0 
                    WHILE DUP 1 AND IF -ROT TUCK 1 AND IF R@ + THEN SWAP 1 RSHIFT  ROT THEN 
                          1 RSHIFT  R<<  
                REPEAT
                    errBigOp THROW \ u слишком большое, не помещается в маску
                THEN  2DROP R> DROP
                ;

            : condense ( u' mask -- u) \ собрать число u из u' по битовой маске
                0 -ROT 1 >R
                BEGIN DUP \ пока маска>0
                WHILE DUP 1 AND IF -ROT TUCK 1 AND IF R@ + THEN SWAP R<< ROT THEN
                      1 2RSHIFT   
                REPEAT 2DROP R> DROP
                ;

            : >enc ( x mask --) \ вложить x в текущий код команды
                disperse enc @ OR enc !
                ;  
            : enc> ( mask -- x) \ вытащить число из текущей команды
                enc @ SWAP condense
                ;

            \ ============ Обработка операндов ==================================
            : /2? ( n -- n/2) \ проверка на делимость и деление  
                DUP 1 AND IF errImm!2 THROW ELSE 2/  THEN
                ;

            : /4? ( n -- n/4) \ проверка на делимость и деление
                DUP 3 AND IF errImm!4 THROW ELSE 4 / THEN
                ;

            : itisReg? ( r x -- r x f) \ TRUE - регистр
                DEPTH 1 > 
                IF OVER itisReg = 
                ELSE FALSE THEN
                ;

            : Reg! ( [r,x] mask --) \ запомнить номер регистра в текущей команде
                >R itisReg? IF NIP R> >enc ELSE errNoReg THROW THEN
                ;

            : Reg# ( #Reg -- c-adr u) \ дать строку с цифровым именем регистра
                S>D DEC[ <# #S [CHAR] R HOLD #> ]DEC 
                ;

            : [PC] ( -- PC) \ программный счетчик
                finger 4 + 
                ;

            : sMask ( n mask -- [n]) \ проверть, что n ложится в маску
                \ без потери знака
                2DUP 2/ INVERT \ n !mask/2
                SWAP DUP 0< IF INVERT THEN
                AND IF errBigOp THROW THEN
                AND
                ;

            : [adr] ( adr mask -- ) \ запомнить адрес метки в текущей команде
                >R [PC] - \ adr-PC
                /2? 
                R@ sMask 
                R> >enc
                ;

            : LabelName ( [adr] -- adr u) \ дать строку с именем метки
                DROP ." метка (не доделано)"
                ;

            : RegName ( #Reg -- c-adr u) \ дать строку с именем регистра
                DUP 13 = IF DROP S" SP" ELSE
                DUP 14 = IF DROP S" LR" ELSE
                DUP 15 = IF DROP S" PC" ELSE
                Reg# \ неименованый регистр будет с номером
                THEN THEN THEN
                ;
                
            : <Reg>  \ обработчик регистров
                ASM> ( [r,x] mask -- ) Reg! 
                DIS> ( mask -- c-adr u ) enc> RegName
                ;

            : <Imm> \ простое числовое значение
                ASM> ( x mask --) >enc 
                DIS> ( mask -- x) enc>
                ; 

            : <label> \ метка
                ASM> ( adr mask --) [adr] 
                DIS> ( mask -- c-adr u ) enc> LabelName
                ;

            : maybe_duplex ( {[r,x]} [r,x] -- [r,x]) \ опциональный дубль регистров
                \ если на стеке два регистра, то они должны быть одинаковые
                \ дубль убрать
                2>R itisReg?
                IF 2R@ D= NOT errRdn AND THROW \ проверка убивает дубликат
                THEN \ один регистр
                2R>
                ;
            : need_two ( {[r',x']} [r,x] -- [r',x'] [r,x]) \ нужно два регистра
                \ если на стеке два регистра - ничего не делать
                \ если на стеке один регистр - продублировать его
                2>R itisReg? NOT IF 2R@ THEN 2R>
                ;

            : assert= ( [r,x] [r,x] --) D= NOT errEncode AND THROW 
                ;

            \ ############ Обработчики операндов ###########################

            \ обработчик|-тэг-|--операнд-----|-синоним|
            ' <Reg>     CHAR d 2CONSTANT Rd  
            ' <Reg>     CHAR n 2CONSTANT Rn  
            ' <Reg>     CHAR m 2CONSTANT Rm  
            ' <Reg>     CHAR t 2CONSTANT Rt  
            ' <Imm>     CHAR i 2CONSTANT imm
            ' <label>   CHAR i 2CONSTANT label

            :NONAME ( {[r',x']} [r,x] mask -- [r',x']) >R need_two R> <Reg> ;
                \ в отсутствии Rd ([r',x']), Rn ([r,x]) оставит свой дубликат ([r,x]=[r',x'])
                        CHAR n 2CONSTANT Rnd   
            :NONAME ( {[r,x]} [r,x] mask --) >R maybe_duplex R> <Reg> ; 
                        CHAR d 2CONSTANT Rdn  \ : Rdn, Rdn ;
            :NONAME ( {PC,} mask --) DROP itisReg? IF PC assert= THEN ;
                        CHAR * 2CONSTANT {PC}
            :NONAME (  PC mask --)   DROP PC assert= ;
                        CHAR c 2CONSTANT PC  
            :NONAME ( {SP,} mask --) DROP itisReg? IF SP assert= THEN ;
                        CHAR * 2CONSTANT {SP} 
            :NONAME (  SP mask --)   DROP SP assert= ;
                        CHAR p 2CONSTANT SP  
            :NONAME ( imm!4 mask --) 
                >R /4? R> <Imm> ;
                        CHAR i 2CONSTANT imm!4
            :NONAME ( imm!2 mask --) 
                >R /2? R> <Imm> ;
                        CHAR i 2CONSTANT imm!2

            : <I> ( <c> --) \ проверка символа "i"
                BL WORD COUNT DROP C@ CHAR-UPPERCASE [CHAR] I = NOT IF errNoSym THROW THEN ;
            : i ( --)
                ['] <I> encodes first .eXt ! ;
        ;MODULE

        : replaceBytes ( adr u b1 b2 -- adr u i) \ заменить в строке adr u все байты b1 на b2
            \ i -количество замен
            2>R 2DUP 0 -ROT 2R> 2SWAP 
            OVER + SWAP
            DO OVER I C@ = IF DUP I C! ROT 1+ -ROT THEN
            LOOP 2DROP 
            ;

    EXPORT

    \ NOTFOUND
    \ если слово не найдено И содержит запятые,
    \ попробовать интерпретировать слово как строку без запятых
    :NONAME ( adr u -- true | adr u false) 
        [CHAR] , BL replaceBytes
        IF EVALUATE TRUE ELSE FALSE THEN 
        ; enqueueNOTFOUND

    DEFINITIONS

        S"     " DROP @ CONSTANT 4BL \ 4 пробела как число 

        : Phrase ( <str> -- adr u)  \ выделить из входного потока фразу
            \ фраза: последовательность слов разделенных не более чем 3 пробелами
            SOURCE >IN @ /STRING SWAP >R \ R: адрес начала строки
            0 \ u i
            BEGIN  2DUP = NOT WHILE DUP R@ + @ 4BL = NOT WHILE 1+ REPEAT THEN
            NIP R> SWAP
            ;

        : 4BLparse ( <str> -- adr u) \ изъять из входного потока фразу
            \ фраза: последовательность слов разделенных не более чем 3 пробелами
            Phrase >IN @ OVER + >IN ! \ отрезать фразу
            ;

        : createMnemo ( adr u -- adr_strMnemo)
            2DUP CREATED    
            structMnem alloc
            DUP .mAlt iniChain 
            -ROT str> OVER .mStr ! 
            DUP ,
            DOES> @ .mAlt @ ( nexus) asmcoder
            ;

        : createEncode ( -- adr_strEncode) \ создать структуру кодировщика
            structEncode alloc    \ обнулить поля структуры
            DUP encodes +hung    \ включиться в цепочку кодировщиков (в начало)
            0 OVER .eXt ! \ нету предИсполнителя
            DUP .eHlp  iniChain   \ пустая цепочка   
            DUP .eOps  iniChain   \ пустая цепочка   
            ;
        

            0 \ структура помощника
            CELL -- .hTag  \ метка
            CELL -- .hStr  \ ->строка описания
            CONSTANT structHelper
        
        : createHlp ( tag adr u -- adr_strHlp) \ создать структуру помощника
            str> \ tag c-addr
            structHelper alloc  ( tag c-adr adr_Hlp)  \ обнулить поля структуры
            TUCK .hStr !
            TUCK .hTag !
            ;
    EXPORT

    : Assm: ( <mnemonics> -- 0 ) \ создает или находит структуру 
        \ ассемблерной команды <mnemonics>
        \ возвращает ссылку на неё
        [CHAR] V Phrase -BL createHlp \ hlp запомнить фразу команды в структуре помощника
        BL WORD COUNT    \ hlp adr u - мнемоника во входном буфере
        2DUP UPPERCASE-W \ ВСЕГДА В ВЕРХНЕМ РЕГИСТРЕ
        2DUP GET-CURRENT SEARCH-WORDLIST  
        IF  \  есть такое, 
            NIP NIP
            >BODY  @ \ выдать адрес структуры мнемоники
        ELSE \ нету, создать
            createMnemo
        THEN
        SWAP \ adr_strMnemo hlp 
        createEncode
        \ adr_strMnemo hlp adr_strEncode
        TUCK .eHlp hung+ \ подключить помощника
        \ adr_strMnemo adr_strEncode
        OVER .mStr @ OVER .eMnemo ! 
        SWAP .mAlt @ hung+
        ALSO OperandsHandlers \ подключить обработчики операндов
        0
        ;

    DEFINITIONS

        : tagMask ( adr u tag -- маска) \ из строки adr u вида "0100000101mmmddd"
            \ сделать маску по тэгу(символу)
            \ маска - число у которого биты =1 
            \ в позициях, где тэг/символ встречается в строке
            \      0100000101mmmddd 
            \ d -> 0000000000000111
            \ m -> 0000000000111000
            \ 0 -> 1011111010000000
            \ 1 -> 0100000101000000
            0 2SWAP
            OVER + SWAP
            DO ( tag mask) 2* OVER I C@ = IF 1+ THEN
            LOOP NIP
            ;

        : cliche&mask ( adr u -- mask cliche ) \ из строки adr u вида "0100000101mmmddd"
            \ сделать клише и маску команды
            \ по маске из машинного слова выделяется опознавательный код команды,
            \ а клише служит для сравнения "код=клише"
            2DUP 
            [CHAR] 1 tagMask >R \ R: mask'1'=клише
            [CHAR] 0 tagMask \ mask'0'
            R@ OR R>         \ mask'01' mask'1'
            ;


        : createOp ( xt tag chain --) \ создать структуру оператора
                \ и добавить его в конец цепочки операндов
                structOp alloc \ xt tag chain adr
                DUP ROT hung+ 
                2DUP .oTag ! \ xt tag adr
                SWAP S@ ROT tagMask \ xt adr mask
                OVER .oMask ! \ xt adr
                .oXt ! 
            ;

        : inStr? ( x adr u -- f) \ x есть в строке adr u?
            ROT FALSE 2SWAP OVER + SWAP
            DO ( x f ) OVER I C@ = IF DROP TRUE LEAVE THEN
            LOOP NIP
            ;

        \ ===================================================================
        : +listExcepTag ( adr u -- adr' u') \ добавить к строке тэги исключения
            \ строка adr u не изменяется, изменяется её временная копия
            >S S" cp*" +>S S> ; 

        : fillEncode ( 0 n*[xt,tag] adr2 u2 -- 0) \ дополнить структуру кодировщика команды
            \ по шаблону adr2 u2
            encodes first >R
            >S
                S@ cliche&mask  
                R@ .eCliche !
                R@ .eMask !
                BEGIN ( xt,tag) 
                    DUP S@ +listExcepTag inStr? 
                    \ потребление операндов
                WHILE  
                    R@ .eOps createOp
                REPEAT
            S> 2DROP
            ( 0)
            R> DROP
            ;
    EXPORT

    : Encod: ( 0 n*[xt,tag] "encode" --  ) \ заполняет структуру кодирования 
    \ потребляет операнды и мнемонику со стека
        PREVIOUS \ отключить обработчики операндов
        BL WORD COUNT fillEncode \ дополнить структуру
        \ (0)
        DROP
        ;

    DEFINITIONS
    \ ============== слова помощники/описатели команд ===========================
        : chainHelp+ ( adr -- ) \ добавить Это место к помощникам
            encodes first .eHlp hung+ 
            ;

        : helper: ( tag <name> -- ) \ определить помощника
            CREATE ,
            DOES> @ 4BLparse createHlp chainHelp+ 
            ;
    EXPORT

    CHAR A helper: Action: ( <str> --) \ строка описывающее действие команды
    CHAR F helper: Flags:  ( <str> --) \ -*- флаги на которые влияет команда
    CHAR C helper: Cycles: ( <str> --) \ -*- циклы
    CHAR N helper: Notes:  ( <str> --) \ дополнительные замечания

    DEFINITIONS

        : tag. ( symbol --) \ развернуть тэг
            DUP [CHAR] V = IF ." Variant: " ELSE
            DUP [CHAR] A = IF ." Action : " ELSE
            DUP [CHAR] F = IF ." Flags  : " ELSE
            DUP [CHAR] C = IF ." Cycles : " ELSE
            DUP [CHAR] N = IF ." Notes  : " 
            THEN THEN THEN THEN THEN DROP
            ;

        VARIABLE tabul \ табулятор

        : tab> tabul @ SPACES ;

        : extHlp ( obj -- f)
            DUP .hTag C@ tab> tag.
            .hStr @ str# TYPE CR
            TRUE 
            ;
    EXPORT

    : help. ( nexus -- )
         ['] extHlp extEach 
        ;

    DEFINITIONS

        : extAhlp ( obj -- f)
            .eHlp @  help.
            4 tabul +!
            TRUE
            ;
    EXPORT

    : helpAsm ( <name> --) \ показать справку по команде <name>
        CR BL WORD FIND
        IF  0 tabul !
            >BODY @ ( mnen)
            .mAlt @ ['] extAhlp extEach 
        ELSE DROP
        THEN
        ;

    DEFINITIONS
    \ слова лишние, но помогающие

        : 32bit. ( u -- ) \ печатать 32-битное число в бинарном виде
            8 CELLS BIN[ U.0R ]BIN 
            ;

        : extOps ( obj -- f) \ показать оператор
            tab>   DUP .oTag  ." tag=   " @ EMIT              CR 
            tab>   DUP .oMask ." mask=  " @ 32bit.            CR 
            tab>       .oXt   ." xt=    " @ .HEX              CR 
            TRUE
            ;

        : shwOps ( nexus  --)
            ['] extOps extEach 
            ;

        : shwEncode ( obj --) \ показать структуру кодировщика команды
            \ с отступом 
            tab> ." =======================================" CR 
            DUP .eHlp @ first extHlp DROP             
            tab> ." ---------------------------------------" CR 
            tab> DUP .eCliche ." clishe=" @ 32bit.            CR 
            tab> DUP .eMask   ." mask=  " @ 32bit.            CR 
            tab> DUP .eXt     ." preXt= " @ .HEX              CR
            tab> DUP .eMnemo  ." mnemo= " @ str# TYPE  CR
                 DUP .eOps @ shwOps
            tab> ." ---------------------------------------"  CR 
            .eHlp @ tail help.  CR 
            ;

        : shwMnemo ( xt --) \ показать структуру мнемоники
            >BODY @
            .mStr @ ." mnemo= " str# TYPE CR
            ;

        : extCmd ( obj -- f)
            4 tabul +! shwEncode SWAP TRUE 
            ;
    EXPORT

    : shwCmd ( xt --) \ показать команду полностью
        0 tabul !
        DUP shwMnemo
        >BODY @ .mAlt @  ( nexus)
        ['] extCmd extEach 
        ; \ пример импользования: ' ANDS shwCmd

    #def langASM .( loaded) CR
;MODULE



