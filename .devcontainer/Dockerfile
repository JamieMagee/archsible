FROM docker.io/library/archlinux:base-devel

RUN \
    # create a user
    useradd vscode -m \
    # delete the vscode password
    && passwd -d vscode \
    # enable vscode to sudo without password
    && printf 'root ALL=(ALL) ALL\n' | tee -a /etc/sudoers \
    # update package database
    && pacman -Syy \
    # install dependencies
    && pacman -S --noconfirm \
      # required sudo
      sudo \
      # required to 
      git \
      # required to write and lint ansible
      ansible \
      ansible-lint \
      molecule \
      yamllint \
    # upgrade distro
    && pacman -Syyu --noconfirm \
    # clean downloaded packages
    && yes | pacman -Scc