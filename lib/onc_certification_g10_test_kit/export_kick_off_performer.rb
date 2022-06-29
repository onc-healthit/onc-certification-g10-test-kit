module ONCCertificationG10TestKit
  module ExportKickOffPerformer
    def perform_export_kick_off_request(use_token: true, params: '')
      skip_if use_token && bearer_token.blank?, 'Could not verify this functionality when bearer token is not set'

      headers = ({ accept: 'application/fhir+json', prefer: 'respond-async' })
      headers.merge!({ authorization: "Bearer #{bearer_token}" }) if use_token

      url = "Group/#{group_id}/$export"
      url.concat("?#{params}") unless params.empty?
      get(url, client: :bulk_server, name: :export, headers: headers)
    end
  end
end
