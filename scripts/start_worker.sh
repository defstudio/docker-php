#!/usr/bin/env bash

HORIZON_DIRECTORY=/var/www/vendor/laravel/horizon

if [ -d "$HORIZON_DIRECTORY" ]; then
   echo "Running Horizon worker..."
   php /var/www/artisan horizon
else
   echo "Running Standard worker..."
   php /var/www/artisan queue:work --verbose --tries=3 --timeout=90
fi

