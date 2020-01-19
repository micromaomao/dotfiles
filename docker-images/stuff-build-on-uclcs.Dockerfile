FROM centos:7

RUN yum update -y && \
    # bison, ncurses, flex, openssl and expat is present in UCL cs linux system \
    yum install -y bzip2 gcc gcc-c++ make gettext bison bison-devel ncurses-devel flex flex-devel openssl-devel curl-devel expat-devel
RUN mkdir -p /cs/student/ug/2019/tingmwan/stuff && \
    # fish shell \
    cd /usr/src/ && \
    curl -sL 'https://github.com/fish-shell/fish-shell/releases/download/3.0.2/fish-3.0.2.tar.gz' -o fish-3.0.2.tar.gz && \
    tar zxf fish-3.0.2.tar.gz && \
    cd fish-3.0.2 && \
    ./configure --prefix=/cs/student/ug/2019/tingmwan/stuff/ && \
    make -j3 && \
    make install && \
    # Nmap \
    cd /usr/src/ && \
    curl -sL 'https://nmap.org/dist/nmap-7.80.tar.bz2' -o nmap-7.80.tar.bz2 && \
    bzip2 -d < nmap-7.80.tar.bz2 | tar x && \
    cd nmap-7.80 && \
    ./configure --prefix=/cs/student/ug/2019/tingmwan/stuff/ --without-zenmap --with-libpcap=included --with-libpcre=included && \
    make -j3 && \
    make install && \
    # vim \
    cd /usr/src/ && \
    curl -sL 'https://github.com/vim/vim/archive/v8.2.0046.tar.gz' -o vim.tar.gz && \
    tar zxf vim.tar.gz && \
    cd vim-8.2.0046 && \
    ./configure --prefix=/cs/student/ug/2019/tingmwan/stuff/ --with-x=no --disable-gui --with-features=huge && \
    make -j3 && \
    make install && \
    # git \
    cd /usr/src/ && \
    curl -sL 'https://github.com/git/git/archive/v2.24.1.tar.gz' -o git.tar.gz && \
    tar zxf git.tar.gz && \
    cd git-2.24.1/ && \
    make -j3 prefix=/cs/student/ug/2019/tingmwan/stuff/ && \
    make prefix=/cs/student/ug/2019/tingmwan/stuff/ install && \
    # cmake \
    cd /usr/src/ && \
    curl -sL 'https://github.com/Kitware/CMake/releases/download/v3.16.2/cmake-3.16.2.tar.gz' -o cmake.tar.gz && \
    tar zxf cmake.tar.gz && \
    cd cmake-3.16.2/ && \
    ./bootstrap --prefix=/cs/student/ug/2019/tingmwan/stuff/ && \
    gmake && \
    gmake install

RUN function t () { \
      filename="$1"; \
      if [ ! -f "/cs/student/ug/2019/tingmwan/stuff/bin/$filename" ]; then \
        echo $filename does not exist!; \
        exit 1; \
      fi; \
    }; \
    t fish && \
    t nmap && \
    t vim && \
    t git && \
    t cmake
