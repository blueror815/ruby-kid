require 'active_support'

include ActiveSupport::Inflector

module ObjectSugar

  ##
  # Setup

  def self.setup!
    extend_object_with_constant_constant_helpers!
    extend_class_and_module_with_constants!
    extend_class_and_module_with_value_enums!
    extend_class_and_module_with_bitwise_enums!
  end

  ##
  # Extend object with helper methods to create class/module constants

  def self.extend_object_with_constant_constant_helpers!
    Object.class_eval do
      private

      ##
      # Creates a class +name+ and creates constants for each +args+
      #
      # Also accepts hashes as key/value pairs for constant
      #
      # class Foo
      #   object_constants :my_constants, :one, :two, :three => "tre"
      # end
      #
      # Will create the following constants, values on class Foo
      #
      # Foo::MyConstants::ONE   => ONE
      # Foo::MyConstants::TWO   => TWO
      # Foo::MyConstants::THREE => tre

      def create_constants(name, *args)
        const = name.to_s.camelize.to_sym
        klass = const_defined?(const) ? const_get(const) : const_set(name.to_s.camelize.to_sym, Class.new)
        klass.extend ObjectSugar::InstanceMethods

        args.flatten.each do |enum|
          if enum.is_a?(Hash)
            enum.each { |key, value| klass.const_set(key.to_s.underscore.upcase, value) }
          else
            key, value = Array.new(2, enum.to_s.underscore.upcase)
            klass.const_set(key, value)
          end
        end

        klass
      end

      ##
      # Creates a class +name+ on self and creates a simple enumeration whereas
      # each subsequent argument in +args+ has a value +factor+^index

      def create_enum(name, factor, *args)
        const = name.to_s.camelize.to_sym
        klass = const_defined?(const) ? const_get(const) : const_set(name.to_s.camelize.to_sym, Class.new)
        klass.extend ObjectSugar::InstanceMethods

        offset = klass.constants.size

        args.flatten.each_with_index do |const, index|
          value = (factor == 1) ? (factor * (index + offset)) : (factor.power!(index + offset))

          klass.const_set(const.to_s.underscore.upcase, value.to_i)
        end

        klass
      end

      ##
      # Create a constant with a name of the pluralized version of +name+
      # that returns all of the class constants of +name+
      #
      # class Foo
      #   object_constants :my_constants, :one, :two, :three
      # end
      #
      # Will add the following constant on class Foo
      #
      # Foo::MY_CONSTANTS
      #
      # Which would return
      # => ONE, TWO, THREE

      def create_pluralized_constant(name)
        pluralized = ActiveSupport::Inflector.pluralize(name.to_s).upcase.to_sym
        constants  = const_get(name.to_s.camelize.to_sym).constants

        const_set(pluralized, constants)
      end
    end
  end

  ##
  # Extend with #object_constants

  def self.extend_class_and_module_with_constants!
    [Class, Module].each do |object|
      object.class_eval do
        def object_constants(name, *args)
          create_constants(name, *args)
          create_pluralized_constant(name)
        end
      end
    end
  end

  ##
  # Extend with #value_enums

  def self.extend_class_and_module_with_value_enums!
    [Class, Module].each do |object|
      object.class_eval do
        def value_enums(name, *args)
          create_enum(name, 1, *args)
          create_pluralized_constant(name)
        end
      end
    end
  end

  ##
  # Extend with #bitwise_enums

  def self.extend_class_and_module_with_bitwise_enums!
    [Class, Module].each do |object|
      object.class_eval do
        def bitwise_enums(name, *args)
          create_enum(name, 2, *args )
          create_pluralized_constant(name)
        end
      end
    end
  end

  module InstanceMethods
    include Enumerable

    ##
    # Iterate over each const name and value

    def each(&block)
      constants.each { |c| yield(c, const_get(c)) }
    end

    ##
    # Names

    def names
      map(&:first)
    end

    ##
    # Values

    def values
      map(&:last)
    end

    ##
    # Find Name

    def find_name(&block)
      _found = find(&block)
      _found ? _found.first : nil
    end

    ##
    # Find Value

    def find_value(&block)
      _found = find(&block)
      _found ? _found.last : nil
    end
  end
end

ObjectSugar.setup!