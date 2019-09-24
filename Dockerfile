# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
ARG BASE_CONTAINER=jupyter/minimal-notebook
FROM $BASE_CONTAINER

LABEL maintainer="JupyterLisp Project "

# RUN pwd && ls -latr

USER root

# RUN echo "root:!jupyter" | chpasswd -m

# ffmpeg for matplotlib anim
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
ENV GRANT_SUDO yes

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
     jupyter lab build --dev-build=False --debug --debug-log-path=lab_build_debug.log && \
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
RUN conda install --quiet --yes \
    'jupyter_console' \
    && \
    conda clean --all -f -y && \
    fix-permissions $CONDA_DIR && \
    fix-permissions ${HOME}

RUN ros install sbcl-bin
RUN ros install ./common-lisp-jupyter.asd; exit 0
RUN ros install ./common-lisp-jupyter.asd

# stalls
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


# Install Python 3 packages
# RUN conda install --quiet --yes \
#     'beautifulsoup4=4.8.*' \
#     'conda-forge::blas=*=openblas' \
#     'bokeh=1.3*' \
#     'cloudpickle=1.2*' \
#     'cython=0.29*' \
#     'dask=2.2.*' \
#     'dill=0.3*' \
#     'h5py=2.9*' \
#     'hdf5=1.10*' \
#     'ipywidgets=7.5*' \
#     'matplotlib-base=3.1.*' \
#     'numba=0.45*' \
#     'numexpr=2.6*' \
#     'pandas=0.25*' \
#     'patsy=0.5*' \
#     'protobuf=3.9.*' \
#     'scikit-image=0.15*' \
#     'scikit-learn=0.21*' \
#     'scipy=1.3*' \
#     'seaborn=0.9*' \
#     'sqlalchemy=1.3*' \
#     'statsmodels=0.10*' \
#     'sympy=1.4*' \
#     'vincent=0.4.*' \
#     'xlrd' \
#     && \
#     conda clean --all -f -y && \
#     # Activate ipywidgets extension in the environment that runs the notebook server
#     jupyter nbextension enable --py widgetsnbextension --sys-prefix && \
#     # Also activate ipywidgets extension for JupyterLab
#     # Check this URL for most recent compatibilities
#     # https://github.com/jupyter-widgets/ipywidgets/tree/master/packages/jupyterlab-manager
#     jupyter labextension install @jupyter-widgets/jupyterlab-manager@^1.0.1 --no-build && \
#     jupyter labextension install jupyterlab_bokeh@1.0.0 --no-build && \
#     jupyter lab build --dev-build=False && \
#     npm cache clean --force && \
#     rm -rf $CONDA_DIR/share/jupyter/lab/staging && \
#     rm -rf /home/$NB_USER/.cache/yarn && \
#     rm -rf /home/$NB_USER/.node-gyp && \
#     fix-permissions $CONDA_DIR && \
#     fix-permissions /home/$NB_USER

# # Install facets which does not have a pip or conda package at the moment
# RUN cd /tmp && \
#     git clone https://github.com/PAIR-code/facets.git && \
#     cd facets && \
#     jupyter nbextension install facets-dist/ --sys-prefix && \
#     cd && \
#     rm -rf /tmp/facets && \
#     fix-permissions $CONDA_DIR && \
#     fix-permissions /home/$NB_USER

# # Import matplotlib the first time to build the font cache.
# ENV XDG_CACHE_HOME /home/$NB_USER/.cache/
# RUN MPLBACKEND=Agg python -c "import matplotlib.pyplot" && \
#     fix-permissions /home/$NB_USER

# USER $NB_UID


# FROM archlinux/base:latest

# ARG NB_USER=app
# ARG NB_UID=1000

# ENV USER ${NB_USER}
# ENV HOME /home/${NB_USER}
# ENV PATH "${HOME}/.roswell/bin:${PATH}"

# RUN echo "[multilib]" >> /etc/pacman.conf
# RUN echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf

# RUN pacman -Syu --noconfirm base-devel git jre8-openjdk jupyter lib32-zeromq \
#   maven readline

# RUN useradd --create-home --shell=/bin/false --uid=${NB_UID} ${NB_USER}

# WORKDIR ${HOME}

# USER ${NB_USER}
# RUN git clone https://aur.archlinux.org/roswell.git
# WORKDIR ${HOME}/roswell
# RUN makepkg

# USER root
# RUN ls -t *.pkg.tar.xz | xargs pacman -U --noconfirm

# WORKDIR ${HOME}/common-lisp-jupyter

# COPY . ${HOME}/http://wdune.ourproject.org/examples/pixeltexturetest2.html-lisp-jupyter
# RUN chown -R ${NB_UID} ${HOME} && chgrp -R ${NB_USER} ${HOME}

# USER ${NB_USER}

# RUN ros install sbcl-bin
# RUN ros install ./common-lisp-jupyter.asd; exit 0
# RUN ros install ./common-lisp-jupyter.asd
# RUN echo quit | jupyter-console --no-confirm-exit --kernel=common-lisp \
#   --ZMQTerminalInteractiveShell.kernel_timeout=240

# RUN ros install abcl-bin
# RUN ros run --lisp abcl-bin --eval "(ql:quickload :common-lisp-jupyter)" \
#   --eval "(cl-jupyter:install-roswell :implementation \"abcl-bin\")" --quit
# RUN echo quit | jupyter-console --no-confirm-exit --kernel=common-lisp_abcl-bin \
#   --ZMQTerminalInteractiveShell.kernel_timeout=240

# RUN ros install ccl-bin
# RUN ros run --lisp ccl-bin --eval "(ql:quickload :common-lisp-jupyter)" \
#   --eval "(cl-jupyter:install-roswell :implementation \"ccl-bin\")" --quit
# RUN echo quit | jupyter-console --no-confirm-exit --kernel=common-lisp_ccl-bin \
#   --ZMQTerminalInteractiveShell.kernel_timeout=240

# RUN ros install cmu-bin
# RUN ros run --lisp cmu-bin --eval "(ql:quickload :common-lisp-jupyter)" \
#   --eval "(cl-jupyter:install-roswell :implementation \"cmu-bin\")" --quit
# RUN echo quit | jupyter-console --no-confirm-exit --kernel=common-lisp_cmu-bin \
#   --ZMQTerminalInteractiveShell.kernel_timeout=240

# RUN ros use sbcl-bin

# WORKDIR ${HOME}/common-lisp-jupyter/examples
