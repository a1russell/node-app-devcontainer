# syntax=docker/dockerfile:1

FROM a1russell/node-app-dev-ubuntu

ENV EDITOR='code --wait'

COPY .generated-init.env /etc/devcontainer-generated-init.env

RUN <<EOF
set -o errexit

. /etc/devcontainer-generated-init.env

if [ \
	-n "${CONTAINER_USERNAME}" -a \
	-n "${CONTAINER_UID}" -a \
	-n "${CONTAINER_GID}" \
]; then
	# Remove the `ubuntu` user.
	touch /var/mail/ubuntu
	chown ubuntu /var/mail/ubuntu
	userdel --remove ubuntu

	# Add the container user.
	addgroup --gid ${CONTAINER_GID} ${CONTAINER_USERNAME}
	adduser --disabled-password --uid ${CONTAINER_UID} --gid ${CONTAINER_GID} --shell /bin/zsh ${CONTAINER_USERNAME}
	touch "/home/${CONTAINER_USERNAME}/.zshrc"

	# Set up the .ssh directory for the container user.
	mkdir --parents "/home/${CONTAINER_USERNAME}/.ssh"
	chown "${CONTAINER_UID}:${CONTAINER_GID}" "/home/${CONTAINER_USERNAME}/.ssh"
	chmod 700 "/home/${CONTAINER_USERNAME}/.ssh"

	# Set up Node.js for the container user.
	su --shell /bin/zsh - "${CONTAINER_USERNAME}" <<-'EOI'
		eval "$(fnm env --use-on-cd --shell zsh)"
		fnm install --lts
		npm install --global corepack@latest
		corepack enable pnpm
		corepack install --global pnpm@latest
	EOI

fi

EOF

RUN rm /etc/devcontainer-generated-init.env
