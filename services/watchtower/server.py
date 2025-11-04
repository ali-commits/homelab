from http.server import HTTPServer, BaseHTTPRequestHandler
import json

class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length) if content_length > 0 else b''
        
        print(f'\n=== Incoming Request ===')
        print(f'Path: {self.path}')
        print(f'Headers:')
        for header, value in self.headers.items():
            print(f'  {header}: {value}')
        print(f'Body: {body}')
        print(f'Body decoded: {body.decode("utf-8", errors="ignore")}')
        print('=' * 40)
        
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(b'{"status": "ok"}')

server = HTTPServer(('0.0.0.0', 9999), Handler)
print('Webhook logger started on port 9999')
server.serve_forever()
