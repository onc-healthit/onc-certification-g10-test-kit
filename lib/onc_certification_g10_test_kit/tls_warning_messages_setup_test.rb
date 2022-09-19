module ONCCertificationG10TestKit
  class TLSWarningMessagesSetupTest < Inferno::Test
    id :g10_tls_warning_messages_setup
    title 'Handle TLS Warning Messages'

    input :tls_warning_messages
    output :unique_tls_warning_messages

    run do
      pass if tls_warning_messages.blank?

      warning do
        warning_messages = JSON.parse(tls_warning_messages)

        raw_current_warning_messages =
          Inferno::Repositories::SessionData.load(
            test_session_id: test_session_id,
            name: 'unique_tls_warning_messages'
          )

        current_warning_messages =
          raw_current_warning_messages.blank? ? [] : JSON.parse(raw_current_warning_messages)

        current_warning_messages.concat(warning_messages).uniq!

        output unique_tls_warning_messages: JSON.generate(current_warning_messages)
      end
    end
  end
end
