module ONCCertificationG10TestKit
  class IncorrectlyPermittedTLSVersionsMessagesSetupTest < Inferno::Test
    id :g10_incorrectly_permitted_tls_versions_messages_setup
    title 'Handle TLS Warning Messages'

    input :incorrectly_permitted_tls_versions_messages
    output :unique_incorrectly_permitted_tls_versions_messages,
           :tls_documentation_required

    run do
      pass_if incorrectly_permitted_tls_versions_messages.blank?

      warning do
        Inferno::Application['logger'].info(self.class.id)
        Inferno::Application['logger'].info('111111111111111111111111111111111111111111111')
        new_warning_messages = incorrectly_permitted_tls_versions_messages&.split("\n")
        Inferno::Application['logger'].info('222222222222222222222222222222222222222222222')
        Inferno::Application['logger'].info(new_warning_messages.to_s)

        pass_if new_warning_messages.blank?

        Inferno::Application['logger'].info('333333333333333333333333333333333333333333333')
        raw_previous_warning_messages =
          Inferno::Repositories::SessionData.new.load(
            test_session_id: test_session_id,
            name: 'unique_incorrectly_permitted_tls_versions_messages'
          )

        previous_warning_messages =
          raw_previous_warning_messages.blank? ? [] : raw_previous_warning_messages.split("\n")
        Inferno::Application['logger'].info(previous_warning_messages.to_s)

        warning_messages = (previous_warning_messages + new_warning_messages).uniq

        Inferno::Application['logger'].info('4444444444444444444444444444444444444444444')
        Inferno::Application['logger'].info(warning_messages.to_s)
        output unique_incorrectly_permitted_tls_versions_messages: warning_messages.join("\n"),
               tls_documentation_required: 'true'
      end
    end
  end
end
