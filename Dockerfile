FROM skranz/repbox_mono:dev

ARG STATA_LIC

RUN echo $STATA_LIC > /usr/local/stata/stata.lic

COPY run_config.yml /root/run_config.yml
COPY io_config.yml /root/io_config.yml


MAINTAINER Sebastian Kranz "sebastian.kranz@uni-ulm.de"
