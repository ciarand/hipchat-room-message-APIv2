hipchat-room-message-APIv2
==========================
This is a simple perl script that will use Hipchat's API v2 to message a room
after passing in the room name, authentication token and a message.

Also includes features for selecting the colour, notifying the room, passing in
an HTML message, using a proxy and using API v1 should you so choose.

>Note: This script uses a [`cpanfile`][cpanfile] to track dependencies. It was
>tested with Perl 5.21.0, but should work on prior versions.

[cpanfile]: https://metacpan.org/pod/distribution/Module-CPANfile/lib/cpanfile.pod

Sample Script Output: This script will send a notification to hipchat.

```
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
```

Sample Successful Call:
```
$ hipchat.pl -room Jenkins -token abc -message 'Hello World!' \
    -color green -proxy http://127.0.0.1:3128
Hipchat notification posted successfully.
```

Sample Unsuccessful Call (bad token):
```
$ hipchat.pl -room Jenkins -token abd -message 'Hello World!' \
    -color green -proxy http://127.0.0.1:3128
Hipchat notification failed!
401 Unauthorized
```

Credit
======
The original script was created by Chris Tobey and can be found
[here][original]. Thanks Chris!

[original]: https://github.com/tobeychris/hipchat-room-message-APIv2

License
=======
GPL v2, see the [LICENSE][license] file.

[license]: /LICENSE
