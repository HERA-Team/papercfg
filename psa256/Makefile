REFERENCE_FILES = sta_to_ant.yml \
                  sta_to_pos.yml \
                  sta_to_rx.yml  \
                  rxpol_to_plate.yml

DERIVED_FILES = ant_to_pos.yml \
                ant_to_sta.yml \
                stapol_to_rxpol.yml

all: $(DERIVED_FILES)

# Files created by paper_config_invert.rb

ant_to_sta.yml: sta_to_ant.yml
	paper_config_invert.rb $^ > $@

# Files created by paper_config_polarize.rb

stapol_to_rxpol.yml: sta_to_rx.yml
	paper_config_polarize.rb $^ > $@

# Files created by paper_config_chain.rb

ant_to_pos.yml: ant_to_sta.yml sta_to_pos.yml
	paper_config_chain.rb $^ > $@

# Validate all files in the current directory
validate:
	echo Coming soon...

# Remove all derived files
clean:
	rm -f $(DERIVED_FILES)

.PHONY: all validate
