#!/usr/bin/env bash
echo "Running Nighwatch agent..."
php /var/www/artisan nightwatch:agent --listen-on=127.0.0.1:2407
