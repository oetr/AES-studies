GHDL = ghdl
TARGET_001 = AES_TB

RM = rm -rf
SIM_DIR = ./sim
MKDIR_P = mkdir -p

all: mkdir_and_copy target_001

mkdir_and_copy:
	$(MKDIR_P) $(SIM_DIR)
	cp AES_128_Simple_002.vhd $(SIM_DIR)
	cp AESlib.vhd $(SIM_DIR)
	cp txt_util.vhd $(SIM_DIR)
	cp AES_TB.vhd $(SIM_DIR)
	cp Makefile $(SIM_DIR) # copy this Makefile into the simulation directory

target_001: $(TARGET_001).vhd
	$(MAKE) -C $(SIM_DIR) target_001_subdir

target_001_subdir: $(TARGET_001).vhd
	$(GHDL) -i *.vhd
	$(GHDL) make $(TARGET_001)
	$(GHDL) -r  $(TARGET_001) --stop-delta=10 --wave=./$(TARGET_001).ghw

.PHONY: clean
clean:
	$(RM) $(SIM_DIR)/*.vhd
	$(RM) $(SIM_DIR)/*.ghw
	$(RM) $(SIM_DIR)/*.cf
	$(RM) $(SIM_DIR)/
