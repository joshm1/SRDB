require 'socket'
require 'cgi'

HOST = ARGV[0] || '127.0.0.1'
PORT = ARGV[1] || '8080'
SERVER = TCPServer.new(HOST, PORT)
MINE_TYPES = {} # quick access to mime types based on file ext (key = extension, value = mime type)

# parse definitions of supported extensions (last item per line is the mine type)
File.read(File.join(File.dirname(__FILE__), 'file_types.txt')).each_line do |line|
  begin
    pieces = line.chomp.split(' ')
    exts, mtype = pieces[0...-1], pieces[-1]
    exts.each { |ext| MINE_TYPES[ext] = mtype }
  rescue # ignore bad lines
  end
end

def stop session, response_code, content_type = nil, body = nil
  session.print "HTTP/1.0 #{response_code}\n"
  session.print "Content-Type: #{content_type}\n" if content_type
  session.print "Content-Length: #{body.size}\n\n#{body}" if body
  session.close
  Thread.stop # assumes each request has its own thread
end

trap('SIGINT') { print "Cleaing up... "; SERVER.close; puts "Done."; exit 0; } # cleanup on Ctrl-C

while s = SERVER.accept
  Thread.new(s) do |session| # new thread per session; a thread pool would more efficient, but this is for fun
    begin
      request_line = session.gets # first line of the HTTP request
      stop(session, 400) unless request_line # exit if somehow we accepted a socket and got no message

      # first lint should at least have match "GET /?p=<path>" or "GET /<path>"
      matches = request_line.match(%r~(\w+)\s+(.*)(?:HTTP/1.[01])~)
      full, method, remote_path = matches.to_a
      remote_path = CGI.unescape(remote_path.strip!)

      # default to C: for systems where / does not exist
      remote_path = "C:" if remote_path == "/" and not File.exist?(remote_path)

      stop(session, 405) if (!method || method.downcase != 'get') # only accept GET requests
      stop(session, 404) unless remote_path or remote_path.size == 0 # no valid path was passed

      param_prefix = "/?p="
      # strip the prefix if it was provided to get the real directory/file path
      dir_path = if remote_path.start_with?(param_prefix) then remote_path[param_prefix.size..-1] # substring the path
                 else remote_path # may work without the 'p' param, but it's safer to use it
                 end

      # extract the MIME type from the path or default to plain if something isn't right
      content_type = "text/html"

      if File.directory?(dir_path)
        if File.readable?(dir_path)
          body = "#{dir_path}<br />\n"
          Dir.foreach(dir_path) do |path| # link to each item in the directory except "."
            next if %w'/ .'.include?(path) or ('..' == path and '/' == dir_path)
            href = File.expand_path File.join(dir_path, path)
            body << ("&nbsp;" * 8) + %~<a href="/?p=#{CGI.escape href}">#{path}</a><br />\n~
          end
        else
          body = "Read permission denied on the directory #{CGI.escapeHTML dir_path}"
        end
      elsif File.exist?(dir_path)
        if File.readable?(dir_path)
          # default to text/plain if we don't recognize the extension
          content_type = dir_path && MINE_TYPES[File.extname(dir_path)[1..-1]] || 'text/plain'

          # special check for binary files: png, gif, jpeg
          html = File.open(dir_path, content_type =~ /(png|gif|jpe?g)/ ? 'rb' : 'r') { |f| f.read }
        else
          body = "Read permission denied on the file <b>#{CGI.escapeHTML dir_path}</b>"
        end
      else
        body = dir_path ? "File <b>#{CGI.escapeHTML dir_path}</b> does not exist" : "Directory path not specified"
      end

      html ||= "<html><head><title>#{dir_path} [SRDB]</title><body>#{body}</body></html>"
      stop(session, "200/OK", content_type, html)
    rescue => e
      stop(session, "200/OK", "text/html", "[ERROR] " + e.message)
      $stderr.puts "[#{e.class.name}] #{e.message}\n\t" + e.backtrace.join("\n\t")
    end
  end
end 
