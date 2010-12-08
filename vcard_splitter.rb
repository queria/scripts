#!/usr/bin/env ruby

# your configuration: ----------------------------------
source_file = "std.vcf"
output_dir = "_parsed"

	# in my case ... splitted vCards was NOT binary equal with
	# those splitted by Kontact some time before
	# ... after inspecting them i realized
	# that they were only missing last crlf
	# so if you say 'true' here it will append
	# \n\r at end of each vcard file
append_crlf = true

# end of configuration ---------------------------------

class Kontakt
	attr_accessor :UID
	attr_accessor :content

	def initialize()
		@content = ""
	end
	def to_s
		"Kontakt["+@UID+"]"
	end
	def filename
		@UID + ".vcf"
	end
end

puts <<WLCM
Hello world ...
... of vCard splitters :)

WLCM

if not File.directory?( output_dir ) or not File.writable?( output_dir )
	puts "Sorry: output_dir='"+output_dir+"' is not writable directory!"
	exit 1
end
if not File.file? source_file or not File.readable? source_file
	puts "Sorry: source_file='"+source_file+"' is not readable file!"
	exit 1
end

f = File.new source_file

kontakty = {}
k = nil

print "parsing - please wait ... "
f.each_line { |line|
	if line[/^BEGIN:VCARD/]
		k = Kontakt.new
	end
	
	next if k.nil?

	k.content += line

	if line[/^UID/]
		k.UID = line[4,line.length].strip
		kontakty[ k.UID ] = k
	elsif line[/^END:VCARD/]
		k = nil
	end


}

puts "done"

print "\nwriting to files ...      "
kontakty.each_value { |kontakt|
	kf = File.new( File.join( output_dir, kontakt.filename ), "w" )
	kf.write( kontakt.content )

	kf.write( "\r\n" ) if append_crlf

	kf.close
}
puts "done\n\n"

