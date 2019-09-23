# mb-system-install-script
Mb-System install script by Jakub Zdroik 2019-09-21

## Script is for Ubuntu 18.04 

Script should do:
- check ubuntu libraries
- download gmt,mb-system sources
- compile && install to $HOME/mb-system
- will create $HOME/gmt.conf using mb-system in $HOME/mb-system
- check gmt mbcontour, gmt mbswath, gmt mbgrdtiff
- check mbinfo 
- add MB-System environment to $HOME/.profile 

## Running this beast:

    git clone https://github.com/qbazd/mb-system-install-script.git
    cd mb-system-install-script
    # ./mb-system_install.sh stable # currently 5.7.5
    # ./mb-system_install.sh git # bleading edge master from dev repo

And hope for the best. If script doesn't work check errors.
Fingers crossed ;)

## Uninstall:

To uninstall:
  - remove $HOME/mb-system
  - remove $HOME/gmt.conf