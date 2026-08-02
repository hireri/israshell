#!/usr/bin/env python3
"""LocalSend protocol v2.1 (https://github.com/localsend/protocol)

Known gaps vs. the full spec
----------------------------
HTTP legacy discovery fallback (multicast-blocked networks),
the reverse/download API (browser-based receiving), requiring a pin
on inbound transfers, and TLS (we run in http mode BUT the protocol explicitly
allows mixed http/https peers).
"""

import argparse
import http.client
import json
import mimetypes
import os
import platform
import select
import signal
import socket
import ssl
import struct
import sys
import threading
import time
import urllib.error
import urllib.request
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, unquote, urlparse

MULTICAST_ADDR = "224.0.0.167"
MULTICAST_PORT = 53317
PROTOCOL_VERSION = "2.1"
CONFIRM_TIMEOUT = 60
INBOUND_STALL_TIMEOUT = 45
INBOUND_MAX_AGE = 6 * 3600
PROGRESS_INTERVAL = 0.12
LOOPBACK_IPS = ("127.0.0.1", "::1")
DEVICE_TYPES = ("mobile", "desktop", "web", "headless", "server")

RESULT_OK = ("sent", "received")

_UNVERIFIED_SSL_CONTEXT = ssl._create_unverified_context()


def _urlopen(req, timeout):
    ctx = _UNVERIFIED_SSL_CONTEXT if req.full_url.startswith(
        "https://") else None
    return urllib.request.urlopen(req, timeout=timeout, context=ctx)


def local_events_socket_path():
    return os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "isra-localsend-events.sock")


_local_ip_cache = (0.0, "127.0.0.1")


def _local_ip():
    global _local_ip_cache
    now = time.monotonic()
    if now - _local_ip_cache[0] < 5:
        return _local_ip_cache[1]
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
    except OSError:
        ip = "127.0.0.1"
    finally:
        s.close()
    _local_ip_cache = (now, ip)
    return ip


def _persistent_fingerprint():
    state_dir = Path(os.environ.get("XDG_STATE_HOME",
                     Path.home() / ".local" / "state")) / "isra"
    fp_file = state_dir / "localsend-fingerprint"
    try:
        fp = fp_file.read_text().strip()
        if fp:
            return fp
    except OSError:
        pass
    fp = uuid.uuid4().hex
    try:
        state_dir.mkdir(parents=True, exist_ok=True)
        fp_file.write_text(fp)
    except OSError:
        pass
    return fp


def _die_with_parent():
    try:
        import ctypes
        libc = ctypes.CDLL("libc.so.6", use_errno=True)
        PR_SET_PDEATHSIG = 1
        libc.prctl(PR_SET_PDEATHSIG, signal.SIGTERM)
        if os.getppid() == 1:
            sys.exit(0)
    except Exception:
        pass


def _kill_stale_instances(my_port):
    me = os.getpid()
    for pid_dir in Path("/proc").iterdir():
        if not pid_dir.name.isdigit() or int(pid_dir.name) == me:
            continue
        try:
            cmdline = (pid_dir / "cmdline").read_bytes().decode("utf-8",
                                                                "replace").split("\0")
        except OSError:
            continue
        if not any(arg.endswith("/localsend-server.py") or arg == "localsend-server.py" for arg in cmdline):
            continue
        try:
            port_idx = cmdline.index("--port")
            other_port = int(cmdline[port_idx + 1])
        except (ValueError, IndexError):
            other_port = MULTICAST_PORT
        if other_port != my_port:
            continue
        try:
            os.kill(int(pid_dir.name), signal.SIGTERM)
            print(
                f"[localsend] killed stale instance pid {pid_dir.name} (port {other_port})")
        except OSError:
            pass


class SelfInfo:
    def __init__(self, port, device_type="desktop", alias=None):
        self.default_alias = os.environ.get(
            "LOCALSEND_ALIAS") or socket.gethostname()
        self.alias = alias or self.default_alias
        self.version = PROTOCOL_VERSION
        self.deviceModel = platform.system()
        self.deviceType = device_type if device_type in DEVICE_TYPES else "desktop"
        self.fingerprint = _persistent_fingerprint()
        self.port = port
        self.protocol = "http"
        self.download = False

    def as_dict(self, announce=None):
        d = {
            "alias": self.alias,
            "version": self.version,
            "deviceModel": self.deviceModel,
            "deviceType": self.deviceType,
            "fingerprint": self.fingerprint,
            "port": self.port,
            "protocol": self.protocol,
            "download": self.download,
        }
        if announce is not None:
            d["announce"] = announce
        return d


class EventBus:
    """🚍🚍🚍🚍🚍"""

    SEND_TIMEOUT = 3.0

    def __init__(self, path, greeting=None):
        self.path = path
        self.greeting = greeting
        self._clients = []
        self._lock = threading.Lock()

    def start(self):
        threading.Thread(target=self._serve, daemon=True).start()

    def _serve(self):
        if os.path.exists(self.path):
            os.unlink(self.path)
        srv = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        srv.bind(self.path)
        srv.listen(8)
        print(f"[localsend] events on {self.path}")
        while True:
            try:
                conn, _ = srv.accept()
            except OSError:
                continue
            conn.settimeout(self.SEND_TIMEOUT)
            with self._lock:
                self._clients.append(conn)
            if self.greeting is not None:
                try:
                    conn.sendall(self._encode(self.greeting()))
                except OSError:
                    with self._lock:
                        if conn in self._clients:
                            self._clients.remove(conn)
                    try:
                        conn.close()
                    except OSError:
                        pass

    @staticmethod
    def _encode(obj):
        return (json.dumps(obj, separators=(",", ":")) + "\n").encode("utf-8")

    def emit(self, event_type, data=None):
        payload = self._encode(
            {"type": event_type, "data": data if data is not None else {}})
        with self._lock:
            clients = list(self._clients)
        dead = []
        for c in clients:
            try:
                c.sendall(payload)
            except (OSError, socket.timeout):
                dead.append(c)
        if not dead:
            return
        with self._lock:
            for c in dead:
                if c in self._clients:
                    self._clients.remove(c)
        for c in dead:
            try:
                c.close()
            except OSError:
                pass


