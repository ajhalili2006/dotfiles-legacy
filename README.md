# Andrei Jiroh's Personal Dotfiles
<!-- markdownlint-disable-file MD033 -->

This is the main portal to my personal configuration for Linux/macOS stuff. If you're
working at Recap Time Squad (formerly The Pins Team), see [our dotfiles][df-gl] (currently unmaintained and on old namespace).

[df-gl]: https://gitlab.com/MadeByThePinsHub/dotfiles

## Getting Started

While the clone URLs use GitLab SaaS as the canonical Git repository URL, you can still clone the repository from the following URLs:

* GitLab self-hosted instances: `https://mau.dev/ajhalili2006/dotfiles`[^1]
* SourceHut (official instance): `https://git.sr.ht/~ajhalili2006/dotfiles` (SSH: `git@git.sr.ht:~ajhalili2006/dotfiles`)

[^1]: mau.dev will be my GitLab instance homeserver due to changes to the SaaS free plan, but I'll stay the GitLab SaaS repo on as an mirror.

To get started, run the bootstrap script which handles the repository cloning/pulling for you and then sets things up for you.

```sh
# Pro-tip: Install the essientials like Git and Doppler first!
# Using the essientials setup script will handle Homebrewing for you, among other software-related
# chores. Works on Debian-based distros and Alpine Linux.
$(command -v curl>>/dev/null && echo curl -o- || echo wget -q0-) https://ctrl-c.club/~ajhalili2006/bin/essientials-setup-dotfiles.sh

# Run the bootstrap script without Doppler
$(command -v curl>>/dev/null && echo curl -o- || echo wget -q0-) https://gitlab.com/ajhalili2006/dotfiles/raw/main/bootstrap | bash -
```

## Directory Structure

```bash
$ date && echo && tree -d .
# Monday, 31 October, 2022 11:39:54 PM PST
#
# .
# |-- bash-wakatime # TODO: Migrate to tools directory
# |-- bin # Handmade and third-party scripts go here. (binaries should be in ~/.local/bin instead)
# |-- config # Configuration files, mostly not per distro, with exception of Termux and WSL2 in some cases.
# |   |-- aerc
# |   |   `-- templates
# |   |-- bashrc
# |   |-- byobu
# |   |-- gitconfig
# |   |-- konsole
# |   |-- nanorc
# |   |   |-- config
# |   |   `-- highlighting
# |   |-- ssh-client
# |   |-- systemd
# |   |   `-- system
# |   |-- tmux
# |   `-- zshrc
# |-- docs # Markdown versions of my dotfiles docs at my Miraheze-hosted wiki
# |   |-- additional-tools
# |   `-- os-installation
# |-- gnupg # TODO: Migrate to config directory
# |-- nixos # TODO: Migrate to config directory
# |-- systemd -> config/systemd # TODO: Remove symlink soon
# |-- tests # Testing bootstrap scripts across distros
# |   |-- alpine
# |   |-- common
# |   |   `-- bin
# |   `-- ubuntu
# |-- tools # A bit of homegrown tools and some other stuff I use
# |   |-- archive
# |   |   `-- scripts
# |   |-- bootstrap-utils
# |   `-- setup-scripts
# `-- update-golang # TODO: Migrate to tools directory, might be deprecated due to usage of asdf/other tools

34 directories
```

### Documentation

Available documentation for the on/offboarding processes I do for devices + other tidbits of the bootstrap script can be accessible through [the `docs` directory](./docs) and on [my personal wiki hosted on Miraheze](https://ajhalili2006.miraheze.org/wiki/Dotfiles).

## License and contributions

Code is licensed under [the MPL-2.0](LICENSE) license, while docs on my MediaWiki-powered wiki + here in this repository are licensed
under [CC BY-SA 4.0 International](https://creativecommons.org/licenses/by-sa/4.0/legalcode) license.

Patches (either via GitLab merge requests or email patches via
`~ajhalili2006/public-inbox@lists.sr.ht`) are welcome, but technical
support for forks is currently unavailable due to this repository being
used for personal day-to-day use.

### Third-party source code

Some of the code used in this dotfiles repository (and related repositories via Git submodules)
uses third-party code, which might be licensed under other licenses, sometimes might not be compartible with
the repository licenses.

* TBD
* [Drew DeVault's Dotfiles][sircmpwn-df], specifically some [templates][sircmpwn-dt-aerc-templates] and [config for aerc][sircmpwn-dt-aerc]

[sircmpwn-df]: https://git.sr.ht/~sircmpwn/dotfiles
[sircmpwn-dt-aerc-templates]: https://git.sr.ht/~sircmpwn/dotfiles/tree/.config/aerc/templates
[sircmpwn-dt-aerc]: https://git.sr.ht/~sircmpwn/dotfiles/tree/.config/aerc
---

<details>

<summary>Deprecated docs stashed here for archival purposes, might be removed later.</summary>

## Want to fork me owo?

> This section is outdated and will be revised in the future since I also have other stuff to do behind the scenes.

Follow the checklist below after forking to ensure no references to mine are found. **Remember that your fork, your problem.** It's up to you on how do you customize stuff. You can use [The Pins Team's dotfiles template][template] to start from our template.

[template]: https://github.com/MadeByThePinsHub/dotfiles-template

* [ ] Customize the `dotfiles-bootstrapper-script.sh` and `setup.sh` into your needs.
* [ ] Delete any existing dotfiles I made (e.g. `gitconfig/*`, `bashrc/*` excluding `aliases` and `worthwhile-functions`, etc.) and do `bin/backup-dotfiles`. That script will move your current config into your `.dotfiles` local repo and do soft links.
* [ ] Edit `bin/fix-wrong-emails#L6-7` to use your email instead of mine.
* [ ] Edit `bin/add-ssh-keys#L4` to use your SSH key in `~/.ssh` directory.
* [ ] Want to backup your worst secrets AKA SSH and PGP keys (and some Pyrgoram session files?) Use my `bin/init-secrets-dir` script to setup an `secrets` directory. Don't forget to push this into an GitLab private repo.

</details>
