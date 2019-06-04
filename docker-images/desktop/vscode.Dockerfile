FROM maowtm/gtk
WORKDIR /tmp/

# For vscode go extension we need: dlv gocode gocode-gomod godef goimports gometalinter go-outline gopkgs gorename go-symbols guru
RUN pacman -S --force --noconfirm fakeroot && \
    runuser -u nobody -g nobody --preserve-environment -- bash -c "\
    curl -sL 'https://aur.archlinux.org/cgit/aur.git/snapshot/visual-studio-code-bin.tar.gz' -o visual-studio-code-bin.tar.gz && \
    tar zxf visual-studio-code-bin.tar.gz && \
    cd visual-studio-code-bin && \
    makepkg" && \
    pacman --force --noconfirm -U visual-studio-code-bin/visual-studio-code-bin-*.tar && \
    rm -rf visual-studio-code-bin visual-studio-code-bin.tar.gz && \
    pacman --noconfirm -R rust && \
    pacman --force --noconfirm -S fish pkgfile rustup && \
    pkgfile --update && \
    export GOPATH=/tmp/go/ HOME=/tmp/ SHELL=/usr/bin/fish && \
    runuser -u nobody -g nobody --preserve-environment -- bash -c "\
    mkdir /tmp/go && cd /tmp/go && \
    go get github.com/ramya-rao-a/go-outline/ \
           github.com/mdempsky/gocode \
           github.com/uudashr/gopkgs \
           github.com/acroca/go-symbols \
           golang.org/x/tools/cmd/guru \
           golang.org/x/tools/cmd/gorename \
           github.com/go-delve/delve/cmd/dlv \
           github.com/rogpeppe/godef \
           golang.org/x/tools/cmd/goimports \
           github.com/alecthomas/gometalinter && \
    cd /tmp && \
    rustup toolchain install stable" && \
    (chmod a+rX -R /tmp || true) && \
    rm -rf /tmp/.cache /var/cache/pkgfile/*

ENV GOPATH=/tmp/go/
ENV HOME=/tmp/
ENV SHELL=/usr/bin/fish

USER nobody:nobody

VOLUME [ "/tmp/.vscode", "/tmp/workspace", "/tmp/.X11-unix" ]
ENTRYPOINT [ "code", "--new-window", "--verbose", "/tmp/workspace" ]