class PeerRegistry:
    def __init__(self, self_fingerprint, on_change):
        self.self_fingerprint = self_fingerprint
        self.on_change = on_change
        self.peers = {}
        self.lock = threading.Lock()

    def upsert(self, info, ip):
        fp = info.get("fingerprint")
        if not fp or fp == self.self_fingerprint:
            return
        entry = {
            "fingerprint": fp,
            "alias": info.get("alias") or "Unknown device",
            "deviceModel": info.get("deviceModel"),
            "deviceType": info.get("deviceType") if info.get("deviceType") in DEVICE_TYPES else "desktop",
            "ip": ip,
            "port": info.get("port") or MULTICAST_PORT,
            "protocol": info.get("protocol") or "http",
            "lastSeen": time.time(),
        }
        with self.lock:
            prev = self.peers.get(fp)
            self.peers[fp] = entry
        if prev is None or any(prev.get(k) != entry.get(k) for k in ("alias", "deviceType", "ip", "port", "protocol")):
            self.on_change()

    def prune(self, max_age=120):
        with self.lock:
            stale = [fp for fp, p in self.peers.items(
            ) if time.time() - p["lastSeen"] > max_age]
            for fp in stale:
                del self.peers[fp]
        if stale:
            self.on_change()

    def list(self):
        with self.lock:
            peers = sorted(self.peers.values(),
                           key=lambda p: (p["alias"] or "").lower())
            return [
                {
                    "fingerprint": p["fingerprint"],
                    "alias": p["alias"],
                    "deviceType": p["deviceType"],
                    "deviceModel": p["deviceModel"],
                    "ip": p["ip"],
                    "port": p["port"],
                    "protocol": p["protocol"],
                }
                for p in peers
            ]

    def find_by_ip(self, ip):
        with self.lock:
            for p in self.peers.values():
                if p["ip"] == ip:
                    return dict(p)
        return None


class Discovery:
    def __init__(self, self_info, registry):
        self.self_info = self_info
        self.registry = registry
        self.send_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.send_sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.send_sock.setsockopt(
            socket.IPPROTO_IP, socket.IP_MULTICAST_TTL, 2)
        self.recv_sock = None
        self.available = False

    def start(self):
        self.recv_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.recv_sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            self.recv_sock.bind(("", MULTICAST_PORT))
            mreq = struct.pack("4sl", socket.inet_aton(
                MULTICAST_ADDR), socket.INADDR_ANY)
            self.recv_sock.setsockopt(
                socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, mreq)
        except OSError as e:
            print(
                f"[localsend] multicast unavailable, discovery disabled: {e}")
            self.recv_sock = None
            return
        self.available = True
        threading.Thread(target=self._listen, daemon=True).start()
        threading.Thread(target=self._announce_loop, daemon=True).start()
        threading.Thread(target=self._startup_burst, daemon=True).start()

    def _startup_burst(self):
        for delay in (0, 1.0, 3.0):
            time.sleep(delay)
            self.announce()

    def announce(self):
        msg = json.dumps(self.self_info.as_dict(announce=True)).encode()
        try:
            self.send_sock.sendto(msg, (MULTICAST_ADDR, MULTICAST_PORT))
        except OSError as e:
            print(f"[localsend] announce failed: {e}")

    def _announce_loop(self):
        while True:
            time.sleep(30)
            self.announce()
            self.registry.prune()

    def _listen(self):
        while True:
            try:
                data, addr = self.recv_sock.recvfrom(16384)
            except OSError:
                time.sleep(0.2)
                continue
            try:
                info = json.loads(data.decode("utf-8"))
            except (ValueError, UnicodeDecodeError):
                continue
            if not isinstance(info, dict):
                continue
            fp = info.get("fingerprint")
            if not fp or fp == self.self_info.fingerprint:
                continue
            self.registry.upsert(info, addr[0])
            if info.get("announce"):
                threading.Thread(
                    target=self._respond,
                    args=(addr[0], info.get("port") or MULTICAST_PORT,
                          info.get("protocol") or "http"),
                    daemon=True,
                ).start()

    def _respond(self, ip, port, protocol):
        body = json.dumps(self.self_info.as_dict()).encode()
        req = urllib.request.Request(
            f"{protocol}://{ip}:{port}/api/localsend/v2/register",
            data=body, method="POST", headers={"Content-Type": "application/json"}
        )
        try:
            _urlopen(req, timeout=4).read()
            return
        except Exception as e:
            print(
                f"[localsend] register response to {ip} ({protocol}) failed: {e}")
        try:
            self.send_sock.sendto(
                json.dumps(self.self_info.as_dict(announce=False)).encode(),
                (MULTICAST_ADDR, MULTICAST_PORT),
            )
        except OSError:
            pass


