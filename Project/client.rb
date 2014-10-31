require 'socket'
 
host = 'localhost'
port = 8000                           

request = "Delete test.txt\n"

puts "Connecting to server...."
socket = TCPSocket.open(host,port)
puts "Connected to server\n\n"

puts "Sending request to server...."
#sleep(1)
socket.send(request, 0)
puts "Sent request to server\n\n"
response = socket.recv(1000000)
puts(response)