#!/bin/bash

top -bn10 -d1 | \
    grep "Cpu(s)" | \
    awk -F',' '{print $4}' | \
    awk '{sum+=$1} END {print "Average idle: " sum/NR "%, Average usage: " (100-sum/NR) "%"}'