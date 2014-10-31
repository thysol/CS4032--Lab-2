require 'socket'  
require 'thread'

THREADS = 8
PORTNUMBER = ARGV[0]
DIRECTORYNAME = "C:\\Users\\Henrik\\Documents\\CS4032\\Project\\File_System\\"
MAXFILESIZE = 1073741824

freeThreads = THREADS
semaphore = Mutex.new
clients = Queue.new

def default(message)
   
end

def getFileName(message)
	filename = message.split(" ", 2)
	filename = filename[1].split("\n", 2)
	return filename[0]
end

def getData(message)
	data = message.split("\n", 2)
	
	return data[1]
end

def openFile(filename)
	file = File.new(filename, "r")
	return file	
end

def readFile(file)
	data =  file.sysread(MAXFILESIZE)
	file.close
	return data
end

def writeFile(filename, data)
	deleteFile(filename)
	file = File.new(filename, "w")
	file.syswrite(data)
	file.close
end

def deleteFile(filename)
	begin
		File.delete(filename)
		
	rescue	
		puts("File doesn't exist, no problem....")
		
	end
end

Dir.chdir DIRECTORYNAME

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
							begin 
							response = client.recv(1000000)
							puts("Received message from client: ")
							puts(response)
							
							if (response == "")
								puts("Disconnecting...")
								break
							end
							
							if (response.casecmp("KILL_SERVICE\n") == 0)
								puts("Received KILL_SERVICE message from client. Shutting down....")
								exit!
							
							elsif (response[0...4].casecmp("HELO") == 0)
								puts("Sending response: ")
								answer = response + "IP:" + UDPSocket.open {|s| s.connect("64.233.187.99", 1); s.addr.last} + "\nPort:" + PORTNUMBER.to_s + "\nStudentID:11449298"
								puts(answer)
								
								begin
									client.send(answer, 0)
								
								rescue
									puts("Error sending message")
									
								end
	
							elsif (response[0...8].casecmp("Download") == 0)
								filename = getFileName(response)
								
								file = openFile(filename)
								data = readFile(file)
								
								begin
									client.send(data, 0)
								
								rescue
									puts("Error sending message")
									
								end
							
							elsif (response[0...6].casecmp("Upload") == 0)
								filename = getFileName(response)
								data = getData(response)
								
								writeFile(filename, data)
							
							elsif (response[0...6].casecmp("Delete") == 0)
								filename = getFileName(response)
								
								deleteFile(filename)
								
							else
								default(response)
							end
							
							rescue Exception => e
								puts e.message
								puts ("Something went wrong....")
								
								if (not updated)
									semaphore.synchronize do
										freeThreads += 1
									end
								end
							
							break
							end
						end
						
						puts("Closing client connection")
						
						client.close
						
						semaphore.synchronize do
							freeThreads += 1
							updated = true
						end
						
					rescue Exception => e
						puts e.message
						puts ("Client disconnect")
						
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
