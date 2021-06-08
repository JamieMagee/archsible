FROM docker.io/library/archlinux:base

RUN \
  pacman -Syy \
  # install dependencies
  && pacman -S --noconfirm \
    openssh \
    python \
  && ssh-keygen -A \
  # configure SSH
  && sed -i 's/#Port 22/Port 2121/g' /etc/ssh/sshd_config \
  && sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords yes/g' /etc/ssh/sshd_config \
  && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config \
  # upgrade distro
  && pacman -Syyu --noconfirm \
  # clean downloaded packages
  && yes | pacman -Scc \
  && passwd -d root

EXPOSE 2121

ENTRYPOINT [ "/usr/sbin/sshd", "-d" ]