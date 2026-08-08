vlib work
vlog RAM.v spi_slave.v spi_wrapper.v MASTER_tb.v
vsim -voptargs=+acc work.MASTER
add wave *
add wave -position insertpoint  \
sim:/MASTER/DUT/SPI_SLAVE/tx_valid \
sim:/MASTER/DUT/SPI_SLAVE/tx_data \
sim:/MASTER/DUT/SPI_SLAVE/rx_data \
sim:/MASTER/DUT/SPI_SLAVE/rx_valid
run -all
#quit -sim