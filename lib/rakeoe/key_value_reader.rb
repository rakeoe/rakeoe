# -*- ruby -*-

# TODO Write Test cases for class

module RakeOE
#
# Provides functions for accessing key/value variables out of a file.
# For every variable of that file a getter method to this class is auto generated
#
# Supported file conventions:
#
# var1 = val1
# var2 = val2
# export var3 = val3:val4:val5
# var4 = 'val6'
# var5 = "val7"
# "var6" = 'val8'
class KeyValueReader
  attr_accessor :env

  def initialize(env_file)
    raise "No such file #{env_file}" unless File.exist?(env_file)

    @file_name = env_file
    @env = self.class.read_file(@file_name)
    self.class.substitute_dollar_symbols!(@env)
  end

  # Substitute all dollar values with either already parsed
  # values or with system environment variables
  def self.substitute_dollar_symbols!(env)
    resolved_dollar_vars = env.each_with_object(Hash.new) do |var, obj|
      # search for '$BLA..' identifier
      pattern = /\$[[:alnum:]]+/
      match = var[1].match(pattern)
      if match
        # remove '$' from match, we don't need it as key
        key = match[0].gsub('$', '')
        value = env[key] ? env[key] : ENV[key]
        raise "No $#{key} found in environment" if value.nil?

        obj[var[0]] = var[1].gsub(pattern, value)
      end
    end
    # overwrite old values with resolved values
    env.merge!(resolved_dollar_vars)
  end


  # Read the given file and split according to expected key=value format
  # Ignore empty lines or lines starting with a comment (#), ignores comments within a line
  # Also removes quote characters ('")
  #
  # @param [String] file_name   Filename to be used for operation
  # @return [Hash]  A hash containing all parsed key/value pairs
  #
  def self.read_file(file_name)
    env = Hash.new
    prev_key = String.new

    File.readlines(file_name).each do |line|
      line.strip!
      next if line.start_with?('#')
      next if line.empty?

      # delete comments within line
      line.gsub!(/#.*/, '')

      key, *value = line.split('=')
      next unless key

      # remove 'export ', quotes and leading/trailing white space from line
      key.gsub!(/^export\s*/, '')
      key.gsub!(/["']*/, '')
      key.strip!

      if value.empty?
        if prev_key && !line.include?('=')
          # multiline value: treat key as value and add to previous found key
          env[prev_key] = "#{env[prev_key]} #{key}"
        end
      else
        prev_key = key
        # We could have split multiple '=' in one line.
        # Put back any "=" in the value part
        # and concatenate split strings
        val = value.join('=').strip
        val.gsub!(/^["']*/, '')
        val.gsub!(/["']$/, '')
        val.gsub!(/[\n]*/, '')
        env[key] = val.strip
      end

    end
    env
  end


  # Returns all keys (i.e. left handed side of the parsed key/values)
  #
  # @return [Array]   all keys
  #
  def keys
    @env.keys
  end


  # Returns all values (i.e. right handed side of the parsed key/values)
  #
  # @return [Array]   all values
  #
  def values
    @env.values
  end

  # Returns filename of read file
  #
  # @return [String]   File name
  #
  def file
    @file_name
  end


  # Returns the value belonging to key (right hand side), or empty string if no such value
  #
  # @param [String] key   Key that should be used for operation
  # @return [String]      Value of given key
  #
  def get(key)
    @env[key] || ''
  end


  # Sets a value for key
  #
  # @param [String] key     Key that should be used for operation
  # @param [String] value   Value that should be used for operation
  #
  def set(key, value)
    @env[key] = value
  end

  # Merges a hash of key value pairs without actually overwriting existing entries.
  # This is similar as the ||= operator on a key => value basis.
  #
  # @param a_hash   Hash of Key/Value pairs
  #
  # @return the
  def merge(a_hash)
    @env.merge!(a_hash) { |key, v1, v2| v1 }
  end

  # Adds a value for key
  #
  # @param [String] key     Key that should be used for operation
  # @param [String] value   Value that should be used for operation
  #
  def add(key, value)
    if @env.has_key?(key)
      @env[key] += value
    else
      set(key,value)
    end
  end


  # Dumps all parsed variables as debugging aid
  def dump
    puts "#{@file_name}"
    @env.each_pair do |key, value|
      puts "[#{key}]: #{value}"
    end
  end

end

end
