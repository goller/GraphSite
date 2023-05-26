# syntax=docker/dockerfile-upstream:master-labs
FROM python:3.8.5
RUN python3 -m pip install -U pip setuptools
RUN python3 -m pip install numpy==1.19.4   --only-binary :all:
RUN python3 -m pip install pandas==1.1.3   --only-binary :all:
RUN python3 -m pip install biopython==1.78 --only-binary :all:
# GOLLER: see https://pytorch.org/get-started/previous-versions/#linux-and-windows-27 for CUDA
# NOTE: only works for amd64
RUN python3 -m pip install torch==1.7.1+cpu torchvision==0.8.2+cpu torchaudio==0.7.2 -f https://download.pytorch.org/whl/torch_stable.html

WORKDIR /dat
RUN curl --output ncbi-blast-2.10.1+-x64-linux.tar.gz https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.10.1/ncbi-blast-2.10.1+-x64-linux.tar.gz && \
    tar -xzf ncbi-blast-2.10.1+-x64-linux.tar.gz && rm ncbi-blast-2.10.1+-x64-linux.tar.gz

WORKDIR /src
COPY . .

# ftp://ftp.uniprot.org/pub/databases/uniprot/uniref/uniref90/uniref90.fasta.gz <-- 38GB!!
