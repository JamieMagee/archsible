# Archsible

[![MIT license](https://img.shields.io/badge/license-MIT-blue.svg?style=for-the-badge)](http://opensource.org/licenses/MIT)

Archsible is a collection of [Ansible](https://www.ansible.com/) playbooks for [Arch Linux](https://www.archlinux.org/).

## Requirements

* [`ansible`](https://www.archlinux.org/packages/community/any/ansible/)

## Installation

1. `git clone https://github.com/JamieMagee/archsible.git`
2. Copy `host_vars/localhost.yml.example` to `host_vars/localhost`
3. Edit `localhost` for your own setup
4. Install ansible galaxy roles `ansible-galaxy install -r requirements.yml -p galaxy`
5. Run `ansible-playbook playbooks/<playbook>.yml`
6. Update donf db `sudo dconf update`
7. Reboot

## Development

### Requirements

* [`ansible-lint`](https://www.archlinux.org/packages/community/any/ansible-lint/)
* [`yamllint`](https://aur.archlinux.org/packages/yamllint/)

### Testing

Run:

```sh
yamllint .
ansible-lint <playbook>.yml
```
