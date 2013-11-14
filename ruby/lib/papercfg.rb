require 'yaml'
require 'papercfg/version'

module PaperCfg

  COMPONENT_TYPES = {
    'ant'    => 'antenna',
    'antpol' => 'antenna polarization',
    'sta'    => 'station',
    'stapol' => 'station polarization',
    'rx'     => 'recevier',
    'rxpol'  => 'receiver polarization',
    'plate'  => 'plate connector',
    'fxin'   => 'F engine input',
    'pos'    => 'position'
  }

  PATTERNS = {
    'ant'    => /^a(-?[1-9]\d*|0)$/,
    'antpol' => /^a(-?[1-9]\d*|0)[XY]$/,
    'sta'    => /^s[A-Z]([1-9]\d*|0)$/,
    'stapol' => /^s[A-Z]([1-9]\d*|0)[XY]$/,
    'rx'     => /^r[1-8][AB][1-8]$/,
    'rxpol'  => /^r[1-8][AB][1-8][XY]$/,
    'plate'  => /^p[1-6]r[1-6]c[1-8]$/,
    'fxin'   => /^f[1-8][A-H][1-4]$/,
    'pos'    => nil # Validating positions not yet supported
  }

  MNEMONICS = PATTERNS.keys

  MNEMONICS_PATTERN = /#{MNEMONICS.join('|')}/
  CANONICAL_PATTERN = /^(#{MNEMONICS_PATTERN})_to_(#{MNEMONICS_PATTERN}).ya?ml$/

  def load_file(f)
    YAML.load_file(f)
  end
  module_function :load_file

  # Returns three stats regarding map: number of keys, number of non-nil
  # values, and number of duplicate values.
  def get_map_stats(map)
    keys = map.keys
    vals = map.values
    non_nil_vals = vals.compact
    #num_nil_vals = vals.length - non_nil_vals.length
    uniq_non_nil_vals = non_nil_vals.uniq
    num_dup_vals = non_nil_vals.length - uniq_non_nil_vals.length
    #puts "#{keys.length} keys"
    #puts "#{non_nil_vals.length} values present"
    #puts "#{num_nil_vals} values missing"
    #puts "#{num_dup_vals} duplicate values"
    [keys.length, non_nil_vals.length, num_dup_vals]
  end
  module_function :get_map_stats

  def print_map_validity_for_filename(map, filename)
    # Get stats
    num_keys, num_vals, num_dups = get_map_stats(map)

    # See if this is a canonical filename
    basename = File.basename(filename)
    if basename !~ CANONICAL_PATTERN
      puts "File #{basename} is not a canonical filename"
      # Print stats
      printf "%6d keys\n", num_keys
      printf "%6d values present\n", num_vals
      printf "%6d values missing\n", num_keys-num_vals
      printf "%6d duplicate values\n", num_dups
    else
      # Get matching mnemonics from regexp match
      from_mnemonic, to_mnemonic = $1, $2
      from_comp = COMPONENT_TYPES[from_mnemonic]
      to_comp   = COMPONENT_TYPES[to_mnemonic]
      puts "File #{basename} maps #{from_comp} to #{to_comp}"

      # Print stats
      printf "%6d keys\n", num_keys
      printf "%6d values present\n", num_vals
      printf "%6d values missing\n", num_keys-num_vals
      printf "%6d duplicate values\n", num_dups

      # Check for invalid keys (but remove any 'metadata' key first)
      keys = map.keys - ['metadata']
      bad_keys = keys.reject {|k| k =~ PATTERNS[from_mnemonic]}
      num_bad_keys = bad_keys.length

      # Print key validity info
      printf "%6d invalid #{from_comp} keys\n", num_bad_keys

      # Check validity of values (if applicable)
      if PATTERNS[to_mnemonic]
        non_nil_vals = map.values.compact
        bad_vals = non_nil_vals.reject {|v| v =~ PATTERNS[to_mnemonic]}
        num_bad_vals = bad_vals.length
        printf "%6d invalid #{to_comp} values\n", num_bad_vals
      end
    end
  end
  module_function :print_map_validity_for_filename
end
