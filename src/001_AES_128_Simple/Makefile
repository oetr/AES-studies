GHDL = ghdl
TARGET = AES_TB

RM = rm -rf
SIM_DIR = ./sim
MKDIR_P = mkdir -p

all: mkdir_and_copy target

mkdir_and_copy:
	$(MKDIR_P) $(SIM_DIR)
	cp AES_128_Simple.vhd $(SIM_DIR)
	cp AESlib.vhd $(SIM_DIR)
	cp AES_TB.vhd $(SIM_DIR)
	cp ../txt_util.vhd $(SIM_DIR)
	cp Makefile $(SIM_DIR) # copy this Makefile into the simulation directory

target: $(TARGET).vhd
	$(MAKE) -C $(SIM_DIR) target_subdir

target_subdir: $(TARGET).vhd
	$(GHDL) -i *.vhd
	$(GHDL) make $(TARGET)
	$(GHDL) -r  $(TARGET) --stop-delta=10 --wave=./$(TARGET).ghw
# $(GHDL) -r  $(TARGET) --stop-delta=10 --vcd=./$(TARGET).vcd

.PHONY: clean
clean:
	$(RM) $(SIM_DIR)/*.vhd
	$(RM) $(SIM_DIR)/*.ghw
	$(RM) $(SIM_DIR)/*.vcd
	$(RM) $(SIM_DIR)/*.cf
	$(RM) $(SIM_DIR)/
