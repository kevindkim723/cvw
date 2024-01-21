#!/bin/sh

setQ_OFF() {
sed -i "33s/Q_SUPPORTED.*/Q_SUPPORTED = 0;/" $WALLY/config/shared/config-shared.vh
}
setQ_ON() {
sed -i "33s/Q_SUPPORTED.*/Q_SUPPORTED = 1;/" $WALLY/config/shared/config-shared.vh
}

setD_ON() {
sed -i "28s/D_SUPPORTED.*/D_SUPPORTED = 1;/" $WALLY/config/shared/config-shared.vh
}
setD_OFF() {
sed -i "28s/D_SUPPORTED.*/D_SUPPORTED = 0;/" $WALLY/config/shared/config-shared.vh
}

setR1(){
sed -i "164s/localparam.*/localparam RADIX = 32\'h2;/" $WALLY/config/rv64gc/config.vh
}
setR2(){

sed -i "164s/localparam.*/localparam RADIX = 32\'h4;/" $WALLY/config/rv64gc/config.vh
}

setK1(){

sed -i "165s/localparam.*/localparam DIVCOPIES = 32\'h1;/" $WALLY/config/rv64gc/config.vh
}
setK2(){

sed -i "165s/localparam.*/localparam DIVCOPIES = 32\'h2;/" $WALLY/config/rv64gc/config.vh
}
setK4(){

sed -i "165s/localparam.*/localparam DIVCOPIES = 32\'h4;/" $WALLY/config/rv64gc/config.vh
}


gen(){
    mkdir $WALLY/testbench/runs
    cd ../sim
    setQ_ON
    setD_ON
    setK1

    #k=1,r=1
    setR1
    ./sim-testfloat-batch div > $WALLY/testbench/runs/k_1_r_1Q.out

    #k=1,r=2
    setR2

    ./sim-testfloat-batch div > $WALLY/testbench/runs/k_1_r_2Q.out
    setK2

    #k=2, r=1
    setR1

    ./sim-testfloat-batch div > $WALLY/testbench/runs/k_2_r_1Q.out

    #k=2,r=2
    setR2

    ./sim-testfloat-batch div > $WALLY/testbench/runs/k_2_r_2Q.out
    setK4

    #k=4,r=1
    setR1
    
    ./sim-testfloat-batch div > $WALLY/testbench/runs/k_4_r_1Q.out
    #k=4,r=2
    setR2
    ./sim-testfloat-batch div > $WALLY/testbench/runs/k_4_r_2Q.out


    setQ_OFF
    setD_ON
    setK1

    #k=1,r=1
    setR1
    ./sim-testfloat-batch div > $WALLY/testbench/runs/k_1_r_1D.out

    #k=1,r=2
    setR2
    ./sim-testfloat-batch div > $WALLY/testbench/runs/k_1_r_2D.out

    setK2

    #k=2, r=1
    setR1
    ./sim-testfloat-batch div > $WALLY/testbench/runs/k_2_r_1D.out

    #k=2,r=2
    setR2
    ./sim-testfloat-batch div > $WALLY/testbench/runs/k_2_r_2D.out

    setK4

    #k=4,r=1
    setR1
    ./sim-testfloat-batch div > $WALLY/testbench/runs/k_4_r_1D.out
    
    #k=4,r=2
    setR2
    ./sim-testfloat-batch div > $WALLY/testbench/runs/k_4_r_2D.out
}


gen2(){
    mkdir $WALLY/testbench/runs
    cd ../sim
    setQ_OFF
    setD_OFF
    setK1

    #k=1,r=1
    setR1
    ./sim-testfloat-batch div > $WALLY/testbench/runs/k_1_r_1F.out

    #k=1,r=2
    setR2

    ./sim-testfloat-batch div > $WALLY/testbench/runs/k_1_r_2F.out
    setK2

    #k=2, r=1
    setR1

    ./sim-testfloat-batch div > $WALLY/testbench/runs/k_2_r_1F.out

    #k=2,r=2
    setR2

    ./sim-testfloat-batch div > $WALLY/testbench/runs/k_2_r_2F.out
    setK4

    #k=4,r=1
    setR1
    
    ./sim-testfloat-batch div > $WALLY/testbench/runs/k_4_r_1F.out
    #k=4,r=2
    setR2
    ./sim-testfloat-batch div > $WALLY/testbench/runs/k_4_r_2F.out


}
edge(){
    setQ_OFF
    setD_ON
    setK2
    setR2
    cd ../sim
    ./sim-testfloat-batch div > $WALLY/testbench/runs/k_2_r_2D.out
}