class InboundSession:
    """One accepted-or-pending prepare-upload from a peer."""

    def __init__(self, session_id, sender_info, files):
        self.session_id = session_id
        self.sender_info = sender_info or {}
        self.files = files
        self.tokens = {fid: uuid.uuid4().hex for fid in files}
        self.confirm_event = threading.Event()
        self.confirmed = None
        self.cancelled = False
        self.created_at = time.monotonic()
        self.last_activity = time.monotonic()
        self.finalized = False

        self.lock = threading.Lock()
        self.bytes_done = {}
        self.done = set()
        self.failed = set()
        self.dest_paths = {}
        self.bytes_total = sum(int(f.get("size") or 0) for f in files.values())

    @property
    def peer(self):
        return self.sender_info.get("alias") or "device"

    @property
    def device_type(self):
        dt = self.sender_info.get("deviceType")
        return dt if dt in DEVICE_TYPES else "desktop"

    def note_bytes(self, file_id, n):
        with self.lock:
            self.bytes_done[file_id] = n
            self.last_activity = time.monotonic()
            return sum(self.bytes_done.values())

    def finish_file(self, file_id, ok):
        with self.lock:
            self.last_activity = time.monotonic()
            (self.done if ok else self.failed).add(file_id)
            if self.finalized:
                return False, False
            if len(self.done) + len(self.failed) < len(self.files):
                return False, False
            self.finalized = True
            return True, not self.failed

    def settle(self):
        with self.lock:
            if self.finalized:
                return False
            self.finalized = True
            return True

    def progress(self):
        with self.lock:
            return sum(self.bytes_done.values()), len(self.done)


class _CancelledSend(Exception):
    pass


class _ProgressReader:
    """Filelike body for outbound uploads"""

    def __init__(self, path, cancel_event, on_progress):
        self._f = open(path, "rb")
        self._cancel = cancel_event
        self._on_progress = on_progress
        self._done = 0
        self._last_emit = 0.0

    def read(self, n=-1):
        if self._cancel.is_set():
            raise _CancelledSend()
        chunk = self._f.read(n)
        self._done += len(chunk)
        now = time.monotonic()
        if chunk and now - self._last_emit >= PROGRESS_INTERVAL:
            self._last_emit = now
            self._on_progress(self._done)
        return chunk

    def close(self):
        try:
            self._f.close()
        except OSError:
            pass


class Server:
    def __init__(self, port, download_dir, device_type="desktop", alias=None):
        self.self_info = SelfInfo(port, device_type, alias)
        self.events = EventBus(local_events_socket_path(),
                               greeting=self.state_message)
        self.registry = PeerRegistry(
            self.self_info.fingerprint, self.push_state)
        self.discovery = Discovery(self.self_info, self.registry)
        self.download_dir = download_dir
        self.favorites = []

        self.state_lock = threading.RLock()
        self.instance_id = uuid.uuid4().hex
        self.seq = 0
        self.incoming = None
        self.active = None
        self.result = None

        self.inbound_sessions = {}
        self.inbound_lock = threading.Lock()

        self.outbound = None
        self.outbound_lock = threading.Lock()

    def _snapshot_locked(self):
        return {
            "instanceId": self.instance_id,
            "seq": self.seq,
            "self": {
                "alias": self.self_info.alias,
                "fingerprint": self.self_info.fingerprint,
                "port": self.self_info.port,
                "protocol": self.self_info.protocol,
                "deviceType": self.self_info.deviceType,
                "localIp": _local_ip(),
                "multicast": self.discovery.available,
                "downloadDir": str(self.download_dir),
            },
            "incoming": dict(self.incoming) if self.incoming else None,
            "active": dict(self.active) if self.active else None,
            "result": dict(self.result) if self.result else None,
            "devices": self.registry.list(),
        }

    def snapshot(self):
        with self.state_lock:
            return self._snapshot_locked()

    def state_message(self):
        return {"type": "state", "data": self.snapshot()}

    def push_state(self):
        with self.state_lock:
            self.seq += 1
            snap = self._snapshot_locked()
        self.events.emit("state", snap)

    def set_incoming(self, value):
        with self.state_lock:
            self.incoming = value
        self.push_state()

    def clear_incoming(self, session_id=None):
        with self.state_lock:
            if self.incoming and (session_id is None or self.incoming.get("sessionId") == session_id):
                self.incoming = None
            else:
                return
        self.push_state()

    def set_active(self, value):
        with self.state_lock:
            self.active = value
        self.push_state()

    def update_active(self, transfer_id, **fields):
        with self.state_lock:
            if not self.active or self.active.get("id") != transfer_id:
                return False
            self.active.update(fields)
        self.push_state()
        return True

    def clear_active(self, transfer_id=None):
        with self.state_lock:
            if not self.active:
                return False
            if transfer_id is not None and self.active.get("id") != transfer_id:
                return False
            self.active = None
        return True

    def finish(self, transfer_id, kind, peer, device_type="desktop", count=0, files=None, code=None, detail=None):
        with self.state_lock:
            if transfer_id is not None and self.active and self.active.get("id") != transfer_id:
                return
            self.active = None
            self.result = {
                "id": uuid.uuid4().hex,
                "kind": kind,
                "peer": peer,
                "deviceType": device_type if device_type in DEVICE_TYPES else "desktop",
                "count": count,
                "files": files or [],
                "code": code,
                "detail": detail,
                "at": time.time(),
            }
        self.push_state()

    def dismiss_result(self, result_id=None):
        with self.state_lock:
            if not self.result:
                return
            if result_id and self.result.get("id") != result_id:
                return
            self.result = None
        self.push_state()

    def is_busy(self):
        with self.state_lock:
            return self.active is not None or self.incoming is not None

    def _reap_loop(self):
        while True:
            time.sleep(2)
            try:
                self._reap_once()
            except Exception as e:
                print(f"[localsend] reaper error: {e}")

    def _reap_once(self):
        now = time.monotonic()
        with self.inbound_lock:
            sessions = list(self.inbound_sessions.items())

        for sid, session in sessions:
            if session.confirmed is not True or session.finalized:
                if now - session.created_at > INBOUND_MAX_AGE:
                    with self.inbound_lock:
                        self.inbound_sessions.pop(sid, None)
                continue

            stalled = now - session.last_activity > INBOUND_STALL_TIMEOUT
            too_old = now - session.created_at > INBOUND_MAX_AGE
            if not (stalled or too_old):
                continue
            if not session.settle():
                continue
            with self.inbound_lock:
                self.inbound_sessions.pop(sid, None)
            session.cancelled = True
            self._cleanup_partials(session)
            self.finish(
                f"recv:{sid}", "recv_failed", session.peer, session.device_type,
                count=len(session.files),
                files=[{"fileName": f.get("fileName", "file")}
                       for f in session.files.values()],
                detail="The sender stopped responding.",
            )

    @staticmethod
    def _cleanup_partials(session):
        with session.lock:
            partials = [p for fid, p in session.dest_paths.items()
                        if fid not in session.done]
        for p in partials:
            try:
                os.unlink(p)
            except OSError:
                pass

    def start(self):
        self.download_dir.mkdir(parents=True, exist_ok=True)
        self.events.start()
        self.discovery.start()
        threading.Thread(target=self._reap_loop, daemon=True).start()


