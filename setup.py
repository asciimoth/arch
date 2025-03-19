#!/bin/python3
from sys import argv
from os import path, environ, listdir, chdir, getcwd
import subprocess
import shutil
from pathlib import Path
import yaml

CONFIG_PATH = path.dirname(path.abspath(argv[0]))
USER = environ["USER"]
ESCALATE_CMD = "sudo"

BASIC_HOSTS = """
# Static table lookup for hostnames.
# See hosts(5) for details.
127.0.0.1 localhost
::1 localhost
127.0.1.1 {}
""".strip()

print("Path to config:", CONFIG_PATH)

def green(text):
	return "\033[32m"+text+"\033[m"

def header(text):
	print("\n"+green(text))

def resolve_path(p, user):
	if p.startswith("~"):
		p = f"/home/{user}" + p[1:]
	return p

def split(text, delimiter=" "):
	return text.split(delimiter)

def with_cfg_path(p):
	return path.join(CONFIG_PATH, p)

def add_user_to_groups(user, groups):
	for group in groups:
		print(f"Adding {user} to group {group}")
		subprocess.run([ESCALATE_CMD, "usermod", "-aG", group, user])

def copyfile(src, dst, with_cfg=True, escalate=False):
	if with_cfg:
		src = with_cfg_path(src)
	print(f"Copying file {src} -> {dst}")
	cmd = ["cp", src, dst]
	if escalate:
		cmd = [ESCALATE_CMD] + cmd
	subprocess.run(cmd)

def read_file(file, with_cfg=True):
	if with_cfg:
		file = with_cfg_path(file)
	with open(file, "rt") as f:
		return f.read()

def write_to_file(file, data, escalate=False, append=False):
	cmd = ["tee"]
	if append:
		cmd += ["-a"]
	cmd += [file]
	if escalate:
		cmd = [ESCALATE_CMD] + cmd
	subprocess.run(cmd, input=data)

def delete(file):
	if Path(file).exists():
		print(f"Deleting {file}")
		subprocess.run([ESCALATE_CMD, "rm", "-rf", file])

def move(src, dst):
	if Path(src).exists():
		print(f"Moving {src} -> {dst}")
		subprocess.run([ESCALATE_CMD, "mv", src, dst])

def backup(file):
	move(file, file+".backup")

def mkdir(p, escalate=False):
	cmd = ["mkdir", "-p", p]
	if escalate:
		cmd = [ESCALATE_CMD] + cmd
	subprocess.run(cmd)

def chmod(file, mode, escalate=True):
	cmd = ["chmod", str(mode), file]
	if escalate:
		cmd = [ESCALATE_CMD] + cmd
	subprocess.run(cmd)

def yaml_load(file, with_cfg=True):
	if with_cfg:
		file = with_cfg_path(file)
	with open(file) as stream:
		return yaml.safe_load(stream)

def symlink(src, dst, escalate=False):
	print(f"Creating symlink {dst} -> {src}")
	if Path(dst).exists() and not Path(dst).is_symlink():
		backup(dst)
	delete(dst)
	cmd = ["ln", "-sf", src, dst]
	if escalate:
		cmd = [ESCALATE_CMD] + cmd
	subprocess.run(cmd)

def comapre(a, b, with_cfg=True):
	if with_cfg:
		a = with_cfg_path(a)
	return read_file(a, False) == read_file(b, False)

def is_installed(pkg):
	return subprocess.run(
		["pacman", "-Qi", pkg],
		stdout = subprocess.DEVNULL,
		stderr = subprocess.DEVNULL
	).returncode == 0

def pacman_install(pkgs, pacman="pacman", escalate=True):
	cmd = f"{pacman} -S --noconfirm --needed".split(" ") + pkgs
	if escalate:
		cmd = [ESCALATE_CMD]+cmd
	code = subprocess.run(cmd).returncode
	if code != 0:
		print("\nIf some pkgs are not found try to update system before running setup:")
		print(f"$ {ESCALATE_CMD} pacman -Syu\n")
		raise Exception(f"Failed to install pkgs: {pkgs}")

