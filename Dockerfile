# Copyright (c) Jupyter Development Team, A. Plesch, Waltham, MA
# Distributed under the terms of the Modified BSD License.
ARG BASE_CONTAINER=jupyter/minimal-notebook
FROM $BASE_CONTAINER

LABEL maintainer="JupyterLisp Project"

USER root

# java for abcl
# 32bit for cmucl
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
     ffmpeg \
     curl \
     libczmq-dev \
     libczmq-dev:i386 \
     gcc-multilib \
     libc6-dev-i386 \
     libpng-dev \
     libpng-dev:i386 \
     maven \
     libreadline-dev \
     openjdk-8-jdk && \
    rm -rf /var/lib/apt/lists/*

# abcl needs java8
RUN update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java

COPY . ${HOME}/common-lisp-jupyter
RUN chown -R ${NB_UID} ${HOME} && chgrp -R ${NB_GID} ${HOME}

ENV USER ${NB_USER}
ENV HOME /home/${NB_USER}
ENV PATH "${HOME}/.roswell/bin:${PATH}"
#ENV GRANT_SUDO yes

USER $NB_UID
WORKDIR ${HOME}

#lab extension install also builds
# RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager && \

# RUN  conda install --quiet --yes \
#      'ipywidgets=7.5*' && \ 
#      jupyter nbextension enable --py widgetsnbextension --sys-prefix && \
     # Install Python 3 packages
     # Activate ipywidgets extension in the environment that runs the notebook server
     # Also activate ipywidgets extension for JupyterLab
     # Check this URL for most recent compatibilities
     # https://github.com/jupyter-widgets/ipywidgets/tree/master/packages/jupyterlab-manager
RUN  jupyter labextension install @jupyter-widgets/jupyterlab-manager --no-build && \
     # jupyter labextension install jupyterlab_bokeh@1.0.0 --no-build && \
     jupyter lab build --minimize=False --dev-build=False --debug --debug-log-path=lab_build_debug.log && \
     jupyter lab workspaces import ${HOME}/common-lisp-jupyter/jupyterlab/defaultWorkspace.json && \
     npm cache clean --force && \
     rm -rf $CONDA_DIR/share/jupyter/lab/staging && \
     rm -rf /home/$NB_USER/.cache/yarn && \
     rm -rf /home/$NB_USER/.node-gyp && \
     fix-permissions $CONDA_DIR && \
     fix-permissions ${HOME}

RUN curl -L https://github.com/roswell/roswell/releases/download/v19.08.10.101/roswell_19.08.10.101-1_amd64.deb --output roswell.deb
USER root
RUN dpkg -i roswell.deb

WORKDIR ${HOME}/common-lisp-jupyter

USER $NB_UID

# jupyter-console
RUN conda install --quiet --yes 'jupyter_console' && \
    conda clean --all -f -y && \
    fix-permissions $CONDA_DIR && \
    fix-permissions ${HOME}

RUN ros install sbcl-bin
RUN ros install ./common-lisp-jupyter.asd; exit 0
RUN ros install ./common-lisp-jupyter.asd
RUN echo '(print "Hello World!")' | jupyter-console --no-confirm-exit --kernel=common-lisp \
  --ZMQTerminalInteractiveShell.kernel_timeout=240

RUN ros install cmu-bin
RUN ros run --lisp cmu-bin --eval "(ql:quickload :common-lisp-jupyter)" \
  --eval "(cl-jupyter:install-roswell :implementation \"cmu-bin\")" --quit
RUN echo '(print "Hello World!")' | jupyter-console --no-confirm-exit --kernel=common-lisp_cmu-bin \
  --ZMQTerminalInteractiveShell.kernel_timeout=240

RUN ros install abcl-bin
RUN ros run --lisp abcl-bin --eval "(ql:quickload :common-lisp-jupyter)" \
  --eval "(cl-jupyter:install-roswell :implementation \"abcl-bin\")" --quit
RUN echo '(print "Hello World!")' | jupyter-console --no-confirm-exit --kernel=common-lisp_abcl-bin \
  --ZMQTerminalInteractiveShell.kernel_timeout=240

RUN ros install ccl-bin
RUN ros run --lisp ccl-bin --eval "(ql:quickload :common-lisp-jupyter)" \
  --eval "(cl-jupyter:install-roswell :implementation \"ccl-bin\")" --quit
RUN echo '(print "Hello World!")' | jupyter-console --no-confirm-exit --kernel=common-lisp_ccl-bin \
  --ZMQTerminalInteractiveShell.kernel_timeout=240

RUN ros use sbcl-bin

WORKDIR ${HOME}/common-lisp-jupyter/examples
