#!/usr/bin/env python

import pynvml
# curl -fSsL "$(curl -fSsL https://pypi.org/simple/nvidia-ml-py/ | \grep 'a href' | tail -n1 | sed 's|<a href=*"||; s|#.*||')" | tar -xO nvidia_ml_py-*/pynvml.py > pynvml.py
import json
import argparse
import functools
import time


@functools.cache
def get_handle(device_index):
    return pynvml.nvmlDeviceGetHandleByIndex(device_index)


def one_time():
    device_count = pynvml.nvmlDeviceGetCount()
    for device_index in range(device_count):
        handle = get_handle(device_index)
        uuid = pynvml.nvmlDeviceGetUUID(handle)
        shutdown_temp = pynvml.nvmlDeviceGetTemperatureThreshold(handle, pynvml.NVML_TEMPERATURE_THRESHOLD_SHUTDOWN)
        slow_temp = pynvml.nvmlDeviceGetTemperatureThreshold(handle, pynvml.NVML_TEMPERATURE_THRESHOLD_SLOWDOWN)
        gpu_temp_threshold = pynvml.nvmlDeviceGetTemperatureThreshold(handle, pynvml.NVML_TEMPERATURE_THRESHOLD_GPU_MAX)

        print('gpu_index,gpu_uuid,shutdown_temp,slowdown_temp,threshold_temp')
        print(f'{device_index},{uuid},{shutdown_temp},{slow_temp},{gpu_temp_threshold}')


def monitor(frequency, delay):
    device_count = pynvml.nvmlDeviceGetCount()

    count = 1
    t0 = time.time()

    while True:
        try:
            for device_index in range(device_count):
                temperature = pynvml.nvmlDeviceGetTemperature(
                    get_handle(device_index),
                    pynvml.NVML_TEMPERATURE_GPU
                )
            t1 = time.time()
            print(f'{t1:-.7f} GPU {device_index}: {temperature}°C')
            try:
                if delay is not None:
                    time.sleep(t0 + count * delay - t1)
                else:
                    time.sleep(t0 + count / frequency - t1)
            except ValueError:
                print("Time step too small")
            count += 1
        except KeyboardInterrupt:
          break


if __name__ == "__main__":
    argument_parser = argparse.ArgumentParser()
    argument_parser.add_argument('--frequency', default=1, type=float, help="How often to query temperature")
    argument_parser.add_argument('--delay', default=None, type=float, help="How often to query temperature")
    args = argument_parser.parse_args()

    try:
        pynvml.nvmlInit()
        one_time()
        monitor(args.frequency, args.delay)
    finally:
        print('Shutting down')
        pynvml.nvmlShutdown()
