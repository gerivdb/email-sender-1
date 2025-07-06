Help on module http_server:

NAME
    http_server - Serveur HTTP simple pour tester l'accessibilité du port 8000.

CLASSES
    http.server.SimpleHTTPRequestHandler(http.server.BaseHTTPRequestHandler)
        SimpleHTTPRequestHandler

    class SimpleHTTPRequestHandler(http.server.SimpleHTTPRequestHandler)
     |  SimpleHTTPRequestHandler(*args, directory=None, **kwargs)
     |
     |  Method resolution order:
     |      SimpleHTTPRequestHandler
     |      http.server.SimpleHTTPRequestHandler
     |      http.server.BaseHTTPRequestHandler
     |      socketserver.StreamRequestHandler
     |      socketserver.BaseRequestHandler
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  do_GET(self)
     |      Serve a GET request.
     |
     |  do_POST(self)
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from http.server.SimpleHTTPRequestHandler:
     |
     |  __init__(self, *args, directory=None, **kwargs)
     |      Initialize self.  See help(type(self)) for accurate signature.
     |
     |  copyfile(self, source, outputfile)
     |      Copy all data between two file objects.
     |
     |      The SOURCE argument is a file object open for reading
     |      (or anything with a read() method) and the DESTINATION
     |      argument is a file object open for writing (or
     |      anything with a write() method).
     |
     |      The only reason for overriding this would be to change
     |      the block size or perhaps to replace newlines by CRLF
     |      -- note however that this the default server uses this
     |      to copy binary data as well.
     |
     |  do_HEAD(self)
     |      Serve a HEAD request.
     |
     |  guess_type(self, path)
     |      Guess the type of a file.
     |
     |      Argument is a PATH (a filename).
     |
     |      Return value is a string of the form type/subtype,
     |      usable for a MIME Content-type header.
     |
     |      The default implementation looks the file's extension
     |      up in the table self.extensions_map, using application/octet-stream
     |      as a default; however it would be permissible (if
     |      slow) to look inside the data to make a better guess.
     |
     |  list_directory(self, path)
     |      Helper to produce a directory listing (absent index.html).
     |
     |      Return value is either a file object, or None (indicating an
     |      error).  In either case, the headers are sent, making the
     |      interface the same as for send_head().
     |
     |  send_head(self)
     |      Common code for GET and HEAD commands.
     |
     |      This sends the response code and MIME headers.
     |
     |      Return value is either a file object (which has to be copied
     |      to the outputfile by the caller unless the command was HEAD,
     |      and must be closed by the caller under all circumstances), or
     |      None, in which case the caller has nothing further to do.
     |
     |  translate_path(self, path)
     |      Translate a /-separated PATH to the local filename syntax.
     |
     |      Components that mean special things to the local file system
     |      (e.g. drive or directory names) are ignored.  (XXX They should
     |      probably be diagnosed.)
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes inherited from http.server.SimpleHTTPRequestHandler:
     |
     |  extensions_map = {'.Z': 'application/octet-stream', '.bz2': 'applicati...
     |
     |  index_pages = ('index.html', 'index.htm')
     |
     |  server_version = 'SimpleHTTP/0.6'
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from http.server.BaseHTTPRequestHandler:
     |
     |  address_string(self)
     |      Return the client address.
     |
     |  date_time_string(self, timestamp=None)
     |      Return the current date and time formatted for a message header.
     |
     |  end_headers(self)
     |      Send the blank line ending the MIME headers.
     |
     |  flush_headers(self)
     |
     |  handle(self)
     |      Handle multiple requests if necessary.
     |
     |  handle_expect_100(self)
     |      Decide what to do with an "Expect: 100-continue" header.
     |
     |      If the client is expecting a 100 Continue response, we must
     |      respond with either a 100 Continue or a final response before
     |      waiting for the request body. The default is to always respond
     |      with a 100 Continue. You can behave differently (for example,
     |      reject unauthorized requests) by overriding this method.
     |
     |      This method should either return True (possibly after sending
     |      a 100 Continue response) or send an error response and return
     |      False.
     |
     |  handle_one_request(self)
     |      Handle a single HTTP request.
     |
     |      You normally don't need to override this method; see the class
     |      __doc__ string for information on how to handle specific HTTP
     |      commands such as GET and POST.
     |
     |  log_date_time_string(self)
     |      Return the current time formatted for logging.
     |
     |  log_error(self, format, *args)
     |      Log an error.
     |
     |      This is called when a request cannot be fulfilled.  By
     |      default it passes the message on to log_message().
     |
     |      Arguments are the same as for log_message().
     |
     |      XXX This should go to the separate error log.
     |
     |  log_message(self, format, *args)
     |      Log an arbitrary message.
     |
     |      This is used by all other logging functions.  Override
     |      it if you have specific logging wishes.
     |
     |      The first argument, FORMAT, is a format string for the
     |      message to be logged.  If the format string contains
     |      any % escapes requiring parameters, they should be
     |      specified as subsequent arguments (it's just like
     |      printf!).
     |
     |      The client ip and current date/time are prefixed to
     |      every message.
     |
     |      Unicode control characters are replaced with escaped hex
     |      before writing the output to stderr.
     |
     |  log_request(self, code='-', size='-')
     |      Log an accepted request.
     |
     |      This is called by send_response().
     |
     |  parse_request(self)
     |      Parse a request (internal).
     |
     |      The request should be stored in self.raw_requestline; the results
     |      are in self.command, self.path, self.request_version and
     |      self.headers.
     |
     |      Return True for success, False for failure; on failure, any relevant
     |      error response has already been sent back.
     |
     |  send_error(self, code, message=None, explain=None)
     |      Send and log an error reply.
     |
     |      Arguments are
     |      * code:    an HTTP error code
     |                 3 digits
     |      * message: a simple optional 1 line reason phrase.
     |                 *( HTAB / SP / VCHAR / %x80-FF )
     |                 defaults to short entry matching the response code
     |      * explain: a detailed message defaults to the long entry
     |                 matching the response code.
     |
     |      This sends an error response (so it must be called before any
     |      output has been generated), logs the error, and finally sends
     |      a piece of HTML explaining the error to the user.
     |
     |  send_header(self, keyword, value)
     |      Send a MIME header to the headers buffer.
     |
     |  send_response(self, code, message=None)
     |      Add the response header to the headers buffer and log the
     |      response code.
     |
     |      Also send two standard headers with the server software
     |      version and the current date.
     |
     |  send_response_only(self, code, message=None)
     |      Send the response header only.
     |
     |  version_string(self)
     |      Return the server software version string.
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes inherited from http.server.BaseHTTPRequestHandler:
     |
     |  MessageClass = <class 'http.client.HTTPMessage'>
     |
     |  default_request_version = 'HTTP/0.9'
     |
     |  error_content_type = 'text/html;charset=utf-8'
     |
     |  error_message_format = '<!DOCTYPE HTML>\n<html lang="en">\n    <head>\...
     |
     |  monthname = [None, 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'A...
     |
     |  protocol_version = 'HTTP/1.0'
     |
     |  responses = {<HTTPStatus.CONTINUE: 100>: ('Continue', 'Request receive...
     |
     |  sys_version = 'Python/3.12.6'
     |
     |  weekdayname = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from socketserver.StreamRequestHandler:
     |
     |  finish(self)
     |
     |  setup(self)
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes inherited from socketserver.StreamRequestHandler:
     |
     |  disable_nagle_algorithm = False
     |
     |  rbufsize = -1
     |
     |  timeout = None
     |
     |  wbufsize = 0
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from socketserver.BaseRequestHandler:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

DATA
    PORT = 8000

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\python\http_server.py


