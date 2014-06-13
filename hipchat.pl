#!/usr/bin/env perl
#
# Perl script to send a notification to hipchat using either the REST api v1 or v2.
#
# Created by Chris Tobey.
# Modified by Ciaran Downey.

use Modern::Perl '2014';

use Getopt::Long;
use LWP::UserAgent;
use JSON;
use List::Util qw(any none);

sub get_usage {
    print <<'    USAGE_MESSAGE';
Usage:
    -room      Hipchat room name or ID.
        Example: '-room "test"'
    -token     Hipchat Authentication token.
        Example: '-token "abc"'
    -message   Message to be sent to room.
        Example: '-message "Hello World!"'
    -type      (Optional) Hipchat message type (text|html).
        Example: '-type "text"'                   (default: text)
    -api       (Optional) Hipchat api Version. (v1|v2).
        Example: '-type "v2"'                     (default: v2)
    -notify    (Optional) Message will trigger notification.
        Example: '-notify'                        (default: false)
    -color     (Optional) Message color (y|r|g|p|g|random)
        Example: '-color "green"'                 (default: yellow)
    -from      (Optional) Name message is to be sent from.
        Example: '-from "Test"'                   (only used with apiv1)
    -proxy     (Optional) Network proxy to use.
        Example: '-proxy "http://127.0.0.1:3128"'
    -strict    (Optional) Return non-zero on failure
        Example: '-strict'                        (default: false)

Basic Example:
    hipchat.pl -room "test" -token "abc" -message "Hello World!"

Full Example:
    hipchat.pl -room "test" -token "abc" -message "Hello World!" -type text \
        -api v2 -notify true -color green -proxy http://127.0.0.1:3128
    USAGE_MESSAGE
}

# Set some options statically.
my $hipchat_host   = "https://api.hipchat.com";
my $message_limit  = 10000;
my @valid_colors   = qw/yellow red green purple gray random/;
my @valid_types    = qw/html text/;
my @valid_apis     = qw/v1 v2/;

# defaults
my $default_color  = "yellow";
my $default_api    = "v2";
my $default_type   = "text";

my $strict_mode    = 0;
my $option_type    = $default_type;
my $option_api     = $default_api;
my $option_color   = $default_color;
my $option_room    = "";
my $option_token   = "";
my $option_message = "";
my $option_from    = "";
my $option_proxy   = "";
my $option_notify  = "";
my $option_debug   = "";
my $hipchat_url    = "";
my $hipchat_json   = "";
my $ua             = "";
my $request        = "";
my $response       = "";
my $exit_code      = "";

# a list of api params that should be lc'd
my @api_params     = (\$option_type, \$option_notify, \$option_api, \$option_color);

my %required_fields_and_errors = (
    "You must specify a Hipchat room!"                 => \$option_room,
    "You must specify a Hipchat Authentication Token!" => \$option_token,
    "You must specify a message to post!"              => \$option_message,
);

# Get the input options.
GetOptions(
    # string options
    "room=s"    => \$option_room,
    "token=s"   => \$option_token,
    "message=s" => \$option_message,
    "from=s"    => \$option_from,
    "type=s"    => \$option_type,
    "api=s"     => \$option_api,
    "proxy=s"   => \$option_proxy,
    "color=s"   => \$option_color,
    "debug=s"   => \$option_debug,
    # booleans
    "strict!"   => \$strict_mode,
    "notify!"   => \$option_notify,
);

##############################
## VERIFY OPTIONS
##############################

sub die_with_usage {
    die(join("\n", $_[0], "", get_usage()));
}

# lowercase all api params
@api_params = map { lc $_ } @api_params;

# check all required options first
while (my ($message, $arg) = each(%required_fields_and_errors)) {
    die_with_usage($message) unless $$arg ne "";
}

# Check to verify that all options are valid before continuing.
die_with_usage("$option_api is not a valid api type")
    unless any { $option_api eq $_ } @valid_apis;

die_with_usage("You must select a valid message type!")
    unless any { $option_type eq $_ } @valid_types;

die_with_usage("You must select a valid color!")
    unless any { $option_color eq $_ } @valid_colors;

# Check that the From name exists if using api v1.
die_with_usage("You must specify a 'from' name when using api v1!")
    unless (($option_from ne "") || ($option_api ne "v1"));

# Check that the message is shorter than $message_limit characters.
die_with_usage("Message must be $message_limit characters or less!")
    unless (length($option_message) <= $message_limit);

# we need some json-y truthy / falsey values depending on the API
my $truth = $option_api eq "v1" ? "1" : JSON::true;
my $false = $option_api eq "v1" ? "0" : JSON::false;

$option_notify = $option_notify ? $truth : $false;

##############################
### SUBMIT THE NOTIFICATION ##
##############################

# Setup the User Agent.
$ua = LWP::UserAgent->new;

# Set the default timeout.
$ua->timeout(10);

# Set the proxy if it was specified.
if ($option_proxy ne "") {
   $ua->proxy(['http', 'https', 'ftp'], $option_proxy);
}

# Submit the notification based on api version
if ($option_api eq "v1") {
    $hipchat_url = "$hipchat_host\/$option_api\/rooms/message";

    $response = $ua->post($hipchat_url, {
            auth_token     => $option_token,
            room_id        => $option_room,
            from           => $option_from,
            message        => $option_message,
            message_format => $option_type,
            notify         => $option_notify,
            color          => $option_color,
            format         => 'json',
        });
} elsif ($option_api eq "v2") {
   $hipchat_url = "$hipchat_host\/$option_api\/room/$option_room/notification?auth_token=$option_token";
   $hipchat_json = to_json({
           color          => $option_color,
           message        => $option_message,
           message_format => $option_type,
           notify         => $option_notify
       });

   $request = HTTP::Request->new(POST => $hipchat_url);
   $request->content_type('application/json');
   $request->content($hipchat_json);

   $response = $ua->request($request);
} else {
   die_with_usage("The api version was not correctly set! Please try again.");
}

# Check the status of the notification submission.
if ($response->is_success) {
   say "Hipchat notification posted successfully";
} else {
   say "Hipchat notification failed!";
   say $response->status_line;
}

# Print some debug info if requested.
if ($option_debug ne "") {
   say $response->decoded_content;
   say "URL            = $hipchat_url";
   say "JSON           = $hipchat_json";
   say "auth_token     = $option_token";
   say "room_id        = $option_room";
   say "from           = $option_from";
   say "message        = $option_message";
   say "message_format = $option_type";
   say "notify         = $option_notify";
   say "color          = $option_color";
   say "strict_mode    = $strict_mode";
}

if (!$strict_mode) {
    exit 0;
}

exit $response->is_success ? 0 : 1;
