
//--------------------------------------

//Project: ASCON_Core

//--------------------------------------

//--------------------------------------

//HOW TO CHOOSE A TESTCASE AND RUN with MODELSIM 

//--------------------------------------

Step 1: Create new project in MODELSIM

Step 2: choose tb.sv file

Step 3: from 90th line -> 106th line, comment and uncomment test case to run sim

===========================================================================
    TESTCASE                    =   associated expected VALUE MODEL file   
===========================================================================                                         
./MULTI_MODE/mul_mode.sv        =   multi_mode_model.sv
--------------------------------------------=------------------------------
./ENC_HASH_CASE/mul_mode.sv     =   enc_hash_model.sv
---------------------------------------------------------------------------
./DEC_HASH_CASE/mul_mode.sv     =   dec_hash_model.sv 
===========================================================================                                         

Step 4: type command "do run.do" in MODELSIM Transcript window

  
