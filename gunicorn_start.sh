#!/bin/bash

# As seen in http://tutos.readthedocs.org/en/latest/source/ndg.html

EVL_DIR="/var/interlegis/evl"

# Seta um novo diretório foi passado como raiz para o EVL
# caso esse tenha sido passado como parâmetro
if [ "$1" ]
then
    EVL_DIR="$1"
fi

NAME="EVL"                                     # Name of the application (*)
DJANGODIR=/var/interlegis/evl/                    # Django project directory (*)
SOCKFILE=/var/interlegis/evl/run/gunicorn.sock    # we will communicate using this unix socket (*)
USER=`whoami`                                   # the user to run as (*)
GROUP=`whoami`                                  # the group to run as (*)
NUM_WORKERS=3                                   # how many worker processes should Gunicorn spawn (*)
                                                # NUM_WORKERS = 2 * CPUS + 1
TIMEOUT=60
MAX_REQUESTS=100                                # number of requests before restarting worker
DJANGO_SETTINGS_MODULE=evl_admin.settings            # which settings file should Django use (*)
DJANGO_WSGI_MODULE=evl_admin.wsgi                    # WSGI module name (*)

echo "Starting $NAME as `whoami` on base dir $EVL_DIR"

# parameter can be passed to run without virtualenv
if [[ "$@" != "no-venv" ]]; then
    # Activate the virtual environment
    cd $DJANGODIR
    source /var/interlegis/.virtualenvs/evl/bin/activate
    export DJANGO_SETTINGS_MODULE=$DJANGO_SETTINGS_MODULE
    export PYTHONPATH=$DJANGODIR:$PYTHONPATH
fi

# Create the run directory if it doesn't exist
RUNDIR=$(dirname $SOCKFILE)
test -d $RUNDIR || mkdir -p $RUNDIR

# Start your Django Unicorn
# Programs meant to be run under supervisor should not daemonize themselves (do not use --daemon)
exec gunicorn ${DJANGO_WSGI_MODULE}:application \
  --name $NAME \
  --log-level debug \
  --timeout $TIMEOUT \
  --workers $NUM_WORKERS \
  --max-requests $MAX_REQUESTS \
  --user $USER \
  --access-logfile /var/log/evl/access.log \
  --error-logfile /var/log/evl/error.log \
  --bind=unix:$SOCKFILE
