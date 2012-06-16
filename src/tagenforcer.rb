#!/usr/bin/env ruby

$:.push(File.dirname(__FILE__))

require 'rubygems'
require 'flickraw'
require 'settings'

def main
  setup if ARGV.empty?

  FlickRaw.api_key = Settings::API_KEY
  FlickRaw.shared_secret = Settings::SHARED_SECRET
  token = Settings::TOKEN
  secret = Settings::SECRET
  batch_mode = false

  if token == nil || token.empty?
    begin
      token = auth
      puts "Modify settings.rb as below then re-run this script"
      puts
      puts "TOKEN = '#{flickr.access_token}'"
      puts "SECRET = '#{flickr.access_secret}'"
      puts
      exit(-1)
    rescue FlickRaw::OAuthClient::FailedResponse => e
      leave("Authentication failed : #{e}")
    end
  else
    flickr = FlickRaw::Flickr.new
    flickr.access_token = token
    flickr.access_secret = secret

    login = flickr.test.login
    puts "You are authenticated as #{login.username}"
  end

  tag = ARGV[0]
  group = nil

  if ARGV.size > 1
    group = fetch_group(flickr, ARGV[1])
    batch_mode = true
  else
    groups = fetch_moderated_groups(flickr)
    group = choose_group(groups)

    if !group
      leave "No group selected or not confirmed"
    end
  end

  photos = fetch_photos(flickr, group)
  to_remove = photos.inject([]) do |to_remove, photo|
    to_remove << photo if (!has_tag?(photo, tag))

    to_remove
  end

  leave "All photos in group #{group.name} appear to have the tag #{tag}" if to_remove.empty?

  puts "Found #{to_remove.size} photos without tag #{tag}"

  confirm_remove = batch_mode
  if !batch_mode
    puts "Remove them all from the group (y/N)?"
    confirm_remove = $stdin.gets.chomp == 'y'
  end

  if confirm_remove
    remove_from_group(flickr, to_remove, group)
  else
    puts "No photos removed from group"
  end
end

def choose_group(groups)
  group = nil

  i = 1
  groups.each do |gr|
    puts "#{i}) #{gr.name} (#{gr.nsid})"
    i = i + 1
  end

  puts
  puts "Choose a group by number"
  num = $stdin.gets.chomp

  if num && num.to_i <= i && num.to_i > 0
    index = num.to_i - 1
    if groups[index]
      puts "You chose #{groups[index].name}"
      puts "Are you sure (y/N)"

      confirm = $stdin.gets.chomp

      group = groups[index] if confirm == 'y'
    end
  end

  group
end

def remove_from_group(flickr, photos, group)

  photos.each do |photo|
    url = FlickRaw.url_photopage(photo)
    puts "Removing photo #{url} from group #{group.name}"

    flickr.groups.pools.remove(:photo_id => photo.id, :group_id => group.id)
  end
end

def fetch_photos(flickr, group)
  puts "Fetching photos from group #{group.name}..."
  flickr.groups.pools.getPhotos(:group_id => group.id, :extras => 'tags', :per_page => 500)
end

def fetch_group(flickr, group_id)
  flickr.groups.getInfo(:group_id => group_id)
end

def has_tag?(photo, tag)
  photo.tags =~ /\b#{tag}\b/
end

def fetch_moderated_groups(flickr)
  puts "Fetching groups..."
  groups = flickr.groups.pools.getGroups()
  return groups.inject([]) do |mod_groups, group|
    mod_groups << group if group.admin

    mod_groups
  end
end

def auth
  token = flickr.get_request_token
  auth_url = flickr.get_authorize_url(token['oauth_token'], :perms => 'write')

  puts "Open this url in your browser to complete the authentication process:"
  puts "#{auth_url}"
  `open #{auth_url}`
  puts "Copy here the number given when you complete the process."
  verify = $stdin.gets.strip

  flickr.get_access_token(token['oauth_token'], token['oauth_token_secret'], verify)
  login = flickr.test.login
  puts "You are now authenticated as #{login.username}"
end

def setup
print <<"EOF";
Usage: tagenforcer.rb <required tag>
       Prompt for a group to choose from then check and remove photos from that group's pool
       Will prompt for confirmation before removing any photos

Usage: tagenforcer.rb <required tag> <flickr group nsid>
       Check the pool of the specified group and remove photos from that group's pool
       This does not prompt for confirmation - it's designed to be used from cron jobs etc
EOF

  leave
end

def leave(msg = '')
  puts msg
  puts "Exiting..."

  exit(-1)
end

main
