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
  batch_mode = false

  if token == nil
    token = auth
    puts "Your token is '#{token}'"
    leave "Copy/paste into settings.rb then re-run this script"
  end

  tag = ARGV[0]
  group = nil

  if ARGV.size > 1
    group = fetch_group(token, ARGV[1])
    batch_mode = true
  else
    groups = fetch_moderated_groups(token)
    group = choose_group(groups)

    if !group
      leave "No group selected or not confirmed"
    end
  end

  photos = fetch_photos(token, group)
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
    remove_from_group(token, to_remove, group)
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

      if confirm == 'y'
        group = groups[index]
      end
    end
  end
  
  return group
end

def remove_from_group(token, photos, group)

  photos.each do |photo|
    url = FlickRaw.url_photopage(photo)
    puts "Removing photo #{url} from group #{group.name}"

    flickr.groups.pools.remove(:auth_token => token, :photo_id => photo.id, :group_id => group.id)
  end
end

def fetch_photos(token, group)
  puts "Fetching photos from group #{group.name}..."
  return flickr.groups.pools.getPhotos(:auth_token => token, :group_id => group.id, :extras => 'tags', :per_page => 500)
end

def fetch_group(token, group_id)
  return flickr.groups.getInfo(:auth_token => token, :group_id => group_id)
end

def has_tag?(photo, tag)
  return photo.tags =~ /\b#{tag}\b/
end

def fetch_moderated_groups(token)
  puts "Fetching groups..."
  groups = flickr.groups.pools.getGroups(:auth_token => token)
  return groups.inject([]) do |mod_groups, group|
    mod_groups << group if group.admin == 1

    mod_groups
  end
end

def auth
  frob = flickr.auth.getFrob
  auth_url = FlickRaw.auth_url :frob => frob, :perms => 'write'
  token = nil

  puts "Open this url in your browser to complete the authentication process:"
  puts "#{auth_url}"
  puts "Press Enter when you are finished."
  $stdin.getc

  begin
    auth = flickr.auth.getToken :frob => frob
    login = flickr.test.login
    puts "You are now authenticated as #{login.username}"
    token = auth.token
  rescue FlickRaw::FailedResponse => e
    $stderr.puts "Authentication failed : #{e.msg}"
  end

  return token
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
