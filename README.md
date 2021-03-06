# Archsible

[![Build Status](https://travis-ci.org/JamieMagee/archsible.svg?branch=master)](https://travis-ci.org/JamieMagee/archsible)
[![MIT license](https://img.shields.io/badge/license-MIT-blue.svg)](http://opensource.org/licenses/MIT)
[![Requirements Status](https://requires.io/github/JamieMagee/archsible/requirements.svg?branch=master)](https://requires.io/github/JamieMagee/archsible/requirements/?branch=master)

Archsible is a collection of [Ansible](https://www.ansible.com/) playbooks for [Arch Linux](https://www.archlinux.org/).

## Requirements

* [`ansible`](https://www.archlinux.org/packages/community/any/ansible/)

## Installation

1. `git clone https://github.com/JamieMagee/archsible.git --recurse-submodules`
2. Copy `host_vars/localhost.example` to `host_vars/localhost`
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
