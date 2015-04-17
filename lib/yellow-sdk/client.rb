module Yellow

        VERSION = "0.1"
        YELLOW_SERVER = "https://" + (ENV["YELLOW_SERVER"] || "api.yellowpay.co")

    class YellowApiError < Exception ; end

    class Client
        def initialize(api_key, api_secret)
            @api_key = api_key
            @api_secret = api_secret
        end

        def create_invoice(base_ccy, base_price, callback)
            ####
            # This method creates a yellow invoices based on the bellow parameters:
            #
            # #param    str    base_ccy      required - a 3-letter currency code
            #                                (e.g. “AED”) representing the national 
            #                                currency used by the merchant.
            # #param    str    base_price    required - The invoice price in the 
            #                                national currency (e.g. “20”).
            # #param    str    callback      required - The callback URL we'll POST
            #                                payment notifications to.
            # #returns  JSON parsed data
            ####

            endpoint = "/v1/invoice/"

            body = { 
                        :base_ccy => base_ccy,
                        :base_price => base_price,
                        :callback => callback
                    }.to_json

            make_request('Post', endpoint, body)
        end

        def query_invoice(invoice_id)
            ####
            # Use this method to query an invoice you created earlier using its ID 
            #
            # #param    str    invoice_id    required - the ID of the invoice you're querying
            # 
            # #returns  JSON parsed data                                
            ####

            endpoint = "/v1/invoice/#{invoice_id}"
            make_request('Get', endpoint, "")
        end

        def verify_ipn
        end

        private
        def make_request(method, endpoint, body)
            url = YELLOW_SERVER + endpoint

            nonce = Time.now.to_i * 1000
            signature = get_signature(url, body, nonce, @api_secret)

            uri = URI.parse(YELLOW_SERVER)
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE

            if method == 'Get'
                request = Net::HTTP::Get.new(endpoint)
            elsif method == 'Post'
                request = Net::HTTP::Post.new(endpoint)
            end
            
            request.add_field('Content-Type', 'application/json')
            request.add_field('API-Key', @api_key)
            request.add_field('API-Nonce', nonce)
            request.add_field('API-Sign', signature)
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
            # A tiny function used by our SDK to sign and verify requests.
            ####
            message = nonce.to_s + url + body
            hash    = OpenSSL::HMAC.hexdigest('sha256', api_secret, message)
        end
    end
end