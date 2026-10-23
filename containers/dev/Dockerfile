# syntax=docker/dockerfile:1
FROM debian:trixie-slim AS neovim
ARG NEOVIM_REF=master
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential ca-certificates cmake curl gettext git ninja-build unzip \
    && rm -rf /var/lib/apt/lists/*
RUN git clone --filter=blob:none https://github.com/neovim/neovim.git /src/neovim \
    && cd /src/neovim && git checkout "$NEOVIM_REF" \
    && git rev-parse HEAD > /neovim-commit \
    && make CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX=/opt/neovim \
    && make install

FROM debian:trixie-slim AS rust
ARG RUST_TOOLCHAIN=stable
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*
RUN curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs -o /rustup-init.sh \
    && CARGO_HOME=/opt/rust-tools RUSTUP_HOME=/opt/rustup \
       sh /rustup-init.sh -y --profile minimal --no-modify-path \
       --default-toolchain "$RUST_TOOLCHAIN"

FROM debian:trixie-slim
ARG OPENCODE_VERSION=latest
ARG UV_VERSION=latest
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash bat build-essential ca-certificates cmake curl fd-find fzf gettext gh git \
    libssl-dev locales ninja-build nodejs npm openssh-client pkg-config python3 python3-dev \
    python3-venv ripgrep stow tmux unzip wget xz-utils zoxide zsh \
    zsh-autosuggestions zsh-syntax-highlighting zstd \
    && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -f UTF-8 en_US.UTF-8 \
    && npm install -g "@opencode/cli@${OPENCODE_VERSION}" \
    && python3 -m venv /opt/uv \
    && if [ "$UV_VERSION" = latest ]; then /opt/uv/bin/pip install --no-cache-dir uv; \
       else /opt/uv/bin/pip install --no-cache-dir "uv==$UV_VERSION"; fi \
    && ln -s /opt/uv/bin/uv /usr/local/bin/uv \
    && ln -s /opt/uv/bin/uvx /usr/local/bin/uvx \
    && ln -s /usr/bin/fdfind /usr/local/bin/fd \
    && ln -s /usr/bin/batcat /usr/local/bin/bat \
    && useradd --create-home --uid 1000 --shell /usr/bin/zsh dev \
    && mkdir -p /workspace /home/dev/dotfiles \
    && chown dev:dev /workspace /home/dev/dotfiles
COPY --from=neovim /opt/neovim /opt/neovim
COPY --from=rust /opt/rust-tools/bin/ /opt/rust-tools/bin/
COPY --from=rust /opt/rustup/ /opt/rustup/
RUN ln -s /opt/neovim/bin/nvim /usr/local/bin/nvim \
    && for tool in cargo rustc rustdoc rustup; do \
         ln -s "/opt/rust-tools/bin/$tool" "/usr/local/bin/$tool"; \
       done
COPY --from=neovim /neovim-commit /usr/local/share/neovim-commit
COPY --chown=dev:dev nvim/ /home/dev/dotfiles/nvim/
COPY --chown=dev:dev containers/dev/config/ /home/dev/dotfiles/container/
COPY --chown=dev:dev opencode/.config/opencode/opencode.json opencode/.config/opencode/cli.json opencode/.config/opencode/AGENTS.md /home/dev/dotfiles/container/.config/opencode/
COPY --chown=dev:dev tmux/.tmux.conf /home/dev/dotfiles/container/.tmux.conf
COPY --chmod=755 containers/dev/entrypoint.sh /usr/local/bin/dev-entrypoint
ENV LANG=en_US.UTF-8 \
    RUSTUP_HOME=/opt/rustup \
    PATH=/opt/neovim/bin:/home/dev/.cargo/bin:/home/dev/.local/bin:/opt/rust-tools/bin:/usr/local/bin:/usr/bin:/bin \
    EDITOR=nvim VISUAL=nvim
USER dev
RUN python3 -c 'import json, pathlib; p = pathlib.Path("/home/dev/dotfiles/container/.config/opencode/opencode.json"); c = json.loads(p.read_text()); c["permissions"] = [{"action": "*", "resource": "*", "effect": "allow"}]; p.write_text(json.dumps(c, indent=2) + "\n")' \
    && rm /home/dev/.bashrc \
    && cd /home/dev/dotfiles && stow --target=/home/dev nvim container
WORKDIR /workspace
ENTRYPOINT ["dev-entrypoint"]
CMD ["zsh"]
