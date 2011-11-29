#!/usr/bin/env ruby
require 'yaml'
require 'pathname'
require 'fileutils'

def help
	puts <<HELP
 $ update_repos.rb [path_to_config_file]

 Config file has to be YAML file with at least source_path, target_path and git_baseurl.

 If no path_to_config_file is specified, './update_repos.yml'
  placed next to this script will be used.

  * source_path: where to find repository names
      (like '/home/git/repos' if /home/git/repos/{project,books,kernel,etc}.git etc exists)

  * target_path: where to clone/update repositories
      (like '/home/redmine/external_repos')

  * git_baseurl: prefix for building repository urls
      (like 'git@github.com:' [including ending colon])

  * ignore_repos: colon separated list of repository names to skip
      (from example above we could say 'books.git:etc.git')

  * run_after: string which will be executed after update
      (some shell commands etc, optional)

 so example config.yml could be:
   ---
   source_path: '/home/git/repositories'
   target_path: '/home/redmine/external_repos'
   git_baseurl: 'git@github.com:'
   ignore_repos: 'books.git:etc.git'
   run_after: 'wget -O /dev/null http://redmine.domain/sys/fetch_changesets?key=xyz'
   ...
 
 ---------------------------------------------------------
 Created at 10/2011 by Queria Sa-Tas <public@sa-tas.net>
 sa-tas.net || github.com/queria/
 Published under FreeBSD License (use --license option)
HELP
end

def license
	puts <<LICENSE
 Copyright 2011 Queria Sa-Tas. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are
 permitted provided that the following conditions are met:
 
 	1. Redistributions of source code must retain the above copyright notice, this list of
 	conditions and the following disclaimer.
 
 	2. Redistributions in binary form must reproduce the above copyright notice, this list
 	of conditions and the following disclaimer in the documentation and/or other materials
 	 provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY Queria Sa-Tas ''AS IS'' AND ANY EXPRESS OR IMPLIED
 WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Queria Sa-Tas OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
LICENSE
end

def find_repos(source_path, ignore_names)
	repos = []
	to_scan = [source_path]
	while not to_scan.empty?
		scan_dir = to_scan.pop
		scan_dir.children.each do |child|
			next if not child.directory?
			if child.extname.eql? '.git'
				repo_name = child.to_s[source_path.to_s.length() + 1 .. -1]
				next if ignore_names.include? repo_name
				repos << repo_name
			else
				to_scan << child
			end
		end
	end
	return repos
end

def update_repo(repo_path, repo_name)
	Dir.chdir repo_path

	%x(git fetch origin +refs/heads/*:refs/heads/* 2>&1)
	puts "#{repo_name} update failed" unless $?.success?

end

def clone_repo(repo_path, repo_name, git_baseurl)
	if not repo_path.parent.exist?
		FileUtils.mkpath( repo_path.parent, :mode => 0700 )
	end
	Dir.chdir repo_path.parent

	puts "New repository found: #{git_baseurl}#{repo_name}"
	%x(git clone --bare #{git_baseurl}#{repo_name} #{repo_path.basename} 2>&1)
	puts "#{repo_name} clone failed" unless $?.success?
end

def update_repos(git_baseurl, target_path, repos)
	repos.each do |repo_name|

		repo_path = (target_path + repo_name)

		if repo_path.directory?
			update_repo repo_path, repo_name
		else
			clone_repo repo_path, repo_name, git_baseurl
		end
	end
end

if ARGV.include? '--license'
	license
	exit 0
end

config_path = Pathname.new('./update_repos.yml')
config_path = Pathname.new(ARGV[0]) if ARGV[0]

if config_path.relative?
	config_path = (Pathname($0).realpath().dirname() + config_path)
end

unless config_path.exist?
	puts ''
	puts " Missing path to config file: #{config_path}"
	help
	exit 1
end

config = YAML::load_file(config_path)
source_path = Pathname.new(config['source_path'])
target_path = Pathname.new(config['target_path'])
git_baseurl = config['git_baseurl']
ignore_names = config['ignore_names'].split(':') unless config['ignore_names'].nil?


if source_path.nil? or not source_path.directory? \
	or target_path.nil? or not target_path.directory? \
	or git_baseurl.nil?
	puts ''
	puts ' Missing configuration options:'
	help
	exit 2
end


update_repos(
	git_baseurl,
	target_path,
	find_repos(source_path, ignore_names))

if config['run_after']
	`#{config['run_after']}`
end

