module Rack
  module Handler
    class CGI
      def self.serve(app)
        env = ENV.to_hash
        env.delete "HTTP_CONTENT_LENGTH"

        env.update({"rack.version" => [0,1],
                     "rack.input" => STDIN,
                     "rack.errors" => STDERR,
                     
                     "rack.multithread" => false,
                     "rack.multiprocess" => true,
                     "rack.run_once" => true,
                     
                     "rack.url_scheme" => ["yes", "on", "1"].include?(ENV["HTTPS"]) ? "https" : "http"
                   })
        
        env["QUERY_STRING"] ||= ""
        env["HTTP_VERSION"] ||= env["SERVER_PROTOCOL"]
        env["REQUEST_PATH"] ||= "/"
        
        status, headers, body = app.call(env)
        send_headers status, headers
        send_body body
      end
      
      def self.send_headers(status, headers)
        STDOUT.print "Status: #{status}\r\n"
        headers.each { |k, vs|
          vs.each { |v|
            STDOUT.print "#{k}: #{v}\r\n"
          }
        }
        STDOUT.print "\r\n"
        STDOUT.flush
      end
      
      def self.send_body(body)
        body.each { |part|
          STDOUT.print part
          STDOUT.flush
        }
        body.close  if body.respond_to? :close
      end
    end
  end
end