# see https://github.com/loomio/loomio-deploy/blob/master/crontab

# every hour at the beginning of the hour
every :hour, at: 5 do
  rake 'loomio:hourly_tasks >/dev/null'
end
