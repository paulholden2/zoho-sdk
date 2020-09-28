require "faraday"
require "zoho-sdk/analytics/workspace"

module ZohoSdk
  module Analytics
    API_HOSTNAME = "https://analyticsapi.zoho.com".freeze
    API_PATH = "api".freeze
    API_BASE_URL = "#{API_HOSTNAME}/#{API_PATH}".freeze

    class Client
      def initialize(email, auth_token)
        @email = email
        @auth_token = auth_token
      end

      def workspace_metadata
        get params: {
          "ZOHO_ACTION" => "DATABASEMETADATA",
          "ZOHO_METADATA" => "ZOHO_CATALOG_LIST"
        }
      end

      def create_workspace(name, **opts)
        return if exists?
        res = @client.get params: {
          "ZOHO_ACTION" => "CREATEBLANKDB",
          "ZOHO_DATABASE_NAME" => name,
          "ZOHO_DATABASE_DESC" => opts[:description] || ""
        }
        if res.success?
          data = JSON.parse(res.body)
          ZohoSdk::Analytics::Workspace.new(name, self)
        else
          nil
        end
      end

      def workspace(name)
        res = get params: {
          "ZOHO_ACTION" => "ISDBEXIST",
          "ZOHO_DB_NAME" => name
        }
        if res.success?
          data = JSON.parse(res.body)
          if data.dig("response", "result", "isdbexist") == "true"
            ZohoSdk::Analytics::Workspace.new(name, self)
          else
            nil
          end
        else
          nil
        end
      end

      def get(path: nil, params: {})
        parts = [API_BASE_URL, @email]
        if !path.nil?
          if path[0] == "/"
            path = path[1..-1]
          end
          parts << path
        end
        conn = Faraday.new(url: parts.join("/"))
        res = conn.get do |req|
          req.params["ZOHO_OUTPUT_FORMAT"] = "JSON"
          req.params["ZOHO_ERROR_FORMAT"] = "JSON"
          req.params["ZOHO_API_VERSION"] = "1.0"
          req.params["authtoken"] = @auth_token
          params.each { |key, value|
            req.params[key] = value
          }
        end
      end
    end
  end
end
