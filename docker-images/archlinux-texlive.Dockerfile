FROM archlinux/base

WORKDIR /tmp/mount
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm grep git make curl && \
    pacman -S --noconfirm texlive-bibtexextra texlive-bin texlive-core texlive-fontsextra texlive-formatsextra texlive-langchinese texlive-latexextra texlive-pictures texlive-pstricks texlive-science ghostscript
RUN texconfig rehash

ENTRYPOINT ["bash", "-c"]
