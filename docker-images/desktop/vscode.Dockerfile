FROM maowtm/gtk
WORKDIR /tmp/
RUN pacman -S --force --noconfirm fakeroot
USER nobody:nobody
RUN curl -sL 'https://aur.archlinux.org/cgit/aur.git/snapshot/visual-studio-code-bin.tar.gz' -o visual-studio-code-bin.tar.gz && \
    tar zxf visual-studio-code-bin.tar.gz && \
    cd visual-studio-code-bin && \
    makepkg
USER root:root
RUN pacman --force --noconfirm -U visual-studio-code-bin/visual-studio-code-bin-*.tar && \
    rm -rf visual-studio-code-bin visual-studio-code-bin.tar.gz
USER nobody:nobody
