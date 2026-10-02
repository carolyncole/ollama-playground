# app/operations/orcid_api_status.rb
#
# Replaces a Rails `HealthMonitor::Engine` provider class.
# A dry-rb operation that pings an external API and returns a Result the
# Health::Status action renders.

module OrcidPrinceton
  module Operations
    class OrcidApiStatus
      include Dry::Monads[:result]
      Deps :http

      def call
        case (result = http.get("https://orcid.org/"))
        in Success(response)
          if response.ok?
            Success(body: "ok")
          else
            Failure(status: response.status)
          end
        in Failure(error)
          Failure(cause: error)
        end
      end
    end
  end
end

# Consumed by app/actions/health/status.rb (the HealthMonitor replacement):
# class Status < Action
#   def call(request, response)
#     case (status = deps.orcid_api_status.call)
#     in Success(data) ; response(render Health::Views::Index, status: :ok, body: data[:body])
#     in Failure(data) ; response.status = :service_unavailable
#                          response.render(Health::Views::Index, status: :down, body: data[:cause])
#     end
#   end
# end
