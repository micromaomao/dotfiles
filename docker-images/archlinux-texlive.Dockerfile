FROM archlinux/base

WORKDIR /tmp/mount
RUN pacman -Syu --noconfirm --force && \
    pacman -S --noconfirm --force grep git make curl && \
    pacman -S --noconfirm --force texlive-bibtexextra texlive-bin texlive-core texlive-fontsextra texlive-formatsextra texlive-langchinese texlive-latexextra texlive-pictures texlive-pstricks texlive-science ghostscript

ENTRYPOINT ["bash", "-c"]
