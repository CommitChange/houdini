# frozen_string_literal: true
# this is available in newer versions of rails that we aren't running
if Rails.version < '5'
  require "active_support/core_ext/hash/keys"

  module ActiveModel
    module AttributeAssignment
      include ActiveModel::ForbiddenAttributesProtection

      # Allows you to set all the attributes by passing in a hash of attributes with
      # keys matching the attribute names.
      #
      # If the passed hash responds to <tt>permitted?</tt> method and the return value
      # of this method is +false+ an <tt>ActiveModel::ForbiddenAttributesError</tt>
      # exception is raised.
      #
      #   class Cat
      #     include ActiveModel::AttributeAssignment
      #     attr_accessor :name, :status
      #   end
      #
      #   cat = Cat.new
      #   cat.assign_attributes(name: "Gorby", status: "yawning")
      #   cat.name # => 'Gorby'
      #   cat.status # => 'yawning'
      #   cat.assign_attributes(status: "sleeping")
      #   cat.name # => 'Gorby'
      #   cat.status # => 'sleeping'
      def assign_attributes(new_attributes)
        unless new_attributes.respond_to?(:each_pair)
          raise ArgumentError, "When assigning attributes, you must pass a hash as an argument, #{new_attributes.class} passed."
        end
        return if new_attributes.empty?

        _assign_attributes(sanitize_for_mass_assignment(new_attributes))
      end

      alias attributes= assign_attributes

      private
        def _assign_attributes(attributes)
          attributes.each do |k, v|
            _assign_attribute(k, v)
          end
        end

        def _assign_attribute(k, v)
          setter = :"#{k}="
          if respond_to?(setter)
            public_send(setter, v)
          else
            raise ActiveModel::Errors::UnknownAttributeError.new(self, k.to_s)
          end
        end
    end
    class Errors
      # Raised when unknown attributes are supplied via mass assignment.
      #
      #   class Person
      #     include ActiveModel::AttributeAssignment
      #     include ActiveModel::Validations
      #   end
      #
      #   person = Person.new
      #   person.assign_attributes(name: 'Gorby')
      #   # => ActiveModel::UnknownAttributeError: unknown attribute 'name' for Person.
      class UnknownAttributeError < NoMethodError
        attr_reader :record, :attribute

        def initialize(record, attribute)
          @record = record
          @attribute = attribute
          super("unknown attribute '#{attribute}' for #{@record.class}.")
        end
      end
    end
  end
else
  puts "Monkeypatch for ActiveModel::AttributeAssignment no longer needed"
end
