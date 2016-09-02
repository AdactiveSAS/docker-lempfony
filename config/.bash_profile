# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# Symfony2 console autocomplete
if [ -e ~/symfony2-autocomplete.bash ]; then
    . ~/symfony2-autocomplete.bash
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi
# set PATH so it includes user's composer bin if it exists
if [ -d "$HOME/.composer/vendor/bin" ] ; then
    PATH="$HOME/.composer/vendor/bin:$PATH"
fi

eval "$(symfony-autocomplete)"

export IBUS_ENABLE_SYNC_MODE=1;
export ELECTRON_USE_UBUNTU_NOTIFIER=1
