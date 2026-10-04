#!/usr/bin/env python3
import base64
import json
import os
import socket
import struct
import sys
import time
import urllib.request

CLIENT_ID = "207646673902501888"
ORIGIN = "https://streamkit.discord.com"
TOKEN_URL = "https://streamkit.discord.com/overlay/token"
SCOPES = ["rpc", "messages.read", "rpc.notifications.read"]
TOKEN_FILE = os.path.expanduser("~/.cache/israshell/discord-token.json")

def emit(**kw):
    print(json.dumps(kw), flush=True)

class WebSocket:
    def __init__(self, port):
        self.sock = socket.create_connection(("127.0.0.1", port), timeout=5)
        key = base64.b64encode(os.urandom(16)).decode()
        self.sock.sendall((
            f"GET /?v=1&client_id={CLIENT_ID}&encoding=json HTTP/1.1\r\n"
            f"Host: 127.0.0.1:{port}\r\nOrigin: {ORIGIN}\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
            f"Sec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n\r\n").encode())
        head = b""
        while b"\r\n\r\n" not in head:
            chunk = self.sock.recv(1024)
            if not chunk:
                raise ConnectionError("closed during handshake")
            head += chunk
        head, _, self.buf = head.partition(b"\r\n\r\n")
        if b" 101 " not in head.split(b"\r\n")[0]:
            raise ConnectionError("upgrade refused")
        self.sock.settimeout(None)

    def _read(self, n):
        while len(self.buf) < n:
            chunk = self.sock.recv(65536)
            if not chunk:
                raise ConnectionError("closed")
            self.buf += chunk
        out, self.buf = self.buf[:n], self.buf[n:]
        return out

    def send(self, obj, opcode=1):
        data = json.dumps(obj).encode() if opcode == 1 else obj
        mask = os.urandom(4)
        n = len(data)
        head = bytes([0x80 | opcode])
        head += bytes([0x80 | n]) if n < 126 else bytes([0x80 | 126]) + struct.pack(">H", n) if n < 65536 else bytes([0x80 | 127]) + struct.pack(">Q", n)
        self.sock.sendall(head + mask + bytes(b ^ mask[i % 4] for i, b in enumerate(data)))

    def recv(self):
        message = b""
        while True:
            b0, b1 = self._read(2)
            n = b1 & 0x7F
            if n == 126:
                n = struct.unpack(">H", self._read(2))[0]
            elif n == 127:
                n = struct.unpack(">Q", self._read(8))[0]
            data = self._read(n)
            op = b0 & 0x0F
            if op == 0x8:
                raise ConnectionError("closed by Discord")
            if op == 0x9:
                self.send(data, opcode=0xA)
                continue
            if op in (0x1, 0x0):
                message += data
                if b0 & 0x80:
                    return json.loads(message)