def _read_json_body(handler, limit=32 * 1024 * 1024):
    length = int(handler.headers.get("Content-Length", 0) or 0)
    if length <= 0:
        return {}
    if length > limit:
        raise ValueError("body too large")
    return json.loads(handler.rfile.read(length).decode("utf-8"))


def _send_json(handler, status, obj):
    body = json.dumps(obj).encode("utf-8")
    try:
        handler.send_response(status)
        handler.send_header("Content-Type", "application/json")
        handler.send_header("Content-Length", str(len(body)))
        handler.end_headers()
        handler.wfile.write(body)
    except OSError:
        pass


def _send_empty(handler, status):
    try:
        handler.send_response(status)
        handler.send_header("Content-Length", "0")
        handler.end_headers()
    except OSError:
        pass


def _drain(handler):
    remaining = int(handler.headers.get("Content-Length", 0) or 0)
    while remaining > 0:
        chunk = handler.rfile.read(min(65536, remaining))
        if not chunk:
            break
        remaining -= len(chunk)


def make_handler(server: Server):
    class Handler(BaseHTTPRequestHandler):
        protocol_version = "HTTP/1.1"

        def log_message(self, fmt, *args):
            pass

        def _is_local(self):
            return self.client_address[0] in LOOPBACK_IPS

        def do_GET(self):
            parsed = urlparse(self.path)
            path = parsed.path
            qs = parse_qs(parsed.query)

            if path == "/api/localsend/v2/info":
                return _send_json(self, 200, server.self_info.as_dict())

            if not path.startswith("/api/self/v1/"):
                return _send_empty(self, 404)
            if not self._is_local():
                return _send_empty(self, 403)

            route = path[len("/api/self/v1/"):]

            if route == "state":
                return _send_json(self, 200, server.snapshot())
            if route == "get-network-info":
                return _send_json(self, 200, {
                    "alias": server.self_info.alias,
                    "fingerprint": server.self_info.fingerprint,
                    "port": server.self_info.port,
                    "protocol": server.self_info.protocol,
                    "deviceType": server.self_info.deviceType,
                    "localIp": _local_ip(),
                })
            if route == "set-device-type":
                dtype = qs.get("type", [""])[0]
                if dtype in DEVICE_TYPES and dtype != server.self_info.deviceType:
                    server.self_info.deviceType = dtype
                    server.discovery.announce()
                    server.push_state()
                return _send_empty(self, 200)
            if route == "set-alias":
                alias = qs.get("alias", [""])[0].strip(
                ) or server.self_info.default_alias
                if alias != server.self_info.alias:
                    server.self_info.alias = alias
                    server.discovery.announce()
                    server.push_state()
                return _send_empty(self, 200)
            if route == "get-network-interfaces":
                return _send_json(self, 200, [])
            if route == "scan-current":
                return _send_json(self, 200, server.registry.list())
            if route == "scan-now":
                server.discovery.announce()
                return _send_empty(self, 200)
            if route == "confirm-recv":
                return self._handle_confirm_recv(qs)
            if route == "dismiss-result":
                server.dismiss_result(qs.get("id", [""])[0] or None)
                return _send_empty(self, 200)
            if route == "cancel":
                return self._handle_local_cancel()
            if route == "confirm-download":
                return _send_empty(self, 200)
            if route == "text-received-dismiss":
                return _send_empty(self, 200)
            if route == "favorites":
                return _send_json(self, 200, server.favorites)

            return _send_empty(self, 404)

        def do_POST(self):
            parsed = urlparse(self.path)
            path = parsed.path
            qs = parse_qs(parsed.query)

            if path == "/api/localsend/v2/register":
                try:
                    info = _read_json_body(self)
                except (ValueError, UnicodeDecodeError, OSError):
                    return _send_empty(self, 400)
                if isinstance(info, dict):
                    server.registry.upsert(info, self.client_address[0])
                return _send_json(self, 200, server.self_info.as_dict())

            if path == "/api/localsend/v2/prepare-upload":
                return self._handle_prepare_upload(qs)

            if path == "/api/localsend/v2/upload":
                return self._handle_upload(qs)

            if path == "/api/localsend/v2/cancel":
                return self._handle_remote_cancel(qs)

            if not path.startswith("/api/self/v1/"):
                return _send_empty(self, 404)
            if not self._is_local():
                return _send_empty(self, 403)

            route = path[len("/api/self/v1/"):]

            if route == "upload-batch":
                return self._handle_upload_batch()
            if route == "cancel":
                return self._handle_local_cancel()
            if route == "dismiss-result":
                server.dismiss_result(qs.get("id", [""])[0] or None)
                return _send_empty(self, 200)
            if route == "favorites":
                try:
                    body = _read_json_body(self)
                except (ValueError, UnicodeDecodeError, OSError):
                    return _send_empty(self, 400)
                server.favorites.append(body)
                return _send_json(self, 200, server.favorites)

            return _send_empty(self, 404)

        def do_DELETE(self):
            parsed = urlparse(self.path)
            if parsed.path.startswith("/api/self/v1/favorites/"):
                if not self._is_local():
                    return _send_empty(self, 403)
                fp = parsed.path.rsplit("/", 1)[-1]
                server.favorites[:] = [
                    f for f in server.favorites if f.get("fingerprint") != fp]
                return _send_empty(self, 200)
            return _send_empty(self, 404)

        def _handle_prepare_upload(self, qs):
            try:
                body = _read_json_body(self)
            except (ValueError, UnicodeDecodeError, OSError):
                return _send_empty(self, 400)

            if not isinstance(body, dict):
                return _send_empty(self, 400)
            sender_info = body.get("info") or {}
            raw_files = body.get("files") or {}
            if not isinstance(raw_files, dict) or not raw_files:
                return _send_empty(self, 400)

            files = {}
            for fid, meta in raw_files.items():
                if not isinstance(meta, dict):
                    continue
                files[str(fid)] = {
                    "id": str(fid),
                    "fileName": _safe_file_name(meta.get("fileName") or str(fid)),
                    "size": int(meta.get("size") or 0),
                    "fileType": meta.get("fileType") or "application/octet-stream",
                }
            if not files:
                return _send_empty(self, 400)

            if server.is_busy():
                return _send_empty(self, 409)

            session_id = uuid.uuid4().hex
            session = InboundSession(session_id, sender_info, files)
            with server.inbound_lock:
                server.inbound_sessions[session_id] = session

            server.set_incoming({
                "sessionId": session_id,
                "from": session.peer,
                "deviceType": session.device_type,
                "fileCount": len(files),
                "totalBytes": session.bytes_total,
                "files": [{"fileName": f["fileName"], "size": f["size"]} for f in files.values()],
                "expiresAt": time.time() + CONFIRM_TIMEOUT,
            })

            outcome = self._await_confirmation(session)

            if outcome != "answered" or session.cancelled or not session.confirmed:
                with server.inbound_lock:
                    server.inbound_sessions.pop(session_id, None)
                server.clear_incoming(session_id)
                if outcome == "timeout" and session.settle():
                    server.finish(None, "recv_timeout", session.peer, session.device_type,
                                  count=len(files), detail="No answer in time.")
                elif outcome == "gone" and session.settle():
                    server.finish(None, "recv_cancelled", session.peer, session.device_type,
                                  count=len(files), detail="The sender cancelled the request.")
                return _send_empty(self, 403)

            server.clear_incoming(session_id)
            server.set_active({
                "id": f"recv:{session_id}",
                "direction": "recv",
                "phase": "waiting",
                "peer": session.peer,
                "deviceType": session.device_type,
                "fileName": next(iter(files.values()))["fileName"],
                "index": 0,
                "total": len(files),
                "bytesDone": 0,
                "bytesTotal": session.bytes_total,
                "startedAt": time.time(),
            })

            return _send_json(self, 200, {
                "sessionId": session_id,
                "files": dict(session.tokens),
            })

        def _await_confirmation(self, session):
            deadline = time.monotonic() + CONFIRM_TIMEOUT
            while True:
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    return "timeout"
                if session.confirm_event.wait(min(0.5, remaining)):
                    return "answered"
                if not self._peer_alive():
                    return "gone"

        def _peer_alive(self):
            try:
                readable, _, _ = select.select([self.connection], [], [], 0)
                if not readable:
                    return True
                return bool(self.connection.recv(1, socket.MSG_PEEK))
            except OSError:
                return False

        def _handle_upload(self, qs):
            session_id = qs.get("sessionId", [""])[0]
            file_id = qs.get("fileId", [""])[0]
            token = qs.get("token", [""])[0]

            with server.inbound_lock:
                session = server.inbound_sessions.get(session_id)

            if not session or session.cancelled or session.confirmed is not True:
                _drain(self)
                return _send_empty(self, 403)
            if not token or session.tokens.get(file_id) != token:
                _drain(self)
                return _send_empty(self, 403)
            with session.lock:
                already = file_id in session.done
            if already:
                _drain(self)
                return _send_empty(self, 200)

            file_meta = session.files.get(file_id, {})
            file_name = file_meta.get("fileName", file_id)
            transfer_id = f"recv:{session_id}"
            expected = int(self.headers.get("Content-Length", 0) or 0)

            try:
                dest = _unique_dest_path(server.download_dir, file_name)
            except OSError as e:
                print(
                    f"[localsend] cannot open destination for {file_name}: {e}")
                self._fail_inbound_file(
                    session, file_id, "Couldn't write to the download folder.")
                _drain(self)
                return _send_empty(self, 500)

            with session.lock:
                session.dest_paths[file_id] = str(dest)
                index = len(session.done)

            def publish(done_bytes):
                total_done, completed = session.progress()
                server.update_active(
                    transfer_id,
                    phase="transferring",
                    fileName=file_name,
                    index=completed,
                    total=len(session.files),
                    bytesDone=total_done,
                    bytesTotal=session.bytes_total,
                )

            session.note_bytes(file_id, 0)
            server.update_active(transfer_id, phase="transferring", fileName=file_name,
                                 index=index, total=len(session.files))

            remaining = expected
            received = 0
            last_emit = time.monotonic()
            ok = False
            try:
                with open(dest, "wb") as f:
                    while remaining > 0:
                        if session.cancelled:
                            break
                        chunk = self.rfile.read(min(65536, remaining))
                        if not chunk:
                            break
                        f.write(chunk)
                        remaining -= len(chunk)
                        received += len(chunk)
                        session.note_bytes(file_id, received)
                        now = time.monotonic()
                        if now - last_emit >= PROGRESS_INTERVAL:
                            last_emit = now
                            publish(received)
                ok = remaining == 0 and not session.cancelled
            except OSError as e:
                print(f"[localsend] write failed for {file_name}: {e}")
                ok = False

            if not ok:
                try:
                    os.unlink(dest)
                except OSError:
                    pass
                self._fail_inbound_file(
                    session, file_id, "The transfer was interrupted.")
                return _send_empty(self, 500 if not session.cancelled else 409)

            settled, all_ok = session.finish_file(file_id, True)
            if not settled:
                publish(received)
                return _send_empty(self, 200)

            with server.inbound_lock:
                server.inbound_sessions.pop(session_id, None)
            if all_ok:
                server.finish(
                    transfer_id, "received", session.peer, session.device_type,
                    count=len(session.files),
                    files=[{"fileName": f.get("fileName", "file")}
                           for f in session.files.values()],
                )
            else:
                Server._cleanup_partials(session)
                server.finish(
                    transfer_id, "recv_failed", session.peer, session.device_type,
                    count=len(session.files),
                    files=[{"fileName": f.get("fileName", "file")}
                           for f in session.files.values()],
                    detail="Some files didn't arrive.",
                )
            return _send_empty(self, 200)

        @staticmethod
        def _fail_inbound_file(session, file_id, detail):
            settled, _ = session.finish_file(file_id, False)
            if not settled:
                return
            with server.inbound_lock:
                server.inbound_sessions.pop(session.session_id, None)
            Server._cleanup_partials(session)
            kind = "recv_cancelled" if session.cancelled else "recv_failed"
            server.finish(
                f"recv:{session.session_id}", kind, session.peer, session.device_type,
                count=len(session.files),
                files=[{"fileName": f.get("fileName", "file")}
                       for f in session.files.values()],
                detail=detail,
            )

        def _handle_confirm_recv(self, qs):
            session_id = qs.get("sessionId", [""])[0]
            confirmed = qs.get("confirmed", ["false"])[0] == "true"
            with server.inbound_lock:
                session = server.inbound_sessions.get(session_id)
            if not session:
                server.clear_incoming(session_id)
                return _send_empty(self, 404)
            session.confirmed = confirmed
            session.last_activity = time.monotonic()
            session.confirm_event.set()
            if not confirmed:
                server.clear_incoming(session_id)
            return _send_empty(self, 200)

        def _handle_remote_cancel(self, qs):
            session_id = qs.get("sessionId", [""])[0]

            with server.outbound_lock:
                outbound = server.outbound
            if outbound and session_id and outbound.get("session_id") == session_id:
                outbound["remote_cancelled"] = True
                outbound["cancel"].set()
                _shutdown_conn(outbound.get("conn"))
                return _send_empty(self, 200)

            with server.inbound_lock:
                session = server.inbound_sessions.get(session_id)
            if session:
                session.cancelled = True
                session.confirm_event.set()
                if session.settle():
                    with server.inbound_lock:
                        server.inbound_sessions.pop(session_id, None)
                    Server._cleanup_partials(session)
                    server.clear_incoming(session_id)
                    server.finish(
                        f"recv:{session_id}", "recv_cancelled", session.peer, session.device_type,
                        count=len(session.files), detail="The sender cancelled.",
                    )
            return _send_empty(self, 200)

        def _handle_local_cancel(self):
            with server.outbound_lock:
                outbound = server.outbound
            if outbound:
                outbound["cancel"].set()
                _shutdown_conn(outbound.get("conn"))
                return _send_empty(self, 200)

            with server.inbound_lock:
                sessions = list(server.inbound_sessions.values())
            for session in sessions:
                session.cancelled = True
                session.confirm_event.set()
                if session.settle():
                    with server.inbound_lock:
                        server.inbound_sessions.pop(session.session_id, None)
                    Server._cleanup_partials(session)
                    server.clear_incoming(session.session_id)
                    server.finish(f"recv:{session.session_id}", "cancelled", session.peer,
                                  session.device_type, count=len(
                                      session.files),
                                  detail="Cancelled on this device.")
            if not sessions:
                if server.clear_active():
                    server.push_state()
                server.clear_incoming()
            return _send_empty(self, 200)

        def _handle_upload_batch(self):
            try:
                body = _read_json_body(self)
            except (ValueError, UnicodeDecodeError, OSError):
                return _send_empty(self, 400)

            target_ip = (body.get("target") or "").strip()
            file_urls = body.get("files") or []
            pin = body.get("pin") or ""
            if not target_ip:
                return _send_json(self, 400, {"error": "no target"})

            paths, missing = [], []
            for url in file_urls:
                p = unquote(url[len("file://"):]
                            if url.startswith("file://") else url)
                (paths if os.path.isfile(p) else missing).append(p)
            if not paths:
                return _send_json(self, 400, {"error": "no readable files", "missing": missing})

            peer = server.registry.find_by_ip(target_ip) or {}
            target = {
                "ip": target_ip,
                "port": int(peer.get("port") or body.get("port") or MULTICAST_PORT),
                "alias": peer.get("alias") or body.get("name") or target_ip,
                "protocol": peer.get("protocol") or body.get("protocol") or "http",
                "deviceType": peer.get("deviceType") or body.get("deviceType") or "desktop",
            }

            transfer_id = "send:" + uuid.uuid4().hex
            with server.outbound_lock:
                if server.outbound is not None:
                    return _send_json(self, 409, {"error": "another transfer is already running"})
                if server.is_busy():
                    return _send_json(self, 409, {"error": "busy"})
                outbound = {
                    "id": transfer_id,
                    "cancel": threading.Event(),
                    "conn": None,
                    "session_id": None,
                    "remote_cancelled": False,
                }
                server.outbound = outbound

            total_bytes = 0
            files_meta = {}
            order = []
            for p in paths:
                fid = uuid.uuid4().hex
                size = os.path.getsize(p)
                total_bytes += size
                order.append((fid, p))
                files_meta[fid] = {
                    "id": fid,
                    "fileName": os.path.basename(p),
                    "size": size,
                    "fileType": mimetypes.guess_type(p)[0] or "application/octet-stream",
                }

            server.set_active({
                "id": transfer_id,
                "direction": "send",
                "phase": "waiting",
                "peer": target["alias"],
                "deviceType": target["deviceType"],
                "fileName": files_meta[order[0][0]]["fileName"],
                "index": 0,
                "total": len(order),
                "bytesDone": 0,
                "bytesTotal": total_bytes,
                "startedAt": time.time(),
            })

            threading.Thread(
                target=_outbound_worker,
                args=(server, outbound, target,
                      files_meta, order, total_bytes, pin),
                daemon=True,
            ).start()

            return _send_json(self, 202, {"transferId": transfer_id, "skipped": missing})

    return Handler


