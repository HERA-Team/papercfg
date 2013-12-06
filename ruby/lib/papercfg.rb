require 'yaml'
require 'digest/sha1'
require 'papercfg/version'

# Add Digest.git_hash function that returns Digest::SHA1 object representing
# the "git hash-object" value for a named file.
module Digest
  # Returns Digest::SHA1 object representing the "git hash-object" value for
  # file named by +fn+.
  def self.git_hash(fn)
    Digest::SHA1.new.update("blob #{File.size(fn)}\0").file(fn)
  end
end

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

    # Returns an unfrozen copy of +self+.
    def dup
      out = self.class.new(name)
      self.each {|k,v| out[k] = v}
      out
    end

    # Always converts +k+ to String.
    def [](k)
      # Convert k to String
      k = k.to_s
      super k
    end

    # Always converts +k+ to String.
    def has_key?(k)
      # Convert k to String
      k = k.to_s
      super k
    end

    # Always converts +k+ to String.
    def []=(k,v)
      # Convert k to String
      k = k.to_s

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

    # Returns a Mapping object that maps keys from +self+ to values of
    # <tt>others[-1]</tt> via +self+ and all the mappings in <tt>*others</tt>.
    # Merges any metadata mapping in +self+ and <tt>others[-1]</tt>.  Returns
    # +self+ if +others+ is empty.
    def chain(*others)
      return self if others.empty?
      others.unshift(self)
      outmap = self.class.new
      # Handle 'metadata' keys differently
      ks = keys - ['metadata']
      ks.each do |k|
        val = others.inject(k) {|kk,map| map[kk]}
        outmap[k] = val if val
      end
      metadata = self['metadata']
      if others[-1]
        metadata = metadata ?
                   metadata.merge(others[-1]['metadata']) :
                   others[-1]['metadata']
      end
      outmap['metadata'] = metadata if metadata
      outmap
    end

    # Returns a Hash that has the same keys as +self+.  Each key corresponds to
    # an Array of values encountered by walking through the mappings in
    # +others+.  The Arrays will be of different lengths if some keys don't map
    # all the way through.
    def path(*others)
      others.unshift(self)
      outmap = {}
      # Ignore 'metadata'
      ks = keys - ['metadata']
      ks.each do |k|
        val = others.inject([k]) {|ka,map| ka << map[ka[-1]]}
        outmap[k] = val.compact
      end
      outmap
    end

    # Polarize this mapping by duplicating each key/value pair twice; once with
    # an 'X' suffix on key and value and once with a 'Y' suffix on key and
    # value.  Currently it does not prevent polarizing an already polarized
    # file.  Any metadata information is not polarized.
    def polarize
      outmap = self.class.new
      # Handle 'metadata' keys differently
      ks = keys - ['metadata']
      ks.each do |k|
        outmap["#{k}X"] = "#{self[k]}X"
        outmap["#{k}Y"] = "#{self[k]}Y"
      end
      if has_key? 'metadata'
        outmap['metadata'] = self['metadata']
      end
      outmap
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
      non_nil_vals.length - non_nil_vals.uniq.length
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

    def print_validity(verbose=false)
      # Get stats
      num_keys, num_vals, num_dupk, num_dupv = stats
      num_vmiss = num_keys - num_vals

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
        printf "%6d values present\n", num_vals   if num_vals  > 0 || verbose
        printf "%6d values missing\n", num_vmiss  if num_vmiss > 0 || verbose
        printf "%6d duplicate keys\n", num_dupk   if num_dupk  > 0 || verbose
        printf "%6d duplicate values\n", num_dupv if num_dupv  > 0 || verbose
      else
        puts "File #{basename} maps #{comp_from} to #{comp_to}"

        # Print stats
        printf "%6d keys\n", num_keys
        printf "%6d values present\n", num_vals   if num_vals  > 0 || verbose 
        printf "%6d values missing\n", num_vmiss  if num_vmiss > 0 || verbose 
        printf "%6d duplicate keys\n", num_dupk   if num_dupk  > 0 || verbose 
        printf "%6d duplicate values\n", num_dupv if num_dupv  > 0 || verbose 

        # Check for invalid keys (but remove any 'metadata' key first)
        mapkeys = keys - ['metadata']
        from_pattern = PATTERNS[mnemonic_from]
        bad_keys = mapkeys.reject {|k| k =~ from_pattern}
        num_bad_keys = bad_keys.length

        # Print key validity info
        if num_bad_keys > 0 || verbose
          printf '%6d invalid %s keys', num_bad_keys, comp_from
          printf ':  %s', bad_keys.join(' ') if num_bad_keys > 0
          puts
        end

        # Check validity of values (if applicable)
        if PATTERNS[mnemonic_to]
          non_nil_vals = values.compact
          to_pattern = PATTERNS[mnemonic_to]
          bad_vals = non_nil_vals.reject {|v| v =~ to_pattern}
          num_bad_vals = bad_vals.length
          if num_bad_vals > 0 || verbose
            printf '%6d invalid %s values', num_bad_vals, comp_to
            printf ':  %s', bad_vals.join(' ') if num_bad_vals > 0
            puts
          end
        end
      end
    end

  end # class Mapping

  # Loads a file like YAML.load_file, but counts (and warns on) duplicate keys.
  def load_file(f)
    # Parse file to abstract syntax tree form
    begin
      ast=Psych.parse_file(f)
    rescue
      # Opening file named by f failed.  If f starts with a '.' or a '/', then
      # give up; otherwise try to look in ENV['PAPERCFG_DIR'] or
      # "/etc/papercfg" if PAPERCFG_DIR does not exist in ENV.
      raise if %r{^[./]} =~ f
      f = File.join(ENV['PAPERCFG_DIR']||'/etc/papercfg', f)
      ast=Psych.parse_file(f)
    end

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
    a.sort_by {|e| e =~ PATTERNS['stapol']; [$1, $2.to_i, $3]}
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
