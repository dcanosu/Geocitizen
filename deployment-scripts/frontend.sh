#!/bin/bash

#Colors
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"

PROJECT_FOLDER_PATH="$1"
DEPLOYMENT_URL="${2:-http://localhost:8080/citizen}"

usage() {
	echo -e "${YELLOW}Usage: $0 [<PROJECT_FOLDER_PATH>] [<DEPLOYMENT_URL>]${NC}"
	exit 1
}

if [ "$#" -lt 1 ]; then
	usage;
	exit 1
fi

set_vue_material_new_version() {
	PACKAGE_JSON_PATH="$FRONTED_PATH/package.json"
	OLD_DEPENDENCY='"vue-material": "\^1\.0\.0-beta-7"'
	NEW_DEPENDENCY='"vue-material": "^1.0.0-beta-11"'

	sed -i "s/$OLD_DEPENDENCY/$NEW_DEPENDENCY/g" "$PACKAGE_JSON_PATH"

	if [ $? -eq 0 ]; then
		echo -e "${GREEN} Updated vue-material version in $PACKAGE_JSON_PATH${NC}"
	else
		echo -e "${YELLOW}Failed to update vue-material version in $PACKAGE_JSON_PATH${NC}"
	fi
}

set_server_url() {
	echo -e "${YELLOW}Setting server URL...${NC}"

	CONFIG_FILE="$FRONTED_PATH/src/main.js"
	sed -i "s|export const backEndUrl = .*|export const backEndUrl = '$DEPLOYMENT_URL'|" "$CONFIG_FILE"
}

install_dependencies() {
	echo -e "${YELLOW}Installing compilation dependencies for pyenv...${NC}"

	sudo apt update
	if sudo apt install -y make build-essential libssl-dev zlib1g-dev \
		libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
		libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev \
		liblzma-dev git; then
			echo "Dependencies installed successfully."
	else
			echo "Failed to install dependencies."
			exit 1
	fi
}

clone_pyenv() {
	echo -e "${YELLOW}Cloning pyenv...${NC}"

	if [ -d "$HOME/.pyenv" ]; then
    echo "Directory $HOME/.pyenv already exists. Skipping clone."
	else
			if git clone https://github.com/pyenv/pyenv.git ~/.pyenv; then
					echo "${GREEN}pyenv cloned successfully.${NC}"
			else
					echo "${YELLOW}Failed to clone pyenv.${NC}"
					exit 1
			fi
	fi
}

configure_shell() {
	echo -e "${YELLOW}Configuring shell for pyenv...${NC}"

	if ! grep -q "PYENV_ROOT=\"\$HOME/.pyenv\"" ~/.bashrc; then
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
		echo -e "${GREEN}PYENV_ROOT set in ~/.bashrc${NC}"
	fi

	if ! grep -q "PATH=\"\$PYENV_ROOT/bin:\$PATH\"" ~/.bashrc; then
    echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
		echo -e "${GREEN}PATH set in ~/.bashrc${NC}"
	fi

	if ! grep -q "eval \"\$(pyenv init -)" ~/.bashrc; then
    echo -e 'if command -v pyenv >/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> ~/.bashrc
		echo -e "${GREEN}pyenv init set in ~/.bashrc${NC}"
	fi

	export PYENV_ROOT="$HOME/.pyenv"
	export PATH="$PYENV_ROOT/bin:$PATH"
	if command -v pyenv >/dev/null 2>&1; then
			eval "$(pyenv init -)"
	fi
	source ~/.bashrc
}

install_python_version() {
	echo -e "${YELLOW}Installing Python 2.7.18...${NC}"

	if pyenv install 2.7.18; then
        echo -e "${GREEN}Python 2.7.18 installed successfully.${NC}"
	else
		echo -e "${YELLOW}Failed to install Python 2.7.18.${NC}"
		exit 1
	fi
}

select_local_python_version() {
	echo -e "${YELLOW}Setting Python 2.7.18 as local version...${NC}"

	cd "$PROJECT_FOLDER_PATH"

	if pyenv local 2.7.18; then
		echo -e "${GREEN}Python 2.7.18 set as local version.${NC}"
	else
		echo -e "${YELLOW}Failed to set Python 2.7.18 as local version.${NC}"
		exit 1
	fi
}

