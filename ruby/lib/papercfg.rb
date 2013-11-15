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

  # Patterns used to validate names of each type.  Parentheses are used to
  # capture each variable portion of a name.
  PATTERNS = {
    'ant'    => /^a(-?[1-9]\d*|0)$/,
    'antpol' => /^a(-?[1-9]\d*|0)([XY])$/,
    'sta'    => /^s([A-Z])([1-9]\d*|0)$/,
    'stapol' => /^s([A-Z])([1-9]\d*|0)([XY])$/,
    'rx'     => /^r([1-8])([AB])([1-8])$/,
    'rxpol'  => /^r([1-8])([AB])([1-8])([XY])$/,
    'plate'  => /^p([1-6])r([1-6])c([1-8])$/,
    'fxin'   => /^f([1-8])([A-H])([1-4])$/,
    'pos'    => nil # Positions are Arrays, not Strings
  }

  MNEMONICS = PATTERNS.keys

  MNEMONICS_PATTERN = /#{MNEMONICS.join('|')}/
  CANONICAL_PATTERN = /^(#{MNEMONICS_PATTERN})_to_(#{MNEMONICS_PATTERN}).ya?ml$/

  # This Hash subclass counts how many times a key is reused.
  class Mapping < Hash
    attr_reader :name
    attr_reader :mnemonic_from
    attr_reader :mnemonic_to
    attr_reader :comp_from
    attr_reader :comp_to

    def initialize(name='')
      @name = name || ''
      @canonical = CANONICAL_PATTERN =~ File.basename(name)
      # Get matching mnemonics from regexp match
      @mnemonic_from, @mnemonic_to = $1, $2
      @comp_from = COMPONENT_TYPES[@mnemonic_from]
      @comp_to   = COMPONENT_TYPES[@mnemonic_to]
    end

    def []=(k,v)
      # Check for dups, then call super, then update @dups.
      # This is needed so @dups is not altered if super raises and exception.
      is_dup = has_key? k
      super(k,v)
      if is_dup
        @dups    ||= {}
        @dups[k] ||= 0
        @dups[k]  += 1
      end
    end

    # Returns Hash with same key/value pairs.
    def to_hash
      Hash[self]
    end

    # Output our mappings with sorted keys
    def to_yaml
      yaml = ['---']

      metadata = self['metadata']
      if metadata
        mks = metadata.keys.sort
        max_mk = mks.max_by {|k| k.to_s.length}
        width = max_mk.to_s.length

        yaml << 'metadata:'
        mks.each do |k|
          v = metadata[k]
          yaml << sprintf("  %-*s :%s", width, k, v ? " #{v}" : '')
        end
      end

      ks = PaperCfg.sort(keys - ['metadata'])
      max_k = ks.max_by {|k| k.to_s.length}
      width = max_k.to_s.length
      ks.each do |k|
        v = self[k]
        yaml << sprintf("%-*s :%s", width, k, v ? " #{v}" : '')
      end

      yaml.join("\n")
    end

    # Pretend we are a Hash to YAML
    def to_yaml_properties
      to_hash.to_yaml_properties
    end

    # Returns Hash containing key->reuse_count.
    def dups
      @dups ||= {}
    end

    # Returns an array of keys that have been reused.
    def dup_keys
      dups.keys
    end

    # Returns true if any keys have been reused
    def dup_keys?
      !@dups.empty?
    end

    def inspect
      nk, nv, ndk, ndv = stats
      sprintf('#<%s:%#x %d keys/%d dups, %d values/%d dups>',
        self.class, self.object_id, nk, ndk, nv, ndv)
    end

    def canonical?
      !!@canonical
    end

    # Creates the inverse mapping of this mapping.  The inverse mapping is not
    # considered canonical.  Any metadata of this mapping is also metadata of
    # the inverse mapping.  nil values are NOT copied over as nil keys.
    def invert
      inv = self.class.new
      self.each do |k,v|
        if k == 'metadata'
          inv[k] = v
        elsif v
          inv[v] = k
        end
      end
      inv
    end

    # Returns the number of unique keys
    def num_keys
      keys.length
    end

    # Returns the number of non-nil values
    def num_values
      values.compact.length
    end

    # Returns the number of duplicated keys
    def num_dup_keys
      dup_keys.length
    end

    # Returns the number of duplicated values
    def num_dup_values
      non_nil_vals = values.compact
      non_nil_vals.length - non_nil_vals.compact.length
    end

    # Returns four stats regarding map: number of keys, number of non-nil
    # values, number of duplicate keys, and number of duplicate values.
    def stats
      #non_nil_vals = values.compact
      #uniq_non_nil_vals = non_nil_vals.uniq
      #num_dup_vals = non_nil_vals.length - uniq_non_nil_vals.length
      #[keys.length, non_nil_vals.length, dup_keys.length, num_dup_vals]
      [num_keys, num_values, num_dup_keys, num_dup_values]
    end

    def print_validity
      # Get stats
      num_keys, num_vals, num_dupkeys, num_dupvals = stats

      # See if this is a canonical filename
      basename = File.basename(name)
      if !canonical?
        if basename.empty?
          puts 'Mapping is not from a file'
        else
          puts "Filename #{basename} is not canonical"
        end
        # Print stats
        printf "%6d keys\n", num_keys
        printf "%6d values present\n", num_vals
        printf "%6d values missing\n", num_keys-num_vals
        printf "%6d duplicate keys\n", num_dupkeys
        printf "%6d duplicate values\n", num_dupvals
      else
        puts "File #{basename} maps #{comp_from} to #{comp_to}"

        # Print stats
        printf "%6d keys\n", num_keys
        printf "%6d values present\n", num_vals
        printf "%6d values missing\n", num_keys-num_vals
        printf "%6d duplicate keys\n", num_dupkeys
        printf "%6d duplicate values\n", num_dupvals

        # Check for invalid keys (but remove any 'metadata' key first)
        mapkeys = keys - ['metadata']
        from_pattern = PATTERNS[mnemonic_from]
        bad_keys = mapkeys.reject {|k| k =~ from_pattern}
        num_bad_keys = bad_keys.length

        # Print key validity info
        printf '%6d invalid %s keys', num_bad_keys, comp_from
        printf ':  %s', bad_keys.join(' ') if num_bad_keys > 0
        puts

        # Check validity of values (if applicable)
        if PATTERNS[mnemonic_to]
          non_nil_vals = values.compact
          to_pattern = PATTERNS[mnemonic_to]
          bad_vals = non_nil_vals.reject {|v| v =~ to_pattern}
          num_bad_vals = bad_vals.length
          printf '%6d invalid %s values', num_bad_vals, comp_to
          printf ':  %s', bad_vals.join(' ') if num_bad_vals > 0
          puts
        end
      end
    end

  end

  # Loads a file like YAML.load_file, but raises an exception if the top level
  # is a mapping and it contains duplicate keys.
  def load_file(f)
    # Parse file to abstract syntax tree form
    ast=Psych.parse_file(f)
    map = Mapping.new(f)

    # If root node is a mapping, build Mapping object
    if Psych::Nodes::Mapping === ast.root

      ast.root.children.each_slice(2) do |k,v|
        kk = k.to_ruby
        map[kk] = v.to_ruby
      end

      dups = map.dup_keys
      if dups.length > 0
        warn "#{dups.length} duplicate keys in #{f}: #{dups.join ' '}"
      end

    else
      # In this case, map isn't really a mapping.
      map = ast.to_ruby
    end
    # Freeze map to avoid accidental altering of mapping
    map.freeze
  end
  module_function :load_file

  # Sort +a+ as if it contains antenna names
  def sort_ants(a)
    a.sort_by {|e| e =~ PATTERNS['ant']; $1.to_i}
  end
  module_function :sort_ants

  # Sort +a+ as if it contains antpol names
  def sort_antpols(a)
    a.sort_by {|e| e =~ PATTERNS['antpol']; [$1.to_i, $2]}
  end
  module_function :sort_antpols

  # Sort +a+ as if it contains station names
  def sort_stas(a)
    a.sort_by {|e| e =~ PATTERNS['sta']; [$1, $2.to_i]}
  end
  module_function :sort_stas

  # Sort +a+ as if it contains stapols
  def sort_stapols(a)
    a.sort_by {|e| e =~ PATTERNS['stapol']; [$1.to_i, $2]}
  end
  module_function :sort_stapols

  # Sort +a+ based on type of first element
  def sort(a)
    case a[0]
    when PATTERNS['ant']; sort_ants(a)
    when PATTERNS['antpol']; sort_antpols(a)
    when PATTERNS['sta']; sort_stas(a)
    when PATTERNS['stapol']; sort_stapols(a)
    else
      a.sort
    end
  end
  module_function :sort

end