def _shutdown_conn(conn):
    if conn is None:
        return
    try:
        if getattr(conn, "sock", None):
            conn.sock.shutdown(socket.SHUT_RDWR)
    except OSError:
        pass
    try:
        conn.close()
    except Exception:
        pass


def _peer_responds(base_url, timeout=3):
    try:
        _urlopen(urllib.request.Request(
            f"{base_url}/api/localsend/v2/info"), timeout=timeout).read()
        return True
    except Exception:
        return False


def _outbound_worker(server, outbound, target, files_meta, order, total_bytes, pin):
    try:
        _run_outbound(server, outbound, target,
                      files_meta, order, total_bytes, pin)
    except Exception as e:
        print(f"[localsend] outbound worker crashed: {e!r}")
    finally:
        with server.outbound_lock:
            leaked = server.outbound is outbound
            if leaked:
                server.outbound = None
        if leaked:
            server.finish(outbound["id"], "peer_error", target["alias"], target["deviceType"],
                          count=len(order), detail="The transfer ended unexpectedly.")


def _run_outbound(server, outbound, target, files_meta, order, total_bytes, pin):
    transfer_id = outbound["id"]
    cancel = outbound["cancel"]
    alias = target["alias"]
    dtype = target["deviceType"]
    base_url = f"{target['protocol']}://{target['ip']}:{target['port']}"
    all_names = [{"fileName": files_meta[fid]["fileName"]} for fid, _ in order]

    def done(kind, code=None, detail=None, count=None):
        with server.outbound_lock:
            if server.outbound is outbound:
                server.outbound = None
        server.finish(transfer_id, kind, alias, dtype,
                      count=len(order) if count is None else count,
                      files=all_names, code=code, detail=detail)

    def cancel_remote_session():
        sid = outbound.get("session_id")
        if not sid:
            return
        try:
            _urlopen(urllib.request.Request(
                f"{base_url}/api/localsend/v2/cancel?sessionId={sid}", method="POST"
            ), timeout=5).read()
        except Exception:
            pass

    prep_path = "/api/localsend/v2/prepare-upload" + \
        (f"?pin={pin}" if pin else "")
    prep_body = json.dumps(
        {"info": server.self_info.as_dict(), "files": files_meta}).encode()

    conn = (
        http.client.HTTPSConnection(target["ip"], target["port"], timeout=CONFIRM_TIMEOUT + 5,
                                    context=_UNVERIFIED_SSL_CONTEXT)
        if target["protocol"] == "https" else
        http.client.HTTPConnection(
            target["ip"], target["port"], timeout=CONFIRM_TIMEOUT + 5)
    )
    outbound["conn"] = conn
    try:
        conn.request("POST", prep_path, body=prep_body, headers={
                     "Content-Type": "application/json"})
        resp = conn.getresponse()
        status = resp.status
        prep_raw = resp.read()
    except Exception as e:
        if cancel.is_set():
            return done("cancelled", detail="Cancelled before it started.")
        print(
            f"[localsend] prepare-upload to {target['ip']} ({target['protocol']}) failed: {e}")
        return done("unreachable", detail=f"Couldn't reach {alias}.")
    finally:
        outbound["conn"] = None
        try:
            conn.close()
        except Exception:
            pass

    if cancel.is_set():
        return done("cancelled", detail="Cancelled before it started.")

    if status == 401:
        return done("pin_required", code=401, detail=f"{alias} requires a PIN.")
    if status == 403:
        return done("declined", code=403, detail=f"{alias} declined the transfer.")
    if status == 409:
        return done("busy", code=409, detail=f"{alias} is busy with another transfer.")
    if status == 429:
        return done("rate_limited", code=429, detail=f"{alias} is getting too many requests.")
    if status < 200 or status >= 300:
        return done("peer_error", code=status, detail=f"{alias} answered with HTTP {status}.")

    try:
        prep_resp = json.loads(prep_raw.decode("utf-8")) if prep_raw else {}
    except (ValueError, UnicodeDecodeError):
        prep_resp = {}
    if not isinstance(prep_resp, dict):
        prep_resp = {}

    session_id = prep_resp.get("sessionId")
    tokens = prep_resp.get("files") or {}
    outbound["session_id"] = session_id

    if not session_id or not isinstance(tokens, dict) or not tokens:
        return done("sent", detail="Nothing left to send — the other device already had these.")

    server.update_active(transfer_id, phase="transferring")

    completed_bytes = 0
    sent = 0
    for fid, path in order:
        if cancel.is_set():
            break
        token = tokens.get(fid)
        file_name = files_meta[fid]["fileName"]
        file_size = files_meta[fid]["size"]
        if not token:
            completed_bytes += file_size
            sent += 1
            continue

        def emit_progress(file_done, _name=file_name, _idx=sent, _base=completed_bytes):
            server.update_active(transfer_id, fileName=_name, index=_idx, total=len(order),
                                 bytesDone=_base + file_done, bytesTotal=total_bytes)

        emit_progress(0)
        reader = _ProgressReader(path, cancel, emit_progress)
        try:
            _urlopen(urllib.request.Request(
                f"{base_url}/api/localsend/v2/upload?sessionId={session_id}&fileId={fid}&token={token}",
                data=reader, method="POST",
                headers={"Content-Type": "application/octet-stream",
                         "Content-Length": str(file_size)},
            ), timeout=300).read()
        except Exception as e:
            if cancel.is_set() or isinstance(e, _CancelledSend):
                break
            if outbound["remote_cancelled"]:
                break
            if isinstance(e, urllib.error.HTTPError) and e.code in (403, 404, 409, 410):
                return done("remote_cancelled", code=e.code,
                            detail=f"{alias} cancelled the transfer.")
            print(
                f"[localsend] upload to {target['ip']} ({target['protocol']}) failed: {e}")
            cancel_remote_session()
            if _peer_responds(base_url):
                return done("remote_cancelled", detail=f"{alias} cancelled the transfer.")
            return done("unreachable", detail=f"Lost the connection to {alias} partway through.")
        finally:
            reader.close()

        completed_bytes += file_size
        sent += 1
        server.update_active(transfer_id, index=sent, bytesDone=completed_bytes,
                             bytesTotal=total_bytes)

    if cancel.is_set() or sent < len(order):
        if outbound["remote_cancelled"]:
            return done("remote_cancelled", detail=f"{alias} cancelled the transfer.")
        cancel_remote_session()
        return done("cancelled", count=sent, detail="Cancelled on this device.")

    return done("sent")


