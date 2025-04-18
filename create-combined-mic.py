#!/usr/bin/python3

from typing import Callable, List, Any, Mapping, Set

import os
import sys
import subprocess
import shutil
import json
import threading
import time
import logging

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] [%(levelname)-5s] %(message)s",
    handlers=[
        logging.StreamHandler(sys.stdout),
    ],
)

log_events = False

log = logging.getLogger(__name__)


class PwObject:
    def __init__(self, data: dict):
        self.data = data

    @property
    def id(self) -> int:
        return self.data.get("id")

    @property
    def type(self) -> str:
        return self.data.get("type")

    def props(self, name: str) -> Any:
        info = self.data.get("info")
        if not info:
            return None
        return info.get("props", {}).get(name)

    def __str__(self):
        if self.type == "PipeWire:Interface:Node":
            opt_media_name = self.props('media.name')
            if opt_media_name is None:
                opt_media_name = ""
            else:
                opt_media_name = f" {opt_media_name}"
            return (
                f"Node {self.id} {self.props('media.class')} {self.props('node.name')}{opt_media_name}"
            )
        elif self.type == "PipeWire:Interface:Port":
            return f"Port {self.id} {self.props('port.name')}"
        elif self.type == "PipeWire:Interface:Link":
            return f"Link {self.id} {self.props('link.output.node')} : {self.props('link.output.port')} -> {self.props('link.input.node')} : {self.props('link.input.port')}"
        elif self.type == "PipeWire:Interface:Client":
            return f"Client {self.id} {self.props('application.name')}"
        else:
            return f"Unknown object {self.id} of type {self.type}"


def parse_pw_dump(pw_dump_str: str) -> List[PwObject]:
    nodes = []
    pw_dump = json.loads(pw_dump_str)
    assert isinstance(pw_dump, list)
    for node in pw_dump:
        nodes.append(PwObject(node))
    return nodes


def pw_dump() -> List[PwObject]:
    res = subprocess.check_output(["pw-dump"], text=True)
    return parse_pw_dump(res)


class VirtualSink:
    def __init__(self, name: str):
        self.sink_name = name
        curr_table = pw_dump()
        for node in curr_table:
            if (
                node.type == "PipeWire:Interface:Node"
                and node.props("factory.name") == "support.null-audio-sink"
                and node.props("node.name") == self.sink_name
            ):
                log.warning(
                    f"Virtual sink {self.sink_name} already exists - skipping creation"
                )
                self.module_id = node.props("pulse.module.id")
                return

        module_id_str = subprocess.check_output(
            [
                "pactl",
                "load-module",
                "module-null-sink",
                "media.class=Audio/Source/Virtual",
                "node.passive=true",
                # "node.latency=8192/48000",
                f"sink_name={self.sink_name}",
                "channel_map=front-left,front-right",
            ]
        )
        self.module_id = int(module_id_str.strip())
        dump = pw_dump()
        for node in dump:
            if self.match_pw_node(node):
                self.pw_node_id = node.id
                break
        else:
            raise RuntimeError(
                f"Failed to find PipeWire node for virtual sink {self.sink_name} after creation"
            )
        log.info(
            f"Created virtual sink {self.sink_name} with pipewire node id {self.pw_node_id}",
        )

    def delete(self):
        log.info(f"Deleting virtual sink {self.sink_name}")
        subprocess.check_call(["pactl", "unload-module", str(self.module_id)])

    def match_pw_node(self, node: PwObject) -> bool:
        return (
            node.type == "PipeWire:Interface:Node"
            and node.props("factory.name") == "support.null-audio-sink"
            and node.props("node.name") == self.sink_name
            and node.props("pulse.module.id") == self.module_id
        )


def pw_monitor():
    proc = subprocess.Popen(
        "pw-dump -m | jq -c --unbuffered",
        shell=True,
        stdout=subprocess.PIPE,
        text=True,
    )

    all_objs: Mapping[int, PwObject] = {}

    try:
        for line in iter(proc.stdout.readline, None):
            if not line:
                continue
            parsed_json = json.loads(line)
            assert isinstance(parsed_json, list)
            for change in parsed_json:
                if not change.get("type") and not change.get("info"):
                    # Deletion
                    deleted_obj_id = change.get("id")
                    if not deleted_obj_id:
                        log.warning(f"Empty change object received: {change}")
                        continue
                    if deleted_obj_id in all_objs:
                        obj = all_objs[deleted_obj_id]
                        if log_events:
                            log.debug(f"Event: delete on {obj}")
                        del all_objs[deleted_obj_id]
                else:
                    obj = PwObject(change)
                    exists = obj.id in all_objs
                    all_objs[obj.id] = obj
                    if log_events:
                        if exists:
                            log.debug(f"Event: change on {obj}")
                        else:
                            log.debug(f"Event: add on {obj}")
            yield all_objs.values()
    except KeyboardInterrupt:
        print("", flush=True)
        return


evt = threading.Event()
v_sink = None
latest_dump = None
stopped = False


