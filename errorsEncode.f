REQUIRE toolbox         toolbox.f
REQUIRE chain:          chains.f
REQUIRE err:            errorschain.f
REQUIRE curSrc          filist.f

MODULE: MerrorsEncode
\ накопитель ошибок
\ если все альтернативы дали сбой - выдать весь список
\ если хоть одна сработала - забыть про них
    EXPORT
    \ описание ошибок кодирования
        DECIMAL
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
    DEFINITIONS    

        0 \ структура описания источника ошибок
        CELL -- .file   \ --> в каком файле определена
        CELL -- .line   \ в какой строке
        CELL -- .pos    \ на какой позиции
        256  -- .src    \ буфер строки
        CONSTANT structSrc

        CREATE srcA structSrc ALLOT \ текущий оператор (исходик)
        CREATE srcB structSrc ALLOT \ отложенный оператор (исходик)

        chain: errAsm    \ накопитель ошибок
        
        VARIABLE lastNum
        : extErr ( # #' -- # f)
            DUP lastNum ! OVER  <> 
            ;

        : new? ( #  -- f)
            \ проверить наличие такого номера в списке
            errAsm chCount 0= 
            IF DROP TRUE 
            ELSE errAsm ['] extErr extEach 
            lastNum @ <> 
            THEN
            ;

        : S! ( adr u adr1 -- ) \ записать строку adr u в adr1 как строку со счётчиком
            >R 0xFF AND DUP R@ C! R> 1+ SWAP CMOVE
            ;

        : src! ( adr -- ) \ запомнить источник возможных проблем
            >R
            curSrc   R@ .file !
            CURSTR @ R@ .line !
            >IN    @ R@ .pos  !
            SOURCE   R> .src S!
            ;
    
        : extErrs ( pos #err -- pos TRUE)
            OVER 2- SPACES ." ^-- " err? TYPE CR
            TRUE
            ;
    EXPORT

        : errClean ( --) \ очистить список ошибок
            errAsm chClean
            ;

        : +errAsm ( # --) \ добавить новый код ошибки к списку ошибок
            DUP new?
            IF errAsm +hung ELSE DROP THEN
            ;

        : errQuit ( --) \ выход с ошибкой
            CR ." Ошибка: " srcA >R
            R@ .file @ str# TYPE ." :" R@ .line @ . ." :" R@ .pos @ . CR
            R@ .src COUNT TYPE CR 
            R> .pos @ errAsm ['] extErrs extEach
            QUIT \ THROW
            ;

        : srcSWAP ( --)    
            srcB srcA structSrc CMOVE
            \ захватить текущую строку исходника для отладки
            srcB src! 
            ;
;MODULE

\ примеры использования и тест
[IF_main] \ определено в spf4.ini

301 +errAsm  302 +errAsm  303 +errAsm  303 +errAsm  302 +errAsm 

ALSO MerrorsEncode
srcA src!
CR .( / ) errAsm chPrint .( / <= / 303 302 301 /)
CR .S .( <--пусто?) CR
CR .( ТУТ должно вылезти Ошибка:) 
errQuit \ должен ругаться
[THEN]