def _safe_file_name(name):
    name = str(name).replace("\\", "/").split("/")[-1].strip()
    name = name.replace("\0", "")
    if not name or name in (".", ".."):
        return "file"
    return name[:200]


def _unique_dest_path(directory, file_name):
    base = Path(file_name).stem or "file"
    ext = Path(file_name).suffix
    dest = directory / file_name
    i = 1
    while dest.exists():
        dest = directory / f"{base} ({i}){ext}"
        i += 1
    return dest


class _QuietThreadingHTTPServer(ThreadingHTTPServer):
    daemon_threads = True

    def handle_error(self, request, client_address):
        exc = sys.exc_info()[1]
        if isinstance(exc, (ConnectionResetError, BrokenPipeError, TimeoutError, socket.timeout)):
            return
        super().handle_error(request, client_address)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=MULTICAST_PORT)
    parser.add_argument("--download-dir", type=str,
                        default=str(Path.home() / "Downloads" / "LocalSend"))
    parser.add_argument("--device-type", type=str,
                        default="desktop", choices=DEVICE_TYPES)
    parser.add_argument("--alias", type=str, default="")
    args = parser.parse_args()

    _die_with_parent()
    _kill_stale_instances(args.port)

    server = Server(args.port, Path(args.download_dir),
                    args.device_type, args.alias or None)

    httpd = None
    for _ in range(10):
        try:
            httpd = _QuietThreadingHTTPServer(
                ("0.0.0.0", args.port), make_handler(server))
            break
        except OSError:
            time.sleep(0.3)
    if httpd is None:
        print(f"[localsend] cannot bind port {args.port}, giving up")
        sys.exit(1)

    server.start()
    print(
        f"[localsend] alias={server.self_info.alias} fingerprint={server.self_info.fingerprint} port={args.port}")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
