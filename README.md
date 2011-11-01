About Me
========

SRDB = Simple Remote Desktop Browser

This application implements a basic HTTP server along with the ability to
browser the file system of the server it is hosted on.  It is capable of
opening text and image files.

HIGHLY recommended to not broadcast this outside your local system, as it will
give any visitor read access to much of your file system.

Disclaimer
----------

This project is simply for fun and proof of concept (how to create a small
    server and website in < 80 lines). The author is not liable for any issues
resulting in its use.  Please use at your own risk.

Usage
-----

  ruby ./srdb.rb [HOST] [PORT]

HOST and PORT are optional. They default to localhost (127.0.0.1) and 8080
respectively.  This command just starts the server.  Use your internet browser
or telnet or whatever to make requests to the server.

For example, if you run the server on localhost:8080, navigate to
http://localhost:8080/

If you're using windows, you may want to use a formed like the following:
http://localhost:8080/?p=C: where C is the drive you want to browse.  The
colon after the letter is necessary.

It can be used remotely by specifying your LAN IP address for the HOST
argument.

License
-------

"New BSD License" - see LICENSE.txt