def flatpak_is_installed(pkg):
	return subprocess.run(
		["flatpak", "info", pkg],
		stdout = subprocess.DEVNULL,
		stderr = subprocess.DEVNULL
	).returncode == 0

def is_cmd_available(cmd):
	for place in environ["PATH"].split(":"):
		try:
			for entry in listdir(place):
				if entry == cmd:
					return True
		except FileNotFoundError:
			pass
	return False

# ==== Actions ====

def setup_user(user):
	header(f"[ Setting up user {user} ]")
	add_user_to_groups(user, split("audio wheel"))

def setup_hosts():
	header(f"[ Setting up user hosts file ]")
	hosts = BASIC_HOSTS.format(read_file("/etc/hostname", False)) \
		+ "\n" + read_file("hosts")
	write_to_file("/etc/hosts", hosts.encode("utf-8"), True)

def create_symlinks(user):
	header(f"[ Creating symlinks ]")
	symlinks = yaml_load("symlinks.yaml")
	for dst in symlinks:
		src = with_cfg_path(symlinks[dst])
		dst = resolve_path(dst, user)
		symlink(src, dst)

def setup_locales():
	header("[ Setting up locales ]")
	if comapre("locale.gen", "/etc/locale.gen"):
		print("/etc/locale.gen is up to date")
	else:
		copyfile("locale.gen", "/etc/locale.gen", escalate=True)
		print("Generatiung locales")
		subprocess.run([ESCALATE_CMD, "locale-gen"])
	if comapre("locale.conf", "/etc/locale.conf"):
		print("/etc/locale.conf is up to date")
	else:
		copyfile("locale.conf", "/etc/locale.conf", escalate=True)

def setup_xorg():
	header("[ Setting up xorg ]")
	mkdir("/etc/X11/xorg.conf.d", True)
	chmod("/etc/X11", 755)
	chmod("/etc/X11/xorg.conf.d", 755)
	for entry in listdir(with_cfg_path("xorg")):
		src = with_cfg_path(path.join("xorg", entry))
		dst = "/etc/X11/xorg.conf.d/10-"+entry
		copyfile(src, dst, with_cfg=False, escalate=True)

def setup_bash(user):
	header("[ Setting up bash ]")
	startxcmd = '[[ $(tty) == /dev/tty1 ]] && exec startx'
	loadbrcmd = ". "+with_cfg_path("bashrc")
	bash_profile = resolve_path("~/.bash_profile", user)
	bashrc = resolve_path("~/.bashrc", user)
	if startxcmd in read_file(bash_profile, False):
		print(".bash_profile already up to date")
	else:
		write_to_file(
			bash_profile,
			startxcmd.encode("utf-8"),
			escalate=False,
			append=True
		)
	if loadbrcmd in read_file(bashrc, False):
		print(".bashrc already up to date")
	else:
		write_to_file(
			bashrc,
			loadbrcmd.encode("utf-8"),
			escalate=False,
			append=True
		)

def setup_gpg():
	header("[ Setting up gpg ]")
	kdir = with_cfg_path("keys")
	for entry in listdir(kdir):
		subprocess.run(["gpg", "--import", path.join(kdir, entry)])

def install_pkgs():
	header("[ Installing pkgs ]")
	print("Collecting info...")
	to_install = []
	for row in read_file("pkgs").split("\n")+["git", "base-devel"]:
		if row.strip() == "" or row.startswith("#"):
			continue
		if not is_installed(row):
			to_install.append(row)
	if len(to_install) < 1:
		print("All pkgs already installed; Nothing to do")
		return
	print("Pkgs to install:", to_install)
	pacman_install(to_install)

