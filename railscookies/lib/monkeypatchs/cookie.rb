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
  end
end
