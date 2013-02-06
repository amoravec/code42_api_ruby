require "crashplan/ext/string"

module Crashplan
  module Resource
    class << self
      def included(base)
        base.extend ClassMethods
      end
    end

    module ClassMethods
      def attribute_translations
        @attribute_translations ||= {}
      end

      def from_response(response)
        deserialize_and_initialize(response['data'])
      end

      def deserialize_and_initialize(data)
        new deserialize(data)
      end

      def serialize(data)
        translate_attributes(data, true)
      end

      def deserialize(data)
        translate_attributes(data, false)
      end

      def translate_attributes(data, serialize = false)
        translations = attribute_translations
        translations = translations.invert if serialize
        new_hash = {}

        # Iterate over hash elements
        data.each do |k,v|
          new_key = serialize ? k.to_s.camelize : k.underscore.to_sym
          if attributes.include?(new_key.to_sym)
            if translations.has_key?(new_key.to_sym)
              new_key = translations[new_key.to_sym]
            end
            new_hash[new_key] = v
          end
        end
        new_hash
      end

      def translate_attribute(serialized, deserialized)
        attribute_translations[serialized.to_s] = deserialized
      end

      def attributes
        @attributes ||= []
      end

      def attribute(*args)
        options = args.extract_options!
        if options.has_key?(:as)
          name = args.first
          attributes << name
          attribute_translations[name] = options[:as]
        else
          attributes.push(*args)
        end
      end
    end

    attr_reader :attributes

    def initialize(data = {})
      @attributes = {}
      data.each do |key, value|
        unless self.respond_to?("#{key}=".to_sym)
          self.class.send :define_method, "#{key}=".to_sym do |v|
            instance_variable_set("@" + key.to_s, v)
          end
        end
        unless self.respond_to?("key".to_sym)
          self.class.send :define_method, key.to_sym do
            instance_variable_get("@" + key.to_s)
          end
        end
        self.send("#{key}=", value)
        @attributes[key.to_sym] = send(key.to_sym)
      end
    end
  end
end
