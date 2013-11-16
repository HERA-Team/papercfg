# Reference files are the master inputs.
# They should never appear as targets.
# They should never be a dependency of the "clean" target.
REFERENCE_FILES = sta_to_ant.yml \
                  sta_to_pos.yml \
                  sta_to_rx.yml  \
                  rxpol_to_plate.yml \
                  plate_to_fxin.yml

DERIVED_FILES = ant_to_pos.yml \
                ant_to_sta.yml \
                antpol_to_fxin.yml \
                antpol_to_stapol.yml \
                fxin_to_antpol.yml \
                fxin_to_stapol.yml \
                fxin_to_plate.yml \
                plate_to_rxpol.yml \
                plate_to_stapol.yml \
                stapol_to_fxin.yml \
                stapol_to_plate.yml \
                stapol_to_rxpol.yml

all: $(DERIVED_FILES)

# Files created by paper_config_invert.rb

ant_to_sta.yml: sta_to_ant.yml
	paper_config_invert.rb $^ > $@

fxin_to_antpol.yml: antpol_to_fxin.yml
	paper_config_invert.rb $^ > $@

fxin_to_stapol.yml: stapol_to_fxin.yml
	paper_config_invert.rb $^ > $@

fxin_to_plate.yml: plate_to_fxin.yml
	paper_config_invert.rb $^ > $@

plate_to_rxpol.yml: rxpol_to_plate.yml
	paper_config_invert.rb $^ > $@

plate_to_stapol.yml: stapol_to_plate.yml
	paper_config_invert.rb $^ > $@

# Files created by paper_config_polarize.rb

antpol_to_stapol.yml: ant_to_sta.yml
	paper_config_polarize.rb $^ > $@

stapol_to_rxpol.yml: sta_to_rx.yml
	paper_config_polarize.rb $^ > $@

# Files created by paper_config_chain.rb

ant_to_pos.yml: ant_to_sta.yml sta_to_pos.yml
	paper_config_chain.rb $^ > $@

stapol_to_plate.yml: stapol_to_rxpol.yml rxpol_to_plate.yml
	paper_config_chain.rb $^ > $@

stapol_to_fxin.yml: stapol_to_rxpol.yml rxpol_to_plate.yml plate_to_fxin.yml
	paper_config_chain.rb $^ > $@

antpol_to_fxin.yml: antpol_to_stapol.yml stapol_to_fxin.yml
	paper_config_chain.rb $^ > $@

# Validate all files in the current directory
validate:
	echo Coming soon...

# Remove all derived files
clean:
	rm -f $(DERIVED_FILES)

.PHONY: all validate
