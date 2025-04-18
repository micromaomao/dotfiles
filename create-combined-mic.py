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
    level=logging.DEBUG,
    format="[%(asctime)s] [%(levelname)-5s] %(message)s",
    handlers=[
        logging.StreamHandler(sys.stdout),
    ],
)

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
                "node.latency=8192/48000",
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
                        log.debug(f"Event: delete on {obj.id} (type={obj.type})")
                        del all_objs[deleted_obj_id]
                else:
                    obj = PwObject(change)
                    exists = obj.id in all_objs
                    all_objs[obj.id] = obj
                    if exists:
                        log.debug(f"Event: change on {obj.id} (type={obj.type})")
                    else:
                        log.debug(f"Event: add on {obj.id} (type={obj.type})")
            yield all_objs.values()
    except KeyboardInterrupt:
        print("", flush=True)
        return


evt = threading.Event()
v_sink = None
latest_dump = None


def link_node(dump: List[PwObject], source: PwObject, sink: PwObject):
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
            log.warning(f"Port {port.id} has no channel")
            continue
        if channel in source_channels_port:
            log.warning(
                f"Source {source.id} has duplicate channel {channel} among output ports"
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
                f"Sink {sink.id} has duplicate channel {channel} among input ports"
            )
            continue
        sink_channels_port[channel] = port
    if set(source_channels_port.keys()) != set(sink_channels_port.keys()):
        log.error(
            f"Source {source.id} and sink {sink.id} have different channel sets - refusing to link"
        )
        return
    if not source_channels_port:
        log.warning(f"Source {source.id} has no output ports")
        return
    for channel in source_channels_port.keys():
        source_port = source_channels_port[channel]
        sink_port = sink_channels_port[channel]
        if (source_port.id, sink_port.id) in existing_links:
            log.debug(
                f"Link {source_port.id} -> {sink_port.id} already exists - skipping"
            )
            continue
        log.debug(
            f"Linking {source.id} {source_port.props('port.name')} to {sink.id} {sink_port.props('port.name')}"
        )
        subprocess.check_call(
            ["pw-link", str(source_port.id), str(sink_port.id)],
        )


def update(dump: List[PwObject]):
    global v_sink
    v_sink_node = None
    need_connect_sources = []
    already_connected_node_ids = set()

    log.debug("Updating links")

    for link in dump:
        if v_sink.match_pw_node(link):
            v_sink_node = link
            continue
        if (
            link.type == "PipeWire:Interface:Node"
            and link.props("media.class") == "Stream/Output/Audio"
        ):
            if "discord" in link.props("media.name").lower():
                log.debug(
                    f"Ignoring Discord source {link.id} {link.props('node.name')} ({link.props('media.name')})"
                )
                continue
            need_connect_sources.append(link)
            continue

    if v_sink_node is None:
        raise RuntimeError(f"Virtual sink {v_sink.sink_name} has disappeared")

    for link in dump:
        if (
            link.type == "PipeWire:Interface:Link"
            and link.props("link.input.node") == v_sink_node.id
        ):
            already_connected_node_ids.add(link.props("link.output.node"))

    for link in set(need_connect_sources):
        if link.id in already_connected_node_ids:
            continue
        node_name = link.props("node.name")
        media_name = link.props("media.name")
        log.info(
            f"Connecting source {link.id} {node_name} ({media_name}) to virtual sink {v_sink.sink_name}"
        )
        link_node(dump, link, v_sink_node)


def update_thread():
    global evt, latest_dump
    while True:
        evt.wait()
        evt.clear()
        update(latest_dump)
        time.sleep(0.5)


t = threading.Thread(target=update_thread)
t.daemon = True
t.start()

try:
    v_sink = VirtualSink("combined-mic")
    for d in pw_monitor():
        latest_dump = d
        evt.set()
        if not t.is_alive():
            t = threading.Thread(target=update_thread)
            t.daemon = True
            t.start()
finally:
    evt.clear()
    if v_sink:
        v_sink.delete()
