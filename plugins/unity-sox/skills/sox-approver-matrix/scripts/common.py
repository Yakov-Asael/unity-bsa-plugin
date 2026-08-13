"""Shared config loading for the SOX approver-matrix control."""
import json, os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, os.pardir))
SHOTS = os.path.join(HERE, "shots")
RAW = os.path.join(HERE, "raw")
DATA = os.path.join(HERE, "data")
# One output location, outside scripts/, so a run's results are easy to find.
OUT = os.path.join(ROOT, "output")


def config():
    with open(os.path.join(ROOT, "config.json")) as fh:
        return json.load(fh)


def objects():
    return config()["objects"]


def keys():
    return [o["key"] for o in objects()]


def by_key(key):
    for o in objects():
        if o["key"] == key:
            return o
    raise KeyError(f"{key} is not in config.json")


def load_json(path):
    with open(path) as fh:
        return json.load(fh)


def permission_sets(key):
    """Permission sets discovered for this object, from the captured ObjectPermissions
    result. Rows with a profile name are a profile's implicit permission set, not a
    real one, so they are excluded."""
    d = load_json(os.path.join(RAW, f"{key}_objperm.json"))
    names = [r.get("Parent.Name", "") for r in d.get("rows", [])
             if not r.get("Parent.Profile.Name")]
    return sorted({n for n in names if n})
