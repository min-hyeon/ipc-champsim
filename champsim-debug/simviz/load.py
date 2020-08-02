import os
import json
import collections
from parse import *


def dict_from_stats(path, fileparse):
    return fileparse(json.load(open(path, mode='r')))


def dict_from_debug(path):
    return 'not-implemented-yet'


def parse_json(d, pred, sep, stop, drop):
    items = []
    for key, value in d.items():
        key = pred + sep + key if pred else key
        if all(parse(expr, key) is None for expr in drop):
            if any(parse(expr, key) is not None for expr in stop):
                items.append((key, value))
            else:
                if isinstance(value, collections.MutableMapping):
                    items.extend(parse_json(value, pred=key, sep=sep, stop=stop, drop=drop).items())
                else:
                    items.append((key, value))
    return dict(items)


def dict_from_dir(path, fileload):
    dict = {}
    if os.path.isfile(path):
        return fileload(path)
    else:
        for subdir in os.listdir(path):
            if os.path.isdir(path):
                dict[subdir] = dict_from_dir(os.path.join(path, subdir), fileload)
        return dict