#!/bin/bash
for f in 18*.mp4
do
	echo Processing $f ...
	./rone $f
done
