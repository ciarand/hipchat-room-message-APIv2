#!/usr/bin/env perl -w
#
# Perl script to send a notification to hipchat using either the REST API v1 or v2.
#
# Created by Chris Tobey.
# Modified by Ciaran Downey.

use Modern::Perl '2014';

use Getopt::Long;
use LWP::UserAgent;
use JSON;

my $usage = <<'USAGE_MESSAGE';
    Usage:
        -room      Hipchat room name or ID.                      Example: '-room "test"'
        -token     Hipchat Authentication token.                 Example: '-token"abc"'
        -message   Message to be sent to room.                   Example: '-message"Hello World!"'
        -type      (Optional) Hipchat message type (text|html).  Example: '-type "text"'                   (default: text)
        -API       (Optional) Hipchat API Version. (v1|v2).      Example: '-type "v2"'                     (default: v2)
        -notify    (Optional) Message will trigger notification. Example: '-notify "true"'                 (default: false)
        -color     (Optional) Message color (y|r|g|p|g|random)   Example: '-color "green"'                 (default: yellow)
        -from      (Optional) Name message is to be sent from.   Example: '-from "Test"'                   (only used with APIv1)
        -proxy     (Optional) Network proxy to use.              Example: '-proxy "http://127.0.0.1:3128"'

    Basic Example:
        hipchat.pl -room "test" -token "abc" -message "Hello World!"
        Full Example:
        hipchat.pl -room "test" -token "abc" -message "Hello World!" -type text -api v2 -notify true -color green -proxy http://127.0.0.1:3128
USAGE_MESSAGE

my $optionRoom         = "";
my $optionToken        = "";
my $optionMessage      = "";
my $optionFrom         = "";
my $optionType         = "";
my $optionAPI          = "";
my $optionProxy        = "";
my $optionNotify       = "";
my $optioncolor       = "";
my $optionDebug        = "";
my $hipchat_host       = "";
my $hipchat_url        = "";
my $hipchat_json       = "";
my $message_limit      = "";
my @valid_colors      = qw/yellow red green purple gray random/;
my $color_is_valid    = "";
my $default_color     = "";
my @valid_types        = qw/html text/;
my $type_is_valid      = "";
my $default_type       = "";
my @valid_APIs         = qw/v1 v2/;
my $api_is_valid       = "";
my $default_API        = "";
my $ua                 = "";
my $request            = "";
my $response           = "";
my $exit_code          = "";

# Set some options statically.
$hipchat_host          = "https://api.hipchat.com";
$default_color        = "yellow";
$default_API           = "v2";
$default_type          = "text";
$message_limit         = 10000;

# Get the input options.
GetOptions("room=s"   => \$optionRoom,
           "token=s"  => \$optionToken,
           "message=s"=> \$optionMessage,
           "from=s"   => \$optionFrom,
           "type=s"   => \$optionType,
           "api=s"    => \$optionAPI,
           "proxy=s"  => \$optionProxy,
           "notify=s" => \$optionNotify,
           "color=s" => \$optioncolor,
           "debug=s"  => \$optionDebug);

##############################
## VERIFY OPTIONS
##############################

# Check to verify that all options are valid before continuing.

if ($optionRoom eq "") {
   print "\tYou must specify a Hipchat room!\n";
   die ("$usage\n");
}

if ($optionToken eq "") {
   print "\tYou must specify a Hipchat Authentication Token!\n";
   die ("$usage\n");
}

if ($optionMessage eq "") {
   print "\tYou must specify a message to post!\n";
   die ($usage);
}

# Check that the API version is valid.
if ($optionAPI eq "") {
   $optionAPI = $default_API;
}

foreach my $api (@valid_APIs) {
   if (lc($optionAPI) eq $api) {
      $api_is_valid = 1;
      $optionAPI = $api;
      last;
   }
}

if (!$api_is_valid) {
   print "\tYou must select a valid API version!\n";
   die ("$usage\n");
}

# Check that the From name exists if using API v1.
if ($optionFrom eq "") {
   if ($optionAPI eq "v1") {
      print "\tYou must specify a From name when using API v1!\n";
      die ($usage);
   }
}

# Check that the message is shorter than $message_limit characters.
if (length($optionMessage) > $message_limit) {
   print "\tMessage must be $message_limit characters or less!\n";
   die ("$usage\n");   
}

# Check that the message type is valid.
if ($optionType eq "") {
   $optionType = $default_type;
}
foreach my $type (@valid_types) {
   if (lc($optionType) eq $type) {
      $type_is_valid = 1;
      $optionType = $type;
      last;
   }
}
if (!$type_is_valid) {
   print "\tYou must select a valid message type!\n";
   die ("$usage\n");
}

# Check if the notify option is set, else turn it off.
if (lc($optionNotify) eq "y" || lc($optionNotify) eq "yes" || lc($optionNotify) eq "true") {
   if ($optionAPI eq "v1") {
      $optionNotify = "1";
   } else {
      $optionNotify = JSON::true;
   }
} else {
   $optionNotify = JSON::false;
}

# Check that the color is valid.
if ($optioncolor eq "") {
   $optioncolor = $default_color;
}
foreach my $color (@valid_colors) {
   if (lc($optioncolor) eq $color) {
      $color_is_valid = 1;
      $optioncolor = $color;
      last;
   }
}
if (!$color_is_valid) {
   print "\tYou must select a valid color!\n";
   die ("$usage\n");
}

##############################
### SUBMIT THE NOTIFICATION ##
##############################

# Setup the User Agent.
$ua = LWP::UserAgent->new;

# Set the default timeout.
$ua->timeout(10);

# Set the proxy if it was specified.
if ($optionProxy ne "") {
   $ua->proxy(['http', 'https', 'ftp'], $optionProxy);
}

# Submit the notification based on API version
if ($optionAPI eq "v1") {
    $hipchat_url = "$hipchat_host\/$optionAPI\/rooms/message";

    $response = $ua->post($hipchat_url, {
            auth_token     => $optionToken,
            room_id        => $optionRoom,
            from           => $optionFrom,
            message        => $optionMessage,
            message_format => $optionType,
            notify         => $optionNotify,
            color          => $optioncolor,
            format         => 'json',
        });
} elsif ($optionAPI eq "v2") {
   $hipchat_url = "$hipchat_host\/$optionAPI\/room/$optionRoom/notification?auth_token=$optionToken";
   $hipchat_json = to_json({
           color          => $optioncolor,
           message        => $optionMessage,
           message_format => $optionType,
           notify         => $optionNotify
       });

   $request = HTTP::Request->new(POST => $hipchat_url);
   $request->content_type('application/json');
   $request->content($hipchat_json);

   $response = $ua->request($request);
} else {
   print "The API version was not correctly set! Please try again.\n";
}

# Check the status of the notification submission.
if ($response->is_success) {
   print "Hipchat notification posted successfully.\n";
} else {
   print "Hipchat notification failed!\n";
   print $response->status_line . "\n";
}

# Print some debug info if requested.
if ($optionDebug ne "") {
   print $response->decoded_content . "\n";
   print "URL            = $hipchat_url\n";
   print "JSON           = $hipchat_json\n";
   print "auth_token     = $optionToken\n";
   print "room_id        = $optionRoom\n";
   print "from           = $optionFrom\n";
   print "message        = $optionMessage\n";
   print "message_format = $optionType\n";
   print "notify         = $optionNotify\n";
   print "color          = $optioncolor\n";
}

# Always exit with 0 so scripts don't fail if the notification didn't go through.
# Will still fail if input to the script is invalid.

$exit_code = 0;
exit $exit_code;
