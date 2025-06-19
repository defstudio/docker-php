#!/usr/bin/env bash
echo "Running Nighwatch agent..."
php /var/www/artisan nightwatch:agent --listen-on=0.0.0.0:2407
