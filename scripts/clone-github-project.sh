#!/bin/bash
# add ssh keys authentication in github.com
git config --global http.sslVerify false
git clone https://github.com/plusjade/jekyll-bootstrap.git zylishiyu.github.com
git config --global http.sslVerify true
cd zylishiyu.github.com/
git remote set-url origin git@github.com:zylishiyu/zylishiyu.github.com.git
git push origin master

