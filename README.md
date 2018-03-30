# Archsible

[![Build Status](https://travis-ci.org/JamieMagee/archsible.svg?branch=master)](https://travis-ci.org/JamieMagee/archsible)

Archsible is a collection of [Ansible](https://www.ansible.com/) playbooks for [Arch Linux](https://www.archlinux.org/).

## Requirements

- [ansible](https://www.archlinux.org/packages/?name=ansible)
- [python2](https://www.archlinux.org/packages/?name=python2)

## Installation

1. Copy `host_vars/localhost.example` to `host_vars/localhost`
2. Edit `localhost` for your own setup
3. Run `ansible-playbook <playbook>.yml`

## Development

### Requirements

- [python-pipenv](https://www.archlinux.org/packages/?name=python-pipenv)
- [docker](https://www.archlinux.org/packages/?name=docker)
- [virtualbox](https://www.archlinux.org/packages/?name=virtualbox)
- [vagrant](https://www.archlinux.org/packages/?name=vagrant)

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

Navigate to the directory of the role:

```sh
cd roles/timezone
```

Run the tests:

```sh
molecule test
```

To run tests for all roles run:

```sh
chmod +x test.sh
./test.sh
```

Or if your computer doesn't support VT-x, and you only want to run docker tests, run:

```sh
chmod +x test-docker.sh
./test.sh
```
