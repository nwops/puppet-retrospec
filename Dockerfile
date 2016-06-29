FROM ruby:2.2
MAINTAINER Corey Osman
RUN useradd developer -m -s /bin/bash
USER developer
WORKDIR /home/developer/module
ENV HOME /home/developer
ENV GEM_HOME "${HOME}/.gems"
ENV PATH "$${PATH}:${HOME}/bin"
# don't include ri/rdoc with gem installs
RUN mkdir /home/developer/puppet-retrospec && echo "gem: --no-rdoc --no-ri --bindir ~/bin\ngemdir: ~/.gems" > /home/developer/.gemrc

# Install
COPY ./ /home/developer/puppet-retrospec
RUN cd /home/developer/puppet-retrospec && \
    gem build puppet-retrospec.gemspec && \
    gem install /home/developer/puppet-retrospec/puppet-retrospec*.gem facter hiera

# RUN THIS COMMAND AND EXIT
CMD retrospec puppet

# TO BUILD RUN
# docker build --rm -t nwops/puppet-retrospec:latest .
