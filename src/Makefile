GHDL = ghdl
TARGET_001 = AES_TB

RM = rm -rf
SIM_DIR = ./sim
MKDIR_P = mkdir -p

all: mkdir_and_copy target_001

mkdir_and_copy:
	$(MKDIR_P) $(SIM_DIR)
	cp *.vhd $(SIM_DIR)

target_001: $(TARGET_001).vhd
	cd $(SIM_DIR) && $(GHDL) -i *.vhd && $(GHDL) -m $(TARGET_001) --std="08"; \
		$(GHDL) -r  $(TARGET_001) --stop-delta=10 --wave=./$(TARGET_001).ghw ;

.PHONY: clean
clean:
	$(RM) $(SIM_DIR)/*.vhd
	$(RM) $(SIM_DIR)/*.ghw
	$(RM) $(SIM_DIR)/*.cf
	$(RM) $(SIM_DIR)/
