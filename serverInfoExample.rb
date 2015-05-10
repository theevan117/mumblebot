module Server
	def Server.address
		return address = 'test.test.com'
	end
	def Server.port
		return port = 1234
	end
	def Server.username
		return username = 'test'
	end
	def Server.password
		return password = 'testPassword'
	end
	def Server.channel
		return channel = 'chat'
	end
	def Server.namedPipe
	    return namedPipe = "/audio/myFifo.fifo"
	end
	def Server.audioFolder
	    return audioFolder = "/audio/"
    end
end