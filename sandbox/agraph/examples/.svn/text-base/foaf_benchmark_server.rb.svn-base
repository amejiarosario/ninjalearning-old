require 'socket'

def choose_response request
  case request
  when /query=/
    <<EOD
HTTP/1.1 200  OK
Date: Sat, 20 Oct 2007 15:47:17 GMT
Connection: Close
Content-Type: application/sparql-results+xml

<?xml version="1.0"?>
<sparql xmlns="http://www.w3.org/2005/sparql-results#">
  <head>
    <variable name="s"/>
  </head>
  <results ordered="false" distinct="false">
    <result>
      <binding name="s">
        <uri>http://example.org/stuff/Bond</uri>
      </binding>
    </result>
  </results>
</sparql>
EOD
  when /statements/
    <<EOD
HTTP/1.1 200  OK
Date: Sat, 20 Oct 2007 15:49:33 GMT
Connection: Close
Content-Type: application/rdf+ntriples

<http://example.org/stuff/Bond> <http://xmlns.com/foaf/0.1/name> "James Bond" .
EOD
  end
end

server = TCPServer.new('127.0.0.1', 8112)
while (socket = server.accept)
  request = socket.gets
  socket.write(choose_response(request))
  socket.close
end
