"""Уведомление на каждое заблокированное USB-устройство, с кнопками.

«Разрешить» пускает устройство до отключения. «Разрешить навсегда» пускает
его сразу и дописывает в белый список репозитория (USBGUARD_RULES_FILE):
правила самого демона лежат в /nix/store, и `allow-device -p` там не
разрешает устройство вовсе — демон падает, пытаясь сохранить правило.
"""

import os
import subprocess

import dbus
import dbus.mainloop.glib
from gi.repository import GLib

RULES_FILE = os.environ["USBGUARD_RULES_FILE"]

# Значения перечислений usbguard: Rule::Target и DeviceManager::EventType.
TARGET_ALLOW = 0
EVENT_INSERT = 1

# id уведомления -> (id устройства, его атрибуты): понять, на чём нажали.
pending = {}


def notifications():
    bus = dbus.SessionBus()
    obj = bus.get_object("org.freedesktop.Notifications", "/org/freedesktop/Notifications")
    return dbus.Interface(obj, "org.freedesktop.Notifications")


def show(summary, body, actions=(), urgency=1, timeout=-1):
    return notifications().Notify(
        "USBGuard", 0, "drive-removable-media", summary, body,
        list(actions), {"urgency": dbus.Byte(urgency)}, timeout,
    )


def on_presence(dev_id, event, target, _rule, attributes):
    if int(event) != EVENT_INSERT or int(target) == TARGET_ALLOW:
        return
    attrs = {str(k): str(v).strip() for k, v in attributes.items()}
    name = attrs.get("name") or "USB-устройство без имени"
    details = " · ".join(x for x in (attrs.get("id"), attrs.get("via-port")) if x)
    # urgency 2 (critical): само не гаснет, иначе его легко пропустить.
    nid = show(
        "USB-устройство заблокировано",
        f"{name}\n{details}" if details else name,
        ["allow", "Разрешить", "allow-permanent", "Разрешить навсегда"],
        urgency=2, timeout=0,
    )
    pending[int(nid)] = (int(dev_id), attrs)


def remember(attrs):
    """Дописать устройство в белый список, если его там ещё нет."""
    rule = f"allow id {attrs['id']}"
    with open(RULES_FILE, encoding="utf-8") as rules:
        if any(line.split("#")[0].strip() == rule for line in rules):
            return
    name = " ".join(attrs.get("name", "").split()) or "без имени"
    with open(RULES_FILE, "a", encoding="utf-8") as rules:
        rules.write(f"{rule} # {name}\n")


def on_action(nid, action):
    entry = pending.pop(int(nid), None)
    if entry is None:
        return
    dev_id, attrs = entry
    # Через CLI: он ходит по IPC-сокету (доступ дан в IPCAllowedUsers) и не
    # требует диалога polkit.
    subprocess.run(["usbguard", "allow-device", str(dev_id)], check=False)
    if str(action) == "allow-permanent" and attrs.get("id"):
        remember(attrs)
        show("Добавлено в белый список", "Навсегда — после следующего rebuild.", timeout=5000)


def on_closed(nid, _reason):
    pending.pop(int(nid), None)


def main():
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    dbus.SystemBus().add_signal_receiver(
        on_presence,
        signal_name="DevicePresenceChanged",
        dbus_interface="org.usbguard.Devices1",
    )
    session = dbus.SessionBus()
    session.add_signal_receiver(
        on_action,
        signal_name="ActionInvoked",
        dbus_interface="org.freedesktop.Notifications",
    )
    session.add_signal_receiver(
        on_closed,
        signal_name="NotificationClosed",
        dbus_interface="org.freedesktop.Notifications",
    )
    GLib.MainLoop().run()


if __name__ == "__main__":
    main()
