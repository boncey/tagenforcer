## Simple command line script to check photos in a Flickr group pool contain a specified tag and optionally remove non-compliant photos from the group.

**Not for beginners!**

### Requirements

* A working version of [Ruby](http://www.ruby-lang.org/)
* A recent-ish version of the [flickraw](http://hanklords.github.com/flickraw/) gem
* Your own API key and shared secret from the [Flickr API](http://www.flickr.com/services/api/)

It's expected that you are fairly comfortable using the command line and working with the Flickr API if you want to use this script.


### Usage
Install Ruby and flickraw.

Go to the [Flickr API page](http://www.flickr.com/services/api/) - click on 'API Keys' and generate an API key and shared secret.

Paste the values into settings.rb.

Run tagenforcer.rb once to authenticate against the Flickr API and fetch the token and secret then paste into settings.rb.
You're now ready to go.

tagenforcer has an interactive mode and a batch mode.

#### Interactive mode
Usage: `tagenforcer.rb <required tag>`  
In interactive mode tagenforcer will load all the groups you're an admin of.
You can then choose one and it then checks and offers to remove photos from that group's pool.
It will prompt for confirmation before removing any photos.


#### Batch mode
Usage: `tagenforcer.rb <required tag> <flickr group nsid>`  
This is designed to be used from cron jobs etc and removes photos without any prompts.
You can grab the group's NSID from using it in interactive mode.