class Session:
    def __init__(self, ws):
        self.ws = ws
        self.n = 0
        self.pending = {}
        self.channel = None
        self.users = {}
        self.subs = []

    def call(self, cmd, args=None, evt=None):
        self.n += 1
        nonce = str(self.n)
        msg = {"cmd": cmd, "args": args or {}, "nonce": nonce}
        if evt:
            msg["evt"] = evt
        self.ws.send(msg)
        return nonce

    def wait(self, nonce):
        while True:
            m = self.ws.recv()
            if m.get("nonce") == nonce:
                if m.get("evt") == "ERROR":
                    raise RuntimeError(m.get("data", {}).get("message", "RPC error"))
                return m.get("data")
            self.handle(m)

    def token(self):
        try:
            with open(TOKEN_FILE) as f:
                return json.load(f)["access_token"]
        except (OSError, KeyError, ValueError):
            return None

    def authenticate(self):
        token = self.token()
        if token:
            try:
                self.wait(self.call("AUTHENTICATE", {"access_token": token}))
                return
            except RuntimeError:
                pass
        emit(status="authorize", detail="Approve the request in Discord")
        code = self.wait(self.call("AUTHORIZE", {"client_id": CLIENT_ID, "scopes": SCOPES}))["code"]
        req = urllib.request.Request(TOKEN_URL, json.dumps({"code": code}).encode(), {"Content-Type": "application/json", "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) isra-shell"})
        with urllib.request.urlopen(req, timeout=15) as r:
            token = json.load(r)["access_token"]
        os.makedirs(os.path.dirname(TOKEN_FILE), exist_ok=True)
        with open(TOKEN_FILE, "w") as f:
            json.dump({"access_token": token}, f)
        os.chmod(TOKEN_FILE, 0o600)
        self.wait(self.call("AUTHENTICATE", {"access_token": token}))

    def user(self, vs):
        u = vs.get("user", {})
        st = vs.get("voice_state", {})
        return u.get("id"), {
            "id": u.get("id"),
            "name": vs.get("nick") or u.get("global_name") or u.get("username") or "?",
            "avatar": u.get("avatar"),
            "speaking": self.users.get(u.get("id"), {}).get("speaking", False),
            "mute": bool(st.get("mute") or st.get("self_mute") or vs.get("mute")),
            "deaf": bool(st.get("deaf") or st.get("self_deaf")),
        }

    def push(self):
        emit(status="ok", channel=self.channel, users=list(self.users.values()))

    def join(self, channel_id):
        for evt in self.subs:
            self.call("UNSUBSCRIBE", {"channel_id": evt[1]}, evt[0])
        self.subs = []
        self.users = {}
        self.channel = None
        if channel_id:
            data = self.wait(self.call("GET_SELECTED_VOICE_CHANNEL"))
            if data:
                self.channel = data.get("name")
                for vs in data.get("voice_states", []):
                    uid, u = self.user(vs)
                    self.users[uid] = u
                for evt in ("VOICE_STATE_CREATE", "VOICE_STATE_UPDATE", "VOICE_STATE_DELETE", "SPEAKING_START", "SPEAKING_STOP"):
                    self.call("SUBSCRIBE", {"channel_id": channel_id}, evt)
                    self.subs.append((evt, channel_id))
        self.push()

    def handle(self, m):
        evt, data = m.get("evt"), m.get("data") or {}
        if evt == "VOICE_CHANNEL_SELECT":
            self.join(data.get("channel_id"))
        elif evt in ("VOICE_STATE_CREATE", "VOICE_STATE_UPDATE"):
            uid, u = self.user(data)
            self.users[uid] = u
            self.push()
        elif evt == "VOICE_STATE_DELETE":
            self.users.pop(data.get("user", {}).get("id"), None)
            self.push()
        elif evt in ("SPEAKING_START", "SPEAKING_STOP"):
            u = self.users.get(data.get("user_id"))
            if u:
                u["speaking"] = evt == "SPEAKING_START"
                self.push()

    def run(self):
        ready = self.ws.recv()
        if ready.get("evt") != "READY":
            raise ConnectionError("no READY")
        self.authenticate()
        self.call("SUBSCRIBE", {}, "VOICE_CHANNEL_SELECT")
        data = self.wait(self.call("GET_SELECTED_VOICE_CHANNEL"))
        self.join(data["id"] if data else None)
        while True:
            self.handle(self.ws.recv())

def main():
    delay = 2
    while True:
        try:
            for port in range(6463, 6473):
                try:
                    ws = WebSocket(port)
                    break
                except (OSError, ConnectionError):
                    continue
            else:
                emit(status="waiting", detail="Discord isn't running")
                time.sleep(5)
                continue
            delay = 2
            Session(ws).run()
        except (ConnectionError, OSError) as e:
            emit(status="waiting", detail=str(e))
        except Exception as e:
            emit(status="error", detail=str(e))
            delay = min(delay * 2, 60)
        time.sleep(delay)

if __name__ == "__main__":
    main()
