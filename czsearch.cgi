#!/usr/bin/ruby
require 'uri'
require 'net/http'
require 'yaml'
require 'cgi'

class Logger
	QUIET = 0
	WARN = 1
	INFO = 2
	DEBUG = 3

	@@level = Logger::DEBUG
	@@messages = []

	def Logger.level
		return @@level
	end
	def Logger.level=(new_level)
		@@level = new_level
	end

	def Logger.log(level, message)
		if level == 0
			raise 'Sending zero level log messages is prohibited! Zero is meant for quiet behavior'
		end

		if level <= @@level
			@@messages << message
		end
	end

	def Logger.messages
		return @@messages
	end
end

class CZShareParser
    def initialize()
		@line_regexps = {
            'name'=>Regexp.new('<a[^>]+>(.*)</a>'),
            'url'=>Regexp.new('<a href="([^"]+)"'),
            'size'=>Regexp.new('<td class="col4">(.*)</td>'),
            'desc'=>Regexp.new("</a>[ \t]*(.*?)[ \t]*</td>")
		}
        @next_regexp = Regexp.new('<a href="([^"]+)" class="btn-next">')
	end

	def parse_line(line)
		parsed = {}
		@line_regexps.each_key { |k|
			m = @line_regexps[k].match(line)
			if m
				parsed[k] = m[1].strip
			else
				parsed[k] = ''
			end
		}
		if parsed['name'].empty?
			Logger.log(Logger::WARN, line)
		end
		#parsed['name'] = 'ERROR - ' + parsed['url'] if parsed['name'].empty?
		return parsed
	end

    def find_next(line)
        url = @next_regexp.match(line)
        if url:
			if url[1].include? 't=txt'
				Logger.log(Logger::INFO, 'found next url: '+url.to_s)
				if not url[1][0] == '/'
					return '/'+url[1]
				end
				return url[1]
			end
		end
        return nil
	end
end
class CZShare

	def initialize()
		@server = 'czshare.com'
		@parser = CZShareParser.new
		@con = Net::HTTP.new(@server, 80)
	end

	def parse_page(lines)
		Logger.log(Logger::INFO, 'parsing page with '+lines.size.to_s+' lines')
		Logger.log(Logger::INFO, lines.to_s.length.to_s)
		waiting_for_table = false
		started = false

		downloads = []
		next_url = nil

		lines.each do |line|
			#line.strip!

			if not next_url
				next_url = @parser.find_next(line)
			end

			if line.include? 'id="tab-table-all"'
				waiting_for_table = true
			end

			if waiting_for_table and line.include? '<table>'
				waiting_for_table = false
				started = true
			end

			if started and line.include? 'col2'
				downloads << @parser.parse_line(line)
			end

			if started and line.include? '</table>'
				started = false
				break
			end
		end

		return {'downloads'=>downloads, 'next'=>next_url }
	end

	def load_search(page_url)
		Logger.log(Logger::INFO, 'loading page ' + page_url)

		page_source = ''
		@con.get(page_url) { |body|
			page_source += body
		}
		return parse_page(page_source.split("\n"))
	end


	def search(term)
		Logger.log(Logger::INFO, 'searching for '+term)
		downloads = []
		next_url = '/search.php?q='+URI.escape(term)
		while next_url
			res = load_search(next_url)
			downloads = downloads + res['downloads']
			next_url = res['next']
		end
		#downloads.sort(key=lambda d: d['name'])
		downloads.sort! { |a,b| a['name'] <=> b['name'] }
		return downloads
	end
end

class Printer
	def initialize
		@use_html = true
	end

	def use_html
		return @use_html
	end
	def use_html=(should_use_html)
		@use_html = should_use_html
	end

	def out(txt)
		puts(txt)
	end

	def print_downloads(downloads)
		out('<div class="downloads">')
		out("<div class=\"count\">Found #{downloads.size} entries (displayed <span id=\"displayedCount\">#{downloads.size}</span>):</div>")
		downloads.each_with_index do |down, idx|
			out('<div class="download">' + idx.to_s + ') ' +
			"<a target=\"_blank\" href=\"#{down['url']}\">#{down['name']}</a>" +
			' - '+down['size']+' - '+down['desc'] +
			'</div>')
			$stdout.flush
		end
		out('</div>')
	end

	def print_header(term)
		return if not @use_html
		out('Content-Type: text/html')
		out('')
		out('<! DOCTYPE html >')
		out('<html>')
		out('<head>')
		out('<meta charset="utf-8"><title>CZShare Search</title>')
		out('<style>')
		out('.error { color:red; }')
		out('.download { font-size:11px; }')
		out('.log { color: #ccc; background-color:#333; font-size:x-small; margin-top: 2em; border-top: 1px solid gray; }')
		out('.log { height: 1.1em; overflow:hidden;}')
		out('.log:hover { height: auto; }')
		out('</style>')
		out('<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.6.4/jquery.min.js"></script>')
		out('<script type="text/javascript">')
		out('$(document).ready(function() {')
		out('	var filterInput = $("#filter");')
		out('	var filterTimeOut = 0;')
		out('	var lastFilter = "";')
		out('	var allDown = $(".download");')
		out('	var displayedCount = $("#displayedCount");')
		out('	var doFilter = function () { ')
		out('		var fv = $.trim(filterInput.val()).toLowerCase();')
		out('		if( fv == lastFilter ) { return; } else { lastFilter = fv; }')
		out('		var displ = 0;')
		out('		allDown.each(function(){')
		out('			var d = $(this);')
		out('			if(!d.attr("textLower")) { d.attr("textLower", d.text().toLowerCase()); }')
		out('			if(fv == "" || d.attr("textLower").indexOf(fv) != -1) {')
		out('				d.show();')
		out('				displ++;')
		out('			} else { ')
		out('				d.hide();')
		out('			}')
		out('		});')
		out('		displayedCount.text(displ);')
		out('	};')
		out('	var requestFilter = function () { ')
		out('		clearTimeout(filterTimeOut);')
		out('		filterTimeOut = setTimeout(doFilter, 250);')
		out('	};')
		out('	filterInput.bind("change", requestFilter);')
		out('	filterInput.bind("input", requestFilter);')
		out('	filterInput.bind("keyup", requestFilter);')
		out('});')
		out('</script>')
		out('</head>')
		out('<body><h1>CZShare Search</h1>')
		out('<form action="" method="post"><div>')
		out('<label for="term">What to look for?</label>')
		out('<input type="text" name="term" id="term" value="'+term+'" />')
		out('<input type="submit" value="Search" />')
		out('</div></form>')
		out('<div>Filter results: <input type="text" id="filter" /></div>');
		$stdout.flush
	end

	def print_footer
		print_logs
		return if not @use_html
		out('</body>')
		out('</html>')
	end

	def print_logs
		out('<div class="log">')
		out('Progress log:<br />')
		Logger.messages.each do |msg|
			out('<div class="message">')
			out(CGI.escapeHTML(msg))
			out('</div>')
		end
		out('</div>')
	end
end

cgi = CGI.new
czs = CZShare.new
printer = Printer.new

if cgi.key? 'plaintext'
	printer.use_html = false
end

printer.print_header cgi['term']

if cgi.key?('inputfile')
	p czs.parse_page(open(cgi['inputfile']))
elsif cgi.key?('term')
	downloads = czs.search(cgi['term'])
	printer.print_downloads(downloads)
end

printer.print_footer

