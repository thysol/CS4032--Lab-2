require 'socket'  
require 'thread'

THREADS = 4
PORTNUMBER = ARGV[0]

freeThreads = THREADS
semaphore = Mutex.new
clients = Queue.new

def default(message)
   
end

server = TCPServer.open(PORTNUMBER)

workers = (0...THREADS).map do
	Thread.new do
		begin
			loop do
				updated = false
				client = clients.pop()
				if (client != nil)
					begin
						loop do 
							response = client.gets
							puts("Received message from client: ")
							puts(response)
							
							if (response.casecmp("KILL_SERVICE\n") == 0)
								puts("Received KILL_SERVICE message from client. Shutting down....")
								exit!
							
							elsif (response[0...4].casecmp("HELO") == 0)
								puts("Sending response: ")
								ip = UDPSocket.open {|s| s.connect("64.233.187.99", 1); s.addr.last}
								answer = response + "IP:" + ip + "\nPort:" + PORTNUMBER.to_s + "\nStudentID:11449298"
								puts(answer)
								
								client.send(answer, 0)
								puts("Sent message")
	
							else
								default(response)
							end
						end
						client.close
						
						semaphore.synchronize do
							freeThreads += 1
							updated = true
						end
						
					rescue Exception => e
						puts e.message
						
						if (not updated)
							semaphore.synchronize do
								freeThreads += 1
							end
						end
					end
				else
					sleep(1.0/8.0)
				end
			end
			rescue ThreadError
		end
	end
end

loop do
	client = server.accept
	
	puts("Free Threads: " + freeThreads.to_s)
	
	if (freeThreads > 0)
		clients << client
	
		semaphore.synchronize do
			freeThreads -= 1
		end

	else
		puts("Server overloaded! Rejected client!")
		client.puts("Server overloaded! Please try again later....")
		client.close
	end
end
