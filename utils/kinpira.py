#!/usr/bin/env python3
"""Utility functions for kinpira.

This script supports the integration of major DL frameworks and kinpira.
"""

from os.path import exists, join
import numpy as np

def dump(model, path_root="."):
    """Weight dumping function for kinpira.

    This script makes binary data for kinpira from software DL frameworks,
    such as tensorflow, chainer.
    """

    assert model
    # tensorflow model

    try:
        import tensorflow
    except ImportError:
        pass

    try:
        import keras
        # keras sequential model
        if isinstance(model, keras.models.Sequential):
            pass
        # keras functional model
        elif isinstance(model, keras.engine.training.Model):
            pass
        else:
            pass
    except ImportError:
        pass

    try:
        import chainer
        # chainer classifier model
        if isinstance(model, chainer.links.model.classifier.Classifier):
            pass
        else:
            pass
    except ImportError:
        pass

    assert isinstance(data, numpy.ndarray)

    data_int = np.around(data).astype("int16")

    assert path_root
    np.savetxt()


def graph(model):
    """Export the flow-graph for module definition.

    """

    assert model
