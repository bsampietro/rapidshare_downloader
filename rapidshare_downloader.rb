#!/usr/bin/ruby

require 'rubygems'
require 'hpricot'
require 'mechanize'

HELP = "\n-------- HELP FOR rapidshare_downloader --------- \n\n" << \
		 "rapidshare_downloader RAPIDSHARE_URLS...(separated by spaces) DOWNLOAD_DIRECTORY \n\n" << \
		 "Example: rapidshare_downloader http://rapidshare.com/something1 http://rapidshare.com/something2 /home/myname/somedirectorypath \n\n" << \
		 "Or you can also call it this way(which is more practical): \n\n" << \
		 "rapidshare_downloader DOWNLOAD_FILE \n\n" << \
		 "where DOWNLOADFILE is a text file containing on each line a rapidshare address, and in the last line an existing directory in the filesystem \n\n" << \
		 "Example of a \"DOWNLOADFILE\": \n" << \
		 "http://rapidshare.com/something1 \n" << \
		 "http://rapidshare.com/something2 \n" << \
		 "/home/myname/somedirectorypath \n\n" << \
		 "Empty lines and lines starting with \"#\" are not read. \n"
PLUS_SECS = 5 # Amount of extra secs to wait
USER_AGENT = 'Linux Mozilla'

def get_paths(filename)
  paths = Array.new
  File.open(filename) do |file|
	 line = nil
	 while (line = file.gets)
		line = line.strip
		paths << line unless (line == '' || line[0,1] == '#')
	 end
  end
  paths
end

# --------- Main Program Here -----------

path = nil 
paths = nil
not_downloaded_files = Array.new 

if ARGV.length == 0
  puts HELP
  exit
elsif ARGV.length == 1
  begin
	 paths = get_paths(ARGV[0])
  rescue
	 puts 'There was a problem opening the input file.'
	 exit
  end
else
  paths = ARGV
end

if !File.directory?(paths.last)
  puts 'The last argument should be a directory and the directory should exist.'
  exit
elsif !File.writable?(paths.last)
  puts 'You do not have permissions to write on the specified directory.'
  exit
end

agent = WWW::Mechanize.new
agent.user_agent_alias = USER_AGENT
agent.redirect_ok = true

paths.each do |path|
  if path != paths.last
	 begin
		page = agent.get(path)
		page = agent.submit(page.forms.first)
		wait_time = page.root.to_s.slice(%r{var c=(.*?);}).match(/\d+/)[0].to_s.to_i
		extracted_form = page.root.to_s.slice(%r{<form name="dlf"(.*?)</form>}m).gsub!(/[+']|onclick="(.*?)"/, '')
		hform = WWW::Mechanize::Form.new(Hpricot(extracted_form).at('form'))  
		puts "Downloading from: #{path}."
		sleep (wait_time + PLUS_SECS)
		file = agent.submit(hform)
		file.save_as(File.join(File.expand_path(paths.last), file.filename))
		file = nil
		ObjectSpace.garbage_collect
	 rescue 
		puts "There was a problem downloading the file from url: #{path}."  
		not_downloaded_files << path
	 else
		puts "The file from the url: #{path} was downloaded succesfully."
	 end
  end
end

puts 'The download session has finished.'
if not_downloaded_files.length > 0
  puts "The following file(s) could not be downloaded:"
  puts not_downloaded_files
end
