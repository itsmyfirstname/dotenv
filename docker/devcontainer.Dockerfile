FROM debian:trixie

# System Updates
RUN apt update && apt install \
	git -y

# Install Opencode
RUN curl -fsSL https://opencode.ai/install | bash

