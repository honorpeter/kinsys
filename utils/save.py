#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
from os.path import exists, join

import numpy as np

_save_func = {
    "LSTM":
        lambda name, layer: _save_lstm(name, layer),
    "BatchNormalization":
        lambda name, layer: _save_bn(name, layer),
}

def weight_fixed(model):
    model_name = model.__class__.__name__.lower()

    if not exists(model_name):
        os.makedirs(model_name)

    for layer_name, layer in model.namedlinks(skipself=True):
        layer_class = layer.__class__.__name__
        name = model_name + layer_name
        if layer_class in _save_func:
            params = _save_func[layer_class](name, layer)
        else:
            params = _save(name, layer)

        for filename, param in params:
            floatfile = param * 256
            fixedhex = np.around(floatfile).astype(np.int) & 0xffff
            np.savetxt(filename, fixedhex, fmt="%.4x")

def weight(model):
    model_name = model.__class__.__name__.lower()

    if not exists(model_name):
        os.makedirs(model_name)

    for layer_name, layer in model.namedlinks(skipself=True):
        layer_class = layer.__class__.__name__
        name = model_name + layer_name
        if layer_class in _save_func:
            params = _save_func[layer_class](name, layer)
        else:
            params = _save(name, layer)

        for filename, param in params:
            np.savetxt(filename, param, fmt="%8.8f")

def _save(name, layer, params=None):
    if not exists(name):
        os.makedirs(name)

    if params is None:
        params = layer.params()

    params_data = list()
    for param in params:
        filename = join(name, param.name+".dat")
        if isinstance(param.data, np.ndarray):
            params_data.append((filename, param.data.ravel()))
        else:
            params_data.append((filename, cupy.asnumpy(param.data.ravel())))
        print(filename, param.data.shape)

    return params_data

def save_bn(name, layer):
    params = [ ("gamma", layer.gamma.data)
             , ("beta", layer.beta.data)
             , ("mean", layer.avg_mean)
             , ("var",  layer.avg_var)
             , ("eps",  np.asarray(layer.eps, dtype=np.float32))
             ]

    save(name, layer, params)

def _save_lstm(name, layer):
    print(layer.__class__.__name__)
    for name, layer in layer.namedlinks():
        print(name)

