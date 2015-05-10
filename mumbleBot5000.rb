require 'rubygems'
#require 'bundler/setup'
require 'mumble-ruby'
require 'net/https'
require 'uri'
require 'json'
require 'base64'
require 'open-uri'
require "./serverInfoExample.rb"

class MambleBot
    
    @@currentChannel = Server.channel               # Set initial channel

	def log(msg)
		File.open('mumble.log', 'a') { |file| file.write(msg+"\n") }
	end
	
	# Initial info when bot joins channel
	
	def initInfo  
	    send("Type /help for a list of commands")
	    send("Use the /add [file name] to fix queue problems")
	end
	
	# Lists mumblebot commands
	 
	def help 
	    send("Commands:")
	    send("/p [file name]")
	    send("/add [file name]")
	    send("/update")
	    send("/channel [channel name]")
	    send("/d[number]")
	end
	
	# Used to fix bot not streaming when only 1 item is in the queue
	
	def addFile(msg)
	    msg = msg.strip
		file =	File.join("#{msg}.mp3")
		add = system( "mpc add #{file}" )           # Add sound to MPC queue
		if add
			send("File Added")
		else                                        # When no file with that name exists
			send("No File Found!")
		end
		sleep(1)
	end

    # Send message to user

	def send(msg)
		log Server.username+": "+msg
		@cli.text_channel @@currentChannel, msg
	end

    # Restart MPC to activate new sounds

	def reset
		reset = system("mpc update")
		if reset 
			send("MPC reset") 
		else 
			send("MPC not reset") 
		end
	end
    
    # Sync and reset at the same time
    
    def update
        reset()
    end
    
    # Instruct mumblebot to join a different channel

	def channel_commands(name)
	    name = name.strip.to_s
	    begin
            @cli.join_channel(name)
            @@currentChannel = name
        rescue                                      # In case invalid channel name is entered
            send("Invalid Channel Name")
        end
		sleep(1)
	end

    # Play an mp3 clip stored in the directory specified for Mumblebot

	def play(msg)
		msg = msg.strip
		@cli.player.stream_named_pipe(Server.namedPipe) # Point to pre-designated pipe file
		file =	File.join("#{msg}.mp3")
		add = system( "mpc add #{file}" )           # Add sound to MPC queue
		if add
			system( "mpc play 1" )           # Play sound in MPC queue
			system( "mpc del 1" )              # Remove sound from MPC queue
		else                                        # When no file with that name exists
			send("No File Found!")
		end
		sleep(1)
	end
	
	# Select a random file and play it
	def random
	    randomFile = Dir.entries(Server.audioFolder).sample
	    send(randomFile)
	    play(File.basename(randomFile,File.extname(randomFile)))
	end
	
	# Dice rolling simulator
	
	def roll_dice(d)
		if d != "1"
			return Random.rand(1...d.to_i).to_s 
		else
			return "It's 1, underachiever!"
		end
	end

    # Mumblebot starting actions

	def initialize
		`~/.dropbox-dist/dropboxd`
		@cli = Mumble::Client.new(Server.address, Server.port, Server.username, Server.password)            # Connect mumblebot using server info specified in serverInfo
		@cli.connect                                # Connect to CLI to handle inputs
		@cli.on_text_message do |msg|
			if @cli.users.has_key?(msg.actor)
				log @cli.users[msg.actor].name + ": " + msg.message
				case msg.message.to_s
				when /^(?:[\/\\]|)d(\d{1,3})$/      # Call roll_dice
					send roll_dice($1)
				when /^\/channel/                   # Call channel_commands
					channel_commands($')
				when /^\/update/                    # Call update
					update()
				when /^\/p/                      # Call play
					play($')
				when /^\/r/                         # Call random
				    random()                
				when /^\/add/                       # Call addFile
				    addFile($')
				when /^\/help/                      # Call help
				    help()
				when /^msg/ then send($')
				end
			end
		end
		sleep(1)
		@cli.join_channel(Server.channel)           # Join default channel
		initInfo()
		puts 'Press enter to terminate script';
		gets
		@cli.disconnect                             # Gracefully disconnect
	end
end

bot = MambleBot.new()
