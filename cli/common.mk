# Common variables
# Raw OS and Arch detection
OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH := $(shell uname -m)
INSTALL_DIR ?= /usr/local/bin