def link_node(dump: List[PwObject], source: PwObject, sink: PwObject):
    global stopped
    source_ports = []
    sink_ports = []
    existing_links: Set[(int, int)] = set()
    for port in dump:
        if port.type == "PipeWire:Interface:Port":
            if port.props("node.id") == source.id:
                source_ports.append(port)
            elif port.props("node.id") == sink.id:
                sink_ports.append(port)
        elif port.type == "PipeWire:Interface:Link":
            source_id = port.props("link.output.port")
            sink_id = port.props("link.input.port")
            existing_links.add((source_id, sink_id))

    log.debug(
        f"  Source ports: {', '.join([p.props('port.name') for p in source_ports])}"
    )
    log.debug(f"  Sink ports: {', '.join([p.props('port.name') for p in sink_ports])}")
    source_channels_port = {}
    sink_channels_port = {}
    for port in source_ports:
        channel = port.props("audio.channel")
        direction = port.props("port.direction")
        if direction != "out":
            continue
        if channel is None:
            log.warning(f"{port} has no channel")
            continue
        if channel in source_channels_port:
            log.warning(
                f"Source {source} has duplicate channel {channel} among output ports"
            )
            continue
        source_channels_port[channel] = port
    for port in sink_ports:
        channel = port.props("audio.channel")
        direction = port.props("port.direction")
        if direction != "in":
            continue
        if channel is None:
            log.warning(f"Port {port.id} has no channel")
            continue
        if channel in sink_channels_port:
            log.warning(
                f"Sink {sink} has duplicate channel {channel} among input ports"
            )
            continue
        sink_channels_port[channel] = port
    if set(source_channels_port.keys()) != set(sink_channels_port.keys()):
        log.error(
            f"Source {source} and sink {sink} have different channel sets - refusing to link"
        )
        return
    if not source_channels_port:
        log.warning(f"Source {source} has no output ports")
        return
    for channel in source_channels_port.keys():
        source_port = source_channels_port[channel]
        sink_port = sink_channels_port[channel]
        if (source_port.id, sink_port.id) in existing_links:
            log.debug(
                f"Link {source_port.id} -> {sink_port.id} already exists - skipping"
            )
            continue
        if stopped:
            return
        attempts = 0
        while True:
            if attempts > 0:
                check_dump = pw_dump()
                found = False
                for obj in check_dump:
                    if obj.type == "PipeWire:Interface:Link":
                        if (
                            obj.props("link.output.port") == source_port.id
                            and obj.props("link.input.port") == sink_port.id
                        ):
                            log.info(
                                f"  ... but it did work. Continuing."
                            )
                            found = True
                            break
                if found:
                    break
            log.debug(
                f"Linking {source} {source_port.props('port.name')} to {sink.id} {sink_port.props('port.name')}"
            )
            try:
                subprocess.check_call(
                    ["pw-link", str(source_port.id), str(sink_port.id)],
                    timeout=2
                )
                break
            except subprocess.TimeoutExpired:
                log.error(
                    f"pw-link {source_port.id} {sink_port.id} did not finish within 2 seconds"
                )
                attempts += 1
                if attempts >= 2:
                    raise
            except subprocess.CalledProcessError as e:
                log.error(
                    f"pw-link {source_port.id} {sink_port.id} failed with error code {e.returncode}"
                )
                attempts += 1
                if attempts >= 2:
                    raise
        if stopped:
            return


def update(dump: List[PwObject]):
    global v_sink, stopped
    v_sink_node = None
    need_connect_sources = []
    already_connected_node_ids = set()

    if stopped:
        return

    log.debug("Updating links")

    for obj in dump:
        log.debug(f"Object: {obj}")

    all_input_stream_names = set()
    for obj in dump:
        if obj.type == "PipeWire:Interface:Node" and obj.props("media.class") == "Stream/Input/Audio":
            all_input_stream_names.add((obj.props("node.name"), obj.props("media.name")))
    log.debug(f"All input stream names: {all_input_stream_names}")

    for obj in dump:
        if v_sink.match_pw_node(obj):
            v_sink_node = obj
            continue
        if (
            obj.type == "PipeWire:Interface:Node"
            and obj.props("media.class") == "Stream/Output/Audio"
        ):
            if (obj.props("node.name"), obj.props("media.name")) in all_input_stream_names:
                log.debug(
                    f"Ignoring {obj} because it is also listening for input"
                )
                continue
            if "discord" in obj.props("media.name").lower():
                log.debug(
                    f"Ignoring Discord source {obj}"
                )
                continue
            need_connect_sources.append(obj)
            continue

    if v_sink_node is None:
        raise RuntimeError(f"Virtual sink {v_sink.sink_name} has disappeared")

    for obj in dump:
        if (
            obj.type == "PipeWire:Interface:Node"
            and obj.props("media.class") == "Audio/Source"
            and obj.id != v_sink_node.id
        ):
            need_connect_sources.append(obj)

    for obj in dump:
        if (
            obj.type == "PipeWire:Interface:Link"
            and obj.props("link.input.node") == v_sink_node.id
        ):
            already_connected_node_ids.add(obj.props("link.output.node"))

    for obj in set(need_connect_sources):
        log.debug(f"Eligible source to connect: {obj}")
        if obj.id in already_connected_node_ids:
            log.debug("  ... but already connected")
            continue
        log.info(
            f"Connecting source {obj} to virtual sink {v_sink.sink_name}"
        )
        link_node(dump, obj, v_sink_node)
        if stopped:
            return


def update_thread():
    global evt, latest_dump, stopped
    while not stopped:
        evt.wait()
        if stopped:
            break
        evt.clear()
        update(latest_dump)
        time.sleep(0.5)


t = threading.Thread(target=update_thread)
t.daemon = True
t.start()

try:
    v_sink = VirtualSink("combined-mic")
    for d in pw_monitor():
        # don't hold reference to the original directory in pw_monitor
        latest_dump = list(d)
        evt.set()
        if not t.is_alive():
            t = threading.Thread(target=update_thread)
            t.daemon = True
            t.start()
finally:
    stopped = True
    evt.clear()
    if v_sink:
        v_sink.delete()
