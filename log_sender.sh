#!/bin/ash
DIR_LOG='/tmp'
DIR_ROTATE='/tmp/dir_rotate'
mkdir $DIR_ROTATE
RETRY=$?
if [ $RETRY = 0 ]; then
  mv $DIR_LOG/syslog* $DIR_ROTATE
else
  echo "Retry to send logs from $DIR_ROTATE"
fi
for LOG_PATH in `ls $DIR_ROTATE`
do
  curl -F"operation=upload" -F"file=@$DIR_ROTATE/$LOG_PATH" http://vtest.wifistyle.ru/log_upload.php
  if [ $? = 1 ]; then
    echo "Send err" >&2
    exit 1
  fi
  rm $DIR_ROTATE/$LOG_PATH
done
if [ $RETRY = 1 ]; then
  echo "Send another logs"
  mv $DIR_LOG/syslog* $DIR_ROTATE
  for LOG_PATH in `ls $DIR_ROTATE`
  do
    curl -F"operation=upload" -F"file=@$DIR_ROTATE/$LOG_PATH" http://vtest.wifistyle.ru/log_upload.php
    if [ $? = 1 ]; then
      echo "Send err" >&2
      exit 1
    fi
    rm $DIR_ROTATE/$LOG_PATH
  done
fi
rmdir $DIR_ROTATE
