require 'yellow-sdk'
require 'time'
require "openssl" 
 
DEFAULT_KEY = "KEY" 
DEFAULT_SECRET = "SECRET"
API_KEY = ENV['TEST_API_KEY']
API_SECRET = ENV['TEST_API_SECRET']
CALLBACK = "https://example.com/ipn"
BASE_CCY = "USD"
BASE_PRICE = "0.30000000"
STYLE = "cart"
ORDER = "1234567"
test_invoice_id = ""

describe Yellow::Client do
    
    describe "#create_invoice" do
      it "should create basic invoice" do
        yellow = Yellow::Client.new(API_KEY, API_SECRET)
        
        options = { 
                   :base_ccy => BASE_CCY,
                   :base_price => BASE_PRICE,
                   :callback => CALLBACK,
                   :style => STYLE,
                   :order => ORDER
                  }

        invoice = yellow.create_invoice(options)
        
        expect(invoice['status']).to eq("loading")
        expect(invoice['received']).to eq("0")
        expect(invoice['invoice_ccy']).to eq("BTC")
        expect(invoice['callback']).to eq(CALLBACK)
        expect(invoice['order']).to eq(ORDER)
        expect(invoice['style']).to eq(STYLE)
        expect(invoice['base_ccy']).to eq(BASE_CCY)
        expect(invoice['base_price']).to eq(BASE_PRICE)
        expect(invoice['remaining']).to eq(invoice['invoice_price'])
        expect(invoice['id'].length).to eq(26)
        
        expiration = DateTime.iso8601(invoice['expiration'])
        server_time = DateTime.iso8601(invoice['server_time'])
        
        expect(expiration > server_time).to be true
        
        test_invoice_id = invoice['id']
      end
      
      it "should return authentication error" do
        yellow = Yellow::Client.new(DEFAULT_KEY, DEFAULT_SECRET)
        
        options = { 
                   :base_ccy => BASE_CCY,
                   :base_price => BASE_PRICE,
                   :callback => CALLBACK,
                   :style => STYLE,
                   :order => ORDER
                  }
        
        expect {yellow.create_invoice(options)}.to raise_error(Yellow::YellowApiError)
      end
      
      it "should return nonce error" do
        yellow = Yellow::Client.new(API_KEY, API_SECRET)
        
        options = { 
                   :base_ccy => BASE_CCY,
                   :base_price => BASE_PRICE,
                   :callback => CALLBACK,
                   :style => STYLE,
                   :order => ORDER
                  }

        @time_now = Time.parse("Dec 29 1992")
        Time.stub(:now).and_return(@time_now)
        
        expect {yellow.create_invoice(options)}.to raise_error(Yellow::YellowApiError)
      end
      
      it "should return minimum price error" do
        yellow = Yellow::Client.new(API_KEY, API_SECRET)
        
        options = { 
                   :base_ccy => BASE_CCY,
                   :base_price => '0.01',
                   :callback => CALLBACK,
                   :style => STYLE,
                   :order => ORDER
                  }
  
        expect {yellow.create_invoice(options)}.to raise_error(Yellow::YellowApiError)
      end
      
      it "should return base_ccy error" do
        yellow = Yellow::Client.new(API_KEY, API_SECRET)
        
        options = { 
                   :base_ccy => 'xxx',
                   :base_price => BASE_PRICE,
                   :callback => CALLBACK,
                   :style => STYLE,
                   :order => ORDER
                  }
  
        expect {yellow.create_invoice(options)}.to raise_error(Yellow::YellowApiError)
      end
      
      it "should return callback error" do
        yellow = Yellow::Client.new(API_KEY, API_SECRET)
        
        options = { 
                   :base_ccy => BASE_CCY,
                   :base_price => BASE_PRICE,
                   :callback => 'xxx',
                   :style => STYLE,
                   :order => ORDER
                  }
  
        expect {yellow.create_invoice(options)}.to raise_error(Yellow::YellowApiError)
      end  
    end
    
    
    
    
    describe "#query_invoice" do
      it "should query invoice" do
        yellow = Yellow::Client.new(API_KEY, API_SECRET)

        invoice = yellow.query_invoice(test_invoice_id)
        
        expect(invoice['status']).to eq("new")
        expect(invoice['received']).to eq("0")
        expect(invoice['invoice_ccy']).to eq("BTC")
        expect(invoice['callback']).to eq(CALLBACK)
        expect(invoice['order']).to eq(ORDER)
        expect(invoice['style']).to eq(STYLE)
        expect(invoice['base_ccy']).to eq(BASE_CCY)
        expect(invoice['base_price']).to eq(BASE_PRICE)
        expect(invoice['remaining']).to eq(invoice['invoice_price'])
        expect(invoice['id'].length).to eq(26)
        
        expiration = DateTime.iso8601(invoice['expiration'])
        server_time = DateTime.iso8601(invoice['server_time'])
        
        expect(expiration > server_time).to be true
      end
      
      it "should raise authentication error" do
        yellow = Yellow::Client.new(DEFAULT_KEY, DEFAULT_SECRET)  
        expect {yellow.query_invoice(test_invoice_id)}.to raise_error(Yellow::YellowApiError)
      end
      
      it "should return nonce error" do
        yellow = Yellow::Client.new(API_KEY, API_SECRET)
        
        @time_now = Time.parse("Dec 29 1992")
        Time.stub(:now).and_return(@time_now)
        
        expect {yellow.query_invoice(test_invoice_id)}.to raise_error(Yellow::YellowApiError)
      end
    end
    
    
    
    
    describe "#verify_ipn" do
      it "should verify IPN" do
        yellow = Yellow::Client.new(API_KEY, API_SECRET)
        
        body = {
                "id" => "K8UVTJXK8VNQFQK7QXU3NJVT3A",
                "order" => "1234567", 
                "url" => "//cdn.yellowpay.co/invoice.7b371676.html?invoiceId=K8UVTJXK8VNQFQK7QXU3NJVT3A", 
                "address" => "1682NqBscHgiHD8TBkgSshd4yBAtjhfi76", 
                "base_price" => "0.30000000", 
                "base_ccy" => "USD", 
                "invoice_price" => "0.00107", 
                "invoice_ccy" => "BTC", 
                "expiration" => "2015-08-02T16:21:08.596Z", 
                "server_time" => "2015-08-02T16:11:08.662Z", 
                "callback" => "https://example.com/ipn", 
                "status" => "loading", 
                "received" => "0", 
                "remaining" => "0.00107", 
                "style" => "cart"
               }.to_s
               
        nonce = Time.now.to_f * 1000
        signature = get_signature(body['callback'], body, nonce, API_SECRET)
        
        is_verified = yellow.verify_ipn(body['callback'], signature, nonce, body)
        
        expect(is_verified).to be true
      end
      
      it "should NOT verify IPN" do
        yellow = Yellow::Client.new(API_KEY, API_SECRET)
        
        body = {
                "id" => "K8UVTJXK8VNQFQK7QXU3NJVT3A",
                "order" => "1234567", 
                "url" => "//cdn.yellowpay.co/invoice.7b371676.html?invoiceId=K8UVTJXK8VNQFQK7QXU3NJVT3A", 
                "address" => "1682NqBscHgiHD8TBkgSshd4yBAtjhfi76", 
                "base_price" => "0.30000000", 
                "base_ccy" => "USD", 
                "invoice_price" => "0.00107", 
                "invoice_ccy" => "BTC", 
                "expiration" => "2015-08-02T16:21:08.596Z", 
                "server_time" => "2015-08-02T16:11:08.662Z", 
                "callback" => "https://example.com/ipn", 
                "status" => "loading", 
                "received" => "0", 
                "remaining" => "0.00107", 
                "style" => "cart"
               }.to_s
               
        nonce = Time.now.to_f * 1000
        signature = get_signature(body['callback'], body, nonce, API_SECRET)
        malicious_nonce = '1433708553718';
        
        is_verified = yellow.verify_ipn(body['callback'], signature, malicious_nonce, body)
        
        expect(is_verified).to be false
      end
    end
end


def get_signature(url, body, nonce, api_secret)
    message = nonce.to_s + url + body
    hash    = OpenSSL::HMAC.hexdigest('sha256', api_secret, message)
end
