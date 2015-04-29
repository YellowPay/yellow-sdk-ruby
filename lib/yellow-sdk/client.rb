module Yellow

        VERSION = "0.0.1"
        YELLOW_SERVER = "https://" + (ENV["YELLOW_SERVER"] || "api.yellowpay.co")

    class YellowApiError < Exception ; end

    class Client
        def initialize(api_key, api_secret)
            @api_key = api_key
            @api_secret = api_secret
        end

        def create_invoice(hash={})
            ####
            # This method creates a yellow invoices based on the following options:
            #
            # #param    hash    hash      hash keys matching the expected
            #                             HTTP arguments described here:
            #                             http://yellowpay.co/docs/api/#creating-invoices
            # #returns  JSON parsed data
            ####

            endpoint = "/v1/invoice/"

            make_request('POST', endpoint, hash.to_json)
        end

        def query_invoice(invoice_id)
            ####
            # Use this method to query an invoice you created earlier using its ID 
            #
            # #param    str    invoice_id    the ID of the invoice you're querying
            # 
            # #returns  JSON parsed data                                
            ####

            endpoint = "/v1/invoice/#{invoice_id}/"
            make_request('GET', endpoint, "")
        end

        def verify_ipn(host_url, request_signature, request_nonce, request_body)
            ####
            # This is a helper method to verify that the request you just received really is from Yellow:
            #
            # #param    str    host_url             the callback URL you set when you created the invoice
            # #param    str    request_signature    the signature header of the request
            # #param    str    request_nonce        the nonce header of the request
            # #param    str    request_body         the body of the request
            #
            # #returns  boolean
            ####

            signature = get_signature(host_url, request_body, request_nonce, @api_secret)
            signature == request_signature ? return true : return false
        end

        private
        def make_request(method, endpoint, body)
            ####
            # A method used by our SDK to make requests to our server.
            ####

            url = YELLOW_SERVER + endpoint

            nonce = Time.now.to_i * 1000
            signature = get_signature(url, body, nonce, @api_secret)

            uri = URI.parse(YELLOW_SERVER)
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true

            if method == 'GET'
                request = Net::HTTP::Get.new(endpoint)
            elsif method == 'POST'
                request = Net::HTTP::Post.new(endpoint)
            end
            
            request.add_field('Content-Type', 'application/json')
            request.add_field('API-Key', @api_key)
            request.add_field('API-Nonce', nonce)
            request.add_field('API-Sign', signature)
            request.add_field('API-Platform', "#{RUBY_PLATFORM} - Ruby #{RUBY_VERSION}")
            request.add_field('API-Version', VERSION)
            request.body = body
            response = http.request(request)
            
            if response.code == '200'
                return JSON.parse(response.body)
            else
                raise YellowApiError.new(response.body)
            end     
        end

        private
        def get_signature(url, body, nonce, api_secret)
            ####
            # A tiny method used by our SDK to sign and verify requests.
            ####

            message = nonce.to_s + url + body
            hash    = OpenSSL::HMAC.hexdigest('sha256', api_secret, message)
        end
    end
end