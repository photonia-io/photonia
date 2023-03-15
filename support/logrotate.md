~/logrotate.conf

````
/var/www/directory/shared/log/*.log {
	daily
	missingok
	rotate 15
	compress
	notifempty
	create 0644 photos photos
	sharedscripts
	postrotate
		touch /var/www/directory/current/tmp/restart.txt
	endscript
}
````

crontab entry

    0 2 * * * logrotate /home/user/logrotate.conf --state /home/user/logrotate-state
