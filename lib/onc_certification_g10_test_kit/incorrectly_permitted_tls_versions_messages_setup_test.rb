module ONCCertificationG10TestKit
  class IncorrectlyPermittedTLSVersionsMessagesSetupTest < Inferno::Test
    id :g10_incorrectly_permitted_tls_versions_messages_setup
    title 'Handle TLS Warning Messages'

    input :incorrectly_permitted_tls_versions_messages,
      optional: true
    output :unique_incorrectly_permitted_tls_versions_messages,
           :tls_documentation_required

    run do
      pass_if incorrectly_permitted_tls_versions_messages.blank?

      warning do
        new_warning_messages = incorrectly_permitted_tls_versions_messages&.split("\n")

        pass_if new_warning_messages.blank?

        raw_previous_warning_messages =
          Inferno::Repositories::SessionData.new.load(
            test_session_id:,
            name: 'unique_incorrectly_permitted_tls_versions_messages'
          )

        previous_warning_messages =
          raw_previous_warning_messages.blank? ? [] : raw_previous_warning_messages.split("\n")

        warning_messages = (previous_warning_messages + new_warning_messages).uniq

        output unique_incorrectly_permitted_tls_versions_messages: warning_messages.join("\n"),
               tls_documentation_required: 'true'
      end
    end
  end
end