install_nvm() {
	echo -e "${YELLOW} Installing NVM...${NC}"

	if curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash; then
		echo -e "${GREEN}NVM installed successfully.${NC}"
	else
		echo -e "${YELLOW}Failed to install NVM.${NC}"
		exit 1
	fi
}

load_nvm() {
	echo -e "${YELLOW}Loading NVM...${NC}"

	source ~/.nvm/nvm.sh
}

install_node_14() {
	echo -e "${YELLOW}Installing Node.js 14...${NC}"

	if nvm install 14; then
		echo -e "${GREEN}Node.js 14 installed successfully.${NC}"
	else
		echo -e "${YELLOW}Failed to install Node.js 14.${NC}"
		exit 1
	fi
}

use_node_version() {
	nvm use 14
}

install_node_version() {
	# Node 14 is required for the project

	if [ -d "$HOME/.nvm" ]; then
		echo -e "${GREEN}NVM is already installed.${NC}"
	else
		install_nvm
	fi

	load_nvm

	if nvm ls 14 | grep "v14."; then
		echo -e "${GREEN}Node.js 14 is already installed.${NC}"
	else
		install_node_14
	fi

	if node -v | grep "v14."; then
		echo -e "${GREEN}Node.js 14 is already in use.${NC}"
	else
		use_node_version
	fi
}

install_python_version_with_pyenv() {
	# Python 2.7.18 is required for the project

	if pyenv versions | grep "2.7"; then
		echo -e "${GREEN}Python 2.7 is already installed.${NC}"
	else
		install_dependencies
		clone_pyenv
		configure_shell
		install_python_version
	fi

	cd "$PROJECT_FOLDER_PATH"
	if pyenv version | grep "2.7"; then
		echo -e "${GREEN}Local Python version is already 2.7.${NC}"
	else
		select_local_python_version
	fi
}

npm_install() {
	echo -e "${YELLOW}Installing npm dependencies...${NC}"

	cd "$FRONTED_PATH"
	if npm install; then
		echo -e "${GREEN}npm dependencies installed successfully.${NC}"
	else
		echo -e "${YELLOW}Failed to install npm dependencies.${NC}"
		exit 1
	fi
}

npm_run_build() {
	echo -e "${YELLOW}Building the project...${NC}"

	cd "$FRONTED_PATH"
	if npm run build; then
		echo -e "${GREEN}Project built successfully.${NC}"
	else
		echo -e "${YELLOW}Failed to build the project.${NC}"
		exit 1
	fi
}

set_routes_to_index_html() {
	echo -e "${YELLOW}Setting routes to index.html...${NC}"

	cd "$FRONTED_PATH/dist"
	HTML_FILE="index.html"

	sed -i 's/<script type=text\/javascript src=/<script type=text\/javascript src=./g' "$HTML_FILE";
	sed -i 's/<link href=/<link href=./g' "$HTML_FILE";

	if [ $? -eq 0 ]; then
		echo -e "${GREEN}Routes set to index.html successfully.${NC}"
	else
		echo -e "${YELLOW}Failed to set routes to index.html.${NC}"
		exit 1
	fi
}

move_frontend_to_backend() {
	echo -e "${YELLOW}Moving frontend to backend...${NC}"

	rm -rf "$PROJECT_FOLDER_PATH/src/main/webapp/static"
	rm "$PROJECT_FOLDER_PATH/src/main/webapp/index.html"

	mv "$FRONTED_PATH/dist/index.html" "$PROJECT_FOLDER_PATH/src/main/webapp"
	mv "$FRONTED_PATH/dist/static" "$PROJECT_FOLDER_PATH/src/main/webapp"
}

# Check if the folder exists
if [ ! -d "$PROJECT_FOLDER_PATH" ]; then
	echo "Folder $PROJECT_FOLDER_PATH does not exist"
	exit 1
fi

FRONTED_PATH="$PROJECT_FOLDER_PATH/front-end"

set_vue_material_new_version
set_server_url
install_node_version
install_python_version_with_pyenv
npm_install
npm_run_build
set_routes_to_index_html
move_frontend_to_backend