def install_aur(user):
	header("[ Installing AUR pkgs ]")
	#place = resolve_path("~", user)
	savedir = getcwd()
	if not is_cmd_available("yay"):
		print("Installing yay...")
		builddir = "/tmp/build-setup-yay-"+user
		delete(builddir)
		mkdir(builddir)
		chdir(builddir)
		subprocess.run(split("git clone https://aur.archlinux.org/yay.git"))
		chdir(path,join(builddir, "yay"))
		subprocess.run(split("makepkg -si --needed --noconfirm"))
		subprocess.run(split("yay --refresh --noconfirm"))
	chdir(savedir)
	print("Collecting info...")
	to_install = []
	for row in read_file("aur").split("\n"):
		if row.strip() == "" or row.startswith("#"):
			continue
		if not is_installed(row):
			to_install.append(row)
	if len(to_install) < 1:
		print("All AUR pkgs already installed; Nothing to do")
		return
	print("AUR pkgs to install:", to_install)
	pacman_install(to_install, "yay", False)

def setup_flatpak():
	header("[ Setting up flatpak ]")
	flatpak = yaml_load("flatpak/flatpak.yaml")
	print("Collecting info...")
	to_install = []
	for pkg in flatpak["pkgs"]:
		info = flatpak["pkgs"][pkg]
		if not flatpak_is_installed(info["name"]):
			to_install.append((pkg, info))
	if len(to_install) < 1:
		print("All flatpak pkgs already installed; Nothing to do")
	else:
		print("Flatpak pkgs to install:", list(map(lambda x: x[0], to_install)))
		for pkg in to_install:
			subprocess.run(
				split(f"{ESCALATE_CMD} flatpak install -y")+[pkg[1]["repo"], pkg[1]["name"]]
			)
	delete("/flatpak-aliases")
	mkdir("/flatpak-aliases", True)
	chmod("/flatpak-aliases", 755)
	for pkg in flatpak["pkgs"]:
		info = flatpak["pkgs"][pkg]
		if "device" in info:
			subprocess.run(
				split(f"{ESCALATE_CMD} flatpak override --device={info["device"]}")+[info["name"]]
			)
		if "script" in info:
			cmd = f"#!/bin/bash\nflatpak run {pkg} $@"
			script = path.join("/flatpak-aliases", info["script"])
			write_to_file(script, cmd.encode("utf-8"), True, False)
			chmod(script, 755)

def set_pinas():
	header("[ Setting up pinas ]")
	mkdir("/pinas2", True)
	fstab_entry = "pinas2:/ /pinas2 nfs _netdev,noauto,vers=4.2,soft,retrans=10000,x-systemd.automount,x-systemd.mount-timeout=10,timeo=14,x-systemd.idle-timeout=1min 0 0"
	if fstab_entry in read_file("/etc/fstab", False):
		print("fstab already up to date")
	else:
		write_to_file(
			"/etc/fstab",
			fstab_entry.encode("utf-8"),
			escalate=True,
			append=True
		)

def setservices():
	header("[ Enabling/disabling sysd services ]")
	subprocess.run(split("sudo systemctl daemon-reload"))
	services = yaml_load("services.yaml")
	system = services.get("system") or {}
	for service in system:
		cmd = [
			ESCALATE_CMD,
			"systemctl",
			"enable" if system[service] else "disable"
			"--now",
			service
		]
		print(" ".join(cmd))
		subprocess.run(cmd)
	users = services.get("user") or {}
	for service in users:
		cmd = [
			"systemctl",
			"--user",
			"enable" if users[service] else "disable"
			"--now",
			service
		]
		print(" ".join(cmd))
		subprocess.run(cmd)

def setvscode():
	header("[ Setting up vscode ]")
	for ext in yaml_load("vscode/extensions.yaml"):
		subprocess.run(["code", "--install-extension", ext])

setup_user(USER)
setup_hosts()
create_symlinks(USER)
setup_locales()
setup_xorg()
setup_bash(USER)
setup_gpg()
install_pkgs()
install_aur(USER)
setup_flatpak()
set_pinas()
setservices()
setvscode()
