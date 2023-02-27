\ коммент
\ hex
\ ' AdcS shwCmd
\ CR
\ ' adds shwCmd 
\ bin[ 101 10111000 disperse . ]bin CR CR
\ bin[ 101 10111000 TUCK disperse SWAP CONDENse . ]bin CR

\ asm? on SP bin> 10111000 <reg> enc @ .bin CR
\ asm? off bin> 10111000 <reg> type CR

\ EOF \ локальные отладочные тесты
REQUIRE SAVEhex     Mihex.f

0xFF 0x08000000 0 createSeg: ROM-SEG
ROM-SEG TO SEG

: delArg BL WORD DROP ; \  сожрать аргумент
\ .syntax unified
: .syntax delArg ;
\ .cpu cortex-m0
: .cpu delArg ; \ cortex-m0
\ .fpu softvfp
: .fpu delArg ; \ softvfp
: .thumb ; \
: .text  ROM-SEG TO SEG ;
\ .global tst
: .global delArg ; \ tst

#def nop  mov r8,r8 \ чтоб совпадал с arm-none-eabi-as
' DMB shwCmd

C[ test-af.s ]C

SAVEhex test-af.hex
\ dbg ON
\ hex
\ errChain chPrint
\ errList.
\ dbg on
\ CR errRlo err? TYPE