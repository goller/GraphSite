# syntax=docker/dockerfile-upstream:master-labs
FROM python:3.8.5 as dssp

WORKDIR /app

RUN apt-get update && \
    apt-get install -y make rsync wget && \
    apt-get install -y git g++ libboost-all-dev libbz2-dev doxygen xsltproc docbook docbook-xsl docbook-xml autoconf automake autotools-dev && \
    mkdir -p /deps

# Install libzeep
RUN git clone https://github.com/mhekkel/libzeep.git /deps/libzeep ;\
    cd /deps/libzeep ;\
    git checkout tags/v3.0.3
# XXX: Workaround due to bug in libzeep's makefile
RUN sed -i '71s/.*/\t\$\(CXX\) \-shared \-o \$@ \-Wl,\-soname=\$\(SO_NAME\) \$\(OBJECTS\) \$\(LDFLAGS\)/' /deps/libzeep/makefile
WORKDIR /deps/libzeep
# XXX: Run ldconfig manually to work around a bug in libzeep's makefile
RUN make ; make install ; ldconfig

WORKDIR /app

# TODO(goller): this branch remove the -Werror flag.  It is branched from 3.1.4.
RUN git clone https://github.com/goller/dssp.git && \
    cd dssp && \
    git checkout remove-werror && \
    ./autogen.sh && \
    ./configure && \
    make && \
    make install

# syntax=docker/dockerfile-upstream:master-labs
FROM python:3.8.5 as build
RUN python3 -m pip install -U pip setuptools
RUN python3 -m pip install numpy==1.19.4   --only-binary :all:
RUN python3 -m pip install pandas==1.1.3   --only-binary :all:
RUN python3 -m pip install biopython==1.78 --only-binary :all:

# TODO(goller): slim this down to just what dssp needs
RUN apt-get update && \
    apt-get install -y git glibboost-all-dev libbz2-dev

COPY --from=dssp /app/dssp/mkdssp /dat/dssp-3.1.4/mkdssp

# GOLLER: see https://pytorch.org/get-started/previous-versions/#linux-and-windows-27 for CUDA
# NOTE: only works for amd64
RUN python3 -m pip install torch==1.7.1+cpu torchvision==0.8.2+cpu torchaudio==0.7.2 -f https://download.pytorch.org/whl/torch_stable.html

WORKDIR /dat
RUN curl --output ncbi-blast-2.10.1+-x64-linux.tar.gz https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.10.1/ncbi-blast-2.10.1+-x64-linux.tar.gz && \
    tar -xzf ncbi-blast-2.10.1+-x64-linux.tar.gz && rm ncbi-blast-2.10.1+-x64-linux.tar.gz


# ARM: https://mmseqs.com/hhsuite/hhsuite-linux-arm64.tar.gz
# TODO(goller): We aren't sure if 3.3.0 is the right version.
RUN curl --output hhsuite-linux-avx2.tar.gz https://mmseqs.com/hhsuite/hhsuite-linux-avx2.tar.gz && \
    tar -xvf hhsuite-linux-avx2.tar.gz && rm hhsuite-linux-avx2.tar.gz && \
    mv hhsuite /dat/hhsuite-3.3.0

WORKDIR /src
COPY . .

# ftp://ftp.uniprot.org/pub/databases/uniprot/uniref/uniref90/uniref90.fasta.gz <-- 38GB!!
