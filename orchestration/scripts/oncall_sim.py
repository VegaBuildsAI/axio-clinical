"""Simulador del sistema on-call de AXIO Clinical (no existe el real — §6 del plan).

Acepta POST en cualquier path, responde 200 y loguea el payload a stdout
(visible con `docker compose logs oncall-sim`). D5: el 2xx significa
"un sistema lo recibió", no "un humano se hizo cargo".
"""
import json
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, HTTPServer


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):  # noqa: N802
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length).decode("utf-8", errors="replace")
        try:
            payload = json.dumps(json.loads(body), ensure_ascii=False)
        except ValueError:
            payload = body
        print(
            f"[oncall-sim] {datetime.now(timezone.utc).isoformat()} "
            f"POST {self.path} auth={'sí' if self.headers.get('Authorization') or self.headers.get('X-Crisis-Token') else 'no'} "
            f"payload={payload}",
            flush=True,
        )
        respuesta = b'{"received": true}'
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(respuesta)))
        self.end_headers()
        self.wfile.write(respuesta)

    def log_message(self, *args):  # silenciar el log por defecto (duplicado)
        pass


if __name__ == "__main__":
    print("[oncall-sim] escuchando en :9999", flush=True)
    HTTPServer(("0.0.0.0", 9999), Handler).serve_forever()
