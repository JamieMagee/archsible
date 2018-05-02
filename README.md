# Archsible

[![Build Status](https://travis-ci.org/JamieMagee/archsible.svg?branch=master)](https://travis-ci.org/JamieMagee/archsible)
[![MIT license](https://img.shields.io/badge/license-MIT-blue.svg)](http://opensource.org/licenses/MIT)
[![Requirements Status](https://requires.io/github/JamieMagee/archsible/requirements.svg?branch=master)](https://requires.io/github/JamieMagee/archsible/requirements/?branch=master)
[![Dependabot badge](https://img.shields.io/badge/Dependabot-enabled-blue.svg)](https://dependabot.com/)

Archsible is a collection of [Ansible](https://www.ansible.com/) playbooks for [Arch Linux](https://www.archlinux.org/).

## Requirements

* [python](https://www.archlinux.org/packages/?name=python)
* [python-pipenv](https://www.archlinux.org/packages/?name=python-pipenv)

## Installation

1.  Copy `host_vars/localhost.example` to `host_vars/localhost`
2.  Edit `localhost` for your own setup
3.  Install the dependencies `pipenv install`
4.  Activate the virtualenv `pipenv shell`
5.  Install ansible galaxy roles `ansible-galaxy install -r requirements.yml -p galaxy`
5.  Navigate to the `playbooks` directory
6.  Run `ansible-playbook <playbook>.yml`

## Development

### Installation

Install from Pipfile:

```sh
pipenv install --dev
```

### Testing

Activate the Pipenv shell:

```sh
pipenv shell
```

Run:

```sh
yamllint .
ansible-lint <playbook>.yml
```