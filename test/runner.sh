#!/bin/sh
bash ./node_modules/.bin/nave use 0.8.20 && \
npm install zombie && \
./node_modules/.bin/coffee test/runner.coffee