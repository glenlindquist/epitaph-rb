#!/bin/sh
PIDFile="server.pid"
kill -9 $(<"$PIDFile")
npm run build-dev
bundle exec rackup & echo $! > $PIDFile
