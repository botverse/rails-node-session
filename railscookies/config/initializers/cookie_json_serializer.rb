require 'json'

# Make signed cookies use JSON as serializer instead of Marshal
module ActionDispatch
  class Cookies
    class SignedCookieJar
      def initialize(parent_jar, key_generator, options = {})
        @parent_jar = parent_jar
        @options = options
        secret = key_generator.generate_key(@options[:signed_cookie_salt])
        @verifier   = ActiveSupport::MessageVerifier.new(secret, {:serializer => JSON})
      end
    end

    class EncryptedCookieJar #:nodoc:
      def initialize(parent_jar, key_generator, options = {})
        if ActiveSupport::LegacyKeyGenerator === key_generator
          raise "You didn't set config.secret_key_base, which is required for this cookie jar. " +
                    "Read the upgrade documentation to learn more about this new config option."
        end

        @parent_jar = parent_jar
        @options = options
        secret = key_generator.generate_key(@options[:encrypted_cookie_salt])
        sign_secret = key_generator.generate_key(@options[:encrypted_signed_cookie_salt])
        @encryptor = ActiveSupport::MessageEncryptor.new(secret, sign_secret, {:serializer => JSON})
      end
    end
  end
end

module Devise
  # A method used internally to setup warden manager from the Rails initialize
  # block.
  def self.configure_warden! #:nodoc:
    @@warden_configured ||= begin
      warden_config.failure_app   = Devise::Delegator.new
      warden_config.default_scope = Devise.default_scope
      warden_config.intercept_401 = false

      Devise.mappings.each_value do |mapping|
        warden_config.scope_defaults mapping.name, :strategies => mapping.strategies

        warden_config.serialize_into_session(mapping.name) do |record|
          mapping.to.serialize_into_session(record)
        end

        warden_config.serialize_from_session(mapping.name) do |key|
          # Previous versions contained an additional entry at the beginning of
          # key with the record's class name.
          args = key[-2, 2]
          if args[0][0].class != Moped::BSON::ObjectId
            if args[0][0].class == String
              args[0][0] = JSON.parse args[0][0]
            end
            args[0][0] = Moped::BSON::ObjectId(args[0][0]['$oid'])
          end

          mapping.to.serialize_from_session(*args)
        end
      end

      @@warden_config_block.try :call, Devise.warden_config
      true
    end
  end
end

class Redis
  class Store < self
    module Strategy
      module JsonSession

        class Error < StandardError
        end

        class SerializationError < Redis::Store::Strategy::JsonSession::Error
          def initialize(object)
            super "Cannot correctly serialize object: #{object.inspect}"
          end
        end

        private
        SERIALIZABLE = [String, TrueClass, FalseClass, NilClass, Numeric, Date, Time, Symbol]
        MARSHAL_INDICATORS = ["\x04", "\004", "\u0004"]

        def _dump(object)
          object = _marshal(object)
          JSON.generate(object)
        end

        def _load(string)
          object =
              string.start_with?(*MARSHAL_INDICATORS) ? ::Marshal.load(string) : JSON.parse(string)
          _unmarshal(object)
        end

        def _marshal(object)
          case object
            when Hash
              marshal_hash(object)
            when Array
              object.each_with_index { |v, i| object[i] = _marshal(v) }
            when Set
              _marshal(object.to_a)
            when String
              object.encoding == Encoding::ASCII_8BIT ? object.to_json_raw_object : object
            when Moped::BSON::ObjectId
              object.to_json
            when *SERIALIZABLE
              object
            else
              raise SerializationError.new(object)
          end
        end

        def marshal_hash(object)
          object.each { |k,v| object[k] = _marshal(v) }
        end

        def _unmarshal(object)
          case object
            when Hash
              object.each { |k,v| object[k] = _unmarshal(v) }
            when Array
              object.each_with_index { |v, i| object[i] = _unmarshal(v) }
            when String
              object.start_with?(*MARSHAL_INDICATORS) ? ::Marshal.load(object) : object
            else
              object
          end
        end

      end
    end
  end
end
